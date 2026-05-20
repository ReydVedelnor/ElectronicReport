DO $$
DECLARE
    v_department_name TEXT := 'Участок № 7';

    v_last_name TEXT := 'Иванов';
    v_first_name TEXT := 'Иван';
    v_middle_name TEXT := 'Иванович';

    v_department_id UUID;
    v_user_id UUID;
BEGIN
    ----------------------------------------------------------------
    -- 1. Находим участок
    ----------------------------------------------------------------
    SELECT d.department_id
    INTO v_department_id
    FROM departments d
    WHERE d.name = v_department_name
    LIMIT 1;

    IF v_department_id IS NULL THEN
        RAISE EXCEPTION 'Подразделение "%" не найдено', v_department_name;
    END IF;

    ----------------------------------------------------------------
    -- 2. Ищем пользователя
    ----------------------------------------------------------------
    SELECT u.user_id
    INTO v_user_id
    FROM users u
    WHERE u.last_name = v_last_name
      AND u.first_name = v_first_name
      AND COALESCE(u.middle_name, '') = COALESCE(v_middle_name, '')
    LIMIT 1;

    ----------------------------------------------------------------
    -- 3. Создаем пользователя, если его нет
    ----------------------------------------------------------------
    IF v_user_id IS NULL THEN
        INSERT INTO users (
            user_id,
            last_name,
            first_name,
            middle_name,
            registered_at,
            is_active,
            created_at,
            updated_at
        )
        VALUES (
            gen_random_uuid(),
            v_last_name,
            v_first_name,
            v_middle_name,
            NOW(),
            TRUE,
            NOW(),
            NOW()
        )
        RETURNING user_id INTO v_user_id;
    ELSE
        UPDATE users
        SET
            is_active = TRUE,
            updated_at = NOW()
        WHERE user_id = v_user_id;
    END IF;

    ----------------------------------------------------------------
    -- 4. Привязываем пользователя к участку
    ----------------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1
        FROM department_users du
        WHERE du.department_id = v_department_id
          AND du.user_id = v_user_id
    ) THEN
        INSERT INTO department_users (
            department_id,
            user_id
        )
        VALUES (
            v_department_id,
            v_user_id
        );
    END IF;

    RAISE NOTICE 'Пользователь создан/обновлен и привязан к подразделению. user_id=%, department_id=%',
        v_user_id, v_department_id;
END $$;