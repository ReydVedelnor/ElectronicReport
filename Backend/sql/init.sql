CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================
-- ENUM types
-- =========================

CREATE TYPE shift_status_enum AS ENUM (
    'open',
    'closed'
);

CREATE TYPE handoff_status_enum AS ENUM (
    'sent',
    'accepted',
    'rejected'
);

CREATE TYPE report_status_enum AS ENUM (
    'ready',
    'not_ready'
);

CREATE TYPE attribute_node_type_enum AS ENUM (
    'section',
    'metric'
);

CREATE TYPE template_attribute_display_enum AS ENUM (
    'normal',
    'bold'
);

-- =========================
-- 1. Пользователь
-- =========================

CREATE TABLE users (
    user_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    last_name            VARCHAR(100) NOT NULL,
    first_name           VARCHAR(100) NOT NULL,
    middle_name          VARCHAR(100),
    registered_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================
-- 2. Учётные данные
-- 1:1 с пользователем
-- =========================

CREATE TABLE credentials (
    user_id                    UUID PRIMARY KEY,
    login                      VARCHAR(150) NOT NULL UNIQUE,
    password_hash              TEXT NOT NULL,
    last_login_at              TIMESTAMPTZ,
    failed_login_attempts      INTEGER NOT NULL DEFAULT 0,
    updated_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_credentials_failed_attempts
        CHECK (failed_login_attempts >= 0),
    CONSTRAINT fk_credentials_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

-- =========================
-- 3. Роли
-- =========================

CREATE TABLE roles (
    role_id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                  VARCHAR(100) NOT NULL UNIQUE,
    is_active             BOOLEAN NOT NULL DEFAULT TRUE,
    description           TEXT
);

-- =========================
-- 4. Пользователь-роль
-- =========================

CREATE TABLE user_roles (
    user_id               UUID NOT NULL,
    role_id               UUID NOT NULL,
    assigned_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_roles_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role
        FOREIGN KEY (role_id)
        REFERENCES roles(role_id)
        ON DELETE CASCADE
);

-- =========================
-- 5. Модули
-- =========================

CREATE TABLE modules (
    module_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name          VARCHAR(150) NOT NULL,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description           TEXT,
    is_active             BOOLEAN NOT NULL DEFAULT TRUE
);

-- =========================
-- 6. Роль-модуль
-- =========================

CREATE TABLE role_modules (
    role_id               UUID NOT NULL,
    module_id             UUID NOT NULL,
    PRIMARY KEY (role_id, module_id),
    CONSTRAINT fk_role_modules_role
        FOREIGN KEY (role_id)
        REFERENCES roles(role_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_role_modules_module
        FOREIGN KEY (module_id)
        REFERENCES modules(module_id)
        ON DELETE CASCADE
);

-- =========================
-- 7. Подразделение
-- =========================

CREATE TABLE departments (
    department_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_department_id  UUID,
    hierarchy_level       INTEGER,
    name                  VARCHAR(200) NOT NULL,
    short_name            VARCHAR(100),
    is_active             BOOLEAN NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_departments_hierarchy_level
        CHECK (hierarchy_level IS NULL OR hierarchy_level >= 0),
    CONSTRAINT fk_departments_parent
        FOREIGN KEY (parent_department_id)
        REFERENCES departments(department_id)
        ON DELETE SET NULL
);

-- =========================
-- 8. Расписание подразделения
-- =========================

CREATE TABLE department_schedules (
    schedule_id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id             UUID NOT NULL,
    name                      VARCHAR(100) NOT NULL,
    sort_order                INTEGER NOT NULL DEFAULT 0,
    start_time                TIME NOT NULL,
    end_time                  TIME NOT NULL,
    crosses_midnight          BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_department_schedules_sort_order
        CHECK (sort_order >= 0),
    CONSTRAINT fk_department_schedules_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
        ON DELETE CASCADE,
    CONSTRAINT uq_department_schedules_name
        UNIQUE (department_id, name),
    CONSTRAINT uq_department_schedules_order
        UNIQUE (department_id, sort_order)
);

-- =========================
-- 9. Подразделение-пользователи
-- =========================

CREATE TABLE department_users (
    department_id         UUID NOT NULL,
    user_id               UUID NOT NULL,
    PRIMARY KEY (department_id, user_id),
    CONSTRAINT fk_department_users_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_department_users_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

-- =========================
-- 10. Шаблон отчёта
-- =========================

CREATE TABLE report_templates (
    template_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                  VARCHAR(200) NOT NULL,
    is_active             BOOLEAN NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version               INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT chk_report_templates_version
        CHECK (version > 0),
    CONSTRAINT uq_report_templates_name_version
        UNIQUE (name, version)
);

-- =========================
-- 11. Подразделение-шаблон
-- =========================

CREATE TABLE department_templates (
    department_id         UUID NOT NULL,
    template_id           UUID NOT NULL,
    PRIMARY KEY (department_id, template_id),
    CONSTRAINT fk_department_templates_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_department_templates_template
        FOREIGN KEY (template_id)
        REFERENCES report_templates(template_id)
        ON DELETE CASCADE
);

-- =========================
-- 12. Группы атрибутов
-- =========================

CREATE TABLE attribute_groups (
    group_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                  VARCHAR(200) NOT NULL,
    description           TEXT,
    is_active             BOOLEAN NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================
-- 13. Типы данных
-- По схеме: свои для postgres
-- =========================

CREATE TABLE data_types (
    data_type_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                  VARCHAR(100) NOT NULL UNIQUE,
    base_type             VARCHAR(50) NOT NULL,
    CONSTRAINT chk_data_types_base_type
        CHECK (base_type IN (
            'smallint',
            'integer',
            'bigint',
            'numeric',
            'real',
            'double precision',
            'boolean',
            'text',
            'date',
            'timestamp',
            'timestamptz'
        ))
);

-- =========================
-- 14. Единицы измерения
-- =========================

CREATE TABLE measurement_units (
    unit_id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                  VARCHAR(100) NOT NULL,
    short_name            VARCHAR(30) NOT NULL,
    CONSTRAINT uq_measurement_units_name UNIQUE (name),
    CONSTRAINT uq_measurement_units_short_name UNIQUE (short_name)
);

-- =========================
-- 15. Атрибут
-- =========================

CREATE TABLE attributes (
    attribute_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                  VARCHAR(200) NOT NULL,
    node_type             attribute_node_type_enum NOT NULL,
    group_id              UUID NOT NULL,
    data_type_id          UUID,
    unit_id               UUID,
    is_required           BOOLEAN NOT NULL DEFAULT FALSE,
    is_active             BOOLEAN NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_attributes_metric_datatype_rule
        CHECK (
            (node_type = 'section' AND data_type_id IS NULL)
            OR
            (node_type = 'metric' AND data_type_id IS NOT NULL)
        ),

    CONSTRAINT fk_attributes_group
        FOREIGN KEY (group_id)
        REFERENCES attribute_groups(group_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_attributes_data_type
        FOREIGN KEY (data_type_id)
        REFERENCES data_types(data_type_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_attributes_unit
        FOREIGN KEY (unit_id)
        REFERENCES measurement_units(unit_id)
        ON DELETE SET NULL
);

-- =========================
-- 16. Смена
-- =========================

CREATE TABLE shifts (
    shift_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    started_at            TIMESTAMPTZ NOT NULL,
    ended_at              TIMESTAMPTZ,
    status                shift_status_enum NOT NULL,
    department_id         UUID NOT NULL,
    schedule_id           UUID NOT NULL,
    engineer_user_id      UUID NOT NULL,

    CONSTRAINT fk_shifts_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_shifts_schedule
        FOREIGN KEY (schedule_id)
        REFERENCES department_schedules(schedule_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_shifts_engineer
        FOREIGN KEY (engineer_user_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_shifts_status_time
        CHECK (
            (status = 'open' AND ended_at IS NULL)
            OR
            (status = 'closed' AND ended_at IS NOT NULL AND ended_at >= started_at)
        ),

    CONSTRAINT uq_shifts_department_schedule_started_at
        UNIQUE (department_id, schedule_id, started_at)
);

-- =========================
-- 17. Отчёт (instance)
-- =========================

CREATE TABLE report_instances (
    report_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id           UUID NOT NULL,
    shift_id              UUID NOT NULL,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at             TIMESTAMPTZ,
    status                report_status_enum NOT NULL,

    CONSTRAINT fk_report_instances_template
        FOREIGN KEY (template_id)
        REFERENCES report_templates(template_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_report_instances_shift
        FOREIGN KEY (shift_id)
        REFERENCES shifts(shift_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_report_instances_time
        CHECK (closed_at IS NULL OR closed_at >= created_at),

    CONSTRAINT uq_report_instances_template_shift
        UNIQUE (template_id, shift_id)
);

-- =========================
-- 18. Шаблон-атрибут
-- =========================

CREATE TABLE template_attributes (
    template_id           UUID NOT NULL,
    attribute_id          UUID NOT NULL,
    sort_order            INTEGER NOT NULL DEFAULT 0,
    is_numbered           BOOLEAN NOT NULL DEFAULT FALSE,
    display_style         template_attribute_display_enum NOT NULL DEFAULT 'normal',
    added_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (template_id, attribute_id),

    CONSTRAINT chk_template_attributes_sort_order
        CHECK (sort_order >= 0),

    CONSTRAINT fk_template_attributes_template
        FOREIGN KEY (template_id)
        REFERENCES report_templates(template_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_template_attributes_attribute
        FOREIGN KEY (attribute_id)
        REFERENCES attributes(attribute_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_template_attributes_order
        UNIQUE (template_id, sort_order)
);

-- =========================
-- 19. Значение атрибута
-- =========================

CREATE TABLE attribute_values (
    attribute_value_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id             UUID NOT NULL,
    attribute_id          UUID NOT NULL,
    value_text            TEXT,

    CONSTRAINT fk_attribute_values_report
        FOREIGN KEY (report_id)
        REFERENCES report_instances(report_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_attribute_values_attribute
        FOREIGN KEY (attribute_id)
        REFERENCES attributes(attribute_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_attribute_values_report_attribute
        UNIQUE (report_id, attribute_id)
);

-- =========================
-- 20. История значения атрибута
-- =========================

CREATE TABLE attribute_value_history (
    history_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attribute_value_id    UUID NOT NULL,
    old_value             TEXT,
    new_value             TEXT,
    changed_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    changed_by_user_id    UUID,
    comment               TEXT,

    CONSTRAINT fk_attribute_value_history_value
        FOREIGN KEY (attribute_value_id)
        REFERENCES attribute_values(attribute_value_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_attribute_value_history_user
        FOREIGN KEY (changed_by_user_id)
        REFERENCES users(user_id)
        ON DELETE SET NULL
);

-- =========================
-- 21. Передача смены
-- =========================

CREATE TABLE shift_handoffs (
    handoff_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_shift_id         UUID NOT NULL,
    to_shift_id           UUID NOT NULL,
    handoff_status        handoff_status_enum NOT NULL,
    message               TEXT,

    CONSTRAINT fk_shift_handoffs_from
        FOREIGN KEY (from_shift_id)
        REFERENCES shifts(shift_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_shift_handoffs_to
        FOREIGN KEY (to_shift_id)
        REFERENCES shifts(shift_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_shift_handoffs_not_same
        CHECK (from_shift_id <> to_shift_id)
);

-- =========================
-- Indexes
-- =========================

CREATE INDEX idx_users_last_name
    ON users(last_name);

CREATE INDEX idx_users_is_active
    ON users(is_active);

CREATE INDEX idx_roles_is_active
    ON roles(is_active);

CREATE INDEX idx_modules_is_active
    ON modules(is_active);

CREATE INDEX idx_departments_parent_department_id
    ON departments(parent_department_id);

CREATE INDEX idx_departments_is_active
    ON departments(is_active);

CREATE INDEX idx_department_schedules_department_id
    ON department_schedules(department_id);

CREATE INDEX idx_department_schedules_department_sort
    ON department_schedules(department_id, sort_order);

CREATE INDEX idx_department_users_user_id
    ON department_users(user_id);

CREATE INDEX idx_report_templates_is_active
    ON report_templates(is_active);

CREATE INDEX idx_department_templates_template_id
    ON department_templates(template_id);

CREATE INDEX idx_attribute_groups_is_active
    ON attribute_groups(is_active);

CREATE INDEX idx_attributes_group_id
    ON attributes(group_id);

CREATE INDEX idx_attributes_data_type_id
    ON attributes(data_type_id);

CREATE INDEX idx_attributes_unit_id
    ON attributes(unit_id);

CREATE INDEX idx_attributes_node_type
    ON attributes(node_type);

CREATE INDEX idx_attributes_is_active
    ON attributes(is_active);

CREATE INDEX idx_shifts_department_id
    ON shifts(department_id);

CREATE INDEX idx_shifts_schedule_id
    ON shifts(schedule_id);

CREATE INDEX idx_shifts_engineer_user_id
    ON shifts(engineer_user_id);

CREATE INDEX idx_shifts_status
    ON shifts(status);

CREATE INDEX idx_shifts_started_at
    ON shifts(started_at);

CREATE INDEX idx_report_instances_template_id
    ON report_instances(template_id);

CREATE INDEX idx_report_instances_shift_id
    ON report_instances(shift_id);

CREATE INDEX idx_report_instances_status
    ON report_instances(status);

CREATE INDEX idx_template_attributes_attribute_id
    ON template_attributes(attribute_id);

CREATE INDEX idx_template_attributes_template_sort
    ON template_attributes(template_id, sort_order);

CREATE INDEX idx_attribute_values_report_id
    ON attribute_values(report_id);

CREATE INDEX idx_attribute_values_attribute_id
    ON attribute_values(attribute_id);

CREATE INDEX idx_attribute_value_history_attribute_value_id
    ON attribute_value_history(attribute_value_id);

CREATE INDEX idx_attribute_value_history_changed_by_user_id
    ON attribute_value_history(changed_by_user_id);

CREATE INDEX idx_attribute_value_history_changed_at
    ON attribute_value_history(changed_at);

CREATE INDEX idx_shift_handoffs_from_shift_id
    ON shift_handoffs(from_shift_id);

CREATE INDEX idx_shift_handoffs_to_shift_id
    ON shift_handoffs(to_shift_id);

CREATE INDEX idx_shift_handoffs_status
    ON shift_handoffs(handoff_status);

-- =========================
-- Optional seed for data_types
-- =========================

INSERT INTO data_types (data_type_id, name, base_type) VALUES
    (gen_random_uuid(), 'Малое целое', 'smallint'),
    (gen_random_uuid(), 'Целое число', 'integer'),
    (gen_random_uuid(), 'Большое целое', 'bigint'),
    (gen_random_uuid(), 'Число с фиксированной точностью', 'numeric'),
    (gen_random_uuid(), 'Число с плавающей точкой', 'real'),
    (gen_random_uuid(), 'Число двойной точности', 'double precision'),
    (gen_random_uuid(), 'Булево', 'boolean'),
    (gen_random_uuid(), 'Текст', 'text'),
    (gen_random_uuid(), 'Дата', 'date'),
    (gen_random_uuid(), 'Дата и время', 'timestamp'),
    (gen_random_uuid(), 'Дата и время с часовым поясом', 'timestamptz');
    