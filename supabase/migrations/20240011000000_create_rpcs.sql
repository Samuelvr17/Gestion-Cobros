-- Create Business Logic RPCs for Gestion-Cobros

-- 1. Function: crear_prestamo
CREATE OR REPLACE FUNCTION public.crear_prestamo(
    p_client_id UUID,
    p_collector_id UUID,
    p_principal_amount NUMERIC,
    p_total_installments INTEGER,
    p_payment_frequency TEXT
) RETURNS JSON AS $$
DECLARE
    v_available_fund NUMERIC;
    v_has_active_loan BOOLEAN;
    v_total_amount NUMERIC;
    v_installment_amount NUMERIC;
    v_loan_number TEXT;
    v_expected_end_date TIMESTAMPTZ;
    v_loan_id UUID;
    v_i INTEGER;
    v_due_date TIMESTAMPTZ;
    v_frequency_interval INTERVAL;
    v_result JSON;
BEGIN
    -- 1. Check fund availability
    SELECT available_amount INTO v_available_fund FROM public.fund_accounts WHERE id = 'main';
    IF v_available_fund < p_principal_amount THEN
        RAISE EXCEPTION 'Saldo insuficiente en el fondo principal. Disponible: %', v_available_fund;
    END IF;

    -- 2. Check client active loans
    SELECT EXISTS (SELECT 1 FROM public.loans WHERE client_id = p_client_id AND status = 'ACTIVE') INTO v_has_active_loan;
    IF v_has_active_loan THEN
        RAISE EXCEPTION 'El cliente ya tiene un préstamo activo.';
    END IF;

    -- 3. Calculations
    v_total_amount := p_principal_amount * 1.20;
    v_installment_amount := v_total_amount / p_total_installments;
    v_loan_number := 'LN-' || to_char(NOW(), 'YYYYMMDD') || '-' || floor(random()*9000+1000);
    
    v_frequency_interval := CASE p_payment_frequency 
        WHEN 'DAILY' THEN '1 day'::INTERVAL
        WHEN 'WEEKLY' THEN '7 days'::INTERVAL
        WHEN 'MONTHLY' THEN '1 month'::INTERVAL
        ELSE '1 day'::INTERVAL
    END;

    v_expected_end_date := NOW() + (v_frequency_interval * p_total_installments);

    -- 4. Insert Loan
    INSERT INTO public.loans (
        loan_number, client_id, collector_id, principal_amount, 
        total_amount, installment_amount, payment_frequency, 
        total_installments, remaining_amount, expected_end_date
    ) VALUES (
        v_loan_number, p_client_id, p_collector_id, p_principal_amount,
        v_total_amount, v_installment_amount, p_payment_frequency::payment_frequency,
        p_total_installments, v_total_amount, v_expected_end_date
    ) RETURNING id INTO v_loan_id;

    -- 5. Insert Installments
    FOR v_i IN 1..p_total_installments LOOP
        v_due_date := NOW() + (v_frequency_interval * v_i);
        INSERT INTO public.installments (loan_id, number, amount, due_date)
        VALUES (v_loan_id, v_i, v_installment_amount, v_due_date);
    END LOOP;

    -- 6. Update Funds
    UPDATE public.fund_accounts 
    SET available_amount = available_amount - p_principal_amount,
        total_disbursed = total_disbursed + p_principal_amount,
        updated_at = NOW()
    WHERE id = 'main';

    -- 7. Log Movement
    INSERT INTO public.fund_movements (fund_account_id, type, amount, created_by_id, loan_id, note)
    VALUES ('main', 'LOAN_DISBURSEMENT', p_principal_amount, p_collector_id, v_loan_id, 'Desembolso de préstamo ' || v_loan_number);

    -- 8. Build Result
    SELECT row_to_json(l) INTO v_result FROM public.loans l WHERE l.id = v_loan_id;
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function: registrar_pago
CREATE OR REPLACE FUNCTION public.registrar_pago(
    p_loan_id UUID,
    p_collector_id UUID,
    p_amount NUMERIC,
    p_shift_id UUID
) RETURNS JSON AS $$
DECLARE
    v_loan_status loan_status;
    v_loan_remaining NUMERIC;
    v_collector_check UUID;
    v_amount_left NUMERIC := p_amount;
    v_inst_record RECORD;
    v_apply_to_inst NUMERIC;
    v_payment_id UUID;
    v_result JSON;
