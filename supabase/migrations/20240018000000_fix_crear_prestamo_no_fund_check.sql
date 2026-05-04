CREATE OR REPLACE FUNCTION public.crear_prestamo(
    p_client_id UUID,
    p_collector_id UUID,
    p_principal_amount NUMERIC,
    p_total_installments INTEGER,
    p_payment_frequency TEXT
) RETURNS JSON AS $$
DECLARE
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
    -- Check client active loans (one active loan per client)
    SELECT EXISTS (
      SELECT 1 FROM public.loans 
      WHERE client_id = p_client_id AND status = 'ACTIVE'
    ) INTO v_has_active_loan;
    
    IF v_has_active_loan THEN
        RAISE EXCEPTION 'El cliente ya tiene un préstamo activo.';
    END IF;

    -- Calculations
    v_total_amount := p_principal_amount * 1.20;
    v_installment_amount := v_total_amount / p_total_installments;
    v_loan_number := 'LN-' || to_char(NOW(), 'YYYYMMDD') || '-' 
                     || floor(random()*9000+1000);
    
    v_frequency_interval := CASE p_payment_frequency 
        WHEN 'DAILY' THEN '1 day'::INTERVAL
        WHEN 'WEEKLY' THEN '7 days'::INTERVAL
        WHEN 'MONTHLY' THEN '1 month'::INTERVAL
        ELSE '1 day'::INTERVAL
    END;

    v_expected_end_date := NOW() + (v_frequency_interval * p_total_installments);

    -- Insert Loan
    INSERT INTO public.loans (
        loan_number, client_id, collector_id, principal_amount, 
        total_amount, installment_amount, payment_frequency, 
        total_installments, remaining_amount, expected_end_date
    ) VALUES (
        v_loan_number, p_client_id, p_collector_id, p_principal_amount,
        v_total_amount, v_installment_amount, 
        p_payment_frequency::payment_frequency,
        p_total_installments, v_total_amount, v_expected_end_date
    ) RETURNING id INTO v_loan_id;

    -- Insert Installments
    FOR v_i IN 1..p_total_installments LOOP
        v_due_date := NOW() + (v_frequency_interval * v_i);
        INSERT INTO public.installments (loan_id, number, amount, due_date)
        VALUES (v_loan_id, v_i, v_installment_amount, v_due_date);
    END LOOP;

    -- Log fund movement for tracking only (no balance check)
    UPDATE public.fund_accounts 
    SET total_disbursed = total_disbursed + p_principal_amount,
        updated_at = NOW()
    WHERE id = 'main';

    INSERT INTO public.fund_movements (
      fund_account_id, type, amount, created_by_id, loan_id, note
    )
    VALUES (
      'main', 'LOAN_DISBURSEMENT', p_principal_amount, 
      p_collector_id, v_loan_id, 
      'Desembolso de préstamo ' || v_loan_number
    );

    SELECT row_to_json(l) INTO v_result 
    FROM public.loans l WHERE l.id = v_loan_id;
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
