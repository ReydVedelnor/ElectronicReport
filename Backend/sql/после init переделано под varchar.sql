BEGIN;

-- 1) Снимаем ограничения/дефолты, завязанные на enum

ALTER TABLE public.attributes
    DROP CONSTRAINT IF EXISTS chk_attributes_metric_datatype_rule;

ALTER TABLE public.shifts
    DROP CONSTRAINT IF EXISTS chk_shifts_status_time;

ALTER TABLE public.template_attributes
    ALTER COLUMN display_style DROP DEFAULT;

-- 2) Меняем типы колонок enum -> varchar с сохранением данных

ALTER TABLE public.attributes
    ALTER COLUMN node_type TYPE varchar(20)
    USING node_type::text;

ALTER TABLE public.shifts
    ALTER COLUMN status TYPE varchar(20)
    USING status::text;

ALTER TABLE public.report_instances
    ALTER COLUMN status TYPE varchar(20)
    USING status::text;

ALTER TABLE public.template_attributes
    ALTER COLUMN display_style TYPE varchar(20)
    USING display_style::text;

ALTER TABLE public.shift_handoffs
    ALTER COLUMN handoff_status TYPE varchar(20)
    USING handoff_status::text;

-- 3) Возвращаем default

ALTER TABLE public.template_attributes
    ALTER COLUMN display_style SET DEFAULT 'normal';

-- 4) Возвращаем бизнес-ограничения уже для varchar

ALTER TABLE public.attributes
    ADD CONSTRAINT chk_attributes_metric_datatype_rule
    CHECK (
        (node_type = 'section' AND data_type_id IS NULL)
        OR
        (node_type = 'metric' AND data_type_id IS NOT NULL)
    );

ALTER TABLE public.shifts
    ADD CONSTRAINT chk_shifts_status_time
    CHECK (
        (status = 'open' AND ended_at IS NULL)
        OR
        (status = 'closed' AND ended_at IS NOT NULL AND ended_at >= started_at)
    );

-- 5) Добавляем проверки допустимых значений вместо enum

ALTER TABLE public.report_instances
    ADD CONSTRAINT chk_report_instances_status_values
    CHECK (status IN ('ready', 'not_ready'));

ALTER TABLE public.shift_handoffs
    ADD CONSTRAINT chk_shift_handoffs_status_values
    CHECK (handoff_status IN ('sent', 'accepted', 'rejected'));

ALTER TABLE public.attributes
    ADD CONSTRAINT chk_attributes_node_type_values
    CHECK (node_type IN ('section', 'metric'));

ALTER TABLE public.template_attributes
    ADD CONSTRAINT chk_template_attributes_display_style_values
    CHECK (display_style IN ('normal', 'bold'));

ALTER TABLE public.shifts
    ADD CONSTRAINT chk_shifts_status_values
    CHECK (status IN ('open', 'closed'));

-- 6) Удаляем старые enum types

DROP TYPE IF EXISTS public.shift_status_enum;
DROP TYPE IF EXISTS public.handoff_status_enum;
DROP TYPE IF EXISTS public.report_status_enum;
DROP TYPE IF EXISTS public.attribute_node_type_enum;
DROP TYPE IF EXISTS public.template_attribute_display_enum;

COMMIT;