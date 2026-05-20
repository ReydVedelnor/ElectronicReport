BEGIN;

INSERT INTO public.users (
    user_id, last_name, first_name, middle_name, registered_at, is_active, created_at, updated_at
) VALUES
(
    '1025389a-0e27-4e08-b6a0-b188660bea57',
    'Иванов',
    'Иван',
    'Иванович',
    '2026-03-23 03:06:04.594554+05',
    TRUE,
    '2026-03-23 03:06:04.594554+05',
    '2026-03-23 03:06:04.594554+05'
);

INSERT INTO public.credentials (user_id, login, password_hash, last_login_at, failed_login_attempts, updated_at)
VALUES
    (
        '1025389a-0e27-4e08-b6a0-b188660bea57' ,
        'инженер',
        '$2a$12$oxx1uBZmAOfzA2lu6xSgRO8fhWqFxRGjSWGgBb/xs3ugz1V4B4KyC',
        NOW(),
        0,
        NOW()
    );

INSERT INTO public.departments (
    department_id, parent_department_id, hierarchy_level, name, short_name, is_active, created_at
) VALUES
(
    '3650aab8-254a-440e-9665-e4af33584faa',
    NULL,
    0,
    'УралВагонЗавод',
    'УВЗ',
    TRUE,
    '2026-03-23 01:42:49.309829+05'
),
(
    'a2641f9a-865e-4071-b251-f0c943117370',
    '3650aab8-254a-440e-9665-e4af33584faa',
    1,
    'Цех 2',
    'Ц2',
    TRUE,
    '2026-03-23 01:42:49.309829+05'
),
(
    'e7648a66-d84e-4e37-bfc5-7d760a6ecdd8',
    'a2641f9a-865e-4071-b251-f0c943117370',
    2,
    'Участок № 7',
    'Участок 7',
    TRUE,
    '2026-03-23 01:29:30.552516+05'
);

INSERT INTO public.data_types (
    data_type_id, name, base_type
) VALUES
('ac61e40f-acd4-4aab-9aad-3849218649da', 'Малое целое', 'smallint'),
('180a8774-1e05-49b2-a2f1-5a8f32cb65ad', 'Целое число', 'integer'),
('1802200c-e274-4a02-827e-e85c21737ef1', 'Большое целое', 'bigint'),
('9283b1ba-f4eb-4e4c-b0f3-b839697dbe88', 'Число с фиксированной точностью', 'numeric'),
('2dfb3f08-2ad8-476f-9858-a073b6b8be18', 'Число с плавающей точкой', 'real'),
('d1eb1091-cbea-4fa7-b2de-9520f754c23c', 'Число двойной точности', 'double precision'),
('2d5882cd-1649-4707-9b75-f1ac59ec2bc4', 'Булево', 'boolean'),
('55e33974-3518-47d5-80ab-07e6dca4f681', 'Текст', 'text'),
('4628c77a-1b16-466c-96fc-cfb5374fe74f', 'Дата', 'date'),
('409f8bac-c0c0-48ea-9c64-55e109d5b994', 'Дата и время', 'timestamp'),
('4478f94f-67a5-4b96-831e-6fd6060bd440', 'Дата и время с часовым поясом', 'timestamptz');

INSERT INTO public.measurement_units (
    unit_id, name, short_name
) VALUES
('6c87c859-a336-4be6-8012-0686ba1ac3c3', 'Кубический метр', 'м3'),
('4db0d219-5238-463f-b0f8-191e4ab9ade3', 'Килограмм', 'кг'),
('7d8bcd14-90e1-4bd9-9da2-196259225651', 'Штука', 'шт');

INSERT INTO public.attribute_groups (
    group_id, name, description, is_active, created_at
) VALUES
(
    '5d7a62ca-b9e2-4a95-9f8b-fca0468925eb',
    'Здание 1',
    'Группа шаблона: Здание 1',
    TRUE,
    '2026-03-23 01:29:30.552516+05'
),
(
    '99b8f618-66d8-4404-8f33-b08bb581ce19',
    'Здание 2',
    'Группа шаблона: Здание 2',
    TRUE,
    '2026-03-23 01:29:30.552516+05'
),
(
    '3ce4f7d3-703b-433a-8ab5-f96f894b7ef0',
    'Здание 3',
    'Группа шаблона: Здание 3',
    TRUE,
    '2026-03-23 01:29:30.552516+05'
),
(
    'b98e8641-f7ba-407c-bbc5-1784d36a5ccc',
    'Здание 4',
    'Группа шаблона: Здание 4',
    TRUE,
    '2026-03-23 01:29:30.552516+05'
),
(
    'a8c8179b-5e14-4851-b59d-f2ab12ffda74',
    'Замечания',
    'Группа шаблона: Замечания',
    TRUE,
    '2026-03-23 01:29:30.552516+05'
);

