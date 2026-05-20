DO $$
DECLARE
    v_root_name TEXT := 'УралВагонЗавод';
    v_shop_name TEXT := 'Цех 2';
    v_section_name TEXT := 'Участок № 7';

    v_root_id UUID;
    v_shop_id UUID;
    v_section_id UUID;
BEGIN
    ----------------------------------------------------------------
    -- 1. УралВагонЗавод
    ----------------------------------------------------------------
    SELECT department_id
    INTO v_root_id
    FROM departments
    WHERE name = v_root_name
    LIMIT 1;

    IF v_root_id IS NULL THEN
        INSERT INTO departments (
            department_id,
            parent_department_id,
            hierarchy_level,
            name,
            short_name,
            is_active,
            created_at
        )
        VALUES (
            gen_random_uuid(),
            NULL,
            0,
            v_root_name,
            'УВЗ',
            TRUE,
            NOW()
        )
        RETURNING department_id INTO v_root_id;
    ELSE
        UPDATE departments
        SET
            parent_department_id = NULL,
            hierarchy_level = 0,
            short_name = COALESCE(short_name, 'УВЗ'),
            is_active = TRUE
        WHERE department_id = v_root_id;
    END IF;

    ----------------------------------------------------------------
    -- 2. Цех 2
    ----------------------------------------------------------------
    SELECT department_id
    INTO v_shop_id
    FROM departments
    WHERE name = v_shop_name
    LIMIT 1;

    IF v_shop_id IS NULL THEN
        INSERT INTO departments (
            department_id,
            parent_department_id,
            hierarchy_level,
            name,
            short_name,
            is_active,
            created_at
        )
        VALUES (
            gen_random_uuid(),
            v_root_id,
            1,
            v_shop_name,
            'Ц2',
            TRUE,
            NOW()
        )
        RETURNING department_id INTO v_shop_id;
    ELSE
        UPDATE departments
        SET
            parent_department_id = v_root_id,
            hierarchy_level = 1,
            short_name = COALESCE(short_name, 'Ц2'),
            is_active = TRUE
        WHERE department_id = v_shop_id;
    END IF;

    ----------------------------------------------------------------
    -- 3. Участок № 7
    ----------------------------------------------------------------
    SELECT department_id
    INTO v_section_id
    FROM departments
    WHERE name = v_section_name
    LIMIT 1;

    IF v_section_id IS NULL THEN
        INSERT INTO departments (
            department_id,
            parent_department_id,
            hierarchy_level,
            name,
            short_name,
            is_active,
            created_at
        )
        VALUES (
            gen_random_uuid(),
            v_shop_id,
            2,
            v_section_name,
            'Участок 7',
            TRUE,
            NOW()
        )
        RETURNING department_id INTO v_section_id;
    ELSE
        UPDATE departments
        SET
            parent_department_id = v_shop_id,
            hierarchy_level = 2,
            short_name = COALESCE(short_name, 'Участок 7'),
            is_active = TRUE
        WHERE department_id = v_section_id;
    END IF;

    ----------------------------------------------------------------
    -- 4. Расписание для Участка № 7
    ----------------------------------------------------------------

    -- 1 смена
    IF NOT EXISTS (
        SELECT 1
        FROM department_schedules
        WHERE department_id = v_section_id
          AND name = '1 смена'
    ) THEN
        INSERT INTO department_schedules (
            schedule_id,
            department_id,
            name,
            sort_order,
            start_time,
            end_time,
            crosses_midnight
        )
        VALUES (
            gen_random_uuid(),
            v_section_id,
            '1 смена',
            1,
            TIME '07:00',
            TIME '15:30',
            FALSE
        );
    END IF;

    -- 2 смена
    IF NOT EXISTS (
        SELECT 1
        FROM department_schedules
        WHERE department_id = v_section_id
          AND name = '2 смена'
    ) THEN
        INSERT INTO department_schedules (
            schedule_id,
            department_id,
            name,
            sort_order,
            start_time,
            end_time,
            crosses_midnight
        )
        VALUES (
            gen_random_uuid(),
            v_section_id,
            '2 смена',
            2,
            TIME '15:30',
            TIME '00:00',
            TRUE
        );
    END IF;

    -- 3 смена
    IF NOT EXISTS (
        SELECT 1
        FROM department_schedules
        WHERE department_id = v_section_id
          AND name = '3 смена'
    ) THEN
        INSERT INTO department_schedules (
            schedule_id,
            department_id,
            name,
            sort_order,
            start_time,
            end_time,
            crosses_midnight
        )
        VALUES (
            gen_random_uuid(),
            v_section_id,
            '3 смена',
            3,
            TIME '00:00',
            TIME '07:30',
            FALSE
        );
    END IF;

    RAISE NOTICE 'Иерархия и расписание созданы/обновлены. root=%, shop=%, section=%',
        v_root_id, v_shop_id, v_section_id;
END $$;