DO $$
DECLARE
    v_department_name TEXT := 'Участок № 7';
    v_department_short_name TEXT := 'Участок 7';

    v_department_id UUID;
    v_template_id UUID;

    v_group_building_1 UUID;
    v_group_building_2 UUID;
    v_group_building_3 UUID;
    v_group_building_4 UUID;
    v_group_notes UUID;

    v_data_type_integer UUID;
    v_data_type_numeric UUID;
    v_data_type_text UUID;

    v_unit_m3 UUID;
    v_unit_kg UUID;
    v_unit_pcs UUID;

    v_attribute_id UUID;
BEGIN
    -- 1. Создаем подразделение, если его нет
    SELECT d.department_id
    INTO v_department_id
    FROM departments d
    WHERE d.name = v_department_name
    LIMIT 1;

    IF v_department_id IS NULL THEN
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
            v_department_name,
            v_department_short_name,
            TRUE,
            NOW()
        )
        RETURNING department_id INTO v_department_id;
    END IF;

    -- 2. Типы данных
    SELECT dt.data_type_id INTO v_data_type_integer
    FROM data_types dt
    WHERE dt.base_type = 'integer'
    LIMIT 1;

    SELECT dt.data_type_id INTO v_data_type_numeric
    FROM data_types dt
    WHERE dt.base_type = 'numeric'
    LIMIT 1;

    SELECT dt.data_type_id INTO v_data_type_text
    FROM data_types dt
    WHERE dt.base_type = 'text'
    LIMIT 1;

    IF v_data_type_integer IS NULL THEN
        RAISE EXCEPTION 'Не найден data_types.base_type = integer';
    END IF;

    IF v_data_type_numeric IS NULL THEN
        RAISE EXCEPTION 'Не найден data_types.base_type = numeric';
    END IF;

    IF v_data_type_text IS NULL THEN
        RAISE EXCEPTION 'Не найден data_types.base_type = text';
    END IF;

    -- 3. Единицы измерения
    INSERT INTO measurement_units (unit_id, name, short_name)
    SELECT gen_random_uuid(), 'Кубический метр', 'м3'
    WHERE NOT EXISTS (
        SELECT 1 FROM measurement_units WHERE short_name = 'м3'
    );

    INSERT INTO measurement_units (unit_id, name, short_name)
    SELECT gen_random_uuid(), 'Килограмм', 'кг'
    WHERE NOT EXISTS (
        SELECT 1 FROM measurement_units WHERE short_name = 'кг'
    );

    INSERT INTO measurement_units (unit_id, name, short_name)
    SELECT gen_random_uuid(), 'Штука', 'шт'
    WHERE NOT EXISTS (
        SELECT 1 FROM measurement_units WHERE short_name = 'шт'
    );

    SELECT mu.unit_id INTO v_unit_m3
    FROM measurement_units mu
    WHERE mu.short_name = 'м3'
    LIMIT 1;

    SELECT mu.unit_id INTO v_unit_kg
    FROM measurement_units mu
    WHERE mu.short_name = 'кг'
    LIMIT 1;

    SELECT mu.unit_id INTO v_unit_pcs
    FROM measurement_units mu
    WHERE mu.short_name = 'шт'
    LIMIT 1;

    -- 4. Создаем шаблон
    INSERT INTO report_templates (
        template_id,
        name,
        is_active,
        created_at,
        updated_at,
        version
    )
    VALUES (
        gen_random_uuid(),
        'Шаблон рапорта начальнику цеха Х по участку № 7',
        TRUE,
        NOW(),
        NOW(),
        1
    )
    RETURNING template_id INTO v_template_id;

    -- 5. Создаем группы
    INSERT INTO attribute_groups (group_id, name, description, is_active, created_at)
    VALUES (gen_random_uuid(), 'Здание 1', 'Группа шаблона: Здание 1', TRUE, NOW())
    RETURNING group_id INTO v_group_building_1;

    INSERT INTO attribute_groups (group_id, name, description, is_active, created_at)
    VALUES (gen_random_uuid(), 'Здание 2', 'Группа шаблона: Здание 2', TRUE, NOW())
    RETURNING group_id INTO v_group_building_2;

    INSERT INTO attribute_groups (group_id, name, description, is_active, created_at)
    VALUES (gen_random_uuid(), 'Здание 3', 'Группа шаблона: Здание 3', TRUE, NOW())
    RETURNING group_id INTO v_group_building_3;

    INSERT INTO attribute_groups (group_id, name, description, is_active, created_at)
    VALUES (gen_random_uuid(), 'Здание 4', 'Группа шаблона: Здание 4', TRUE, NOW())
    RETURNING group_id INTO v_group_building_4;

    INSERT INTO attribute_groups (group_id, name, description, is_active, created_at)
    VALUES (gen_random_uuid(), 'Замечания', 'Группа шаблона: Замечания', TRUE, NOW())
    RETURNING group_id INTO v_group_notes;

    ----------------------------------------------------------------
    -- Здание 1
    ----------------------------------------------------------------

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Количество принятых и переработанных методом аммиачного осаждения растворов',
        'metric',
        v_group_building_1,
        v_data_type_numeric,
        v_unit_m3,
        TRUE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 1, TRUE, 'bold', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Количество прокаленной пульпы',
        'metric',
        v_group_building_1,
        v_data_type_numeric,
        v_unit_m3,
        TRUE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 2, TRUE, 'bold', NOW());

    ----------------------------------------------------------------
    -- Здание 2
    ----------------------------------------------------------------

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Количество принятых и переработанных методом известкования растворов',
        'metric',
        v_group_building_2,
        v_data_type_numeric,
        v_unit_m3,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 3, TRUE, 'bold', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Отфильтровано пульпы',
        'metric',
        v_group_building_2,
        v_data_type_numeric,
        v_unit_m3,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 4, TRUE, 'bold', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Получено контейнеров',
        'metric',
        v_group_building_2,
        v_data_type_integer,
        v_unit_pcs,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 5, TRUE, 'bold', NOW());

    ----------------------------------------------------------------
    -- Здание 3
    ----------------------------------------------------------------

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Сжигание отходов',
        'section',
        v_group_building_3,
        NULL,
        NULL,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 6, TRUE, 'bold', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'переработано отходов',
        'metric',
        v_group_building_3,
        v_data_type_integer,
        v_unit_kg,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 7, FALSE, 'normal', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'получено емкостей с золой',
        'metric',
        v_group_building_3,
        v_data_type_integer,
        v_unit_pcs,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 8, FALSE, 'normal', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Прессование отходов',
        'section',
        v_group_building_3,
        NULL,
        NULL,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 9, TRUE, 'bold', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'получено бочек',
        'metric',
        v_group_building_3,
        v_data_type_integer,
        v_unit_pcs,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 10, FALSE, 'normal', NOW());

    ----------------------------------------------------------------
    -- Здание 4
    ----------------------------------------------------------------

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Измельчение фильтров на шредере',
        'section',
        v_group_building_4,
        NULL,
        NULL,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 11, TRUE, 'bold', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'количество',
        'metric',
        v_group_building_4,
        v_data_type_integer,
        v_unit_pcs,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 12, FALSE, 'normal', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'получено мешков',
        'metric',
        v_group_building_4,
        v_data_type_integer,
        v_unit_pcs,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 13, FALSE, 'normal', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Освобождение контейнеров',
        'metric',
        v_group_building_4,
        v_data_type_integer,
        v_unit_pcs,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 14, TRUE, 'bold', NOW());

    ----------------------------------------------------------------
    -- Замечания
    ----------------------------------------------------------------

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Выявленные замечания по механическому оборудованию',
        'metric',
        v_group_notes,
        v_data_type_integer,
        NULL,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 15, TRUE, 'bold', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Выявленные замечания по электротехническому оборудованию',
        'metric',
        v_group_notes,
        v_data_type_integer,
        NULL,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 16, TRUE, 'bold', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Выявленные замечания по приборному оборудованию',
        'metric',
        v_group_notes,
        v_data_type_integer,
        NULL,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 17, TRUE, 'bold', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Отклонения по установкам',
        'metric',
        v_group_notes,
        v_data_type_text,
        NULL,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 18, TRUE, 'bold', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Количество превышений контрольных показателей',
        'metric',
        v_group_notes,
        v_data_type_integer,
        NULL,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 19, TRUE, 'bold', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Замечания по персоналу',
        'metric',
        v_group_notes,
        v_data_type_text,
        NULL,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 20, TRUE, 'bold', NOW());

    INSERT INTO attributes (
        attribute_id, name, node_type, group_id, data_type_id, unit_id,
        is_required, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        'Замечания по оборудованию',
        'metric',
        v_group_notes,
        v_data_type_text,
        NULL,
        FALSE,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING attribute_id INTO v_attribute_id;

    INSERT INTO template_attributes (
        template_id, attribute_id, sort_order, is_numbered, display_style, added_at
    )
    VALUES (v_template_id, v_attribute_id, 21, TRUE, 'bold', NOW());

    -- 6. Привязка шаблона к подразделению
    INSERT INTO department_templates (department_id, template_id)
    VALUES (v_department_id, v_template_id);

    RAISE NOTICE 'Шаблон создан. template_id = %, department_id = %', v_template_id, v_department_id;
END $$;