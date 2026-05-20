CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================
-- 1. Пользователь
-- =========================

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================
-- credentials
-- =========================

CREATE TABLE credentials (
    user_id UUID PRIMARY KEY,
    login VARCHAR(150) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    last_login_at TIMESTAMPTZ,
    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (failed_login_attempts >= 0),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =========================
-- roles
-- =========================

CREATE TABLE roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    description TEXT
);

CREATE TABLE user_roles (
    user_id UUID NOT NULL,
    role_id UUID NOT NULL,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE
);

-- =========================
-- modules
-- =========================

CREATE TABLE modules (
    module_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name VARCHAR(150) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE role_modules (
    role_id UUID NOT NULL,
    module_id UUID NOT NULL,
    PRIMARY KEY (role_id, module_id),
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    FOREIGN KEY (module_id) REFERENCES modules(module_id) ON DELETE CASCADE
);

-- =========================
-- departments
-- =========================

CREATE TABLE departments (
    department_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_department_id UUID,
    hierarchy_level INTEGER,
    name VARCHAR(200) NOT NULL,
    short_name VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (hierarchy_level IS NULL OR hierarchy_level >= 0),
    FOREIGN KEY (parent_department_id)
        REFERENCES departments(department_id)
        ON DELETE SET NULL
);

-- =========================
-- schedules
-- =========================

CREATE TABLE department_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    crosses_midnight BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (sort_order >= 0),
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE,
    UNIQUE (department_id, name),
    UNIQUE (department_id, sort_order)
);

CREATE TABLE department_users (
    department_id UUID NOT NULL,
    user_id UUID NOT NULL,
    PRIMARY KEY (department_id, user_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =========================
-- templates
-- =========================

CREATE TABLE report_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version INTEGER NOT NULL DEFAULT 1,
    CHECK (version > 0),
    UNIQUE (name, version)
);

CREATE TABLE department_templates (
    department_id UUID NOT NULL,
    template_id UUID NOT NULL,
    PRIMARY KEY (department_id, template_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES report_templates(template_id) ON DELETE CASCADE
);

-- =========================
-- attributes
-- =========================

CREATE TABLE attribute_groups (
    group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE data_types (
    data_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    base_type VARCHAR(50) NOT NULL,
    CHECK (base_type IN (
        'smallint','integer','bigint','numeric','real',
        'double precision','boolean','text','date',
        'timestamp','timestamptz'
    ))
);

CREATE TABLE measurement_units (
    unit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    short_name VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE attributes (
    attribute_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    node_type VARCHAR(20) NOT NULL,
    group_id UUID NOT NULL,
    data_type_id UUID,
    unit_id UUID,
    is_required BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (node_type IN ('section','metric')),

    CHECK (
        (node_type = 'section' AND data_type_id IS NULL)
        OR
        (node_type = 'metric' AND data_type_id IS NOT NULL)
    ),

    FOREIGN KEY (group_id) REFERENCES attribute_groups(group_id),
    FOREIGN KEY (data_type_id) REFERENCES data_types(data_type_id),
    FOREIGN KEY (unit_id) REFERENCES measurement_units(unit_id)
);

-- =========================
-- shifts
-- =========================

CREATE TABLE shifts (
    shift_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL,
    department_id UUID NOT NULL,
    schedule_id UUID NOT NULL,
    engineer_user_id UUID NOT NULL,

    CHECK (status IN ('open','closed')),

    CHECK (
        (status = 'open' AND ended_at IS NULL)
        OR
        (status = 'closed' AND ended_at IS NOT NULL AND ended_at >= started_at)
    ),

    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (schedule_id) REFERENCES department_schedules(schedule_id),
    FOREIGN KEY (engineer_user_id) REFERENCES users(user_id),

    UNIQUE (department_id, schedule_id, started_at)
);

-- =========================
-- reports
-- =========================

CREATE TABLE report_instances (
    report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL,
    shift_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL,

    CHECK (status IN ('ready','not_ready')),
    CHECK (closed_at IS NULL OR closed_at >= created_at),

    FOREIGN KEY (template_id) REFERENCES report_templates(template_id),
    FOREIGN KEY (shift_id) REFERENCES shifts(shift_id),

    UNIQUE (template_id, shift_id)
);

CREATE TABLE template_attributes (
    template_id UUID NOT NULL,
    attribute_id UUID NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_numbered BOOLEAN NOT NULL DEFAULT FALSE,
    display_style VARCHAR(20) NOT NULL DEFAULT 'normal',
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (display_style IN ('normal','bold')),
    CHECK (sort_order >= 0),

    PRIMARY KEY (template_id, attribute_id),

    FOREIGN KEY (template_id) REFERENCES report_templates(template_id) ON DELETE CASCADE,
    FOREIGN KEY (attribute_id) REFERENCES attributes(attribute_id) ON DELETE CASCADE,

    UNIQUE (template_id, sort_order)
);

-- =========================
-- values
-- =========================

CREATE TABLE attribute_values (
    attribute_value_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL,
    attribute_id UUID NOT NULL,
    value_text TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (report_id) REFERENCES report_instances(report_id) ON DELETE CASCADE,
    FOREIGN KEY (attribute_id) REFERENCES attributes(attribute_id),

    UNIQUE (report_id, attribute_id)
);

CREATE TABLE attribute_value_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attribute_value_id UUID NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    changed_by_user_id UUID,
    comment TEXT,

    FOREIGN KEY (attribute_value_id) REFERENCES attribute_values(attribute_value_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- =========================
-- handoffs
-- =========================

CREATE TABLE shift_handoffs (
    handoff_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_shift_id UUID NOT NULL,
    to_shift_id UUID NOT NULL,
    handoff_status VARCHAR(20) NOT NULL,
    message TEXT,

    CHECK (handoff_status IN ('sent','accepted','rejected')),
    CHECK (from_shift_id <> to_shift_id),

    FOREIGN KEY (from_shift_id) REFERENCES shifts(shift_id),
    FOREIGN KEY (to_shift_id) REFERENCES shifts(shift_id)
);