INSERT INTO public.attributes (
    attribute_id, name, node_type, group_id, data_type_id, unit_id, is_required, is_active, created_at, updated_at
) VALUES
(
    '7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1',
    'Количество принятых и переработанных методом аммиачного осаждения растворов',
    'metric',
    '5d7a62ca-b9e2-4a95-9f8b-fca0468925eb',
    '9283b1ba-f4eb-4e4c-b0f3-b839697dbe88',
    '6c87c859-a336-4be6-8012-0686ba1ac3c3',
    TRUE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    'f28188e3-fdb9-4d41-9a5a-2d3ff2730842',
    'Количество прокаленной пульпы',
    'metric',
    '5d7a62ca-b9e2-4a95-9f8b-fca0468925eb',
    '9283b1ba-f4eb-4e4c-b0f3-b839697dbe88',
    '6c87c859-a336-4be6-8012-0686ba1ac3c3',
    TRUE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    'cb2e05b8-5feb-47b8-933a-868b1e703342',
    'Количество принятых и переработанных методом известкования растворов',
    'metric',
    '99b8f618-66d8-4404-8f33-b08bb581ce19',
    '9283b1ba-f4eb-4e4c-b0f3-b839697dbe88',
    '6c87c859-a336-4be6-8012-0686ba1ac3c3',
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    '0efafdb9-d607-4960-97f7-4c93eebe8c54',
    'Отфильтровано пульпы',
    'metric',
    '99b8f618-66d8-4404-8f33-b08bb581ce19',
    '9283b1ba-f4eb-4e4c-b0f3-b839697dbe88',
    '6c87c859-a336-4be6-8012-0686ba1ac3c3',
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    '05baf163-db0d-4b25-80ba-05b5b80e4c69',
    'Получено контейнеров',
    'metric',
    '99b8f618-66d8-4404-8f33-b08bb581ce19',
    '180a8774-1e05-49b2-a2f1-5a8f32cb65ad',
    '7d8bcd14-90e1-4bd9-9da2-196259225651',
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    'f03b4d94-e4cd-4814-bd63-de7697ac3f75',
    'Сжигание отходов',
    'section',
    '3ce4f7d3-703b-433a-8ab5-f96f894b7ef0',
    NULL,
    NULL,
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    '0b9672ca-b402-4b76-bd72-1957304940a1',
    'переработано отходов',
    'metric',
    '3ce4f7d3-703b-433a-8ab5-f96f894b7ef0',
    '180a8774-1e05-49b2-a2f1-5a8f32cb65ad',
    '4db0d219-5238-463f-b0f8-191e4ab9ade3',
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    'b7e6b576-fc4d-453c-bdab-27dc5452157c',
    'получено емкостей с золой',
    'metric',
    '3ce4f7d3-703b-433a-8ab5-f96f894b7ef0',
    '180a8774-1e05-49b2-a2f1-5a8f32cb65ad',
    '7d8bcd14-90e1-4bd9-9da2-196259225651',
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    'bae050ac-dc2c-4894-9779-a527fc4914af',
    'Прессование отходов',
    'section',
    '3ce4f7d3-703b-433a-8ab5-f96f894b7ef0',
    NULL,
    NULL,
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    'c334d16b-aaff-4d34-88ef-61f95cbe7e3a',
    'получено бочек',
    'metric',
    '3ce4f7d3-703b-433a-8ab5-f96f894b7ef0',
    '180a8774-1e05-49b2-a2f1-5a8f32cb65ad',
    '7d8bcd14-90e1-4bd9-9da2-196259225651',
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    'e4e1de79-6696-4db5-94c6-c6debb80ede4',
    'Измельчение фильтров на шредере',
    'section',
    'b98e8641-f7ba-407c-bbc5-1784d36a5ccc',
    NULL,
    NULL,
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    '7cc0365f-3df4-4389-93f7-6f3907b1d014',
    'количество',
    'metric',
    'b98e8641-f7ba-407c-bbc5-1784d36a5ccc',
    '180a8774-1e05-49b2-a2f1-5a8f32cb65ad',
    '7d8bcd14-90e1-4bd9-9da2-196259225651',
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    '8f209177-d1f1-4419-bc20-707ccd166660',
    'получено мешков',
    'metric',
    'b98e8641-f7ba-407c-bbc5-1784d36a5ccc',
    '180a8774-1e05-49b2-a2f1-5a8f32cb65ad',
    '7d8bcd14-90e1-4bd9-9da2-196259225651',
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    '55f17e1c-4c8a-4983-8c8c-06e26dac38b4',
    'Освобождение контейнеров',
    'metric',
    'b98e8641-f7ba-407c-bbc5-1784d36a5ccc',
    '180a8774-1e05-49b2-a2f1-5a8f32cb65ad',
    '7d8bcd14-90e1-4bd9-9da2-196259225651',
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    '80497194-a652-4edc-9fcb-5c90d9e9d88f',
    'Выявленные замечания по механическому оборудованию',
    'metric',
    'a8c8179b-5e14-4851-b59d-f2ab12ffda74',
    '180a8774-1e05-49b2-a2f1-5a8f32cb65ad',
    NULL,
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    '5f3148ed-7aaf-4da2-98a1-4b1025edd7a5',
    'Выявленные замечания по электротехническому оборудованию',
    'metric',
    'a8c8179b-5e14-4851-b59d-f2ab12ffda74',
    '180a8774-1e05-49b2-a2f1-5a8f32cb65ad',
    NULL,
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    '734cd218-e0cc-4267-8226-8cafa57be5b9',
    'Выявленные замечания по приборному оборудованию',
    'metric',
    'a8c8179b-5e14-4851-b59d-f2ab12ffda74',
    '180a8774-1e05-49b2-a2f1-5a8f32cb65ad',
    NULL,
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    'cf3783f3-556c-4bf6-94ab-968d28be63d4',
    'Отклонения по установкам',
    'metric',
    'a8c8179b-5e14-4851-b59d-f2ab12ffda74',
    '55e33974-3518-47d5-80ab-07e6dca4f681',
    NULL,
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    'c3fe8886-d3f1-4972-9d51-901392b86864',
    'Количество превышений контрольных показателей',
    'metric',
    'a8c8179b-5e14-4851-b59d-f2ab12ffda74',
    '180a8774-1e05-49b2-a2f1-5a8f32cb65ad',
    NULL,
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    '321d0540-1a62-4508-a5b4-f7bb9f2af4a0',
    'Замечания по персоналу',
    'metric',
    'a8c8179b-5e14-4851-b59d-f2ab12ffda74',
    '55e33974-3518-47d5-80ab-07e6dca4f681',
    NULL,
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
),
(
    '0e7cb6e2-86c6-469f-8520-c7d7d5029604',
    'Замечания по оборудованию',
    'metric',
    'a8c8179b-5e14-4851-b59d-f2ab12ffda74',
    '55e33974-3518-47d5-80ab-07e6dca4f681',
    NULL,
    FALSE,
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05'
);

