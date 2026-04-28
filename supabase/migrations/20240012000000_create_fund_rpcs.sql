-- Create Fund and Shift Management RPCs for Gestion-Cobros

-- 1. Function: invertir_fondo
CREATE OR REPLACE FUNCTION public.invertir_fondo(
    p_admin_id UUID,
    p_amount NUMERIC,
    p_note TEXT
) RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'El monto de inversión debe ser mayor a cero.';
    END IF;

    -- Update account
    UPDATE public.fund_accounts 
    SET available_amount = available_amount + p_amount,
        total_invested = total_invested + p_amount,
        updated_at = NOW()
    WHERE id = 'main';

    -- Log movement
    INSERT INTO public.fund_movements (fund_account_id, type, amount, created_by_id, note)
    VALUES ('main', 'INVESTMENT', p_amount, p_admin_id, p_note);

    SELECT row_to_json(public.fund_accounts.*) INTO v_result FROM public.fund_accounts WHERE id = 'main';
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function: retirar_fondo
CREATE OR REPLACE FUNCTION public.retirar_fondo(
    p_admin_id UUID,
    p_amount NUMERIC,
    p_note TEXT
) RETURNS JSON AS $$
DECLARE
    v_available NUMERIC;
    v_result JSON;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'El monto de retiro debe ser mayor a cero.';
    END IF;

    SELECT available_amount INTO v_available FROM public.fund_accounts WHERE id = 'main';
    
    IF v_available < p_amount THEN
        RAISE EXCEPTION 'Saldo insuficiente para realizar el retiro. Disponible: %', v_available;
    END IF;

    -- Update account
    UPDATE public.fund_accounts 
    SET available_amount = available_amount - p_amount,
        total_withdrawn = total_withdrawn + p_amount,
        updated_at = NOW()
    WHERE id = 'main';

    -- Log movement
    INSERT INTO public.fund_movements (fund_account_id, type, amount, created_by_id, note)
    VALUES ('main', 'WITHDRAWAL', p_amount, p_admin_id, p_note);

    SELECT row_to_json(public.fund_accounts.*) INTO v_result FROM public.fund_accounts WHERE id = 'main';
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Function: obtener_resumen_cobrador
CREATE OR REPLACE FUNCTION public.obtener_resumen_cobrador(
    p_collector_id UUID,
    p_date DATE DEFAULT CURRENT_DATE
) RETURNS JSON AS $$
DECLARE
    v_shift JSON;
    v_total_collected NUMERIC;
    v_total_expenses NUMERIC;
    v_movements JSON;
    v_expenses JSON;
    v_result JSON;
BEGIN
    -- Get shift info
    SELECT row_to_json(s) INTO v_shift 
    FROM public.cash_register_shifts s 
    WHERE s.user_id = p_collector_id AND s.opened_at::date = p_date;

    -- Sums
    SELECT COALESCE(SUM(amount), 0) INTO v_total_collected 
    FROM public.payments 
    WHERE collector_id = p_collector_id AND payment_timestamp::date = p_date;

    SELECT COALESCE(SUM(amount), 0) INTO v_total_expenses 
    FROM public.expenses 
    WHERE user_id = p_collector_id AND created_at::date = p_date;

    -- Movements (Payments with context)
    SELECT json_agg(json_build_object(
        'id', p.id,
        'amount', p.amount,
        'timestamp', p.payment_timestamp,
        'loan_number', l.loan_number,
        'client_name', c.name
    )) INTO v_movements
    FROM public.payments p
    JOIN public.loans l ON p.loan_id = l.id
    JOIN public.clients c ON l.client_id = c.id
    WHERE p.collector_id = p_collector_id AND p.payment_timestamp::date = p_date;

    -- Expenses
    SELECT json_agg(row_to_json(e)) INTO v_expenses
    FROM public.expenses e
    WHERE e.user_id = p_collector_id AND e.created_at::date = p_date;

    -- Assemble
    v_result := json_build_object(
        'shift', v_shift,
        'total_collected', v_total_collected,
        'total_expenses', v_total_expenses,
        'net', v_total_collected - v_total_expenses,
        'payments', COALESCE(v_movements, '[]'::json),
        'expenses', COALESCE(v_expenses, '[]'::json)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Function: abrir_o_obtener_caja
CREATE OR REPLACE FUNCTION public.abrir_o_obtener_caja(
    p_collector_id UUID
) RETURNS JSON AS $$
DECLARE
    v_open_shift_today UUID;
    v_result JSON;
BEGIN
    -- 1. Auto-close shifts from previous days
    UPDATE public.cash_register_shifts
    SET status = 'AUTO_CLOSED',
        closed_at = NOW(),
        final_amount = (total_collected - total_expenses),
        updated_at = NOW()
    WHERE user_id = p_collector_id 
      AND status = 'OPEN' 
      AND opened_at::date < CURRENT_DATE;

    -- 2. Check for today's open shift
    SELECT id INTO v_open_shift_today 
    FROM public.cash_register_shifts
    WHERE user_id = p_collector_id 
      AND status = 'OPEN' 
      AND opened_at::date = CURRENT_DATE;

    -- 3. Return existing or create new
    IF v_open_shift_today IS NOT NULL THEN
        SELECT row_to_json(s) INTO v_result 
        FROM public.cash_register_shifts s WHERE s.id = v_open_shift_today;
    ELSE
        INSERT INTO public.cash_register_shifts (user_id, status, opened_at)
        VALUES (p_collector_id, 'OPEN', NOW())
        RETURNING row_to_json(public.cash_register_shifts.*) INTO v_result;
    END IF;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