BEGIN
    -- 1. Validation
    SELECT status, remaining_amount, collector_id INTO v_loan_status, v_loan_remaining, v_collector_check 
    FROM public.loans WHERE id = p_loan_id;

    IF v_loan_status IS NULL THEN RAISE EXCEPTION 'Préstamo no encontrado.'; END IF;
    IF v_loan_status != 'ACTIVE' THEN RAISE EXCEPTION 'El préstamo no está activo.'; END IF;
    IF v_collector_check != p_collector_id THEN RAISE EXCEPTION 'No tiene permisos para cobrar este préstamo.'; END IF;
    IF p_amount > v_loan_remaining THEN RAISE EXCEPTION 'El monto supera el saldo restante del préstamo.'; END IF;

    -- 2. Process Installments
    FOR v_inst_record IN 
        SELECT id, number, amount, paid_amount, status 
        FROM public.installments 
        WHERE loan_id = p_loan_id AND status != 'PAID'
        ORDER BY number ASC
    LOOP
        EXIT WHEN v_amount_left <= 0;

        v_apply_to_inst := LEAST(v_amount_left, (v_inst_record.amount - v_inst_record.paid_amount));
        
        -- Update Installment
        UPDATE public.installments 
        SET paid_amount = paid_amount + v_apply_to_inst,
            status = CASE WHEN (paid_amount + v_apply_to_inst) >= amount THEN 'PAID'::installment_status ELSE 'PARTIAL'::installment_status END,
            paid_at = CASE WHEN (paid_amount + v_apply_to_inst) >= amount THEN NOW() ELSE paid_at END
        WHERE id = v_inst_record.id;

        -- Insert Payment Record
        INSERT INTO public.payments (loan_id, installment_id, collector_id, shift_id, amount, is_late)
        VALUES (p_loan_id, v_inst_record.id, p_collector_id, p_shift_id, v_apply_to_inst, (NOW() > (SELECT due_date FROM public.installments WHERE id = v_inst_record.id)))
        RETURNING id INTO v_payment_id;

        -- Log Fund Movement for each applied part? (User requested one inflow per call usually, but we log cumulative or per application?)
        -- Applying per application for better traceability or one at end? User says "insert fund_movement type PAYMENT_INFLOW"
        
        v_amount_left := v_amount_left - v_apply_to_inst;
    END LOOP;

    -- 3. Update Loan
    UPDATE public.loans 
    SET paid_amount = paid_amount + p_amount,
        remaining_amount = remaining_amount - p_amount,
        paid_installments = (SELECT count(*) FROM public.installments WHERE loan_id = p_loan_id AND status = 'PAID'),
        status = CASE WHEN (remaining_amount - p_amount) <= 0 THEN 'COMPLETED'::loan_status ELSE status END,
        updated_at = NOW()
    WHERE id = p_loan_id;

    -- 4. Update Shift and Funds
    IF p_shift_id IS NOT NULL THEN
        UPDATE public.cash_register_shifts SET total_collected = total_collected + p_amount WHERE id = p_shift_id;
    END IF;

    UPDATE public.fund_accounts 
    SET available_amount = available_amount + p_amount,
        total_recovered = total_recovered + p_amount,
        updated_at = NOW()
    WHERE id = 'main';

    INSERT INTO public.fund_movements (fund_account_id, type, amount, created_by_id, loan_id, payment_id, note)
    VALUES ('main', 'PAYMENT_INFLOW', p_amount, p_collector_id, p_loan_id, v_payment_id, 'Cobro recibido');

    -- 5. Return Result
    SELECT json_build_object(
        'loan_id', p_loan_id,
        'status', status,
        'applied_amount', p_amount,
        'remaining_amount', remaining_amount
    ) INTO v_result FROM public.loans WHERE id = p_loan_id;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Function: registrar_gasto
CREATE OR REPLACE FUNCTION public.registrar_gasto(
    p_user_id UUID,
    p_shift_id UUID,
    p_category TEXT,
    p_amount NUMERIC,
    p_description TEXT
) RETURNS JSON AS $$
DECLARE
    v_expense_id UUID;
    v_result JSON;
BEGIN
    INSERT INTO public.expenses (user_id, shift_id, category, amount, description)
    VALUES (p_user_id, p_shift_id, p_category, p_amount, p_description)
    RETURNING id INTO v_expense_id;

    IF p_shift_id IS NOT NULL THEN
        UPDATE public.cash_register_shifts SET total_expenses = total_expenses + p_amount WHERE id = p_shift_id;
    END IF;

    SELECT row_to_json(e) INTO v_result FROM public.expenses e WHERE e.id = v_expense_id;
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Function: cerrar_caja
CREATE OR REPLACE FUNCTION public.cerrar_caja(
    p_user_id UUID,
    p_shift_id UUID
) RETURNS JSON AS $$
DECLARE
    v_final_amount NUMERIC;
    v_result JSON;
BEGIN
    -- Verify shift
    IF NOT EXISTS (SELECT 1 FROM public.cash_register_shifts WHERE id = p_shift_id AND user_id = p_user_id AND status = 'OPEN') THEN
        RAISE EXCEPTION 'Caja no encontrada, ya cerrada o no pertenece al usuario.';
    END IF;

    -- Calculate
    SELECT (total_collected - total_expenses) INTO v_final_amount 
    FROM public.cash_register_shifts WHERE id = p_shift_id;

    -- Update
    UPDATE public.cash_register_shifts
    SET status = 'CLOSED',
        closed_at = NOW(),
        final_amount = v_final_amount,
        updated_at = NOW()
    WHERE id = p_shift_id
    RETURNING row_to_json(public.cash_register_shifts.*) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