INSERT INTO public.report_templates (
    template_id, name, is_active, created_at, updated_at, version
) VALUES
(
    'a28e06e4-b250-40f9-ae25-17db1db01534',
    'Шаблон рапорта начальнику цеха Х по участку № 7',
    TRUE,
    '2026-03-23 01:29:30.552516+05',
    '2026-03-23 01:29:30.552516+05',
    1
);

INSERT INTO public.department_schedules (
    schedule_id, department_id, name, sort_order, start_time, end_time, crosses_midnight
) VALUES
(
    '7d94106f-01ca-40ca-b260-3673c0f41c0a',
    'e7648a66-d84e-4e37-bfc5-7d760a6ecdd8',
    '1 смена',
    1,
    '07:00:00',
    '15:30:00',
    FALSE
),
(
    '33c5b11e-13c4-4755-bd73-671f34fcea98',
    'e7648a66-d84e-4e37-bfc5-7d760a6ecdd8',
    '2 смена',
    2,
    '15:30:00',
    '00:00:00',
    TRUE
),
(
    '96e70ab9-2fd7-4727-ab81-20c3edd34159',
    'e7648a66-d84e-4e37-bfc5-7d760a6ecdd8',
    '3 смена',
    3,
    '00:00:00',
    '07:30:00',
    FALSE
);

INSERT INTO public.department_templates (
    department_id, template_id
) VALUES
(
    'e7648a66-d84e-4e37-bfc5-7d760a6ecdd8',
    'a28e06e4-b250-40f9-ae25-17db1db01534'
);

INSERT INTO public.department_users (
    department_id, user_id
) VALUES
(
    'e7648a66-d84e-4e37-bfc5-7d760a6ecdd8',
    '1025389a-0e27-4e08-b6a0-b188660bea57'
);

INSERT INTO public.shifts (
    shift_id, started_at, ended_at, status, department_id, schedule_id, engineer_user_id
) VALUES
(
    '96554daf-3b3f-4967-844b-0245a2e72f78',
    '2026-03-22 07:00:00+05',
    NULL,
    'open',
    'e7648a66-d84e-4e37-bfc5-7d760a6ecdd8',
    '7d94106f-01ca-40ca-b260-3673c0f41c0a',
    '1025389a-0e27-4e08-b6a0-b188660bea57'
);

INSERT INTO public.report_instances (
    report_id, template_id, shift_id, created_at, closed_at, status
) VALUES
(
    'fe238c96-baa2-470b-9245-ccd49439b800',
    'a28e06e4-b250-40f9-ae25-17db1db01534',
    '96554daf-3b3f-4967-844b-0245a2e72f78',
    '2026-03-23 16:18:47.963223+05',
    NULL,
    'not_ready'
);

INSERT INTO public.template_attributes (
    template_id, attribute_id, sort_order, is_numbered, display_style, added_at
) VALUES
('a28e06e4-b250-40f9-ae25-17db1db01534', '7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1', 1, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', 'f28188e3-fdb9-4d41-9a5a-2d3ff2730842', 2, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', 'cb2e05b8-5feb-47b8-933a-868b1e703342', 3, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', '0efafdb9-d607-4960-97f7-4c93eebe8c54', 4, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', '05baf163-db0d-4b25-80ba-05b5b80e4c69', 5, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', 'f03b4d94-e4cd-4814-bd63-de7697ac3f75', 6, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', '0b9672ca-b402-4b76-bd72-1957304940a1', 7, FALSE, 'normal', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', 'b7e6b576-fc4d-453c-bdab-27dc5452157c', 8, FALSE, 'normal', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', 'bae050ac-dc2c-4894-9779-a527fc4914af', 9, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', 'c334d16b-aaff-4d34-88ef-61f95cbe7e3a', 10, FALSE, 'normal', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', 'e4e1de79-6696-4db5-94c6-c6debb80ede4', 11, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', '7cc0365f-3df4-4389-93f7-6f3907b1d014', 12, FALSE, 'normal', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', '8f209177-d1f1-4419-bc20-707ccd166660', 13, FALSE, 'normal', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', '55f17e1c-4c8a-4983-8c8c-06e26dac38b4', 14, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', '80497194-a652-4edc-9fcb-5c90d9e9d88f', 15, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', '5f3148ed-7aaf-4da2-98a1-4b1025edd7a5', 16, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', '734cd218-e0cc-4267-8226-8cafa57be5b9', 17, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', 'cf3783f3-556c-4bf6-94ab-968d28be63d4', 18, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', 'c3fe8886-d3f1-4972-9d51-901392b86864', 19, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', '321d0540-1a62-4508-a5b4-f7bb9f2af4a0', 20, TRUE, 'bold', '2026-03-23 01:29:30.552516+05'),
('a28e06e4-b250-40f9-ae25-17db1db01534', '0e7cb6e2-86c6-469f-8520-c7d7d5029604', 21, TRUE, 'bold', '2026-03-23 01:29:30.552516+05');

INSERT INTO public.attribute_values (
    attribute_value_id, report_id, attribute_id, value_text
) VALUES
(
    '4180eabf-6739-4e8c-b32a-b6339361af86',
    'fe238c96-baa2-470b-9245-ccd49439b800',
    '7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1',
    '200'
),
(
    '03da7a06-7cf0-4570-9fba-36bea3ab7727',
    'fe238c96-baa2-470b-9245-ccd49439b800',
    'f28188e3-fdb9-4d41-9a5a-2d3ff2730842',
    '201'
);

INSERT INTO public.attribute_value_history (
    history_id, attribute_value_id, old_value, new_value, changed_at, changed_by_user_id, comment
) VALUES
(
    '12e8faeb-ac7f-4e05-8ff7-74ad49f5176d',
    '4180eabf-6739-4e8c-b32a-b6339361af86',
    NULL,
    '200',
    '2026-03-25 00:21:21.693698+05',
    '1025389a-0e27-4e08-b6a0-b188660bea57',
    'Первичное заполнение'
),
(
    'a8b51f51-60e3-4d4c-b32e-d5b4c0916e68',
    '03da7a06-7cf0-4570-9fba-36bea3ab7727',
    NULL,
    '201',
    '2026-03-25 00:21:21.75325+05',
    '1025389a-0e27-4e08-b6a0-b188660bea57',
    'Первичное заполнение'
);

COMMIT;