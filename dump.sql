--
-- PostgreSQL database dump
--

\restrict ScKTEsNYQhgDqHqTLfE6y2HjWotMN5PcW7ceOMz5F0lBHlt7i8wOlevSI6JSok5

-- Dumped from database version 18.3 (Ubuntu 18.3-1.pgdg24.04+1)
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: attribute_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attribute_groups (
    group_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.attribute_groups OWNER TO postgres;

--
-- Name: attribute_value_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attribute_value_history (
    history_id uuid DEFAULT gen_random_uuid() NOT NULL,
    attribute_value_id uuid NOT NULL,
    old_value text,
    new_value text,
    changed_at timestamp with time zone DEFAULT now() NOT NULL,
    changed_by_user_id uuid,
    comment text
);


ALTER TABLE public.attribute_value_history OWNER TO postgres;

--
-- Name: attribute_values; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attribute_values (
    attribute_value_id uuid DEFAULT gen_random_uuid() NOT NULL,
    report_id uuid NOT NULL,
    attribute_id uuid NOT NULL,
    value_text text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.attribute_values OWNER TO postgres;

--
-- Name: attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attributes (
    attribute_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(200) NOT NULL,
    node_type character varying(20) NOT NULL,
    group_id uuid NOT NULL,
    data_type_id uuid,
    unit_id uuid,
    is_required boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT attributes_check CHECK (((((node_type)::text = 'section'::text) AND (data_type_id IS NULL)) OR (((node_type)::text = 'metric'::text) AND (data_type_id IS NOT NULL)))),
    CONSTRAINT attributes_node_type_check CHECK (((node_type)::text = ANY ((ARRAY['section'::character varying, 'metric'::character varying])::text[])))
);


ALTER TABLE public.attributes OWNER TO postgres;

--
-- Name: credentials; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.credentials (
    user_id uuid NOT NULL,
    login character varying(150) NOT NULL,
    password_hash text NOT NULL,
    last_login_at timestamp with time zone,
    failed_login_attempts integer DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT credentials_failed_login_attempts_check CHECK ((failed_login_attempts >= 0))
);


ALTER TABLE public.credentials OWNER TO postgres;

--
-- Name: data_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.data_types (
    data_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    base_type character varying(50) NOT NULL,
    CONSTRAINT data_types_base_type_check CHECK (((base_type)::text = ANY ((ARRAY['smallint'::character varying, 'integer'::character varying, 'bigint'::character varying, 'numeric'::character varying, 'real'::character varying, 'double precision'::character varying, 'boolean'::character varying, 'text'::character varying, 'date'::character varying, 'timestamp'::character varying, 'timestamptz'::character varying])::text[])))
);


ALTER TABLE public.data_types OWNER TO postgres;

--
-- Name: department_schedules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.department_schedules (
    schedule_id uuid DEFAULT gen_random_uuid() NOT NULL,
    department_id uuid NOT NULL,
    name character varying(100) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    crosses_midnight boolean DEFAULT false NOT NULL,
    CONSTRAINT department_schedules_sort_order_check CHECK ((sort_order >= 0))
);


ALTER TABLE public.department_schedules OWNER TO postgres;

--
-- Name: department_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.department_templates (
    department_id uuid NOT NULL,
    template_id uuid NOT NULL
);


ALTER TABLE public.department_templates OWNER TO postgres;

--
-- Name: department_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.department_users (
    department_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.department_users OWNER TO postgres;

--
-- Name: departments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departments (
    department_id uuid DEFAULT gen_random_uuid() NOT NULL,
    parent_department_id uuid,
    hierarchy_level integer,
    name character varying(200) NOT NULL,
    short_name character varying(100),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT departments_hierarchy_level_check CHECK (((hierarchy_level IS NULL) OR (hierarchy_level >= 0)))
);


ALTER TABLE public.departments OWNER TO postgres;

--
-- Name: measurement_units; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.measurement_units (
    unit_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    short_name character varying(30) NOT NULL
);


ALTER TABLE public.measurement_units OWNER TO postgres;

--
-- Name: modules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modules (
    module_id uuid DEFAULT gen_random_uuid() NOT NULL,
    display_name character varying(150) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    slug character varying(50) NOT NULL
);


ALTER TABLE public.modules OWNER TO postgres;

--
-- Name: report_instances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report_instances (
    report_id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid NOT NULL,
    shift_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_at timestamp with time zone,
    status character varying(20) NOT NULL,
    CONSTRAINT report_instances_check CHECK (((closed_at IS NULL) OR (closed_at >= created_at))),
    CONSTRAINT report_instances_status_check CHECK (((status)::text = ANY ((ARRAY['ready'::character varying, 'not_ready'::character varying])::text[])))
);


ALTER TABLE public.report_instances OWNER TO postgres;

--
-- Name: report_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(200) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    CONSTRAINT report_templates_version_check CHECK ((version > 0))
);


ALTER TABLE public.report_templates OWNER TO postgres;

--
-- Name: role_modules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_modules (
    role_id uuid NOT NULL,
    module_id uuid NOT NULL
);


ALTER TABLE public.role_modules OWNER TO postgres;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    role_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    description text
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: shift_handoffs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shift_handoffs (
    handoff_id uuid DEFAULT gen_random_uuid() NOT NULL,
    from_shift_id uuid NOT NULL,
    to_shift_id uuid NOT NULL,
    handoff_status character varying(20) NOT NULL,
    message text,
    CONSTRAINT shift_handoffs_check CHECK ((from_shift_id <> to_shift_id)),
    CONSTRAINT shift_handoffs_handoff_status_check CHECK (((handoff_status)::text = ANY ((ARRAY['sent'::character varying, 'accepted'::character varying, 'rejected'::character varying])::text[])))
);


ALTER TABLE public.shift_handoffs OWNER TO postgres;

--
-- Name: shifts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shifts (
    shift_id uuid DEFAULT gen_random_uuid() NOT NULL,
    started_at timestamp with time zone NOT NULL,
    ended_at timestamp with time zone,
    status character varying(20) NOT NULL,
    department_id uuid NOT NULL,
    schedule_id uuid NOT NULL,
    engineer_user_id uuid NOT NULL,
    CONSTRAINT shifts_check CHECK (((((status)::text = 'open'::text) AND (ended_at IS NULL)) OR (((status)::text = 'closed'::text) AND (ended_at IS NOT NULL) AND (ended_at >= started_at)))),
    CONSTRAINT shifts_status_check CHECK (((status)::text = ANY ((ARRAY['open'::character varying, 'closed'::character varying])::text[])))
);


ALTER TABLE public.shifts OWNER TO postgres;

--
-- Name: template_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.template_attributes (
    template_id uuid NOT NULL,
    attribute_id uuid NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_numbered boolean DEFAULT false NOT NULL,
    display_style character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    added_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT template_attributes_display_style_check CHECK (((display_style)::text = ANY ((ARRAY['normal'::character varying, 'bold'::character varying])::text[]))),
    CONSTRAINT template_attributes_sort_order_check CHECK ((sort_order >= 0))
);


ALTER TABLE public.template_attributes OWNER TO postgres;

--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles (
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.user_roles OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    last_name character varying(100) NOT NULL,
    first_name character varying(100) NOT NULL,
    middle_name character varying(100),
    registered_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Data for Name: attribute_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attribute_groups (group_id, name, description, is_active, created_at) FROM stdin;
5d7a62ca-b9e2-4a95-9f8b-fca0468925eb	Здание 1	Группа шаблона: Здание 1	t	2026-03-22 20:29:30.552516+00
99b8f618-66d8-4404-8f33-b08bb581ce19	Здание 2	Группа шаблона: Здание 2	t	2026-03-22 20:29:30.552516+00
3ce4f7d3-703b-433a-8ab5-f96f894b7ef0	Здание 3	Группа шаблона: Здание 3	t	2026-03-22 20:29:30.552516+00
b98e8641-f7ba-407c-bbc5-1784d36a5ccc	Здание 4	Группа шаблона: Здание 4	t	2026-03-22 20:29:30.552516+00
a8c8179b-5e14-4851-b59d-f2ab12ffda74	Замечания	Группа шаблона: Замечания	t	2026-03-22 20:29:30.552516+00
\.


--
-- Data for Name: attribute_value_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attribute_value_history (history_id, attribute_value_id, old_value, new_value, changed_at, changed_by_user_id, comment) FROM stdin;
12e8faeb-ac7f-4e05-8ff7-74ad49f5176d	4180eabf-6739-4e8c-b32a-b6339361af86	\N	200	2026-03-24 19:21:21.693698+00	1025389a-0e27-4e08-b6a0-b188660bea57	Первичное заполнение
a8b51f51-60e3-4d4c-b32e-d5b4c0916e68	03da7a06-7cf0-4570-9fba-36bea3ab7727	\N	201	2026-03-24 19:21:21.75325+00	1025389a-0e27-4e08-b6a0-b188660bea57	Первичное заполнение
748f2900-93dc-4cd8-be96-56a3c7083a61	f8a2d5dc-ea1a-4ff4-bc86-58622148ac05	\N	10	2026-04-13 21:21:11.260147+00	56d79006-412e-4a1a-ab42-da5509b64260	
1f2e4660-8569-40e4-8193-23f74e2de672	7c5bab58-92bc-4fca-88a1-781b50276c9a	\N	11	2026-04-13 21:21:11.958294+00	56d79006-412e-4a1a-ab42-da5509b64260	
9c6c242c-af31-4935-be39-8ef3e47716e0	582b0054-cac3-4d13-a39e-0cca8792c21e	\N	13	2026-04-13 21:21:12.618883+00	56d79006-412e-4a1a-ab42-da5509b64260	
525c6210-5078-4967-9c65-92bd4020a645	12a89697-a746-4442-8613-737d7b74b82f	\N	12	2026-04-13 21:21:13.277851+00	56d79006-412e-4a1a-ab42-da5509b64260	
559f1b53-b2cd-4df3-a1ee-c8eea182f209	5c8a72a3-7f74-4d01-bc22-950e5ca2bd89	\N	34	2026-04-13 21:21:13.936206+00	56d79006-412e-4a1a-ab42-da5509b64260	
559ddddc-99ce-4394-acee-ae8037b613b5	4e24db06-157c-4ad8-bb68-84039def8354	\N	15	2026-04-13 21:21:14.629569+00	56d79006-412e-4a1a-ab42-da5509b64260	
f0d1b5fd-43b4-4ba2-88ec-34cbd23dd609	ed507ff1-8492-4c8e-a617-048f9b6e97d5	\N	16	2026-04-13 21:21:15.289446+00	56d79006-412e-4a1a-ab42-da5509b64260	
bbee81c1-6fe2-4c5a-8613-e848e6a0b550	d2cd827a-c627-4d8e-8233-954c1462e567	\N	11	2026-04-13 21:21:15.947574+00	56d79006-412e-4a1a-ab42-da5509b64260	
5178f77d-0763-4422-bc4c-5c1462410a63	daa78c73-a9fa-4822-8480-2bfc21e86fb9	\N	12	2026-04-13 21:21:16.605281+00	56d79006-412e-4a1a-ab42-da5509b64260	
4b8c0c6b-c0c5-4a3e-ae72-656696f4b095	5bfbd450-962b-4619-ae8a-20b81bfebe8d	\N	11	2026-04-13 21:21:17.264439+00	56d79006-412e-4a1a-ab42-da5509b64260	
331560f7-228d-420a-b758-34c80131efb1	99cae024-3ae2-43d7-93d1-9bc5fe3db8f8	\N	14	2026-04-13 21:21:17.927218+00	56d79006-412e-4a1a-ab42-da5509b64260	
1010589a-01b9-453f-894f-ec20be32a369	321e44ae-f314-4a33-8f7e-4f5538f911e9	\N		2026-04-13 21:21:18.586518+00	56d79006-412e-4a1a-ab42-da5509b64260	
81a8e9bf-aadb-4f30-b5bc-6ec2bf3afc6d	57611ad5-4be9-407b-a1d0-a1f9472674b0	\N		2026-04-13 21:21:19.242099+00	56d79006-412e-4a1a-ab42-da5509b64260	
6361aeeb-70aa-45a2-9965-069e79801059	d47de7b4-9e9b-48c9-8c5f-bc14294dbbfb	\N		2026-04-13 21:21:19.899679+00	56d79006-412e-4a1a-ab42-da5509b64260	
6cf27125-ff43-4627-8db9-4de43b65bc9a	9cf70670-de59-4334-a928-d4ec846c8980	\N		2026-04-13 21:21:20.560207+00	56d79006-412e-4a1a-ab42-da5509b64260	
ba7fd14b-f64b-45f6-bbb4-b44e6aee55ae	9a365636-53a8-4662-98fa-afd334686e2b	\N		2026-04-13 21:21:21.218289+00	56d79006-412e-4a1a-ab42-da5509b64260	
9885a10a-fbcd-4efd-afe5-20deb8e90e81	56e62ee3-bf07-47ea-aafa-5055d781093c	\N		2026-04-13 21:21:21.876857+00	56d79006-412e-4a1a-ab42-da5509b64260	
576e5a7e-cdbf-4e3f-9006-c57c8d6ca549	a08a5023-f7c6-40cf-a1f2-c2efc166095b	\N		2026-04-13 21:21:22.534998+00	56d79006-412e-4a1a-ab42-da5509b64260	
af57e9ff-12d8-4718-a8fb-326f4db8dd4b	f8a2d5dc-ea1a-4ff4-bc86-58622148ac05	10	11	2026-04-13 21:45:09.017592+00	56d79006-412e-4a1a-ab42-da5509b64260	
9cc48a7f-48b8-4767-bf8f-7769fb9e6735	7c5bab58-92bc-4fca-88a1-781b50276c9a	11	11	2026-04-13 21:45:09.639518+00	56d79006-412e-4a1a-ab42-da5509b64260	
095b49be-d4ad-4c8b-9536-07a155c59a3b	582b0054-cac3-4d13-a39e-0cca8792c21e	13	13	2026-04-13 21:45:10.013977+00	56d79006-412e-4a1a-ab42-da5509b64260	
0d48f642-62b6-4e5a-88cf-0462c2fe6c74	12a89697-a746-4442-8613-737d7b74b82f	12	12	2026-04-13 21:45:10.388017+00	56d79006-412e-4a1a-ab42-da5509b64260	
9bfffdff-96cd-4808-8d9a-f489c2dc5a37	5c8a72a3-7f74-4d01-bc22-950e5ca2bd89	34	34	2026-04-13 21:45:10.761264+00	56d79006-412e-4a1a-ab42-da5509b64260	
d03d33d4-f034-42f3-93f5-df111a562ac1	4e24db06-157c-4ad8-bb68-84039def8354	15	15	2026-04-13 21:45:11.134833+00	56d79006-412e-4a1a-ab42-da5509b64260	
5974c28e-c206-42a7-8ef0-bf52bfa4eb73	ed507ff1-8492-4c8e-a617-048f9b6e97d5	16	16	2026-04-13 21:45:11.508877+00	56d79006-412e-4a1a-ab42-da5509b64260	
6c1bdec1-bd91-4088-a9b5-57100db5def8	d2cd827a-c627-4d8e-8233-954c1462e567	11	11	2026-04-13 21:45:11.881826+00	56d79006-412e-4a1a-ab42-da5509b64260	
cee132b8-0cf1-42ea-a28b-16508493dbfc	daa78c73-a9fa-4822-8480-2bfc21e86fb9	12	12	2026-04-13 21:45:12.255019+00	56d79006-412e-4a1a-ab42-da5509b64260	
5cba7f50-3bf9-4979-853b-9e91ceb8d4e6	5bfbd450-962b-4619-ae8a-20b81bfebe8d	11	11	2026-04-13 21:45:12.627753+00	56d79006-412e-4a1a-ab42-da5509b64260	
171aac98-7fe8-4a37-a253-eab99725c302	99cae024-3ae2-43d7-93d1-9bc5fe3db8f8	14	14	2026-04-13 21:45:13.001485+00	56d79006-412e-4a1a-ab42-da5509b64260	
0db4acd9-8f6c-4776-be87-78f200fd16ad	321e44ae-f314-4a33-8f7e-4f5538f911e9			2026-04-13 21:45:13.373996+00	56d79006-412e-4a1a-ab42-da5509b64260	
20166d3e-a8c9-4174-bfaa-0c3e8bccf3d0	57611ad5-4be9-407b-a1d0-a1f9472674b0			2026-04-13 21:45:13.747249+00	56d79006-412e-4a1a-ab42-da5509b64260	
c92bf0df-5efa-412b-8c9f-938e6acaccbb	d47de7b4-9e9b-48c9-8c5f-bc14294dbbfb			2026-04-13 21:45:14.119813+00	56d79006-412e-4a1a-ab42-da5509b64260	
4cde0358-fbe5-4980-b0c0-4191416723f2	9cf70670-de59-4334-a928-d4ec846c8980			2026-04-13 21:45:14.493678+00	56d79006-412e-4a1a-ab42-da5509b64260	
9f9bd7c8-6902-4afc-a2a4-edd5cd9001d2	9a365636-53a8-4662-98fa-afd334686e2b			2026-04-13 21:45:14.867838+00	56d79006-412e-4a1a-ab42-da5509b64260	
c7cc4f62-6bf0-4c50-9a68-de901358d64a	56e62ee3-bf07-47ea-aafa-5055d781093c			2026-04-13 21:45:15.241468+00	56d79006-412e-4a1a-ab42-da5509b64260	
ad81717e-d7e1-4e86-9d59-041b55aa9569	a08a5023-f7c6-40cf-a1f2-c2efc166095b			2026-04-13 21:45:15.614345+00	56d79006-412e-4a1a-ab42-da5509b64260	
53986d21-2149-4ec0-a0d8-1353e04f3207	f8a2d5dc-ea1a-4ff4-bc86-58622148ac05	11	11	2026-04-13 21:46:13.945846+00	56d79006-412e-4a1a-ab42-da5509b64260	
dfd66a8f-972b-4bff-aa22-393b3afd56c6	7c5bab58-92bc-4fca-88a1-781b50276c9a	11	11	2026-04-13 21:46:14.31219+00	56d79006-412e-4a1a-ab42-da5509b64260	
be86a2fa-f15a-42c1-83d1-8b21f9627305	582b0054-cac3-4d13-a39e-0cca8792c21e	13	13	2026-04-13 21:46:14.679129+00	56d79006-412e-4a1a-ab42-da5509b64260	
d70ccfc6-df80-41ea-9634-246197662ad0	12a89697-a746-4442-8613-737d7b74b82f	12	12	2026-04-13 21:46:15.045922+00	56d79006-412e-4a1a-ab42-da5509b64260	
af7a579c-29ac-4c38-be55-c5f9445874be	5c8a72a3-7f74-4d01-bc22-950e5ca2bd89	34	34	2026-04-13 21:46:15.412562+00	56d79006-412e-4a1a-ab42-da5509b64260	
ece205f6-8549-4a89-ab82-b8d77d3c94a2	4e24db06-157c-4ad8-bb68-84039def8354	15	15	2026-04-13 21:46:15.779133+00	56d79006-412e-4a1a-ab42-da5509b64260	
d51d8726-d34d-436e-a893-3f17fbfd612e	ed507ff1-8492-4c8e-a617-048f9b6e97d5	16	16	2026-04-13 21:46:16.146731+00	56d79006-412e-4a1a-ab42-da5509b64260	
f479f17f-f36e-4fed-98b2-18d4a78b02db	d2cd827a-c627-4d8e-8233-954c1462e567	11	11	2026-04-13 21:46:16.513595+00	56d79006-412e-4a1a-ab42-da5509b64260	
ce4f2904-46af-4aad-96b1-2d1fb299822b	daa78c73-a9fa-4822-8480-2bfc21e86fb9	12	12	2026-04-13 21:46:16.880868+00	56d79006-412e-4a1a-ab42-da5509b64260	
86041558-f10c-41b9-a18c-f06ad324b25e	5bfbd450-962b-4619-ae8a-20b81bfebe8d	11	11	2026-04-13 21:46:17.247531+00	56d79006-412e-4a1a-ab42-da5509b64260	
56a105f9-8457-45f8-8a20-493406a4ec32	99cae024-3ae2-43d7-93d1-9bc5fe3db8f8	14	14	2026-04-13 21:46:17.61437+00	56d79006-412e-4a1a-ab42-da5509b64260	
05c19d02-6f40-4b50-af66-1e2cf2c81a68	321e44ae-f314-4a33-8f7e-4f5538f911e9			2026-04-13 21:46:17.9817+00	56d79006-412e-4a1a-ab42-da5509b64260	
31a969a0-99d4-4455-b7df-aa923f65a1d4	57611ad5-4be9-407b-a1d0-a1f9472674b0			2026-04-13 21:46:18.348967+00	56d79006-412e-4a1a-ab42-da5509b64260	
a1f0b1f5-7a43-4864-8965-61ed350ecee5	d47de7b4-9e9b-48c9-8c5f-bc14294dbbfb			2026-04-13 21:46:18.715913+00	56d79006-412e-4a1a-ab42-da5509b64260	
ae852958-72a2-4ef0-8373-4e6d55183e13	9cf70670-de59-4334-a928-d4ec846c8980			2026-04-13 21:46:19.085225+00	56d79006-412e-4a1a-ab42-da5509b64260	
0ac97d0f-934b-4c8d-bf84-a354c3a8f067	9a365636-53a8-4662-98fa-afd334686e2b			2026-04-13 21:46:19.452065+00	56d79006-412e-4a1a-ab42-da5509b64260	
f94c72bc-f492-484e-9b49-409f00e1d0a5	56e62ee3-bf07-47ea-aafa-5055d781093c			2026-04-13 21:46:19.819537+00	56d79006-412e-4a1a-ab42-da5509b64260	
25485466-7823-420f-96b4-e6916e8453c6	a08a5023-f7c6-40cf-a1f2-c2efc166095b			2026-04-13 21:46:20.186481+00	56d79006-412e-4a1a-ab42-da5509b64260	
02f233c2-3670-4361-94b8-7ba1ad12dfc9	4016ed77-1a98-4d6b-8817-bf1fb0633d26	\N	12312	2026-04-14 10:05:31.049327+00	56d79006-412e-4a1a-ab42-da5509b64260	
92bacd58-bb50-4318-b0a0-7431e807e9b4	6b3ef7eb-05f6-4bd8-9f01-8dd19f291c02	\N		2026-04-14 10:05:31.180505+00	56d79006-412e-4a1a-ab42-da5509b64260	
a89dc141-e00f-4380-8766-23bf33243142	e56f7eba-62ea-418a-b0eb-ed4a5f95918e	\N		2026-04-14 10:05:31.309951+00	56d79006-412e-4a1a-ab42-da5509b64260	
a56bbadc-2560-42b4-844c-b2fb0a3928a1	092ddee7-093b-45ee-a0af-b56b1cad3d77	\N		2026-04-14 10:05:31.43952+00	56d79006-412e-4a1a-ab42-da5509b64260	
9dc9b5dd-1f2a-444a-8beb-8bf2576b0dd6	244f920b-8241-4f13-96cf-0f5bf2b0fc49	\N		2026-04-14 10:05:31.570241+00	56d79006-412e-4a1a-ab42-da5509b64260	
3de3c978-79fd-4afd-b900-8f374e1b9d5a	50dd0eea-0972-45f1-9d98-2f490a85aee4	\N		2026-04-14 10:05:31.702311+00	56d79006-412e-4a1a-ab42-da5509b64260	
bb04818c-2bd0-456a-936e-ef79ec5a97d2	6e567c50-796d-4c39-b7c6-d8aa2be57e67	\N		2026-04-14 10:05:31.83168+00	56d79006-412e-4a1a-ab42-da5509b64260	
7312cb2d-f8ff-4733-aaac-2d9dced29c42	9c7bd5a4-2613-43f5-9f30-7e7b9c98abf2	\N		2026-04-14 10:05:31.961691+00	56d79006-412e-4a1a-ab42-da5509b64260	
b5c31498-6437-4142-b8c4-940f7a40d1be	7892338e-2b0a-43aa-8501-eab4b46635f5	\N		2026-04-14 10:05:32.09093+00	56d79006-412e-4a1a-ab42-da5509b64260	
cd56b46f-bea3-416e-84b8-9f0ef324854c	5d497eb0-4237-4435-99e1-dacdc6d17c24	\N		2026-04-14 10:05:32.219091+00	56d79006-412e-4a1a-ab42-da5509b64260	
0f1aab48-4f2f-4ed0-ad0c-0f52e627516b	02f19ddf-496b-416f-a427-06faef00312b	\N		2026-04-14 10:05:32.34882+00	56d79006-412e-4a1a-ab42-da5509b64260	
4773ecea-ba0c-4daf-9f6d-7bd01e1b81fa	91671878-4349-46ce-85c4-3c5c9f1b1408	\N		2026-04-14 10:05:32.47803+00	56d79006-412e-4a1a-ab42-da5509b64260	
d1c881ed-fbd9-4d19-8037-fa93da7bf98b	bff93eec-263e-4250-874e-2014d41b986f	\N		2026-04-14 10:05:32.606886+00	56d79006-412e-4a1a-ab42-da5509b64260	
dd2d4250-54de-43dd-99cb-cd05ab73a954	a15431de-b67b-4976-b6d5-14f4d11026bb	\N		2026-04-14 10:05:32.734505+00	56d79006-412e-4a1a-ab42-da5509b64260	
b8517dc1-2fb8-4cb4-9e91-1919f1e43043	cda3a6dc-a2b0-4fda-b320-6cec78c39fb3	\N		2026-04-14 10:05:32.86168+00	56d79006-412e-4a1a-ab42-da5509b64260	
a0ba3cd6-1c9b-4562-8765-01d7a63183a1	9c76dbf2-f8cb-4873-b003-8aa82f9ba0d9	\N		2026-04-14 10:05:32.989436+00	56d79006-412e-4a1a-ab42-da5509b64260	
621f81b5-a05c-4502-948a-26fe3becacf2	16c420fc-0f73-45bb-967f-2ab85ee65bc7	\N		2026-04-14 10:05:33.117464+00	56d79006-412e-4a1a-ab42-da5509b64260	
ed38dea1-f548-43b6-a92e-f22320abbe47	2e867df1-7f62-45b2-8bf2-eda75091d77d	\N		2026-04-14 10:05:33.24484+00	56d79006-412e-4a1a-ab42-da5509b64260	
9d212383-054f-4ed6-8ea3-2b2878ed8f1d	4016ed77-1a98-4d6b-8817-bf1fb0633d26	12312	12312	2026-04-14 10:05:50.015548+00	56d79006-412e-4a1a-ab42-da5509b64260	
bf5f582d-c7f5-4aba-9ef2-8c8c5f6c00c4	6b3ef7eb-05f6-4bd8-9f01-8dd19f291c02			2026-04-14 10:05:50.093429+00	56d79006-412e-4a1a-ab42-da5509b64260	
01316859-bc07-4326-8eaa-408ac56c5a5f	e56f7eba-62ea-418a-b0eb-ed4a5f95918e			2026-04-14 10:05:50.170351+00	56d79006-412e-4a1a-ab42-da5509b64260	
7f4ca07f-a27b-428d-93e4-a50cf0c03c9e	092ddee7-093b-45ee-a0af-b56b1cad3d77			2026-04-14 10:05:50.246939+00	56d79006-412e-4a1a-ab42-da5509b64260	
ccfa4a45-149d-42d7-ad63-220114acbef1	244f920b-8241-4f13-96cf-0f5bf2b0fc49			2026-04-14 10:05:50.325391+00	56d79006-412e-4a1a-ab42-da5509b64260	
9891d56b-d614-49fd-bd33-8dc935441644	50dd0eea-0972-45f1-9d98-2f490a85aee4			2026-04-14 10:05:50.402887+00	56d79006-412e-4a1a-ab42-da5509b64260	
cbd58ad6-8865-438d-a9ed-cb8e1aed86e7	6e567c50-796d-4c39-b7c6-d8aa2be57e67			2026-04-14 10:05:50.479998+00	56d79006-412e-4a1a-ab42-da5509b64260	
be0e82b3-f4da-4e0f-9286-52fa6190bcc2	9c7bd5a4-2613-43f5-9f30-7e7b9c98abf2			2026-04-14 10:05:50.558267+00	56d79006-412e-4a1a-ab42-da5509b64260	
36a0ff6d-42be-4223-88f9-514d7c3232fb	7892338e-2b0a-43aa-8501-eab4b46635f5			2026-04-14 10:05:50.637778+00	56d79006-412e-4a1a-ab42-da5509b64260	
a9936120-5d5c-4c65-b90f-4e926c8400ca	5d497eb0-4237-4435-99e1-dacdc6d17c24			2026-04-14 10:05:50.716689+00	56d79006-412e-4a1a-ab42-da5509b64260	
78fbb361-7557-4721-b743-7a0a48bc3d91	02f19ddf-496b-416f-a427-06faef00312b			2026-04-14 10:05:50.794625+00	56d79006-412e-4a1a-ab42-da5509b64260	
a939e88d-a1cc-4139-be02-45a9a19bc386	91671878-4349-46ce-85c4-3c5c9f1b1408			2026-04-14 10:05:50.871697+00	56d79006-412e-4a1a-ab42-da5509b64260	
9c2710a6-738e-4dfd-a38a-df1cf58f6380	bff93eec-263e-4250-874e-2014d41b986f			2026-04-14 10:05:50.948683+00	56d79006-412e-4a1a-ab42-da5509b64260	
85252027-4316-487d-9dbe-e3b9f7a0e238	a15431de-b67b-4976-b6d5-14f4d11026bb			2026-04-14 10:05:51.02631+00	56d79006-412e-4a1a-ab42-da5509b64260	
662a6852-35a7-4b07-8d10-bc77e2845e8b	cda3a6dc-a2b0-4fda-b320-6cec78c39fb3			2026-04-14 10:05:51.104014+00	56d79006-412e-4a1a-ab42-da5509b64260	
1a8358a9-c8d2-42ef-8e92-afc5b6724b05	9c76dbf2-f8cb-4873-b003-8aa82f9ba0d9			2026-04-14 10:05:51.181188+00	56d79006-412e-4a1a-ab42-da5509b64260	
38394d9d-e34f-4f6e-86d5-ea7960c14731	16c420fc-0f73-45bb-967f-2ab85ee65bc7			2026-04-14 10:05:51.258711+00	56d79006-412e-4a1a-ab42-da5509b64260	
37cea70d-7e94-488d-bb43-7268501fa0fe	2e867df1-7f62-45b2-8bf2-eda75091d77d			2026-04-14 10:05:51.335684+00	56d79006-412e-4a1a-ab42-da5509b64260	
2c05e1a0-b1ed-4c3f-8884-6fbead0d6e92	4016ed77-1a98-4d6b-8817-bf1fb0633d26	12312	12312	2026-04-14 10:06:18.36547+00	56d79006-412e-4a1a-ab42-da5509b64260	
f9dc496e-281a-41fe-9fc4-22a1acde66db	6b3ef7eb-05f6-4bd8-9f01-8dd19f291c02		1234	2026-04-14 10:06:18.442171+00	56d79006-412e-4a1a-ab42-da5509b64260	
435072d7-7bee-4ad4-95ad-9e9475753ce1	e56f7eba-62ea-418a-b0eb-ed4a5f95918e			2026-04-14 10:06:18.841658+00	56d79006-412e-4a1a-ab42-da5509b64260	
ae716a88-f25a-4b9c-a7d5-44f086a3cc1e	092ddee7-093b-45ee-a0af-b56b1cad3d77			2026-04-14 10:06:18.918571+00	56d79006-412e-4a1a-ab42-da5509b64260	
fbf2f364-8028-4bfb-84fc-0893a62bd05f	244f920b-8241-4f13-96cf-0f5bf2b0fc49			2026-04-14 10:06:18.996191+00	56d79006-412e-4a1a-ab42-da5509b64260	
5d433524-797f-43c1-ba39-179a9d214c82	50dd0eea-0972-45f1-9d98-2f490a85aee4			2026-04-14 10:06:19.072325+00	56d79006-412e-4a1a-ab42-da5509b64260	
ca5b38f8-5a5d-49c8-8783-63cd4d8d14a2	6e567c50-796d-4c39-b7c6-d8aa2be57e67			2026-04-14 10:06:19.149109+00	56d79006-412e-4a1a-ab42-da5509b64260	
70fc087a-af1c-4680-ac18-62f37debdef4	9c7bd5a4-2613-43f5-9f30-7e7b9c98abf2			2026-04-14 10:06:19.225116+00	56d79006-412e-4a1a-ab42-da5509b64260	
b173aa0d-91bf-432f-a7a2-3c1a2b112406	7892338e-2b0a-43aa-8501-eab4b46635f5			2026-04-14 10:06:19.300717+00	56d79006-412e-4a1a-ab42-da5509b64260	
9997d1d8-3b69-4fcf-baf1-c2237fffb970	5d497eb0-4237-4435-99e1-dacdc6d17c24			2026-04-14 10:06:19.621728+00	56d79006-412e-4a1a-ab42-da5509b64260	
6b654d9e-6dd8-47d9-b880-0d5e7cf6eab6	02f19ddf-496b-416f-a427-06faef00312b			2026-04-14 10:06:19.942148+00	56d79006-412e-4a1a-ab42-da5509b64260	
cf070f37-bfe9-4179-9588-dc4911d3e8bb	91671878-4349-46ce-85c4-3c5c9f1b1408			2026-04-14 10:06:20.018892+00	56d79006-412e-4a1a-ab42-da5509b64260	
393ab74f-5fba-4614-b256-e95ddda361c5	bff93eec-263e-4250-874e-2014d41b986f			2026-04-14 10:06:20.094986+00	56d79006-412e-4a1a-ab42-da5509b64260	
c581ad39-2e3b-4802-ac8d-28d68259906d	a15431de-b67b-4976-b6d5-14f4d11026bb			2026-04-14 10:06:20.171183+00	56d79006-412e-4a1a-ab42-da5509b64260	
6ec00689-ae7a-422e-bb60-e5369e70895e	cda3a6dc-a2b0-4fda-b320-6cec78c39fb3			2026-04-14 10:06:20.247163+00	56d79006-412e-4a1a-ab42-da5509b64260	
cf8967dc-4d9c-447b-8369-1b87d023fd61	9c76dbf2-f8cb-4873-b003-8aa82f9ba0d9			2026-04-14 10:06:20.323016+00	56d79006-412e-4a1a-ab42-da5509b64260	
5ee1c843-fd1f-4858-a97d-8dddbbdc341d	16c420fc-0f73-45bb-967f-2ab85ee65bc7			2026-04-14 10:06:20.399281+00	56d79006-412e-4a1a-ab42-da5509b64260	
4718be3e-ca87-418f-bb1a-e40b571447ef	2e867df1-7f62-45b2-8bf2-eda75091d77d			2026-04-14 10:06:20.475206+00	56d79006-412e-4a1a-ab42-da5509b64260	
3c150c06-8106-459f-9615-fafb02aed9bc	5a052d36-39f2-48ff-b178-ff1c745ccdf3	\N		2026-04-14 10:06:37.980972+00	56d79006-412e-4a1a-ab42-da5509b64260	
f9a09a98-aded-4f57-a9b2-46f48361dcdd	c2ec2a3b-6624-4f34-aefb-0551e2c18603	\N		2026-04-14 10:06:38.350835+00	56d79006-412e-4a1a-ab42-da5509b64260	
72ce9c38-bfec-4184-9ce0-601b2ed97f7d	3eb26e58-d4df-4cfd-8282-9ceeecd17a39	\N		2026-04-14 10:06:38.477701+00	56d79006-412e-4a1a-ab42-da5509b64260	
e9581791-1a51-4362-8f6b-bf3af04ef32d	0896be92-ff02-4d76-83ce-bd3cb0c780bd	\N		2026-04-14 10:06:38.602841+00	56d79006-412e-4a1a-ab42-da5509b64260	
b84d703f-a84b-4e52-ad2a-d675b5c071be	bd11e2cd-83e8-4abd-ae6d-4e1d31348463	\N		2026-04-14 10:06:38.727686+00	56d79006-412e-4a1a-ab42-da5509b64260	
072f108b-9293-4715-b918-455e4a3461cc	7ec9cbea-fd82-4673-b841-4722049ae25a	\N		2026-04-14 10:06:38.853358+00	56d79006-412e-4a1a-ab42-da5509b64260	
612b3686-afea-42a0-ad22-e23d7ae389c8	3be17c8c-b0d2-427c-9dab-6e751676c05f	\N		2026-04-14 10:06:38.978677+00	56d79006-412e-4a1a-ab42-da5509b64260	
5377bb61-c877-40b7-a54c-b428142ae030	a36c07c0-2761-498b-b78c-374a2d22f5ad	\N		2026-04-14 10:06:39.103455+00	56d79006-412e-4a1a-ab42-da5509b64260	
23a884e7-fa44-4498-b194-e40d5ee197c7	809e7d98-d767-4112-bf29-de2007829276	\N		2026-04-14 10:06:39.2285+00	56d79006-412e-4a1a-ab42-da5509b64260	
a1cc4ebc-dcb2-4027-a757-41638f56bbc4	6b4f28f3-dfe3-4753-aa3e-7855bfe00ed3	\N		2026-04-14 10:06:39.353225+00	56d79006-412e-4a1a-ab42-da5509b64260	
d02d25b3-fd40-4ad9-9c76-0698bbb20694	5f35b98c-5993-4fe9-ac0c-1093bbc70e65	\N		2026-04-14 10:06:39.479064+00	56d79006-412e-4a1a-ab42-da5509b64260	
5ee8d6c6-09ac-4fdd-a31a-ba2c2caadba2	2606fc49-b999-4495-ba5e-94b789f72f05	\N		2026-04-14 10:06:39.603825+00	56d79006-412e-4a1a-ab42-da5509b64260	
55e17b81-7d8f-4790-ad96-8845022e6a29	27ac0892-a967-41f8-9cc7-cc76586c6907	\N		2026-04-14 10:06:39.728906+00	56d79006-412e-4a1a-ab42-da5509b64260	
6d8a18eb-1cbc-4533-9281-4c743deb4447	6bc6bd7c-52c5-4971-96df-82e29120ac06	\N		2026-04-14 10:06:40.102026+00	56d79006-412e-4a1a-ab42-da5509b64260	
22f00f2e-e057-4b9d-9b64-97ed270f3779	d638262c-74d1-4f05-9535-54200b87900e	\N		2026-04-14 10:06:40.228045+00	56d79006-412e-4a1a-ab42-da5509b64260	
82e6f403-f90c-4cd8-9b20-11ab76d8b3c1	fa11dc7c-2ff7-44d7-985e-3e3a17c8df29	\N		2026-04-14 10:06:40.355945+00	56d79006-412e-4a1a-ab42-da5509b64260	
1c7a2ea5-2dac-4d7c-a0dc-16117414b5f8	c0f2d474-631e-48b4-ab78-7e6ed8c717d7	\N		2026-04-14 10:06:40.481356+00	56d79006-412e-4a1a-ab42-da5509b64260	
64cbd2d3-4fa5-4dd0-83bd-11a05de56a07	0bc077c5-8842-4617-b756-e12a4aae9329	\N		2026-04-14 10:06:40.607414+00	56d79006-412e-4a1a-ab42-da5509b64260	
afd71878-4a45-4a09-a8c6-b60aad0547e7	5a052d36-39f2-48ff-b178-ff1c745ccdf3			2026-04-14 10:20:35.515934+00	56d79006-412e-4a1a-ab42-da5509b64260	
c014ee00-5936-475f-a470-238d460e43b8	c2ec2a3b-6624-4f34-aefb-0551e2c18603			2026-04-14 10:20:35.592973+00	56d79006-412e-4a1a-ab42-da5509b64260	
e1786b4f-4666-46cf-a474-4ace01edd418	3eb26e58-d4df-4cfd-8282-9ceeecd17a39			2026-04-14 10:20:35.669871+00	56d79006-412e-4a1a-ab42-da5509b64260	
824bb4ff-8405-4b02-8aea-5aa0404fc69b	0896be92-ff02-4d76-83ce-bd3cb0c780bd			2026-04-14 10:20:35.747114+00	56d79006-412e-4a1a-ab42-da5509b64260	
815a8abb-2d3f-4787-aaed-d448febb3b47	bd11e2cd-83e8-4abd-ae6d-4e1d31348463			2026-04-14 10:20:35.824478+00	56d79006-412e-4a1a-ab42-da5509b64260	
9e9c4ecb-38d7-4bbb-bb64-42cb702a584b	7ec9cbea-fd82-4673-b841-4722049ae25a			2026-04-14 10:20:35.90137+00	56d79006-412e-4a1a-ab42-da5509b64260	
dae5dd18-bd72-46ca-a871-e03fd76c4178	3be17c8c-b0d2-427c-9dab-6e751676c05f			2026-04-14 10:20:35.978056+00	56d79006-412e-4a1a-ab42-da5509b64260	
7973e52d-b9ce-4c5a-8c97-b38baf9155a8	a36c07c0-2761-498b-b78c-374a2d22f5ad			2026-04-14 10:20:36.053853+00	56d79006-412e-4a1a-ab42-da5509b64260	
c11912fc-9c6b-4ae3-a4f9-0e9ae41e47e0	809e7d98-d767-4112-bf29-de2007829276			2026-04-14 10:20:36.129393+00	56d79006-412e-4a1a-ab42-da5509b64260	
8c2199af-4042-49a7-8330-00a8f6ac9f73	6b4f28f3-dfe3-4753-aa3e-7855bfe00ed3			2026-04-14 10:20:36.204057+00	56d79006-412e-4a1a-ab42-da5509b64260	
d24a8c4f-f3a0-4998-8d03-7683bd18db0f	5f35b98c-5993-4fe9-ac0c-1093bbc70e65			2026-04-14 10:20:36.278525+00	56d79006-412e-4a1a-ab42-da5509b64260	
eeab4094-c5c9-427a-9c21-fb2ecea82268	2606fc49-b999-4495-ba5e-94b789f72f05			2026-04-14 10:20:36.353624+00	56d79006-412e-4a1a-ab42-da5509b64260	
ec5cf984-1422-4382-8863-ea3d5d28fc07	27ac0892-a967-41f8-9cc7-cc76586c6907			2026-04-14 10:20:36.427703+00	56d79006-412e-4a1a-ab42-da5509b64260	
96dec60b-c94f-4e4f-b7a9-e237dfbe19e2	6bc6bd7c-52c5-4971-96df-82e29120ac06			2026-04-14 10:20:36.502416+00	56d79006-412e-4a1a-ab42-da5509b64260	
fcfd19fd-2212-42f4-8663-438ac5b33f45	d638262c-74d1-4f05-9535-54200b87900e			2026-04-14 10:20:36.577445+00	56d79006-412e-4a1a-ab42-da5509b64260	
fc2fb2fb-a74c-4f4b-9111-f769b92a0b92	fa11dc7c-2ff7-44d7-985e-3e3a17c8df29			2026-04-14 10:20:36.652796+00	56d79006-412e-4a1a-ab42-da5509b64260	
7b166644-75df-4d06-9d4c-e88b3ba184a4	c0f2d474-631e-48b4-ab78-7e6ed8c717d7			2026-04-14 10:20:36.727505+00	56d79006-412e-4a1a-ab42-da5509b64260	
bf2c29fa-0399-4043-a51c-8520f8439985	0bc077c5-8842-4617-b756-e12a4aae9329			2026-04-14 10:20:36.801734+00	56d79006-412e-4a1a-ab42-da5509b64260	
f671f82a-d6fd-415b-b36b-bbb5a3f0bfeb	5a052d36-39f2-48ff-b178-ff1c745ccdf3		123	2026-04-14 10:20:45.929679+00	56d79006-412e-4a1a-ab42-da5509b64260	
76bd32f9-1977-481c-b6f8-9f2a162ed39d	c2ec2a3b-6624-4f34-aefb-0551e2c18603		321	2026-04-14 10:20:46.054543+00	56d79006-412e-4a1a-ab42-da5509b64260	
35af0049-d641-45c9-a5b1-7cd6734859a0	3eb26e58-d4df-4cfd-8282-9ceeecd17a39			2026-04-14 10:20:46.179649+00	56d79006-412e-4a1a-ab42-da5509b64260	
c1c2eee6-6b2d-40b0-b54b-a3fed871c207	0896be92-ff02-4d76-83ce-bd3cb0c780bd			2026-04-14 10:20:46.254866+00	56d79006-412e-4a1a-ab42-da5509b64260	
13d1d939-626b-41ae-8f19-eb4268ce56ab	bd11e2cd-83e8-4abd-ae6d-4e1d31348463			2026-04-14 10:20:46.329809+00	56d79006-412e-4a1a-ab42-da5509b64260	
670bb060-938d-436b-b4da-2f40a229721f	7ec9cbea-fd82-4673-b841-4722049ae25a			2026-04-14 10:20:46.404205+00	56d79006-412e-4a1a-ab42-da5509b64260	
6d77f5cf-d42b-4acb-b104-d6640a3be5dd	3be17c8c-b0d2-427c-9dab-6e751676c05f			2026-04-14 10:20:46.478859+00	56d79006-412e-4a1a-ab42-da5509b64260	
fd876087-08e0-4ce0-905b-c7ea4d677508	a36c07c0-2761-498b-b78c-374a2d22f5ad			2026-04-14 10:20:46.553238+00	56d79006-412e-4a1a-ab42-da5509b64260	
0f6e55ed-c7e7-49d0-b08b-2ee690c473cc	809e7d98-d767-4112-bf29-de2007829276			2026-04-14 10:20:46.629074+00	56d79006-412e-4a1a-ab42-da5509b64260	
bc435c3b-eb55-4ea3-bc34-4342b1fe8728	6b4f28f3-dfe3-4753-aa3e-7855bfe00ed3			2026-04-14 10:20:46.703723+00	56d79006-412e-4a1a-ab42-da5509b64260	
ddb8643a-7033-4fa5-afd9-1a052af00ccf	5f35b98c-5993-4fe9-ac0c-1093bbc70e65			2026-04-14 10:20:46.779207+00	56d79006-412e-4a1a-ab42-da5509b64260	
427c1a9e-b365-4a76-9cb6-2f2204d9f54c	2606fc49-b999-4495-ba5e-94b789f72f05			2026-04-14 10:20:46.855047+00	56d79006-412e-4a1a-ab42-da5509b64260	
9ea5ff2b-22a5-42fb-bba6-cebb206024f4	27ac0892-a967-41f8-9cc7-cc76586c6907			2026-04-14 10:20:46.930557+00	56d79006-412e-4a1a-ab42-da5509b64260	
70c9a72e-0c06-4453-8c64-4b156e606d3c	6bc6bd7c-52c5-4971-96df-82e29120ac06			2026-04-14 10:20:47.005828+00	56d79006-412e-4a1a-ab42-da5509b64260	
76a9d701-13ad-4705-b2f4-32c5f8fb02f8	d638262c-74d1-4f05-9535-54200b87900e			2026-04-14 10:20:47.080551+00	56d79006-412e-4a1a-ab42-da5509b64260	
30aab3b3-2557-4928-97a0-cbf5c2a98f56	fa11dc7c-2ff7-44d7-985e-3e3a17c8df29			2026-04-14 10:20:47.155682+00	56d79006-412e-4a1a-ab42-da5509b64260	
eb2a3434-0465-44b5-908e-eb95973daf28	c0f2d474-631e-48b4-ab78-7e6ed8c717d7			2026-04-14 10:20:47.231713+00	56d79006-412e-4a1a-ab42-da5509b64260	
e167f6ea-e9a4-4566-81e5-4f96b2151ddf	0bc077c5-8842-4617-b756-e12a4aae9329			2026-04-14 10:20:47.30617+00	56d79006-412e-4a1a-ab42-da5509b64260	
84c5d0cd-f220-4b42-9010-538961851ba7	2b65a8f2-48c5-4c60-84c5-3cfeefcd26c2	\N		2026-04-14 11:03:40.277169+00	56d79006-412e-4a1a-ab42-da5509b64260	
33b5b664-dcad-44be-a2d6-47f0f3203b52	770007d2-a817-4bb5-932d-1e4939a98074	\N		2026-04-14 11:03:40.404511+00	56d79006-412e-4a1a-ab42-da5509b64260	
38c54fca-76d4-43e7-86b2-193cb3526aca	99b38cda-bc3e-4e08-9c4c-c9f6085906fc	\N		2026-04-14 11:03:40.530787+00	56d79006-412e-4a1a-ab42-da5509b64260	
afd4da42-bd26-4afa-9562-027a22eba6d5	2a12da85-2e0c-4cc9-bde6-1ee749895503	\N		2026-04-14 11:03:40.902612+00	56d79006-412e-4a1a-ab42-da5509b64260	
b9d24edd-ca9d-4f5c-913d-7a6c66e28194	a3144950-2782-4c2b-a834-b196e52bc0e2	\N		2026-04-14 11:03:41.028291+00	56d79006-412e-4a1a-ab42-da5509b64260	
e9713cb0-8b00-481e-96d7-824b986a5d0a	767e3e13-b162-4004-9dd9-e725294f8add	\N		2026-04-14 11:03:41.153849+00	56d79006-412e-4a1a-ab42-da5509b64260	
4d6eea0f-4833-4330-bbc3-8ef807d5dee6	33edec4b-430e-45ac-ae1c-33df782737f8	\N		2026-04-14 11:03:41.278924+00	56d79006-412e-4a1a-ab42-da5509b64260	
9754dd41-ce36-49ab-ad18-16bd8e70ca69	02939f5c-b940-43f0-86b5-e367cf470f5d	\N		2026-04-14 11:03:41.404567+00	56d79006-412e-4a1a-ab42-da5509b64260	
2ec143e8-b1ce-4db0-ae06-a765309d02dd	d65b7f6d-e129-419b-8029-e1eeede2fdf8	\N		2026-04-14 11:03:41.52906+00	56d79006-412e-4a1a-ab42-da5509b64260	
35c2fca6-d38d-4c00-9bd4-01c53899798c	b6948380-a1bf-4497-9c91-6629ef38bb2b	\N		2026-04-14 11:03:41.653995+00	56d79006-412e-4a1a-ab42-da5509b64260	
a5e56f1b-34ad-41ee-93e2-c1d5f634d695	54b8e3a7-8713-43ec-a9b9-749e5700641c	\N		2026-04-14 11:03:41.777885+00	56d79006-412e-4a1a-ab42-da5509b64260	
28b97277-b3f6-482d-8d21-bc6bf0cad31e	2ea2c4ff-93c2-446f-b7cd-8520a26a6de0	\N		2026-04-14 11:03:41.902543+00	56d79006-412e-4a1a-ab42-da5509b64260	
5d74bb96-a3ea-4780-8eb8-fdfc2b74a26b	fb3c0bf3-9afc-4863-8d90-f9a5551e6a25	\N		2026-04-14 11:03:42.026556+00	56d79006-412e-4a1a-ab42-da5509b64260	
c503bb74-c25e-43d1-ad57-d98d7ea0bf2d	b7468503-985f-4866-8c13-915ce9cdd0c8	\N		2026-04-14 11:03:42.150366+00	56d79006-412e-4a1a-ab42-da5509b64260	
57c6d575-a34a-45f7-83e4-f909cc3eede9	9b7c3e2f-f95b-4b71-9338-66c83c3ccb8b	\N		2026-04-14 11:03:42.273485+00	56d79006-412e-4a1a-ab42-da5509b64260	
11d4c048-9b74-4e0a-ad15-65c798ec6188	d0f2f840-7ca4-45dd-b94a-22f9b6142b59	\N		2026-04-14 11:03:42.396844+00	56d79006-412e-4a1a-ab42-da5509b64260	
06657712-723d-4c2f-a274-1a413ed9b1a5	c09b96d1-e306-402c-b924-68a81d67f0bb	\N		2026-04-14 11:03:42.520416+00	56d79006-412e-4a1a-ab42-da5509b64260	
816c7ee3-143d-454a-a594-387882ad6bbf	8e0d8c11-3475-4112-9812-ad38260253e5	\N		2026-04-14 11:03:42.643236+00	56d79006-412e-4a1a-ab42-da5509b64260	
bf71ec77-cce6-4be2-9ceb-cfa9d2d27ef7	2b65a8f2-48c5-4c60-84c5-3cfeefcd26c2			2026-04-14 11:03:47.224319+00	56d79006-412e-4a1a-ab42-da5509b64260	
a96c1423-798d-4776-b1eb-b3313a734c65	770007d2-a817-4bb5-932d-1e4939a98074			2026-04-14 11:03:47.543917+00	56d79006-412e-4a1a-ab42-da5509b64260	
c7bd5227-ceb7-4926-b5ab-6099d5753eba	99b38cda-bc3e-4e08-9c4c-c9f6085906fc			2026-04-14 11:03:47.619007+00	56d79006-412e-4a1a-ab42-da5509b64260	
87274281-2102-43cf-8aed-c20590c830f7	2a12da85-2e0c-4cc9-bde6-1ee749895503			2026-04-14 11:03:47.693434+00	56d79006-412e-4a1a-ab42-da5509b64260	
f254280f-ffbb-4c6a-88f7-72215f05bb42	a3144950-2782-4c2b-a834-b196e52bc0e2			2026-04-14 11:03:47.768439+00	56d79006-412e-4a1a-ab42-da5509b64260	
ddac2f48-1c66-4466-b12f-fc962e893492	767e3e13-b162-4004-9dd9-e725294f8add			2026-04-14 11:03:47.842972+00	56d79006-412e-4a1a-ab42-da5509b64260	
eedcda6b-4086-4269-af13-1061df0e3f93	33edec4b-430e-45ac-ae1c-33df782737f8			2026-04-14 11:03:47.917213+00	56d79006-412e-4a1a-ab42-da5509b64260	
dacd414d-ca1c-44a5-bf4a-651b91ef45fe	02939f5c-b940-43f0-86b5-e367cf470f5d			2026-04-14 11:03:47.991864+00	56d79006-412e-4a1a-ab42-da5509b64260	
cc28afb0-9b15-4380-bbb2-9e09e7dc42c6	d65b7f6d-e129-419b-8029-e1eeede2fdf8			2026-04-14 11:03:48.067573+00	56d79006-412e-4a1a-ab42-da5509b64260	
add1f0d2-a1a9-4398-9c38-8867cc8b5a5b	b6948380-a1bf-4497-9c91-6629ef38bb2b			2026-04-14 11:03:48.142439+00	56d79006-412e-4a1a-ab42-da5509b64260	
fcfa72c7-bf7e-498d-aa3a-809caac4eecd	54b8e3a7-8713-43ec-a9b9-749e5700641c			2026-04-14 11:03:48.218085+00	56d79006-412e-4a1a-ab42-da5509b64260	
51c19527-4055-4424-98d8-25b04fdbbfb8	2ea2c4ff-93c2-446f-b7cd-8520a26a6de0			2026-04-14 11:03:48.294071+00	56d79006-412e-4a1a-ab42-da5509b64260	
86a22153-1922-4751-826c-0b9412746f21	fb3c0bf3-9afc-4863-8d90-f9a5551e6a25			2026-04-14 11:03:48.369947+00	56d79006-412e-4a1a-ab42-da5509b64260	
f45ad6f5-17db-43ca-baff-83e16e61bff8	b7468503-985f-4866-8c13-915ce9cdd0c8			2026-04-14 11:03:48.44608+00	56d79006-412e-4a1a-ab42-da5509b64260	
e6c3e4e7-dc48-49e1-9433-aba27c0f96fc	9b7c3e2f-f95b-4b71-9338-66c83c3ccb8b			2026-04-14 11:03:48.522334+00	56d79006-412e-4a1a-ab42-da5509b64260	
4724e1d5-a37d-4f8c-8f10-66b46978902b	d0f2f840-7ca4-45dd-b94a-22f9b6142b59			2026-04-14 11:03:48.597811+00	56d79006-412e-4a1a-ab42-da5509b64260	
9222cb1b-ee71-4060-ad30-a371dc79ff3e	c09b96d1-e306-402c-b924-68a81d67f0bb			2026-04-14 11:03:48.673505+00	56d79006-412e-4a1a-ab42-da5509b64260	
4d98fc96-b0a4-4f01-be6d-fb21f0e5bf70	8e0d8c11-3475-4112-9812-ad38260253e5			2026-04-14 11:03:48.748756+00	56d79006-412e-4a1a-ab42-da5509b64260	
2cb2ca24-3de6-4933-8130-1bc410e188e9	2b65a8f2-48c5-4c60-84c5-3cfeefcd26c2		111	2026-04-14 11:04:19.981436+00	56d79006-412e-4a1a-ab42-da5509b64260	
febaf8d7-f510-4769-8dcc-f0a3e32c6107	770007d2-a817-4bb5-932d-1e4939a98074		333	2026-04-14 11:04:20.105691+00	56d79006-412e-4a1a-ab42-da5509b64260	
ae21ebb4-9d39-4c93-9815-c5e626a4e4b8	99b38cda-bc3e-4e08-9c4c-c9f6085906fc			2026-04-14 11:04:20.228995+00	56d79006-412e-4a1a-ab42-da5509b64260	
4b9b6e7f-149c-4eb6-9be5-e162f7f0148e	2a12da85-2e0c-4cc9-bde6-1ee749895503			2026-04-14 11:04:20.303549+00	56d79006-412e-4a1a-ab42-da5509b64260	
84ee88cc-7d4b-4400-98b3-c3d68c36ffb8	a3144950-2782-4c2b-a834-b196e52bc0e2			2026-04-14 11:04:20.378433+00	56d79006-412e-4a1a-ab42-da5509b64260	
2b808567-129d-4e11-9c19-a0298afd2ff1	767e3e13-b162-4004-9dd9-e725294f8add			2026-04-14 11:04:20.453937+00	56d79006-412e-4a1a-ab42-da5509b64260	
35ef0568-39e5-4e7f-ba89-59b84215949d	33edec4b-430e-45ac-ae1c-33df782737f8			2026-04-14 11:04:20.528992+00	56d79006-412e-4a1a-ab42-da5509b64260	
4bb1158f-cc2a-4bad-92b5-040363f57ea4	02939f5c-b940-43f0-86b5-e367cf470f5d			2026-04-14 11:04:20.605444+00	56d79006-412e-4a1a-ab42-da5509b64260	
42c7f11c-c69d-439d-98dd-955c0f7547d3	d65b7f6d-e129-419b-8029-e1eeede2fdf8			2026-04-14 11:04:20.681107+00	56d79006-412e-4a1a-ab42-da5509b64260	
3dc76152-942a-4ddf-ae2b-8d237600069a	b6948380-a1bf-4497-9c91-6629ef38bb2b			2026-04-14 11:04:20.756517+00	56d79006-412e-4a1a-ab42-da5509b64260	
6159b497-a819-40a0-93b4-48bd828be446	54b8e3a7-8713-43ec-a9b9-749e5700641c			2026-04-14 11:04:20.831887+00	56d79006-412e-4a1a-ab42-da5509b64260	
18a4ca39-0a4a-4ea9-9090-6271e7ea9f21	2ea2c4ff-93c2-446f-b7cd-8520a26a6de0			2026-04-14 11:04:20.906283+00	56d79006-412e-4a1a-ab42-da5509b64260	
b8c6dc65-1479-4766-841e-62fbdc2426c2	fb3c0bf3-9afc-4863-8d90-f9a5551e6a25			2026-04-14 11:04:20.980883+00	56d79006-412e-4a1a-ab42-da5509b64260	
d14aa65c-e1cd-478f-92ed-6fea3b6d94c9	b7468503-985f-4866-8c13-915ce9cdd0c8			2026-04-14 11:04:21.055652+00	56d79006-412e-4a1a-ab42-da5509b64260	
c496453c-0aa6-429f-988e-d5130b899388	9b7c3e2f-f95b-4b71-9338-66c83c3ccb8b			2026-04-14 11:04:21.13078+00	56d79006-412e-4a1a-ab42-da5509b64260	
662676db-afe9-49f3-b304-23f91e2b4908	d0f2f840-7ca4-45dd-b94a-22f9b6142b59			2026-04-14 11:04:21.205469+00	56d79006-412e-4a1a-ab42-da5509b64260	
03721216-b1b3-42db-a445-909ec7d5ee8a	c09b96d1-e306-402c-b924-68a81d67f0bb			2026-04-14 11:04:21.280777+00	56d79006-412e-4a1a-ab42-da5509b64260	
30ac625a-c80f-4946-a4a9-4fcc0a94f5a2	8e0d8c11-3475-4112-9812-ad38260253e5			2026-04-14 11:04:21.355897+00	56d79006-412e-4a1a-ab42-da5509b64260	
d31e11e4-8af7-4194-9750-16d3032f77e1	759e2643-cb40-4f1f-8150-15446d3ce7ad	\N		2026-04-14 11:06:13.126886+00	56d79006-412e-4a1a-ab42-da5509b64260	
d20d1f44-4373-4d0a-a8fd-e6611414f73b	a3d04889-6f92-4640-b868-b4acd009a70b	\N		2026-04-14 11:06:13.25142+00	56d79006-412e-4a1a-ab42-da5509b64260	
d7080fd0-7eba-452f-b351-e845396a3e4d	8210822a-5907-4b20-a638-cfc27a88e396	\N		2026-04-14 11:06:13.378171+00	56d79006-412e-4a1a-ab42-da5509b64260	
f7719963-8b63-4113-b5f4-9983f98ba0a5	3f9de40e-85f1-4580-b481-e0e090f40a34	\N		2026-04-14 11:06:13.503618+00	56d79006-412e-4a1a-ab42-da5509b64260	
0843a943-e783-4a10-bfce-507310da107b	0eee0970-e218-4273-9e6a-84c09f0574b2	\N		2026-04-14 11:06:13.629984+00	56d79006-412e-4a1a-ab42-da5509b64260	
b03b200e-ec03-40b7-a66b-ad18f3f5faa2	dac8de11-a73d-4ee9-9069-80813b90d7da	\N		2026-04-14 11:06:13.755213+00	56d79006-412e-4a1a-ab42-da5509b64260	
d0388fcf-7ad8-4098-b8ab-6bec7f407642	5d4531bf-262e-41d6-b914-d8b6682c28f1	\N		2026-04-14 11:06:13.879532+00	56d79006-412e-4a1a-ab42-da5509b64260	
179c7576-9719-408d-8cff-3f015cc0e58b	5712a8a6-a365-48f7-9245-1334335e221b	\N		2026-04-14 11:06:14.004392+00	56d79006-412e-4a1a-ab42-da5509b64260	
309d200f-0603-4aab-ba78-313f48f9046b	05e64b4d-79e0-4bab-a305-cde96db384e7	\N		2026-04-14 11:06:14.129114+00	56d79006-412e-4a1a-ab42-da5509b64260	
77a1a418-9e30-42a0-b23f-b29bcbb3e0d0	4fa496cc-bf14-461b-a84b-39866a7baf06	\N		2026-04-14 11:06:14.252975+00	56d79006-412e-4a1a-ab42-da5509b64260	
113f4faf-a603-439c-8faf-0366053f7cb4	b63d8663-05a0-4a40-8ab9-1c41c82e64e6	\N		2026-04-14 11:06:14.376393+00	56d79006-412e-4a1a-ab42-da5509b64260	
23e42cb3-8f35-4b8c-9b83-77ef1fb6f018	d7bb3452-1722-4b8b-9f37-731b10a68988	\N		2026-04-14 11:06:14.499964+00	56d79006-412e-4a1a-ab42-da5509b64260	
6774538a-c9bb-4502-a614-b1c6dc4efa23	09c76d2a-4dcf-4b06-b43a-8d1fecfc29e2	\N		2026-04-14 11:06:14.623549+00	56d79006-412e-4a1a-ab42-da5509b64260	
6b51e5b7-ecb6-4034-8617-540c5cd1dfe5	43e4a9d7-5cee-4209-92c8-174868fdf10f	\N		2026-04-14 11:06:14.746309+00	56d79006-412e-4a1a-ab42-da5509b64260	
5b410d4b-1602-4727-b5b7-e324ebf48494	34529858-f558-4137-96a4-1667602fdd97	\N		2026-04-14 11:06:14.869575+00	56d79006-412e-4a1a-ab42-da5509b64260	
608a78ca-7de5-4335-84f2-a2bf9217bc0e	c9b41fd2-849a-43c0-bebd-1b0611dce08f	\N		2026-04-14 11:06:14.992999+00	56d79006-412e-4a1a-ab42-da5509b64260	
380e5fdf-c2a7-434f-ad2b-2cd2ea6791b1	c60c169b-0d4e-40eb-ac79-36f0fce2b018	\N		2026-04-14 11:06:15.11616+00	56d79006-412e-4a1a-ab42-da5509b64260	
759622a4-036a-4c9d-81e0-0c27cbdcd71e	bfc96d9d-5651-446a-a3ff-a17d1f65215f	\N		2026-04-14 11:06:15.239163+00	56d79006-412e-4a1a-ab42-da5509b64260	
1c4bbe60-549b-4862-8a6f-a913050e5ad1	759e2643-cb40-4f1f-8150-15446d3ce7ad			2026-04-14 11:07:12.747217+00	56d79006-412e-4a1a-ab42-da5509b64260	
e5d1f40d-68b7-4ff2-bbbd-e91891ddbdd2	a3d04889-6f92-4640-b868-b4acd009a70b			2026-04-14 11:07:12.821139+00	56d79006-412e-4a1a-ab42-da5509b64260	
8368e70b-58d7-429a-82e1-f58028d12faa	8210822a-5907-4b20-a638-cfc27a88e396			2026-04-14 11:07:12.894822+00	56d79006-412e-4a1a-ab42-da5509b64260	
d1c00357-c696-4fdb-a708-3ca4be38add2	3f9de40e-85f1-4580-b481-e0e090f40a34			2026-04-14 11:07:12.968917+00	56d79006-412e-4a1a-ab42-da5509b64260	
5b3b8d47-694b-4416-8ebb-8fdeb56e14d4	0eee0970-e218-4273-9e6a-84c09f0574b2			2026-04-14 11:07:13.04324+00	56d79006-412e-4a1a-ab42-da5509b64260	
e1718913-10bd-462c-9456-399e6e4d7a71	dac8de11-a73d-4ee9-9069-80813b90d7da			2026-04-14 11:07:13.117288+00	56d79006-412e-4a1a-ab42-da5509b64260	
05f21f60-c651-4129-a5b3-042788dd4c7f	5d4531bf-262e-41d6-b914-d8b6682c28f1			2026-04-14 11:07:13.190954+00	56d79006-412e-4a1a-ab42-da5509b64260	
193f6c0f-f9da-47d6-989c-3ab67c677f97	5712a8a6-a365-48f7-9245-1334335e221b			2026-04-14 11:07:13.265068+00	56d79006-412e-4a1a-ab42-da5509b64260	
48de88ad-a32a-44c6-aea6-76db216a9df5	05e64b4d-79e0-4bab-a305-cde96db384e7			2026-04-14 11:07:13.339086+00	56d79006-412e-4a1a-ab42-da5509b64260	
440e64ee-794c-40a6-945d-8170073b5a30	4fa496cc-bf14-461b-a84b-39866a7baf06			2026-04-14 11:07:13.413642+00	56d79006-412e-4a1a-ab42-da5509b64260	
f0ab8b5e-cc05-4565-90e8-5da02f255de3	b63d8663-05a0-4a40-8ab9-1c41c82e64e6			2026-04-14 11:07:13.489203+00	56d79006-412e-4a1a-ab42-da5509b64260	
7bab805f-5a2e-4fa8-951f-8fc718755a0f	d7bb3452-1722-4b8b-9f37-731b10a68988			2026-04-14 11:07:13.565243+00	56d79006-412e-4a1a-ab42-da5509b64260	
c9e1e303-a24f-4730-a009-ca6ff3a47c8d	09c76d2a-4dcf-4b06-b43a-8d1fecfc29e2			2026-04-14 11:07:13.640802+00	56d79006-412e-4a1a-ab42-da5509b64260	
c78564a1-6c87-476a-b0b0-8fa9d9a3b5b2	43e4a9d7-5cee-4209-92c8-174868fdf10f			2026-04-14 11:07:13.714968+00	56d79006-412e-4a1a-ab42-da5509b64260	
b2f6e1e8-1110-4ed0-bfd4-18bb150bd139	34529858-f558-4137-96a4-1667602fdd97			2026-04-14 11:07:13.789218+00	56d79006-412e-4a1a-ab42-da5509b64260	
71b43003-2f81-4c0a-beb1-ef0fc99db79d	c9b41fd2-849a-43c0-bebd-1b0611dce08f			2026-04-14 11:07:13.8631+00	56d79006-412e-4a1a-ab42-da5509b64260	
2a5b50c2-e661-4e32-bfb3-9e81b31e9a3e	c60c169b-0d4e-40eb-ac79-36f0fce2b018			2026-04-14 11:07:13.93825+00	56d79006-412e-4a1a-ab42-da5509b64260	
5b552a91-cb3f-4770-affe-5ff9ce73ddc4	bfc96d9d-5651-446a-a3ff-a17d1f65215f			2026-04-14 11:07:14.01335+00	56d79006-412e-4a1a-ab42-da5509b64260	
a60e101f-2888-40c1-8ee3-145b6e557634	759e2643-cb40-4f1f-8150-15446d3ce7ad		123	2026-04-14 11:08:00.50367+00	56d79006-412e-4a1a-ab42-da5509b64260	
7b25f575-9951-433d-9ec3-2135f5222b28	a3d04889-6f92-4640-b868-b4acd009a70b		333	2026-04-14 11:08:00.628027+00	56d79006-412e-4a1a-ab42-da5509b64260	
a29f04c5-0d75-4bd7-8edd-f2361815ab2c	8210822a-5907-4b20-a638-cfc27a88e396			2026-04-14 11:08:00.751586+00	56d79006-412e-4a1a-ab42-da5509b64260	
557428ef-68da-4586-a6e5-8f8466fca5fb	3f9de40e-85f1-4580-b481-e0e090f40a34			2026-04-14 11:08:00.825819+00	56d79006-412e-4a1a-ab42-da5509b64260	
56401c93-17c8-42d5-875c-69e2b49c22af	0eee0970-e218-4273-9e6a-84c09f0574b2			2026-04-14 11:08:00.901393+00	56d79006-412e-4a1a-ab42-da5509b64260	
e307d178-aee0-49ab-b0c6-567e95879eef	dac8de11-a73d-4ee9-9069-80813b90d7da			2026-04-14 11:08:00.977492+00	56d79006-412e-4a1a-ab42-da5509b64260	
8f742c5d-2655-4a18-b0bf-23115688aba4	5d4531bf-262e-41d6-b914-d8b6682c28f1			2026-04-14 11:08:01.052912+00	56d79006-412e-4a1a-ab42-da5509b64260	
b7de5f11-5196-45e2-b5a9-10c23660f75e	5712a8a6-a365-48f7-9245-1334335e221b			2026-04-14 11:08:01.127492+00	56d79006-412e-4a1a-ab42-da5509b64260	
78856f00-26d1-4968-a8d6-d05e62cf0ebd	05e64b4d-79e0-4bab-a305-cde96db384e7			2026-04-14 11:08:01.201908+00	56d79006-412e-4a1a-ab42-da5509b64260	
e1f697a2-5cd5-4352-930f-442aaebecc92	4fa496cc-bf14-461b-a84b-39866a7baf06			2026-04-14 11:08:01.276269+00	56d79006-412e-4a1a-ab42-da5509b64260	
d25270a7-1f1c-4e04-94a8-271c794caa22	b63d8663-05a0-4a40-8ab9-1c41c82e64e6			2026-04-14 11:08:01.350431+00	56d79006-412e-4a1a-ab42-da5509b64260	
5dfadd8b-fd0a-4f0e-8277-993f1c888132	d7bb3452-1722-4b8b-9f37-731b10a68988			2026-04-14 11:08:01.42431+00	56d79006-412e-4a1a-ab42-da5509b64260	
1aaeb320-b51f-4b2a-9479-89da1c7b2d94	09c76d2a-4dcf-4b06-b43a-8d1fecfc29e2			2026-04-14 11:08:01.498158+00	56d79006-412e-4a1a-ab42-da5509b64260	
46eab741-0ff0-412a-a764-e7e3d7c62d10	43e4a9d7-5cee-4209-92c8-174868fdf10f			2026-04-14 11:08:01.572526+00	56d79006-412e-4a1a-ab42-da5509b64260	
f506208d-c27b-48ba-895c-a196ac4f411b	34529858-f558-4137-96a4-1667602fdd97			2026-04-14 11:08:01.646799+00	56d79006-412e-4a1a-ab42-da5509b64260	
2345259a-553a-4378-aa8d-ebc7f8a9de41	c9b41fd2-849a-43c0-bebd-1b0611dce08f			2026-04-14 11:08:01.720938+00	56d79006-412e-4a1a-ab42-da5509b64260	
cf8abe97-4068-485f-8374-a31a69725885	c60c169b-0d4e-40eb-ac79-36f0fce2b018			2026-04-14 11:08:01.795291+00	56d79006-412e-4a1a-ab42-da5509b64260	
48ca99ad-dc64-43c2-9e5c-7d878237586c	bfc96d9d-5651-446a-a3ff-a17d1f65215f			2026-04-14 11:08:01.868831+00	56d79006-412e-4a1a-ab42-da5509b64260	
72eefe8a-0a0e-4068-b77c-5f72f46fa848	2e39df6b-0cba-42ec-9548-463561043190	\N		2026-04-14 11:09:02.087788+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a0288de6-7238-41eb-8450-b2ffb1688f57	bbc93798-faad-44aa-823b-3f264698d6cb	\N		2026-04-14 11:09:02.209826+00	1025389a-0e27-4e08-b6a0-b188660bea57	
970ee10a-592e-472b-bc17-dd5c47539aba	8e020700-b48a-4625-bb92-86bcb9011505	\N		2026-04-14 11:09:02.33336+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0e85b572-6a7f-4424-ac4f-8494a0452638	aba4c830-724d-487f-a223-0fd3c0d867db	\N		2026-04-14 11:09:02.45763+00	1025389a-0e27-4e08-b6a0-b188660bea57	
90fd3b38-a664-42e0-b155-c7c45ac1e278	037c9bbd-cbd3-4693-98df-b4db5fcd9934	\N		2026-04-14 11:09:02.582632+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0cea8892-9b94-4a3a-a982-01c770c4753e	86bc3c61-94e3-45e4-ae73-ecbaf8ba096e	\N		2026-04-14 11:09:02.706412+00	1025389a-0e27-4e08-b6a0-b188660bea57	
192eebdd-ec36-4619-8289-38e960c3b49f	79eaf9ba-e9f1-47f0-bdf4-b9c15708ec93	\N		2026-04-14 11:09:02.830137+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2d3f0969-b579-4d2d-82a4-3950e36b8d99	c613b680-7ead-4686-af35-13f898070f47	\N		2026-04-14 11:09:02.954027+00	1025389a-0e27-4e08-b6a0-b188660bea57	
dbfbc3e3-b13f-4067-bc3b-272556b4e0ae	f02793e8-cdb4-40b2-8a24-c3e50c7fb038	\N		2026-04-14 11:09:03.077158+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4aaad907-d28d-41ee-8304-bed7eb290878	f83f8932-6bad-4c28-a9b0-bf2305d5c898	\N		2026-04-14 11:09:03.200173+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0eaca25d-95a4-4a27-878f-87e9e51fe6c0	e196da2b-5d17-439c-9980-1f5161f38b81	\N		2026-04-14 11:09:03.324777+00	1025389a-0e27-4e08-b6a0-b188660bea57	
69bb8adb-fb95-40b3-b6d8-3952a8a96bfc	d5b0ff01-a4c6-4d08-af17-dec812f6b650	\N		2026-04-14 11:09:03.44859+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5b67a82e-c479-4027-bf26-33721dd1ba47	15dc55ed-ee62-4732-ba3e-9749b054afb9	\N		2026-04-14 11:09:03.572706+00	1025389a-0e27-4e08-b6a0-b188660bea57	
74e4fd4b-d91e-4f85-bedc-c96567c3b29d	e4e7406f-01b3-4ca8-bbbc-5a8d3929adfb	\N		2026-04-14 11:09:03.6962+00	1025389a-0e27-4e08-b6a0-b188660bea57	
04e2847e-3e48-408b-a0ca-cf0b5cd9e603	7e9f745b-0820-4211-b400-bdac30237da6	\N		2026-04-14 11:09:03.818396+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d96d16c3-2d21-434a-8c27-d0f9f2a5529e	6009ae9e-2cee-40b7-aa47-bd5b25078e3b	\N		2026-04-14 11:09:03.943104+00	1025389a-0e27-4e08-b6a0-b188660bea57	
992e801f-510a-4028-8393-11e40dcc463a	56d8b218-382e-4435-a99c-5cfcc90927a5	\N		2026-04-14 11:09:04.068206+00	1025389a-0e27-4e08-b6a0-b188660bea57	
48f05d60-1088-4f97-bd34-e0bd3faee32b	c39ea8db-c7f7-49c7-9fc3-99911ea73587	\N		2026-04-14 11:09:04.194054+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0827f52d-251c-41e8-85b8-b535097d7fb4	2e39df6b-0cba-42ec-9548-463561043190		1233	2026-04-14 11:09:13.029522+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b4b7806b-2305-44b9-a966-35e24fa2cd27	bbc93798-faad-44aa-823b-3f264698d6cb		333	2026-04-14 11:09:13.153092+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0848443d-0584-4071-99ee-cb8bdea8b030	8e020700-b48a-4625-bb92-86bcb9011505			2026-04-14 11:09:13.275872+00	1025389a-0e27-4e08-b6a0-b188660bea57	
469a95fd-2a55-4ebb-833e-3f6213851343	aba4c830-724d-487f-a223-0fd3c0d867db			2026-04-14 11:09:13.349724+00	1025389a-0e27-4e08-b6a0-b188660bea57	
de34e7d9-372b-483a-bf1b-7ae4537d7094	037c9bbd-cbd3-4693-98df-b4db5fcd9934			2026-04-14 11:09:13.423075+00	1025389a-0e27-4e08-b6a0-b188660bea57	
93153934-44af-4dae-8e62-c464b8658d31	86bc3c61-94e3-45e4-ae73-ecbaf8ba096e			2026-04-14 11:09:13.497602+00	1025389a-0e27-4e08-b6a0-b188660bea57	
770f2155-d150-48a0-b71c-486b4afd21d3	79eaf9ba-e9f1-47f0-bdf4-b9c15708ec93			2026-04-14 11:09:13.57201+00	1025389a-0e27-4e08-b6a0-b188660bea57	
1e55e932-592a-41a0-a4a2-fc9a0a0b6e95	c613b680-7ead-4686-af35-13f898070f47			2026-04-14 11:09:13.645947+00	1025389a-0e27-4e08-b6a0-b188660bea57	
da54dd10-43f0-474a-a6bb-174db0ec3d64	f02793e8-cdb4-40b2-8a24-c3e50c7fb038			2026-04-14 11:09:13.720116+00	1025389a-0e27-4e08-b6a0-b188660bea57	
85a43af5-fca3-455e-8eb2-d17cfb2de0cd	f83f8932-6bad-4c28-a9b0-bf2305d5c898			2026-04-14 11:09:13.794589+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4ea32d75-64f2-4402-befd-9f4dd0f142cf	e196da2b-5d17-439c-9980-1f5161f38b81			2026-04-14 11:09:13.868669+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0f725f45-7668-4a2b-a2bd-b35c5f39295b	d5b0ff01-a4c6-4d08-af17-dec812f6b650			2026-04-14 11:09:13.94373+00	1025389a-0e27-4e08-b6a0-b188660bea57	
1bc533f5-6af5-4b2d-9093-b2f6fd3cf067	15dc55ed-ee62-4732-ba3e-9749b054afb9			2026-04-14 11:09:14.018219+00	1025389a-0e27-4e08-b6a0-b188660bea57	
253f78cc-bdf8-418a-b421-333035b2f950	e4e7406f-01b3-4ca8-bbbc-5a8d3929adfb			2026-04-14 11:09:14.093218+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6dd74fde-9b81-499d-993d-5844c8e9ee93	7e9f745b-0820-4211-b400-bdac30237da6			2026-04-14 11:09:14.168639+00	1025389a-0e27-4e08-b6a0-b188660bea57	
59b80aca-918d-442e-aaf1-ba396066e6f7	6009ae9e-2cee-40b7-aa47-bd5b25078e3b			2026-04-14 11:09:14.243504+00	1025389a-0e27-4e08-b6a0-b188660bea57	
842d0a65-eb8b-4d38-b969-8a1a221091c8	56d8b218-382e-4435-a99c-5cfcc90927a5			2026-04-14 11:09:14.317787+00	1025389a-0e27-4e08-b6a0-b188660bea57	
be9aca6e-7ff6-4910-88de-b3e32a23b3f1	c39ea8db-c7f7-49c7-9fc3-99911ea73587			2026-04-14 11:09:14.391943+00	1025389a-0e27-4e08-b6a0-b188660bea57	
048419b1-2e10-4591-9264-4aa04a7139d1	14004acb-7e3f-4a09-9116-4da0ba31e18c	\N		2026-04-14 11:12:13.150728+00	1025389a-0e27-4e08-b6a0-b188660bea57	
36c41f4b-f254-48af-a2d3-594447fa9470	b2bfed10-12dc-454d-a83b-67332f41576d	\N		2026-04-14 11:12:13.273448+00	1025389a-0e27-4e08-b6a0-b188660bea57	
be72fb66-828c-49ef-a479-4cb88851ef1c	50c7b16e-601b-423c-8c06-b6fbc8c16b01	\N		2026-04-14 11:12:13.397215+00	1025389a-0e27-4e08-b6a0-b188660bea57	
264640dc-f65d-4408-bf88-2dc8f0521403	0daebd61-67b5-4021-9285-72058edf9c4e	\N		2026-04-14 11:12:13.522508+00	1025389a-0e27-4e08-b6a0-b188660bea57	
40f73c92-5f01-4d60-83f6-f7aa33fbf0c5	7a4223ad-a980-4c32-8efd-9eb384161033	\N		2026-04-14 11:12:13.646364+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3b0b8d0c-9565-41ae-8c6e-a44e17fda259	b458d2bd-e2ab-451e-9768-d3336122df44	\N		2026-04-14 11:12:13.771142+00	1025389a-0e27-4e08-b6a0-b188660bea57	
57c8346e-d45b-4f77-ad75-a89af1183918	655ecb0c-4edf-4063-a1dd-cbaacf0bed20	\N		2026-04-14 11:12:13.894313+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d2e7a951-4760-468c-ab8c-74aaa586fa88	699cdefe-d5d1-4cbf-88a4-a025ab5c8a12	\N		2026-04-14 11:12:14.016567+00	1025389a-0e27-4e08-b6a0-b188660bea57	
c7d99506-8fcf-4b12-97e2-4bd44ea11546	dff74af2-0e90-4ddd-954f-21e629271433	\N		2026-04-14 11:12:14.139134+00	1025389a-0e27-4e08-b6a0-b188660bea57	
763ff3db-c02c-4b89-aee2-b582bc73293a	c973841b-b814-4e23-a0d2-04b8fba329f2	\N		2026-04-14 11:12:14.261443+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0057737f-b2fd-495d-96b2-08aa70a6c47f	fc000939-97b7-4d05-85a2-ffdff5756f4a	\N		2026-04-14 11:12:14.384027+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2fc2b27d-6b87-40ca-bedd-5c71d0d2caf5	1a1bccd6-adfb-4569-b72f-a470556b049c	\N		2026-04-14 11:12:14.506475+00	1025389a-0e27-4e08-b6a0-b188660bea57	
bd231cc9-174a-43c2-913c-30f08ea63137	ffc84081-c35e-4b42-af96-cce916cd3d41	\N		2026-04-14 11:12:14.628582+00	1025389a-0e27-4e08-b6a0-b188660bea57	
85395fae-c95a-4c15-bc18-426c51032ad2	5574c2a7-b736-4ecd-b10f-9c0dcc7c278f	\N		2026-04-14 11:12:14.750707+00	1025389a-0e27-4e08-b6a0-b188660bea57	
c5eac9e0-c8fb-40bc-a486-64b9b12fb3dc	a6e65e18-c890-42a8-a443-e991794bb922	\N		2026-04-14 11:12:14.873834+00	1025389a-0e27-4e08-b6a0-b188660bea57	
99b6102d-6919-4704-8040-0bf40a99ab0b	582fd56e-5f16-4968-8cd8-0921f109cd7b	\N		2026-04-14 11:12:14.995701+00	1025389a-0e27-4e08-b6a0-b188660bea57	
455472ff-dfd7-4222-abd9-74bff96de214	500ec338-12b3-4e64-b059-f9cac86ea82c	\N		2026-04-14 11:12:15.120072+00	1025389a-0e27-4e08-b6a0-b188660bea57	
db664b47-151e-47d9-bc2b-c89b771b0173	389e4cae-aaae-4f0c-bc8b-7ccd73322bd9	\N		2026-04-14 11:12:15.245276+00	1025389a-0e27-4e08-b6a0-b188660bea57	
01e7fc5a-a2c2-44af-917f-c9140d0ebe10	14004acb-7e3f-4a09-9116-4da0ba31e18c		12333	2026-04-14 11:12:22.299585+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3cd2245d-76e3-43ed-88d4-f47e0d07e2ca	b2bfed10-12dc-454d-a83b-67332f41576d		3333	2026-04-14 11:12:22.422735+00	1025389a-0e27-4e08-b6a0-b188660bea57	
27693bbe-1987-4a21-9b2f-4f5dd55a554f	50c7b16e-601b-423c-8c06-b6fbc8c16b01			2026-04-14 11:12:22.545275+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3dea7aec-7d59-4d87-af5f-f6b5ee031fc8	0daebd61-67b5-4021-9285-72058edf9c4e			2026-04-14 11:12:22.619031+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2f62582d-3f32-4596-b8c8-d0f25cf86770	7a4223ad-a980-4c32-8efd-9eb384161033			2026-04-14 11:12:22.692235+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3d5a6c51-62ed-40a7-ab9c-088d6b4fa32d	b458d2bd-e2ab-451e-9768-d3336122df44			2026-04-14 11:12:22.76629+00	1025389a-0e27-4e08-b6a0-b188660bea57	
278dbf47-4450-4543-b4a4-8db78099376a	655ecb0c-4edf-4063-a1dd-cbaacf0bed20			2026-04-14 11:12:22.840919+00	1025389a-0e27-4e08-b6a0-b188660bea57	
7022b849-a69d-4565-9f40-08a7339b4dce	699cdefe-d5d1-4cbf-88a4-a025ab5c8a12			2026-04-14 11:12:22.915074+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d89419c1-76ba-479e-8f98-8542c2e8f16a	dff74af2-0e90-4ddd-954f-21e629271433			2026-04-14 11:12:22.989146+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6c9e8d9f-38f2-4a1a-b341-a030d0a01204	c973841b-b814-4e23-a0d2-04b8fba329f2			2026-04-14 11:12:23.063374+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b8f8593e-6198-45a9-8a57-89c170b273ef	fc000939-97b7-4d05-85a2-ffdff5756f4a			2026-04-14 11:12:23.137192+00	1025389a-0e27-4e08-b6a0-b188660bea57	
72aa04de-0e85-496b-aad7-f81320b689d2	1a1bccd6-adfb-4569-b72f-a470556b049c			2026-04-14 11:12:23.21063+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3ca7b657-93fd-47b5-ac26-588bf4f518fc	ffc84081-c35e-4b42-af96-cce916cd3d41			2026-04-14 11:12:23.285192+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6dcbc672-2b5b-4dab-83c2-aab209b2cebe	5574c2a7-b736-4ecd-b10f-9c0dcc7c278f			2026-04-14 11:12:23.359599+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ba8a8efd-0ee3-4cc8-b0cb-95bf180c1d93	a6e65e18-c890-42a8-a443-e991794bb922			2026-04-14 11:12:23.43365+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b84ac24c-b8de-48e9-8b16-fef9cac5935f	582fd56e-5f16-4968-8cd8-0921f109cd7b			2026-04-14 11:12:23.50774+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5b07fbfe-8e54-44f6-b709-3acfad669653	500ec338-12b3-4e64-b059-f9cac86ea82c			2026-04-14 11:12:23.581433+00	1025389a-0e27-4e08-b6a0-b188660bea57	
01dc4f4d-d4f4-45db-80a3-89584582e6bc	389e4cae-aaae-4f0c-bc8b-7ccd73322bd9			2026-04-14 11:12:23.655245+00	1025389a-0e27-4e08-b6a0-b188660bea57	
c14153c1-4715-4fe7-a0dd-42916f64452d	d23ae784-7166-4213-8b0c-2d37341c0ec5	\N		2026-04-14 11:12:49.05428+00	1025389a-0e27-4e08-b6a0-b188660bea57	
17c037b3-62cc-4f5b-ae10-22645344d3bd	4fe3b379-6e59-43e9-b294-6ebbe143a911	\N		2026-04-14 11:12:49.175441+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e8bb35ed-408f-499c-af3c-9d682286e595	6dfb33dc-0fbe-4ab2-9a31-35b4436c703c	\N		2026-04-14 11:12:49.297541+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e4942478-4df3-4611-94d9-06207e5c067c	5b66d7ef-5a0e-4397-96cb-8b1c0ef39dd1	\N		2026-04-14 11:12:49.418007+00	1025389a-0e27-4e08-b6a0-b188660bea57	
67b2845c-3035-4d45-934a-f3b3f2d6d36b	40a2c5ca-1bfd-4050-92eb-2c26d47244d2	\N		2026-04-14 11:12:49.539667+00	1025389a-0e27-4e08-b6a0-b188660bea57	
1dcf6bf2-0e6d-4c28-ac7c-227137cbba39	8cf46715-a9dc-4c15-b622-8a1bc772220d	\N		2026-04-14 11:12:49.662587+00	1025389a-0e27-4e08-b6a0-b188660bea57	
558b3a04-79ad-43da-8b14-799b14f5999f	4bc234b5-a27a-450c-80d5-8b7cfda61eb2	\N		2026-04-14 11:12:49.785454+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f11dda51-2fa9-4a80-b0d9-74f73ddc6928	e4d92cd0-8881-49fe-84d6-fadabf26e5e7	\N		2026-04-14 11:12:49.90741+00	1025389a-0e27-4e08-b6a0-b188660bea57	
acb2429f-1769-4e02-a74a-330949b19519	02f825a2-12a7-4334-b949-329f34914b32	\N		2026-04-14 11:12:50.029794+00	1025389a-0e27-4e08-b6a0-b188660bea57	
cb07c2ad-ae85-4c47-b638-d94235a9faca	a4d783fe-f9c0-423e-b35c-a8d493d48037	\N		2026-04-14 11:12:50.152295+00	1025389a-0e27-4e08-b6a0-b188660bea57	
29d77af6-0a6a-407b-9608-61bf64b7a08c	f38bfe36-86d3-4afd-a870-f545977f53af	\N		2026-04-14 11:12:50.274369+00	1025389a-0e27-4e08-b6a0-b188660bea57	
8b7325bb-043f-4d00-8434-5ca3d360830b	07f3cf1e-b6e4-443e-adcd-23426d7124a7	\N		2026-04-14 11:12:50.397198+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6d4bc940-3536-46a1-b7dc-f176e07e84e5	2672fbe8-f295-4d8f-bcfe-85acabc485cc	\N		2026-04-14 11:12:50.519793+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3ee476b4-f4d9-44fe-b548-146d90b46ebc	2be174f0-5921-4da8-966b-c449a1902906	\N		2026-04-14 11:12:50.642213+00	1025389a-0e27-4e08-b6a0-b188660bea57	
48467fc2-1ec1-4ec4-9e4e-20b375cc8d2e	1db44d04-9d40-4997-8a74-bc4be1fcc87b	\N		2026-04-14 11:12:50.765321+00	1025389a-0e27-4e08-b6a0-b188660bea57	
7e559c51-6ec3-481d-bbfb-ef87852a2570	8544bc09-d192-4bc7-af24-513ce20ed1a0	\N		2026-04-14 11:12:50.888899+00	1025389a-0e27-4e08-b6a0-b188660bea57	
396c2932-3d92-4d80-86d0-4c8cd29c5f04	042c98ed-bfc3-4509-9fb8-39197326f98f	\N		2026-04-14 11:12:51.012276+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6d7f50af-0561-40d9-b64d-e54f6356e239	767d2fd0-fea5-40cc-802d-1d2db712876d	\N		2026-04-14 11:12:51.134805+00	1025389a-0e27-4e08-b6a0-b188660bea57	
cb3e3e18-7976-43a1-9fc0-10f2e056a5e1	d23ae784-7166-4213-8b0c-2d37341c0ec5			2026-04-14 11:15:17.596344+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3ba17421-6905-45b4-916b-4d325a70e538	4fe3b379-6e59-43e9-b294-6ebbe143a911			2026-04-14 11:15:17.670698+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ba1c98b4-bf55-4ffe-9a89-ed32876cfb42	6dfb33dc-0fbe-4ab2-9a31-35b4436c703c			2026-04-14 11:15:17.744538+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6e9eb2d3-9406-442a-9c6d-d0e94008060b	5b66d7ef-5a0e-4397-96cb-8b1c0ef39dd1			2026-04-14 11:15:17.819477+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ed42d803-5fd2-4ecb-90cc-298eaec02e37	40a2c5ca-1bfd-4050-92eb-2c26d47244d2			2026-04-14 11:15:17.893634+00	1025389a-0e27-4e08-b6a0-b188660bea57	
927c3ad0-8e0a-4bab-9e3c-1b95c7ad0a73	8cf46715-a9dc-4c15-b622-8a1bc772220d			2026-04-14 11:15:17.967821+00	1025389a-0e27-4e08-b6a0-b188660bea57	
9d49d249-4933-4e4e-9f7e-0c39425c1673	4bc234b5-a27a-450c-80d5-8b7cfda61eb2			2026-04-14 11:15:18.041465+00	1025389a-0e27-4e08-b6a0-b188660bea57	
bb203bfc-395b-4b39-9bd0-7f3802fa207c	e4d92cd0-8881-49fe-84d6-fadabf26e5e7			2026-04-14 11:15:18.11509+00	1025389a-0e27-4e08-b6a0-b188660bea57	
861e35d3-cf2c-47df-9aa4-da923281d8b3	02f825a2-12a7-4334-b949-329f34914b32			2026-04-14 11:15:18.188699+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f7b04c35-40bd-4f5e-b86f-c6c3ac8ca847	a4d783fe-f9c0-423e-b35c-a8d493d48037			2026-04-14 11:15:18.262478+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a163798c-9533-417c-b0c6-aeabb8df0ed8	f38bfe36-86d3-4afd-a870-f545977f53af			2026-04-14 11:15:18.336711+00	1025389a-0e27-4e08-b6a0-b188660bea57	
7481b2a4-c939-4c3c-97d8-883258045f2f	07f3cf1e-b6e4-443e-adcd-23426d7124a7			2026-04-14 11:15:18.411594+00	1025389a-0e27-4e08-b6a0-b188660bea57	
16b56ea4-c2fd-4efc-bda4-29f30b112aca	2672fbe8-f295-4d8f-bcfe-85acabc485cc			2026-04-14 11:15:18.487296+00	1025389a-0e27-4e08-b6a0-b188660bea57	
89962ab6-b270-453c-bd93-12d404b60d94	2be174f0-5921-4da8-966b-c449a1902906			2026-04-14 11:15:18.561642+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e904652d-7b4e-4563-8ffd-df5f39247cd9	1db44d04-9d40-4997-8a74-bc4be1fcc87b			2026-04-14 11:15:18.635891+00	1025389a-0e27-4e08-b6a0-b188660bea57	
7e111a2c-8399-4597-a97f-939637eac0fd	8544bc09-d192-4bc7-af24-513ce20ed1a0			2026-04-14 11:15:18.710093+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4e7597ae-4145-486a-b754-75eccb89c298	042c98ed-bfc3-4509-9fb8-39197326f98f			2026-04-14 11:15:18.783811+00	1025389a-0e27-4e08-b6a0-b188660bea57	
64536547-dd90-43ae-9c7d-25640b85af8e	767d2fd0-fea5-40cc-802d-1d2db712876d			2026-04-14 11:15:18.857405+00	1025389a-0e27-4e08-b6a0-b188660bea57	
811c60ed-a875-4bcb-8c9f-b9403a666de8	d23ae784-7166-4213-8b0c-2d37341c0ec5			2026-04-14 11:15:23.604863+00	1025389a-0e27-4e08-b6a0-b188660bea57	
37d9da18-ecb6-4aca-a94f-300eee77e4db	4fe3b379-6e59-43e9-b294-6ebbe143a911			2026-04-14 11:15:23.678062+00	1025389a-0e27-4e08-b6a0-b188660bea57	
773d4413-f6ac-49bb-a6b0-d3ea019c4f61	6dfb33dc-0fbe-4ab2-9a31-35b4436c703c			2026-04-14 11:15:23.751615+00	1025389a-0e27-4e08-b6a0-b188660bea57	
bf932d5a-9e7d-4c13-814f-7719e34d0df2	5b66d7ef-5a0e-4397-96cb-8b1c0ef39dd1			2026-04-14 11:15:23.825776+00	1025389a-0e27-4e08-b6a0-b188660bea57	
94ea3ab9-d076-40de-be2f-3bdb34b6a62c	40a2c5ca-1bfd-4050-92eb-2c26d47244d2			2026-04-14 11:15:23.89986+00	1025389a-0e27-4e08-b6a0-b188660bea57	
31f8981b-bcb7-4292-8445-cbe81feaf555	8cf46715-a9dc-4c15-b622-8a1bc772220d			2026-04-14 11:15:23.974983+00	1025389a-0e27-4e08-b6a0-b188660bea57	
faad19b5-6476-47ff-bdd6-09a7141e2cb2	4bc234b5-a27a-450c-80d5-8b7cfda61eb2			2026-04-14 11:15:24.049217+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5764064b-b08b-47b8-9c02-06276cef35a2	e4d92cd0-8881-49fe-84d6-fadabf26e5e7			2026-04-14 11:15:24.123793+00	1025389a-0e27-4e08-b6a0-b188660bea57	
958a9f05-c079-4206-8962-054dff1e138a	02f825a2-12a7-4334-b949-329f34914b32			2026-04-14 11:15:24.197453+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0b76f53e-e15a-45cb-aa48-f7821585c59f	a4d783fe-f9c0-423e-b35c-a8d493d48037			2026-04-14 11:15:24.272259+00	1025389a-0e27-4e08-b6a0-b188660bea57	
27e315aa-d3cb-4b9f-9364-875d493d67bb	f38bfe36-86d3-4afd-a870-f545977f53af			2026-04-14 11:15:24.34505+00	1025389a-0e27-4e08-b6a0-b188660bea57	
df3b0f21-e657-4353-80e6-eb58345433c4	07f3cf1e-b6e4-443e-adcd-23426d7124a7			2026-04-14 11:15:24.419259+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d2e2a1ef-1aac-4d02-9178-166a98087779	2672fbe8-f295-4d8f-bcfe-85acabc485cc			2026-04-14 11:15:24.49324+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d3230732-713c-4eac-889f-e94d37283486	2be174f0-5921-4da8-966b-c449a1902906			2026-04-14 11:15:24.567393+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a0168a5f-9fe0-4480-ae29-86a5dcc27f4e	1db44d04-9d40-4997-8a74-bc4be1fcc87b			2026-04-14 11:15:24.640629+00	1025389a-0e27-4e08-b6a0-b188660bea57	
805db9fa-a59c-40f9-a0c5-cb71e7bed5d4	8544bc09-d192-4bc7-af24-513ce20ed1a0			2026-04-14 11:15:24.714318+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0ccff7a7-48a7-4a09-ac3f-28e259e91177	042c98ed-bfc3-4509-9fb8-39197326f98f			2026-04-14 11:15:24.787759+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a06fe8f0-44c8-4c1b-ac75-61ac62ac743c	767d2fd0-fea5-40cc-802d-1d2db712876d			2026-04-14 11:15:24.86177+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6badaad8-6f22-4ab8-a912-d9d9936f6883	d23ae784-7166-4213-8b0c-2d37341c0ec5		11	2026-04-14 11:15:31.077198+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d518b06f-715d-4e0a-bccc-b6db112a33c1	4fe3b379-6e59-43e9-b294-6ebbe143a911		11	2026-04-14 11:15:31.199328+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ef11b7a5-2334-44ec-8b12-5169d750ff66	6dfb33dc-0fbe-4ab2-9a31-35b4436c703c			2026-04-14 11:15:31.322616+00	1025389a-0e27-4e08-b6a0-b188660bea57	
879b0660-c2ee-40f1-964f-ef78ef19b044	5b66d7ef-5a0e-4397-96cb-8b1c0ef39dd1			2026-04-14 11:15:31.397314+00	1025389a-0e27-4e08-b6a0-b188660bea57	
39f69612-1687-4fc8-b160-0bac46fd96a0	40a2c5ca-1bfd-4050-92eb-2c26d47244d2			2026-04-14 11:15:31.472074+00	1025389a-0e27-4e08-b6a0-b188660bea57	
12e5499f-f333-4295-897a-2e6f9b68ecf7	8cf46715-a9dc-4c15-b622-8a1bc772220d			2026-04-14 11:15:31.545549+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d8632849-2bd0-4c57-a975-b369c7470591	4bc234b5-a27a-450c-80d5-8b7cfda61eb2			2026-04-14 11:15:31.621745+00	1025389a-0e27-4e08-b6a0-b188660bea57	
11efeab4-81a1-4e9a-8c8d-a4d91c8098df	e4d92cd0-8881-49fe-84d6-fadabf26e5e7			2026-04-14 11:15:31.696111+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3b9f05c1-c13d-4b52-bcc5-609930854bb3	02f825a2-12a7-4334-b949-329f34914b32			2026-04-14 11:15:31.769749+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2b4610e6-8955-4573-8540-559ed1b16290	a4d783fe-f9c0-423e-b35c-a8d493d48037			2026-04-14 11:15:31.844322+00	1025389a-0e27-4e08-b6a0-b188660bea57	
9fd9911c-b37e-4e7a-8bff-0387a6f5ca01	f38bfe36-86d3-4afd-a870-f545977f53af			2026-04-14 11:15:31.918864+00	1025389a-0e27-4e08-b6a0-b188660bea57	
deeae28b-1c3a-4bc9-a364-ad1dd4e9b68a	07f3cf1e-b6e4-443e-adcd-23426d7124a7			2026-04-14 11:15:31.99273+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6db107ab-565c-4868-8fbe-ff4108e2e7ba	2672fbe8-f295-4d8f-bcfe-85acabc485cc			2026-04-14 11:15:32.066525+00	1025389a-0e27-4e08-b6a0-b188660bea57	
13862488-92bd-487f-8fe8-1e6befb78b67	2be174f0-5921-4da8-966b-c449a1902906			2026-04-14 11:15:32.140268+00	1025389a-0e27-4e08-b6a0-b188660bea57	
9aedca87-ca90-4bb4-8e8f-5b7e228d0a1b	1db44d04-9d40-4997-8a74-bc4be1fcc87b			2026-04-14 11:15:32.214139+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5ead4718-ee70-4ffa-b62c-e0cfc76a9dd3	8544bc09-d192-4bc7-af24-513ce20ed1a0			2026-04-14 11:15:32.289029+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5216cf4a-83f2-4662-a30e-1620992054ed	042c98ed-bfc3-4509-9fb8-39197326f98f			2026-04-14 11:15:32.362339+00	1025389a-0e27-4e08-b6a0-b188660bea57	
8e71395a-4202-4b21-9805-18f51aa23bf9	767d2fd0-fea5-40cc-802d-1d2db712876d			2026-04-14 11:15:32.435594+00	1025389a-0e27-4e08-b6a0-b188660bea57	
baafd08a-f17d-460e-a322-f2039ae9dc19	09503943-243e-4484-b88f-00cca66946a2	\N	444	2026-04-14 11:20:28.745664+00	56d79006-412e-4a1a-ab42-da5509b64260	
bea29999-eb70-4061-b92e-8ac704f866b3	f40c3a72-63d9-4629-b350-3347295924c4	\N	444	2026-04-14 11:20:28.867811+00	56d79006-412e-4a1a-ab42-da5509b64260	
cd8720d7-43ce-429c-b83b-ef5d1bce6d0f	f45d561e-4dfc-4cbe-ac80-d7e95a24519c	\N		2026-04-14 11:20:28.991321+00	56d79006-412e-4a1a-ab42-da5509b64260	
b6209149-dfea-4a53-88f7-a8af3b0ef7aa	ff69f0fd-8a19-4470-a024-92e8ac8ae9dc	\N		2026-04-14 11:20:29.114606+00	56d79006-412e-4a1a-ab42-da5509b64260	
e9a236a1-d0eb-4389-ae73-dd0de2703fcd	f6c1d660-535d-488a-a8ea-307754f706cc	\N		2026-04-14 11:20:29.236848+00	56d79006-412e-4a1a-ab42-da5509b64260	
469d439a-b2b7-4eaa-a020-e39d98dbea1a	4a158661-211f-4f49-85a2-96d8bb06afd7	\N		2026-04-14 11:20:29.359324+00	56d79006-412e-4a1a-ab42-da5509b64260	
a2589886-d28e-493c-97dd-56519a886ccc	ae0357aa-56c7-4237-a392-9b225ae406b0	\N		2026-04-14 11:20:29.481371+00	56d79006-412e-4a1a-ab42-da5509b64260	
d86c956f-8dfd-4a99-ba39-de4a23b1d837	abe1a8a1-a5c6-4818-ab14-06fa714b4e35	\N		2026-04-14 11:20:29.604974+00	56d79006-412e-4a1a-ab42-da5509b64260	
7465f49c-511d-4e38-8a7f-64f8a8ff1fd8	4f2ca4e7-29b0-4aaf-b6ed-03a3f08c2794	\N		2026-04-14 11:20:29.727354+00	56d79006-412e-4a1a-ab42-da5509b64260	
493aa99e-89c5-4b60-b8dc-e1e3c43962a0	68852fcb-ea5b-4bab-9fd0-9303474c1185	\N		2026-04-14 11:20:29.849369+00	56d79006-412e-4a1a-ab42-da5509b64260	
718c148f-8bd1-4a16-9f6e-4414dbb78f9a	a4a36749-19d0-41f4-a146-9c98875d6240	\N		2026-04-14 11:20:29.971057+00	56d79006-412e-4a1a-ab42-da5509b64260	
62eb5ae0-5613-4bff-8389-134de3e5aafd	ace44409-f055-4016-994a-6c40e91f6bef	\N		2026-04-14 11:20:30.093556+00	56d79006-412e-4a1a-ab42-da5509b64260	
35be9991-35da-4795-bab4-7003fb5ab782	4854aa67-1e9a-40e4-ad06-01bfb5269847	\N		2026-04-14 11:20:30.215304+00	56d79006-412e-4a1a-ab42-da5509b64260	
07ef0255-e572-4114-bc07-090cf77932be	95eee469-dbe4-4789-8d60-ab302ccb7901	\N		2026-04-14 11:20:30.337245+00	56d79006-412e-4a1a-ab42-da5509b64260	
6484efb5-0493-45cd-916b-d111e53eaab8	135a6aa8-26e3-43c5-9936-a8edaae366d0	\N		2026-04-14 11:20:30.458983+00	56d79006-412e-4a1a-ab42-da5509b64260	
6abd2c31-a3d2-4c0c-9035-ce9ff22d6240	14151898-3be1-45ff-9abc-269289880c9f	\N		2026-04-14 11:20:30.581232+00	56d79006-412e-4a1a-ab42-da5509b64260	
29bc53a2-1e69-488a-abf8-e024127f276e	c4b8d882-2ce4-4d2a-8138-cd67bcf70d96	\N		2026-04-14 11:20:30.702546+00	56d79006-412e-4a1a-ab42-da5509b64260	
eb4030ec-3aea-4b58-9363-80860852c78e	d304839d-b25e-4787-85b7-e98c45d2d334	\N		2026-04-14 11:20:30.823957+00	56d79006-412e-4a1a-ab42-da5509b64260	
3746e403-f5c9-4910-923a-5cd59e878b6d	a0fe7179-50d9-4dca-8302-e9cb36723bab	\N	123	2026-04-14 20:50:25.013164+00	56d79006-412e-4a1a-ab42-da5509b64260	
493a87c7-4711-47ab-9fdc-54d9d4c1ded3	ac26b134-36a8-497e-9d7c-ca99392a86fe	\N	123	2026-04-14 20:50:25.41016+00	56d79006-412e-4a1a-ab42-da5509b64260	
cec065ad-018b-44f8-bcc0-37c2eab0e0fd	1f0d1cad-867c-46b3-b6be-efff5bd2241a	\N		2026-04-14 20:50:25.850907+00	56d79006-412e-4a1a-ab42-da5509b64260	
53b90d68-4d75-4e1d-99f0-d401f7202f44	3c92b8e2-f1aa-4e7c-b91d-245b5f553211	\N		2026-04-14 20:50:26.246759+00	56d79006-412e-4a1a-ab42-da5509b64260	
4390e76c-4b05-4805-9ca3-586f78c8eb46	4d4276d3-b60d-498e-ad81-e7bc6394b85f	\N		2026-04-14 20:50:26.643066+00	56d79006-412e-4a1a-ab42-da5509b64260	
cbdc3680-12a7-4ffc-a4cd-3edc0ff496f7	fd59b6d7-5b1e-46bb-923b-71fb598db372	\N		2026-04-14 20:50:27.039248+00	56d79006-412e-4a1a-ab42-da5509b64260	
a4b0918f-a105-44b7-9ca6-748edba2ec06	4c0a0346-93b6-49e7-8a8a-8b5b1f0aec9c	\N		2026-04-14 20:50:27.434475+00	56d79006-412e-4a1a-ab42-da5509b64260	
f7cd1d46-6c69-4576-b84b-32f844d64614	951d9f83-b8d0-4cba-80bf-97255a4edd25	\N		2026-04-14 20:50:27.830231+00	56d79006-412e-4a1a-ab42-da5509b64260	
e3692700-99cf-495b-85b0-98f139a27394	18b11bdc-ab6e-4efc-9df0-c5c27db100e6	\N		2026-04-14 20:50:28.224426+00	56d79006-412e-4a1a-ab42-da5509b64260	
f3c9ef3f-133c-4e0a-a4a9-9934963edca8	f2441b0e-e26f-48fc-b657-a185b06c96b1	\N		2026-04-14 20:50:28.620446+00	56d79006-412e-4a1a-ab42-da5509b64260	
6c5e51f6-f697-4a10-b6ad-c5be660fc6bf	e6cac9aa-345b-4f6d-804d-e3acaa335fa9	\N		2026-04-14 20:50:29.028553+00	56d79006-412e-4a1a-ab42-da5509b64260	
3de0dd3e-6ce0-459f-9e79-f388a07c4b5d	882cc1bb-71c6-4260-ae67-21e1d25543b3	\N		2026-04-14 20:50:29.423574+00	56d79006-412e-4a1a-ab42-da5509b64260	
744c3044-f540-40e2-95cc-c22c12ef4008	c1605e34-a9a5-4fec-8b9f-e8cb0e2486e7	\N		2026-04-14 20:50:29.818545+00	56d79006-412e-4a1a-ab42-da5509b64260	
d8150c71-79f4-4523-abab-89a72f9403dc	0c5d9218-fb7c-4cc6-9e4d-f43a6ccacf70	\N		2026-04-14 20:50:30.214398+00	56d79006-412e-4a1a-ab42-da5509b64260	
5a4ae188-aaab-465e-825c-239140ec0b5a	560c0811-31fa-4d12-97f0-ec8d5fea6616	\N		2026-04-14 20:50:30.6091+00	56d79006-412e-4a1a-ab42-da5509b64260	
a4451441-c92f-4417-bf13-9e4cfdf5339d	0842578a-7563-477a-9103-4e72af463dfb	\N		2026-04-14 20:50:31.00335+00	56d79006-412e-4a1a-ab42-da5509b64260	
d321234b-3f4d-4bb7-a8a4-14e4d883bc08	e68702a9-1a48-4bfa-9282-847860aa66c2	\N		2026-04-14 20:50:31.397069+00	56d79006-412e-4a1a-ab42-da5509b64260	
4bfef4e5-168d-4658-8465-c65ee7b5f6ef	b757a29c-b2ff-4604-a746-5f68c5c3daf1	\N		2026-04-14 20:50:31.791403+00	56d79006-412e-4a1a-ab42-da5509b64260	
36a08ff5-0da1-42d4-9c6c-bf19a9b99ac1	326d95f4-8bab-4d22-8398-163310041933	\N	333	2026-04-14 20:50:52.077383+00	56d79006-412e-4a1a-ab42-da5509b64260	
4453c9ec-86fc-49bf-a543-1589b57c2347	b7bf2c4f-7ebf-43ad-ac25-da6ab5b0fbb8	\N	333	2026-04-14 20:50:52.522513+00	56d79006-412e-4a1a-ab42-da5509b64260	
ddfe9889-3d98-410b-8db6-2d95016bb115	f24d3ec7-71cc-416c-9666-9a151ed7a201	\N		2026-04-14 20:50:52.923859+00	56d79006-412e-4a1a-ab42-da5509b64260	
639a61a0-50f9-4899-952c-02591c69c7c9	4aebaf0b-e616-4e1b-8e1a-d8cb166a2238	\N		2026-04-14 20:50:53.32393+00	56d79006-412e-4a1a-ab42-da5509b64260	
cf18a9cf-3f3a-4a37-aa01-a89e7c671f6f	556d44dc-f3e8-41e0-a82a-0ef3bc0abf9c	\N		2026-04-14 20:50:53.724982+00	56d79006-412e-4a1a-ab42-da5509b64260	
5f93ecd6-5f9d-4f61-ad59-1b4996f59384	1c0f993c-418c-4ed1-85ea-a2f03752c82b	\N		2026-04-14 20:50:54.12517+00	56d79006-412e-4a1a-ab42-da5509b64260	
b8fed1bf-1b73-4848-8408-4e52dd6c9ffa	e465e99a-de1c-40d1-abab-b2840263767f	\N		2026-04-14 20:50:54.525233+00	56d79006-412e-4a1a-ab42-da5509b64260	
7534158d-0a1f-4e2a-8061-48f130aaa456	8b727485-6f09-4cf5-aca7-82f2fe91dc40	\N		2026-04-14 20:50:54.925025+00	56d79006-412e-4a1a-ab42-da5509b64260	
cf09b058-6941-4702-b24c-9f27bbbd4bb0	a854cd29-abfb-4df1-91b7-be4a403d8b48	\N		2026-04-14 20:50:55.324332+00	56d79006-412e-4a1a-ab42-da5509b64260	
c72196c5-86e4-424d-b3b2-2d3a58ce96df	c240cfb9-38ca-4ce4-9680-b38ba725381e	\N		2026-04-14 20:50:55.725843+00	56d79006-412e-4a1a-ab42-da5509b64260	
1be0ea8b-2491-43c5-b53b-7f0ae698ac53	bb3e674e-d956-4c6e-a749-4ef6bebe3c41	\N		2026-04-14 20:50:56.126702+00	56d79006-412e-4a1a-ab42-da5509b64260	
5ba698de-686e-42d3-87d5-13f25bee26d9	d44e2c7a-216f-4607-bf8f-5bb5687389b0	\N		2026-04-14 20:50:56.526055+00	56d79006-412e-4a1a-ab42-da5509b64260	
023bcc9f-265a-4c4b-9661-2455a2e719e7	30997fde-3ee8-458d-9645-0beacdb779bf	\N		2026-04-14 20:50:56.925807+00	56d79006-412e-4a1a-ab42-da5509b64260	
883a71c2-1bcf-4f17-b0a8-9395ffe19b25	1b342aab-9b27-4df2-9126-90d148f89c3a	\N		2026-04-14 20:50:57.324914+00	56d79006-412e-4a1a-ab42-da5509b64260	
770061de-81ce-44c5-8d56-79be4149cf94	348097cc-3b69-4395-86a6-022c88790911	\N		2026-04-14 20:50:57.723307+00	56d79006-412e-4a1a-ab42-da5509b64260	
9eba9f08-5c86-4383-91f8-52d83760fb95	dd46eef8-8579-4e2b-9006-fcca8a2ad2ea	\N		2026-04-14 20:50:58.122514+00	56d79006-412e-4a1a-ab42-da5509b64260	
2f4d6382-86f2-4fdb-aaf9-4f39f9466a2b	6b3003a8-011e-421b-bb2a-2f0ecc5c1755	\N		2026-04-14 20:50:58.522029+00	56d79006-412e-4a1a-ab42-da5509b64260	
393f7ed9-1f24-42dd-822a-ad3fa1a4b463	c37d4bb4-9822-441e-b0e0-0cd9e5b17ece	\N		2026-04-14 20:50:58.921626+00	56d79006-412e-4a1a-ab42-da5509b64260	
b819a46c-f564-49e9-8030-65f19cabe41d	eda4602c-60ad-4be5-89bb-74eed064fb10	\N	1	2026-04-22 12:02:24.435168+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ef9aa7e3-e981-4b10-a0be-96b2d937f424	60ee9805-32d6-435e-87fd-3acf0819aa66	\N	1010	2026-04-22 12:02:24.701316+00	1025389a-0e27-4e08-b6a0-b188660bea57	
583deddf-9781-4607-92c8-dae83f23f2c7	dadd53f7-3b71-4a6f-a81e-4e59ab1a07f5	\N		2026-04-22 12:02:24.964996+00	1025389a-0e27-4e08-b6a0-b188660bea57	
95171b0c-2759-4dc8-ab02-4fdbed607d40	2ddfb37d-7433-4c68-af3f-a858eb87c5d8	\N		2026-04-22 12:02:25.236095+00	1025389a-0e27-4e08-b6a0-b188660bea57	
96042dd7-e8f0-45d2-9598-d08bfe744078	34a81a95-8bd8-4a39-8e91-850581d3d63c	\N		2026-04-22 12:02:25.507459+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f4ee4c0d-6637-45a2-a332-c684255c4dab	be245b1c-c2db-40f4-b6c6-c5c474f29c2f	\N		2026-04-22 12:02:25.776446+00	1025389a-0e27-4e08-b6a0-b188660bea57	
1a666c2a-69df-4fd0-b3ff-3a6ba37dab36	4e927d44-06be-433b-b0a6-1e19b25d5d77	\N		2026-04-22 12:02:26.041308+00	1025389a-0e27-4e08-b6a0-b188660bea57	
599025ba-b7ba-4030-bd70-08efad7ec979	60935777-f190-46e0-a3b3-150fc2fa141e	\N		2026-04-22 12:02:26.317682+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0d48a5f2-91d5-4248-94ed-31c1d6be3f21	c1839b79-65ec-43dd-a303-001d188a998d	\N		2026-04-22 12:02:26.582259+00	1025389a-0e27-4e08-b6a0-b188660bea57	
39ec53d3-cc95-4dc9-89f1-9d50cf1d6c92	d72540b7-a29e-4df8-898a-1a237a9a2d58	\N		2026-04-22 12:02:26.845337+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2541ae26-0caa-4ee4-9f3d-f24a254c24a1	8cdaa054-fab0-4061-b493-c34532a6515d	\N		2026-04-22 12:02:27.111835+00	1025389a-0e27-4e08-b6a0-b188660bea57	
de8ecb4e-e4a0-4974-9d67-5e1f4ccf596c	c02a7772-216e-4638-ba2f-9a144f539135	\N		2026-04-22 12:02:27.377492+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ee6ffa80-629d-4bf6-b85e-6097f2008bc1	269d3d1e-b2e5-4748-a29b-788c7e7694e9	\N		2026-04-22 12:02:27.642414+00	1025389a-0e27-4e08-b6a0-b188660bea57	
18088906-7659-4819-bf21-4a7d639a22cc	4b009242-d70b-4950-8592-eb1433aa367e	\N		2026-04-22 12:02:27.905212+00	1025389a-0e27-4e08-b6a0-b188660bea57	
35dd3cdd-9e22-427c-9991-97c8058da678	c2c4c23b-14ae-4381-b201-889e134a1cd5	\N		2026-04-22 12:02:28.171264+00	1025389a-0e27-4e08-b6a0-b188660bea57	
590c0232-c852-44cf-a90c-a1922b351fb1	dd8ac262-bd4f-4b22-8a1f-549e542c66f0	\N		2026-04-22 12:02:28.435585+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f2b72afe-2b5a-47fc-b72b-2690f35c74d1	b54f9a22-0cbe-488d-9188-10f2058f6a94	\N		2026-04-22 12:02:28.696891+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f36f4993-0352-4647-8e00-ac3df8c04910	553024ba-7857-4c91-b4e2-db343665f5ac	\N		2026-04-22 12:02:28.958439+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d7704694-7faa-4eaa-8022-5bf05efc65d8	bd709938-fb52-40a2-86bb-d8345a2cce04	\N	1	2026-04-26 16:31:25.428469+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
98ef0521-bde8-4f40-adc4-16deecc8762e	a28dbf21-1da8-4cca-aa2d-eca7b5d2ae9d	\N	1	2026-04-26 16:31:26.123082+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
d99ddca6-69d6-43f2-9505-26067072dc3e	042f9a82-2442-48d6-81f2-cc99d9d03b22	\N	1	2026-04-26 16:31:26.811635+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
9a14cd49-fc77-457d-90ea-ca390a4e1c7c	38f44b9d-4083-4849-b394-a42227337e57	\N	1	2026-04-26 16:31:27.499317+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
d5ac7d6e-d24b-4fbc-93cf-663f91f3ba8b	97a195f7-7df9-4285-9614-a6ab176a397a	\N	1	2026-04-26 16:31:28.187825+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
e058ccf1-78f2-4e9b-8569-3c29152025d7	909c02b5-28d7-40ab-bf94-92e6a37b12f0	\N	1	2026-04-26 16:31:28.875445+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
b08b98c0-6572-41bb-866a-642c5e7d529c	395bc64a-4fb2-4561-a051-5b901f573bba	\N	1	2026-04-26 16:31:29.562359+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
ffc4eaac-b281-4a64-ac83-0971b144b9ee	e68a4ab1-c9d0-4560-ba4c-67d615d0ae0d	\N	1	2026-04-26 16:31:30.248215+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
e845f3b2-784b-4dae-909c-116220172089	be779330-e202-4cd8-a341-12340bb62015	\N	1	2026-04-26 16:31:30.938225+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
98f1ab1c-df91-4b49-a6da-706cbfdb6d4d	b7e5f39a-9c31-4950-8bbf-77be6ed2d561	\N	1	2026-04-26 16:31:31.623468+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
48210af7-b55d-4525-a1c1-9c24701ec4c8	29818450-dd14-412c-996e-536807bd16da	\N	1	2026-04-26 16:31:32.309989+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
243f8b71-d86c-4955-ae93-29cdadd5bd4e	3e78b743-841b-4bb6-975d-ae26afc7b47c	\N	1	2026-04-26 16:31:32.99665+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
aedd4bf5-9e13-47ba-85fe-7da7ad413f93	dc5498d0-a04d-4bca-acaf-6333950fee8e	\N	1	2026-04-26 16:31:33.681235+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
7f0ceb1f-162b-49b3-81e8-8d3ec696c71e	e78b7258-41ce-44bf-9e03-f23d1b7eb120	\N	1	2026-04-26 16:31:34.365121+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
57d42b20-f7b9-43f3-b0d0-eb3181aa9f53	2d56053d-1e2e-4a4c-896d-2128b6842c2a	\N	ё	2026-04-26 16:31:35.050436+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
ae5adc89-3672-4cc8-9f5e-51bb133f0d23	1bb9f758-59a4-456a-966b-3d74034668ed	\N	1	2026-04-26 16:31:35.7369+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
c0c95b24-5e95-4fdc-8467-a636a8f2ebce	804e8ef1-c84f-4b33-9a1a-a67c0392b18c	\N	ё	2026-04-26 16:31:36.424468+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
0ab98c57-56b8-41f5-aab7-72d4aee779f8	a0356cfe-0ed6-4979-9a87-15eadb3246be	\N	ё	2026-04-26 16:31:37.110025+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
eb3ccfed-5e55-4fb2-aba3-f721eb02ee87	48d2484c-2fb1-4cf0-a48d-3dc188585d64	\N	2	2026-04-26 16:35:26.59674+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
fd3cd6d5-b602-4e0b-bfa0-90ac38413b3b	cece681d-5fb6-43c7-9d21-1590a390c02f	\N	2	2026-04-26 16:35:27.285539+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
66f5de21-37fd-4e5f-9e15-4d6ddb920307	7581ace3-b9cd-48c1-a2c3-2658dc77c0bb	\N	2	2026-04-26 16:35:27.970335+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
d0e6a9c9-13de-45b7-9cde-7049361de65e	f7564202-dc26-4e37-8993-1fe9c5ba489a	\N	2	2026-04-26 16:35:28.653885+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
2ffcfaa9-5dce-439e-bb09-7ebca8405cdd	787676d0-4acc-4bb3-8ccc-4e817afc6961	\N	2	2026-04-26 16:35:29.3395+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
3b955125-257d-4d58-83ae-51d6dac34f98	d57d0d02-82bd-4acd-b6c6-589d85da01cf	\N	2	2026-04-26 16:35:30.026201+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
5f2f0a05-86d3-460c-803c-714eab6aefc4	898fe4a8-c708-4736-87e8-164a66416e5f	\N	2	2026-04-26 16:35:30.714074+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
dcbb74f1-a15c-4734-96cc-ac9bd1997818	a8d2f16a-2561-47c7-b8ce-924edd6a31aa	\N	2	2026-04-26 16:35:31.408119+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
4b25936b-45fb-4023-bc8b-a17e7eca77a8	bf431370-1b35-4f4b-bb34-5e667645252d	\N	2	2026-04-26 16:35:32.093813+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
b12ae5e8-da98-4fe4-90dd-285706bf1593	95389d63-c700-4810-bc90-a032d04716de	\N	2	2026-04-26 16:35:32.7789+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
377cbb44-20cd-4c18-957e-262e8f1b416c	3aa89133-aa8c-4d6e-b92f-5fd8a4f767e0	\N	2	2026-04-26 16:35:33.467684+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
c0a99cff-22fc-4930-9b4b-2603a4f7e425	9441bbc4-b942-42f1-88ed-179138fcea3e	\N	2	2026-04-26 16:35:34.176139+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
384adf85-50c6-4a29-b5d1-176383a63c73	533dd6f6-a1c7-4e7c-b8ea-cc8f46f800f9	\N	2	2026-04-26 16:35:34.892632+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
c7588ddf-fbd3-40e1-a40c-3588cea7d4a3	685bff93-5119-4491-b538-9acdfd7cd04c	\N	2	2026-04-26 16:35:35.58522+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
c7c127e7-b8c2-41e5-952c-52a0c51b237f	6330fd8f-c320-457e-a3bc-eb14eb27c10a	\N	ж	2026-04-26 16:35:36.566184+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
2c28e299-2501-4341-83e3-e6f58257c55a	ceab8680-cd07-4d8f-92ee-626ef7076cc8	\N	2	2026-04-26 16:35:37.25113+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
7624337a-0d0a-43b1-a573-82fc7d79bc2c	821aa5c5-1b79-460a-bde0-0527332794ea	\N	ж	2026-04-26 16:35:37.935502+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
7cfbaab5-52eb-4491-ac54-f7e7224917e6	fc645190-8813-4e94-bc9c-3e135da5fbe0	\N	ж	2026-04-26 16:35:38.630052+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
4caec29e-23bb-4bf8-a3d3-bf511aac85fb	51a0cd97-9caa-4536-bc05-771ba95e586c	\N	10	2026-04-26 16:42:47.626725+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
430b05f9-1293-439b-94ff-fd63c5032bc2	10cae8bd-ecce-4ae8-8b2f-f7384464bdba	\N	10	2026-04-26 16:42:48.31215+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
def2e5cb-33cc-4e94-9dd2-d43736968a0c	a1d208a3-4b68-44c8-b5c2-5dd3dea6f9d4	\N	10	2026-04-26 16:42:48.998281+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
5ce0ec22-2b1e-48b8-8eb7-56f0bc27f0a3	60649fe7-1c42-45e4-9789-9e2d3075340f	\N	10	2026-04-26 16:42:49.714105+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
6dc8a1fe-4270-47f2-a445-4464866d937a	e102a609-e5be-456f-8de9-0becf62fd989	\N	10	2026-04-26 16:42:50.39918+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
0d55568b-18c8-42f2-9bb1-693749513305	d416df40-aeed-42c1-bc4a-91fd20b33c0b	\N	10	2026-04-26 16:42:51.084689+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
0b09b97d-3bf8-49fc-a1b5-0dc81db1be38	36542684-6ba2-4ef0-a2e4-94f75eae7a6c	\N	10	2026-04-26 16:42:51.775614+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
72aca627-c5b3-4fed-beb7-d20f6141934a	9e8a7ad8-e850-464e-9ed0-bffa6b85d49f	\N	10	2026-04-26 16:42:52.467254+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
91eaaa2e-2952-4ddc-a735-0c9077571f23	2932f4ed-519e-4974-b29a-a398d1bd444d	\N	10	2026-04-26 16:42:53.154257+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
5decebed-5556-4ca6-ab09-91e27391fe20	72aba627-d8ae-48e9-81ad-22a1aa912e8e	\N	10	2026-04-26 16:42:53.841212+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
77aacf2f-ffb0-41cc-95ea-8e84c6279206	99e9b863-d37a-489c-bf31-7ab7f3514edd	\N	10	2026-04-26 16:42:54.525582+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
bc52f66d-97da-4b66-98a1-d429248e460b	9f533a1c-8f63-43bc-9bfc-858aa7fd2881	\N	10	2026-04-26 16:42:55.213211+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
96985a3f-c5a0-4504-a43c-c5d405f54d3c	a90da11e-3a47-410a-8247-58433f07081a	\N	10	2026-04-26 16:42:55.897657+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
f3cfac27-9ccf-4553-bd99-c34573656d04	d5e03594-ff91-497d-8e9c-6c8214fc9d9e	\N	10	2026-04-26 16:42:56.584313+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
5a0e5abf-b97f-48a6-9c2f-27a4dc2e0f06	e099e49f-1841-4759-a4fa-81be61b0db42	\N	з	2026-04-26 16:42:57.267961+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
f3e66635-f488-45eb-ab57-b8e345cd6baf	7b718520-f477-4762-b1dd-4aea68bbd2a1	\N	10	2026-04-26 16:42:57.951557+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
2ba97aec-a9a2-43eb-909f-6a8e30a318e7	f20309df-8a09-4c4c-b00a-924f90e1e7d0	\N	з	2026-04-26 16:42:58.63617+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
6f046000-57c4-4604-82e7-91bd1ab1bd53	59897b9f-c661-45de-9521-5c38a2eb19d9	\N	з	2026-04-26 16:42:59.320183+00	1025389a-0e27-4e08-b6a0-b188660bea57	Стандартное заполнение
37350b70-1b16-426c-aa59-b8c2869572c5	14b2bbf2-9fc9-4cfe-a878-6d08cb0e3f0a	\N	11	2026-04-27 17:23:19.72961+00	1025389a-0e27-4e08-b6a0-b188660bea57	
1a8f49f0-3800-47f7-b7dd-fbd5b7f10798	efaa21e1-fe47-4cd1-9bf8-c29d5e88cd83	\N	12	2026-04-27 17:23:20.402028+00	1025389a-0e27-4e08-b6a0-b188660bea57	
13165af7-f40e-4964-a3ba-eee9974569f0	c482686b-165e-4e67-9d29-b8bfa6a8725a	\N	13	2026-04-27 17:23:21.330408+00	1025389a-0e27-4e08-b6a0-b188660bea57	
c994d2d9-dc2d-4f15-8887-7a79cd7384ab	933316a6-6b90-4291-b598-5038f1c0097e	\N	15	2026-04-27 17:23:21.996175+00	1025389a-0e27-4e08-b6a0-b188660bea57	
c740caee-cfc8-4618-9172-a16548b71e7a	c5312b3e-d0b6-4eb4-90dc-4ddad151599b	\N	10	2026-04-27 17:23:22.660401+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2e4f8d6b-7be4-4704-aaf6-18ba94bc0cf1	24af9ecb-d37a-4cec-abf8-1e70b6cbc743	\N	13	2026-04-27 17:23:23.323026+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ca60f16b-515a-4f78-8689-6000da873f0f	3faff43a-c917-44e9-ab72-7f439a0323ff	\N	11	2026-04-27 17:23:23.990252+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b8900fc3-bb6b-4918-a2ef-15c08e27384c	afc5eb45-acc3-4dc1-b755-3eebb6dd8948	\N	14	2026-04-27 17:23:24.656666+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5d7e4ad2-0b1d-4acc-80fb-15d9e31b0820	d8fde113-68f9-4e74-94ab-db4a0a6a5570	\N	16	2026-04-27 17:23:25.318291+00	1025389a-0e27-4e08-b6a0-b188660bea57	
18a1cca1-4f75-414d-a582-842e5f444a8b	a20df019-724b-443c-9b87-fd141bdbda30	\N	14	2026-04-27 17:23:25.987816+00	1025389a-0e27-4e08-b6a0-b188660bea57	
9d47fc49-e1ec-477d-8919-85c2a1340103	3e470ec3-3fbb-4716-abe5-6e359d371a4c	\N	12	2026-04-27 17:23:26.658528+00	1025389a-0e27-4e08-b6a0-b188660bea57	
608d5cce-6e3e-4219-ae4c-d016dae5c55a	c45f6dfe-8bfc-4937-8141-650c2ca1aba4	\N		2026-04-27 17:23:27.326594+00	1025389a-0e27-4e08-b6a0-b188660bea57	
7563c421-b873-4bf3-be1f-cd43d6d041c0	4a1eb88c-5f79-460c-97af-fe831951cb5a	\N		2026-04-27 17:23:27.991646+00	1025389a-0e27-4e08-b6a0-b188660bea57	
67d7e4f4-ca0a-4081-b213-25612bbb545c	48470047-c88f-4efc-a94d-9070f2939b9e	\N		2026-04-27 17:23:28.654927+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f2718998-54f1-477a-a11d-695b5a868c3c	63bc581b-6d25-4982-95c2-604da6a7e6da	\N		2026-04-27 17:23:29.317559+00	1025389a-0e27-4e08-b6a0-b188660bea57	
84ab91f5-0f4a-43c0-921e-77b9e2e91088	5095a361-47a1-476c-a13f-034ed2305c51	\N		2026-04-27 17:23:29.980612+00	1025389a-0e27-4e08-b6a0-b188660bea57	
efa5d4e1-7bc1-49d0-af6d-2240bc4e3050	c55639c2-51c7-4bea-aabf-5aac05fb7445	\N		2026-04-27 17:23:30.643294+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3a7148b5-5994-42fc-8c73-4fb0f66e7462	e08d7a28-2d52-4f42-887c-f822eb60ed07	\N		2026-04-27 17:23:31.615218+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0f734269-1bc7-4376-815f-a72d234ca1bc	14b2bbf2-9fc9-4cfe-a878-6d08cb0e3f0a	11	11	2026-04-27 17:38:24.628937+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3c5b8d85-818f-4bdc-8d97-07060c7f5803	efaa21e1-fe47-4cd1-9bf8-c29d5e88cd83	12	12	2026-04-27 17:38:25.039144+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ac35d786-92d3-447d-8c2d-9c4f5917b802	c482686b-165e-4e67-9d29-b8bfa6a8725a	13	13	2026-04-27 17:38:25.445573+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e9ce0308-84c1-435c-8eda-c72c12099c52	933316a6-6b90-4291-b598-5038f1c0097e	15	15	2026-04-27 17:38:25.863859+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ce438256-94c6-410f-9da2-ce998b9c69ec	c5312b3e-d0b6-4eb4-90dc-4ddad151599b	10	10	2026-04-27 17:38:26.275913+00	1025389a-0e27-4e08-b6a0-b188660bea57	
133b232c-81d5-45e0-946d-2a823f62967b	24af9ecb-d37a-4cec-abf8-1e70b6cbc743	13	13	2026-04-27 17:38:26.689867+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b8508338-f04a-4fea-8b49-e23e538e15d4	3faff43a-c917-44e9-ab72-7f439a0323ff	11	11	2026-04-27 17:38:27.098178+00	1025389a-0e27-4e08-b6a0-b188660bea57	
8645c8e3-49a0-40e3-950d-d428605994e3	afc5eb45-acc3-4dc1-b755-3eebb6dd8948	14	14	2026-04-27 17:38:27.506284+00	1025389a-0e27-4e08-b6a0-b188660bea57	
49f9abca-d759-4b7b-9ebf-2b9f0397f1c3	d8fde113-68f9-4e74-94ab-db4a0a6a5570	16	16	2026-04-27 17:38:27.917458+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2ceddcfe-f0a3-43c8-b9fb-3e5c4dbf5c3b	a20df019-724b-443c-9b87-fd141bdbda30	14	14	2026-04-27 17:38:28.322518+00	1025389a-0e27-4e08-b6a0-b188660bea57	
aeca7863-36f4-4cce-8a0b-7cae8eb3fce1	3e470ec3-3fbb-4716-abe5-6e359d371a4c	12	12	2026-04-27 17:38:28.732765+00	1025389a-0e27-4e08-b6a0-b188660bea57	
96e1d10c-c1bb-43d4-ae3f-b7de22a83429	c45f6dfe-8bfc-4937-8141-650c2ca1aba4			2026-04-27 17:38:29.143303+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ed5d0276-386b-4d39-b5b4-0313e606c27e	4a1eb88c-5f79-460c-97af-fe831951cb5a			2026-04-27 17:38:29.549976+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f67a5c5a-861a-492b-adbe-140b9dc466c2	48470047-c88f-4efc-a94d-9070f2939b9e			2026-04-27 17:38:29.983106+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f02aa777-6782-4a71-8266-15bc66a040af	63bc581b-6d25-4982-95c2-604da6a7e6da			2026-04-27 17:38:30.409239+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3d94cc90-6090-4f3f-be0b-08d2a28cc5b0	5095a361-47a1-476c-a13f-034ed2305c51			2026-04-27 17:38:30.830059+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a2620120-f34f-40d6-8bd7-f4900229fba6	c55639c2-51c7-4bea-aabf-5aac05fb7445			2026-04-27 17:38:31.262284+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ec815348-0da5-4aa6-a94d-59431a4fe4c3	e08d7a28-2d52-4f42-887c-f822eb60ed07			2026-04-27 17:38:31.672083+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6d5a32ad-fbb7-45f5-a44e-e570a9f945d3	27966476-b0eb-477a-9e9d-695e4cf0a0ef	\N	1	2026-04-27 23:16:02.123197+00	\N	
688a0906-f450-45fb-8da8-efab624d75a1	a91f763e-597a-42a0-a90b-4f45f79180e1	\N	2.5	2026-04-27 23:16:02.253274+00	\N	
11d47efb-3ad9-4616-96e2-959bc298379c	27966476-b0eb-477a-9e9d-695e4cf0a0ef	1	1	2026-04-27 23:34:21.019061+00	\N	
afbba383-fb0b-426f-a568-e2184fbace96	a91f763e-597a-42a0-a90b-4f45f79180e1	2.5	2	2026-04-27 23:34:21.118059+00	\N	
dcf46c06-1b12-4afa-bf7a-601537a9ab0c	27966476-b0eb-477a-9e9d-695e4cf0a0ef	1	1	2026-04-27 23:35:45.812409+00	\N	
544d4c8c-100c-4010-ae53-01e04c93b738	a91f763e-597a-42a0-a90b-4f45f79180e1	2	2	2026-04-27 23:35:45.911409+00	\N	
4cab6e62-c6f0-4374-aa29-50efa379dea5	27966476-b0eb-477a-9e9d-695e4cf0a0ef	1	1	2026-04-27 23:36:02.006323+00	1025389a-0e27-4e08-b6a0-b188660bea57	Первичное заполнение отчета
a06c2b16-cf7b-40bf-ad50-90d0c28b3c5c	a91f763e-597a-42a0-a90b-4f45f79180e1	2	2	2026-04-27 23:36:02.102321+00	1025389a-0e27-4e08-b6a0-b188660bea57	Первичное заполнение отчета
a9b23eaa-baeb-4ca6-9504-4268eadaeb35	3a5b439f-b03b-4d40-adb7-d69e1d13e66f	\N	3	2026-04-27 23:36:02.197321+00	1025389a-0e27-4e08-b6a0-b188660bea57	Первичное заполнение отчета
077e168f-ddf2-4a77-972f-f5f3e86ee01b	27966476-b0eb-477a-9e9d-695e4cf0a0ef	1	1	2026-04-27 23:39:38.238068+00	1025389a-0e27-4e08-b6a0-b188660bea57	Первичное заполнение отчета
f96346b2-7424-4249-b1fd-9b2b91045008	27966476-b0eb-477a-9e9d-695e4cf0a0ef	1	2	2026-04-28 00:54:18.781007+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
c56a9e01-1bd1-4762-a5be-dcf6bcf00ef9	a91f763e-597a-42a0-a90b-4f45f79180e1	2	1	2026-04-28 00:54:18.924007+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
f4ccdb31-aefa-4956-bab9-b4b781f6c256	3a5b439f-b03b-4d40-adb7-d69e1d13e66f	3	5	2026-04-28 00:54:19.061006+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
3f1167bc-002d-47ce-b36e-0a53417532d9	714c3cee-5a9c-42f6-a8c1-5794ef56cbc5	\N	1	2026-04-28 00:54:19.200006+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
eed00cba-38d7-4b20-a6a0-7a6050f6d059	bafb14c0-ca8e-4897-9e86-f70eb2be88f1	\N	0	2026-04-28 00:54:19.337007+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
faa56856-a312-4254-848a-ac23a4045502	1a78c3ec-e161-4009-b819-3435ba2bd48b	\N	0	2026-04-28 00:54:19.474009+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
db7f58b7-fdef-48be-9161-8a184a0676ec	d16d2fee-73ad-47b2-82f7-c1fb7015272d	\N	0	2026-04-28 00:54:19.611007+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
d38c47f2-e308-41c1-9124-f560232dd6d0	697818c6-b081-464c-9baa-72626106854b	\N	0	2026-04-28 00:54:19.748006+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
477eda62-1686-4451-937d-e65c31933c2a	30901703-1b6e-46e3-8ff0-753f7feb74cc	\N	0	2026-04-28 00:54:19.885006+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
0c6ee7bb-cc42-440e-829b-57c0405e536c	63502327-0fa2-422e-bb09-c30252e4dd66	\N	0	2026-04-28 00:54:20.021006+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
4284646d-700b-4884-baa0-00845aa9f822	d11fdffe-6f35-43cc-a3b9-235a48bc28c9	\N	0	2026-04-28 00:54:20.159007+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
844bf664-bf9d-44c0-bdc5-bd5a56b578c2	a68285e9-c22f-4953-8909-c994d199e18d	\N	0	2026-04-28 00:54:20.295007+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
7f4edd32-aa24-4f89-9997-ac296cc31066	abcd4b22-a41a-4a51-8ac9-7949cdcf814a	\N	0	2026-04-28 00:54:20.431007+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
63a52023-b040-4997-98bc-8adf5a42b8c0	3631f7c4-5f04-405d-8ed2-2f785f11b5fc	\N	0	2026-04-28 00:54:20.567007+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
92016122-56cb-43f2-9b66-9f237a5c9fcd	d8ea369e-f182-4869-adb9-d7f76099959e	\N	нет	2026-04-28 00:54:20.706008+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
89643b00-9c0f-4c8c-a20d-bea7cc8d506e	496b4952-e403-44ca-948f-8cd472418a51	\N	0	2026-04-28 00:54:20.842007+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
4d34e953-a2b5-4837-b2eb-21851a00ee2b	c40955f4-9bb8-464e-8dd0-50ffd679f2f8	\N	нет	2026-04-28 00:54:20.977299+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
cdecf50f-6835-41e0-adf3-2201d4339a9c	4f30203d-7ed5-4630-b0e7-a4bc2935fca8	\N	нет	2026-04-28 00:54:21.115301+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 2 смены
5dad096b-f901-45eb-9e40-7a6aa4418320	27966476-b0eb-477a-9e9d-695e4cf0a0ef	2	1	2026-04-28 00:55:07.56632+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
47932db0-55bb-42de-afb0-5558eb857306	a91f763e-597a-42a0-a90b-4f45f79180e1	1	1	2026-04-28 00:55:07.701323+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
38953af3-dc60-4c66-8d57-6213f5d4403f	3a5b439f-b03b-4d40-adb7-d69e1d13e66f	5	5	2026-04-28 00:55:07.782319+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
7cc41cdc-cd79-44cf-afc1-16d47788eb9f	714c3cee-5a9c-42f6-a8c1-5794ef56cbc5	1	1	2026-04-28 00:55:07.86432+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
cc2845b9-2abd-40ae-b0c6-182441212fa9	bafb14c0-ca8e-4897-9e86-f70eb2be88f1	0	1	2026-04-28 00:55:07.947323+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
ad680c1b-7677-4f3c-91b0-e6605f3b808b	1a78c3ec-e161-4009-b819-3435ba2bd48b	0	2	2026-04-28 00:55:08.161318+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
10a92492-a6a3-4498-80ad-f96b0833350f	d16d2fee-73ad-47b2-82f7-c1fb7015272d	0	3	2026-04-28 00:55:08.296322+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
592f0e17-7b22-451b-bdaa-129d1f2ce858	697818c6-b081-464c-9baa-72626106854b	0	3	2026-04-28 00:55:08.43032+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
5b39126a-1f1c-491b-8bb6-0d0fea7f8aed	09dcd708-fc87-456b-b4c6-8a6099de8c77	\N		2026-04-28 10:36:14.875495+00	1025389a-0e27-4e08-b6a0-b188660bea57	
bca6a770-4a44-4cf5-9829-385342770bb7	30901703-1b6e-46e3-8ff0-753f7feb74cc	0	4	2026-04-28 00:55:08.565321+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
8b28b760-df46-4171-a94b-9ca04f0c1ed2	63502327-0fa2-422e-bb09-c30252e4dd66	0	8	2026-04-28 00:55:08.70032+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
cf65da5d-1b74-45ea-a9dc-3021d558531f	d11fdffe-6f35-43cc-a3b9-235a48bc28c9	0	10	2026-04-28 00:55:08.834321+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
53f1f185-65ac-4916-b519-c3b46b6f67a7	a68285e9-c22f-4953-8909-c994d199e18d	0	2	2026-04-28 00:55:08.96932+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
70127089-51c6-4ba2-bf33-b85434d51714	abcd4b22-a41a-4a51-8ac9-7949cdcf814a	0	5	2026-04-28 00:55:09.10432+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
9e15b3ae-e9b8-49d1-9090-c3ca2d5185f7	3631f7c4-5f04-405d-8ed2-2f785f11b5fc	0	2	2026-04-28 00:55:09.240321+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
fa24de2f-5f57-4180-844b-b349d4b024cd	d8ea369e-f182-4869-adb9-d7f76099959e	нет	нет	2026-04-28 00:55:09.376321+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
078414ff-65a3-4c70-901f-03e593c8df47	496b4952-e403-44ca-948f-8cd472418a51	0	5	2026-04-28 00:55:09.458321+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
a897fa51-0548-4fa0-b72b-433e2ad6bc28	c40955f4-9bb8-464e-8dd0-50ffd679f2f8	нет	нет	2026-04-28 00:55:09.620322+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
7b15dc3c-9cc4-4936-8609-78b51dd6a348	4f30203d-7ed5-4630-b0e7-a4bc2935fca8	нет	нет	2026-04-28 00:55:09.701322+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
f4ece036-25ed-4867-a567-6b8423135987	27966476-b0eb-477a-9e9d-695e4cf0a0ef	1	1	2026-04-28 01:05:37.126717+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
86188976-c466-4e2a-bf17-0257307b7b76	a91f763e-597a-42a0-a90b-4f45f79180e1	1	1	2026-04-28 01:05:37.228716+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
77cd4042-5188-4e5f-9440-de3ee29eabdf	3a5b439f-b03b-4d40-adb7-d69e1d13e66f	5	5	2026-04-28 01:05:37.326716+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
b210e07e-1103-4f84-b8b1-192000f7fc67	714c3cee-5a9c-42f6-a8c1-5794ef56cbc5	1	1	2026-04-28 01:05:37.428718+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
9873cd99-37f0-4276-b684-d4c7da37b896	bafb14c0-ca8e-4897-9e86-f70eb2be88f1	1	1	2026-04-28 01:05:37.535715+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
0e9bf9e0-e2b8-46c8-88f0-df073cda8eef	1a78c3ec-e161-4009-b819-3435ba2bd48b	2	2	2026-04-28 01:05:37.634717+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
876fed06-4fc7-4f3b-8b09-d38418f3a346	d16d2fee-73ad-47b2-82f7-c1fb7015272d	3	3	2026-04-28 01:05:37.731733+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
ea2b9abe-42f4-4e87-9790-67b499fc35b2	697818c6-b081-464c-9baa-72626106854b	3	3	2026-04-28 01:05:37.828749+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
c06de1d9-78af-49ef-a839-09ca454dd98d	30901703-1b6e-46e3-8ff0-753f7feb74cc	4	4	2026-04-28 01:05:37.926749+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
3213c239-f9fd-4b83-9ba0-857b49cae25a	63502327-0fa2-422e-bb09-c30252e4dd66	8	8	2026-04-28 01:05:38.023749+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
1897bfa2-c5ca-49f0-a05b-c37d0184b0c6	d11fdffe-6f35-43cc-a3b9-235a48bc28c9	10	10	2026-04-28 01:05:38.121748+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
4f71d109-f696-439c-86f5-e70f83be7067	a68285e9-c22f-4953-8909-c994d199e18d	2	2	2026-04-28 01:05:38.219749+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
9396c0fc-37b3-4f0b-bb65-dfa6b53cb325	abcd4b22-a41a-4a51-8ac9-7949cdcf814a	5	5	2026-04-28 01:05:38.316751+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
a5f55030-b6f7-4274-8b37-9b705d1e6642	3631f7c4-5f04-405d-8ed2-2f785f11b5fc	2	2	2026-04-28 01:05:38.412769+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
d896b1be-7c31-4558-9730-40deef797627	d8ea369e-f182-4869-adb9-d7f76099959e	нет	нет	2026-04-28 01:05:38.508782+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
6d1898d3-e1ca-4003-9078-400b1ae2f418	496b4952-e403-44ca-948f-8cd472418a51	5	5	2026-04-28 01:05:38.605783+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
17c5119c-0d46-4203-8226-554172031489	c40955f4-9bb8-464e-8dd0-50ffd679f2f8	нет	нет	2026-04-28 01:05:38.701782+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
a45dc58c-3f92-4efd-8cd1-47b8ba8f6503	4f30203d-7ed5-4630-b0e7-a4bc2935fca8	нет	нет	2026-04-28 01:05:38.797784+00	1025389a-0e27-4e08-b6a0-b188660bea57	Полное заполнение 1 смены
136d7f9f-5404-452b-b129-6eba4b040adc	cba44c0e-12db-4ed5-afb6-6fe40b3120bd	\N	12	2026-04-28 01:10:30.448508+00	1025389a-0e27-4e08-b6a0-b188660bea57	
dda79f85-2efb-48ec-8e99-bb672be5d183	a7749111-3824-47cb-a953-0f85e6ceee7b	\N	14	2026-04-28 01:10:31.066259+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d80b71eb-b0b3-45d6-9a9f-523d6ec8524a	00382468-14d0-4f3c-a684-47164f7f8608	\N	20	2026-04-28 01:10:31.669861+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b02cbd20-b22a-4891-b22f-0f90e1d6476d	8e61ecba-bc24-497f-993d-caafb64a5cdd	\N	10	2026-04-28 01:10:32.273056+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5334dd2c-18a9-4fda-a0f6-386a1a413732	a05449b5-aac3-47e1-a553-cdf056cd9b84	\N	24	2026-04-28 01:10:32.875925+00	1025389a-0e27-4e08-b6a0-b188660bea57	
dc896133-099d-45a4-8a74-44e48d74b4a8	4eea0cf4-cf3a-4cd0-8b55-3cd4401df749	\N	13	2026-04-28 01:10:33.479269+00	1025389a-0e27-4e08-b6a0-b188660bea57	
08670a52-1d1d-495d-8b9e-bdf50b527acf	3e396474-4ce5-4df5-ac5e-6b1539cb3f47	\N	11	2026-04-28 01:10:34.082206+00	1025389a-0e27-4e08-b6a0-b188660bea57	
1a6b0cbd-fde7-4b7b-8bab-102ce44d721b	7665dabf-565a-4bcb-83bd-04718798d3b2	\N	12	2026-04-28 01:10:34.685206+00	1025389a-0e27-4e08-b6a0-b188660bea57	
cc88abfb-0fc4-4642-b9f9-3b8f6465a78a	67175c6e-98e6-49d9-85f9-51afa619c367	\N	17	2026-04-28 01:10:35.288268+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f3f9e1e6-226a-4b39-a59c-17dc37f69df8	5fbba159-c0e1-428d-885e-8b36393b142a	\N	15	2026-04-28 01:10:35.891369+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4a1894b6-8504-4dbb-a15a-e66e669772a1	e7bb7518-e6bf-4e1e-a17a-3e52ea3af84a	\N	16	2026-04-28 01:10:36.496111+00	1025389a-0e27-4e08-b6a0-b188660bea57	
7fae3461-c7b6-4148-beea-ca584b7f23fc	ff4dc068-53d2-462f-b8c9-442e3e641f46	\N		2026-04-28 01:10:37.100075+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a4605d9c-f4a4-4846-acd0-06970a6d88a5	457e6aca-2f53-48e2-af80-d5d051112d16	\N		2026-04-28 01:10:37.714222+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d6e05916-3790-4e6e-9e1b-cc989d5835ce	5a860c90-1941-42b4-b110-447ecd1b2574	\N		2026-04-28 01:10:38.316306+00	1025389a-0e27-4e08-b6a0-b188660bea57	
502489f7-3456-438a-b872-d6da2cb49632	8bf8dfcd-78a6-407d-9f28-6f367bb693fb	\N		2026-04-28 01:10:38.91844+00	1025389a-0e27-4e08-b6a0-b188660bea57	
91703b60-45cd-43a0-9dac-51a27dc333e9	89178d4f-c2ff-4222-aa73-03c610697e5c	\N		2026-04-28 01:10:39.521867+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3bc67e60-48e6-42b9-907a-4472cdf02cef	74ef35c2-e7ce-443e-aea6-4b406a4bd4ae	\N		2026-04-28 01:10:40.125229+00	1025389a-0e27-4e08-b6a0-b188660bea57	
32cc66a6-50b5-4d34-a8a7-e8f8eea0a77c	963fbe56-2c84-4d51-abd1-1072fd6d1213	\N		2026-04-28 01:10:40.728804+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a5084372-d612-4d42-ad91-54765ac4e72d	cba44c0e-12db-4ed5-afb6-6fe40b3120bd	12	12	2026-04-28 01:11:03.005464+00	1025389a-0e27-4e08-b6a0-b188660bea57	
825901d8-c9b6-4914-aec5-f33e3c8d69aa	a7749111-3824-47cb-a953-0f85e6ceee7b	14	14	2026-04-28 01:11:03.429102+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e16a5620-bcd3-48d6-9da2-68b091f49f5a	00382468-14d0-4f3c-a684-47164f7f8608	20	20	2026-04-28 01:11:03.85569+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ec231334-9ae9-426c-a0b1-08a591db6fea	8e61ecba-bc24-497f-993d-caafb64a5cdd	10	10	2026-04-28 01:11:04.279077+00	1025389a-0e27-4e08-b6a0-b188660bea57	
10e0a370-e71d-4741-a778-92509771ea39	a05449b5-aac3-47e1-a553-cdf056cd9b84	24	24	2026-04-28 01:11:04.703298+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b26d717f-a3cd-4068-bcbc-c51f184be45c	4eea0cf4-cf3a-4cd0-8b55-3cd4401df749	13	13	2026-04-28 01:11:05.125619+00	1025389a-0e27-4e08-b6a0-b188660bea57	
021d7f1b-dcb5-44c0-93c5-5a011b6c49e7	3e396474-4ce5-4df5-ac5e-6b1539cb3f47	11	11	2026-04-28 01:11:05.548764+00	1025389a-0e27-4e08-b6a0-b188660bea57	
87a25b54-539e-4432-86df-1e4803b65bec	7665dabf-565a-4bcb-83bd-04718798d3b2	12	12	2026-04-28 01:11:05.972074+00	1025389a-0e27-4e08-b6a0-b188660bea57	
04bd4d6c-14b1-43c1-a0ae-974665704eda	67175c6e-98e6-49d9-85f9-51afa619c367	17	17	2026-04-28 01:11:06.394258+00	1025389a-0e27-4e08-b6a0-b188660bea57	
8ac1f695-f4f5-4d2e-b48f-5f807504da53	5fbba159-c0e1-428d-885e-8b36393b142a	15	15	2026-04-28 01:11:06.816639+00	1025389a-0e27-4e08-b6a0-b188660bea57	
664414cd-0799-4d46-b0c2-6b661f55ccec	e7bb7518-e6bf-4e1e-a17a-3e52ea3af84a	16	16	2026-04-28 01:11:07.237762+00	1025389a-0e27-4e08-b6a0-b188660bea57	
675ede4b-e6e7-491d-acaa-3777ccc29436	ff4dc068-53d2-462f-b8c9-442e3e641f46			2026-04-28 01:11:07.659495+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e4cd6237-6192-4f5f-ae38-fec997614bb1	457e6aca-2f53-48e2-af80-d5d051112d16			2026-04-28 01:11:08.08099+00	1025389a-0e27-4e08-b6a0-b188660bea57	
439e7b38-0474-4f8c-86ce-b32b9023ee68	5a860c90-1941-42b4-b110-447ecd1b2574			2026-04-28 01:11:08.50243+00	1025389a-0e27-4e08-b6a0-b188660bea57	
277c5970-fefc-488e-8d85-5ee1022248a0	8bf8dfcd-78a6-407d-9f28-6f367bb693fb			2026-04-28 01:11:08.929397+00	1025389a-0e27-4e08-b6a0-b188660bea57	
389dd3dd-063a-4614-a4e4-bab62309c92a	89178d4f-c2ff-4222-aa73-03c610697e5c			2026-04-28 01:11:09.350666+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ec38f0b3-6655-4836-9c47-0a251fa7fab7	74ef35c2-e7ce-443e-aea6-4b406a4bd4ae			2026-04-28 01:11:09.77258+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3b7bbe60-0a1d-417c-afe1-e56fbae1cf4d	963fbe56-2c84-4d51-abd1-1072fd6d1213			2026-04-28 01:11:10.195318+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6063ec67-c211-4a48-8108-7379ef219de8	564f8e12-aa10-4213-abe2-9625c7f217b2	\N	123123	2026-04-28 10:36:14.14377+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b159376d-d073-474c-a0bb-5c3ea31fc4e0	38917227-211d-4943-b8ba-7cb2c3393c0e	\N	3123	2026-04-28 10:36:14.267905+00	1025389a-0e27-4e08-b6a0-b188660bea57	
fe92569d-4f11-421e-9bb6-4de610c398de	316158de-e6ed-4845-8979-e458553faefd	\N		2026-04-28 10:36:14.38924+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b78f6a9b-b324-4a0b-9129-331ad8a14851	23313888-8441-4779-bd79-83ee4cb3948e	\N		2026-04-28 10:36:14.510661+00	1025389a-0e27-4e08-b6a0-b188660bea57	
92354767-34ec-47fd-8656-34e8718b3eeb	7f7cc120-bc89-45cd-9240-ce8f230f91ba	\N		2026-04-28 10:36:14.632132+00	1025389a-0e27-4e08-b6a0-b188660bea57	
31c735f9-d889-4751-9892-05cffcc942f3	fe7c5c96-b9ff-459c-adb9-49ead1205e2f	\N		2026-04-28 10:36:14.754879+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5c11e685-3207-49e0-8982-2357c68b2f2e	4c1c9272-ea1a-4658-ae13-65edbec5b97d	\N		2026-04-28 10:36:14.996363+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6196e6cb-16d7-4a5a-b201-1bacea0d3396	3d727c5d-a4ae-4c25-9615-42f892a7d485	\N		2026-04-28 10:36:15.117753+00	1025389a-0e27-4e08-b6a0-b188660bea57	
149d5c42-6546-44c0-8e6e-5e51a472c306	3ba2543c-ebed-47b1-b756-a64a32d97d53	\N		2026-04-28 10:36:15.48384+00	1025389a-0e27-4e08-b6a0-b188660bea57	
43b6f7ef-e613-4355-87a3-d9cc122d64c4	9ba5e13a-e165-49a1-9dcc-c493828b38a8	\N		2026-04-28 10:36:15.604926+00	1025389a-0e27-4e08-b6a0-b188660bea57	
1ccee079-e97f-4c68-b182-94a07d699cb3	d5e2236c-c61f-4a93-920a-4f2d409eba40	\N		2026-04-28 10:36:15.725417+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2303e2db-778f-43be-a18f-6b92c0b69977	86f97f78-30cb-4721-8cfc-68a8d93fd835	\N		2026-04-28 10:36:15.845779+00	1025389a-0e27-4e08-b6a0-b188660bea57	
47ca6e9b-836b-4d8c-bb43-a258f3485024	6826e559-c971-49d0-ad9b-1071144594c0	\N		2026-04-28 10:36:15.966204+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a6c06130-3f04-4291-9de3-94983225db91	a4d23417-9064-4fb2-9849-08e89d03946c	\N		2026-04-28 10:36:16.337162+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e4c9fb81-081e-4b21-a74b-ea1c890549b0	f81149a7-adce-46a4-9d46-79b5c8d219bd	\N		2026-04-28 10:36:16.457282+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0fda3a17-dca6-4cf4-9ab5-310cb81b2d1e	96eefe11-90b8-4c82-923b-0e327cb0045f	\N		2026-04-28 10:36:16.577503+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5fcefa0b-5c4e-4951-856e-b79be9aae922	e23ef766-2b99-4a56-8b6b-82d066fb85c5	\N		2026-04-28 10:36:16.697335+00	1025389a-0e27-4e08-b6a0-b188660bea57	
68d0f876-0ab2-4bff-a212-d2b424cd9170	564f8e12-aa10-4213-abe2-9625c7f217b2	123123	123123	2026-04-28 10:36:20.614207+00	1025389a-0e27-4e08-b6a0-b188660bea57	
c40b5594-daff-4757-b24b-1ecd0149e30d	38917227-211d-4943-b8ba-7cb2c3393c0e	3123	3123	2026-04-28 10:36:20.686228+00	1025389a-0e27-4e08-b6a0-b188660bea57	
8806c23e-919e-49cc-8fdf-4afbecc9fc9d	316158de-e6ed-4845-8979-e458553faefd			2026-04-28 10:36:20.76253+00	1025389a-0e27-4e08-b6a0-b188660bea57	
39460bc0-602d-4398-b013-cb05573ac2c7	23313888-8441-4779-bd79-83ee4cb3948e			2026-04-28 10:36:20.834674+00	1025389a-0e27-4e08-b6a0-b188660bea57	
14aaf634-563c-44ce-ae39-78c4954d0b4a	7f7cc120-bc89-45cd-9240-ce8f230f91ba			2026-04-28 10:36:20.907147+00	1025389a-0e27-4e08-b6a0-b188660bea57	
739f19f9-d646-4aef-bc42-65c4a14af931	fe7c5c96-b9ff-459c-adb9-49ead1205e2f			2026-04-28 10:36:21.218822+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ad3a26cb-edaa-4f3c-8ed9-1ab71d08c861	09dcd708-fc87-456b-b4c6-8a6099de8c77			2026-04-28 10:36:21.291313+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6a95eafc-eec2-48eb-aa3f-7fc4cd39b67d	4c1c9272-ea1a-4658-ae13-65edbec5b97d			2026-04-28 10:36:21.364848+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4e630959-2f46-4b27-931c-9402518abc85	3d727c5d-a4ae-4c25-9615-42f892a7d485			2026-04-28 10:36:21.437438+00	1025389a-0e27-4e08-b6a0-b188660bea57	
7f0b1feb-d969-4d12-a9d2-2efd56f27a83	3ba2543c-ebed-47b1-b756-a64a32d97d53			2026-04-28 10:36:21.509765+00	1025389a-0e27-4e08-b6a0-b188660bea57	
faaff99f-b683-463e-9528-9b35bbc71478	9ba5e13a-e165-49a1-9dcc-c493828b38a8			2026-04-28 10:36:21.582409+00	1025389a-0e27-4e08-b6a0-b188660bea57	
dadee599-e545-4d68-817b-a0d69f5872be	d5e2236c-c61f-4a93-920a-4f2d409eba40			2026-04-28 10:36:21.654917+00	1025389a-0e27-4e08-b6a0-b188660bea57	
54e0ea7e-83ef-4775-81eb-d4b743526b5b	86f97f78-30cb-4721-8cfc-68a8d93fd835			2026-04-28 10:36:21.726917+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f06d046b-4803-4a74-a5fa-6949faec347a	6826e559-c971-49d0-ad9b-1071144594c0			2026-04-28 10:36:21.799417+00	1025389a-0e27-4e08-b6a0-b188660bea57	
9e30791a-de31-43e6-bbbc-e3440a75386d	a4d23417-9064-4fb2-9849-08e89d03946c			2026-04-28 10:36:21.871917+00	1025389a-0e27-4e08-b6a0-b188660bea57	
99bf303f-55e3-4114-bd86-aa0625be4cbf	f81149a7-adce-46a4-9d46-79b5c8d219bd			2026-04-28 10:36:21.944417+00	1025389a-0e27-4e08-b6a0-b188660bea57	
cc3d1520-d0c8-4734-a5bf-7e3d8a0bea1e	96eefe11-90b8-4c82-923b-0e327cb0045f			2026-04-28 10:36:22.016418+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4e6440e6-b244-4f70-81ab-0d92e1961a04	e23ef766-2b99-4a56-8b6b-82d066fb85c5			2026-04-28 10:36:22.089773+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a9014d25-a2f1-4434-8336-aa866d394901	7212c819-d4c0-49b4-974f-f6e8756e24d9	\N	10	2026-05-09 22:12:49.343966+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b61c3465-cb2c-4094-a7de-48eb4816b6ba	7ab59975-151f-48da-bc4d-dcbddc950ee5	\N	11	2026-05-09 22:12:49.982555+00	1025389a-0e27-4e08-b6a0-b188660bea57	
1d09b593-9ff8-4399-8781-719aafc2c0f7	e1d1386f-cf73-43b8-961b-cd899e64519a	\N	11	2026-05-09 22:12:50.620098+00	1025389a-0e27-4e08-b6a0-b188660bea57	
bc1792a1-dfd2-4906-a06b-f79622eeae0f	9de3c1c6-e87f-466b-9eca-787bf07a8dd7	\N	11	2026-05-09 22:12:51.258962+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f885d735-7c0d-415c-b4a6-d9e8488dd0dd	a4ccc9a4-b045-4c5b-8ae2-d94350ecc167	\N	11	2026-05-09 22:12:51.900463+00	1025389a-0e27-4e08-b6a0-b188660bea57	
8dc8fc79-501b-49de-9c3d-7bd4f14231ed	10333a80-4131-48ed-8e95-b8590c23829f	\N	11	2026-05-09 22:12:52.539324+00	1025389a-0e27-4e08-b6a0-b188660bea57	
252c073c-44c8-4b23-ad7e-9c5c651e816a	0aab7177-f4e8-4c13-9c55-0e31b0c4c90e	\N	11	2026-05-09 22:12:53.175737+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b7b368b7-5ee4-410f-bea4-53c225d9b96d	ec986ad5-7f22-436a-92c4-f1d320d443ab	\N	11	2026-05-09 22:12:53.813419+00	1025389a-0e27-4e08-b6a0-b188660bea57	
7bf3028e-d3aa-47b8-8489-e948142f14e3	827f53a5-1611-4e35-a160-3b6e20a56b2d	\N	11	2026-05-09 22:12:54.451224+00	1025389a-0e27-4e08-b6a0-b188660bea57	
50e7d28c-f2f8-41c1-8c37-1093f64d5cc8	69292957-328a-4138-a44f-ee09e5376a0a	\N	11	2026-05-09 22:12:55.090714+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a6453e0f-a912-4e4b-98ed-10421e5be727	e160f0ff-d468-4c95-b370-2be8f4d38cc4	\N	11	2026-05-09 22:12:55.728798+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b6992d0d-7209-44e3-98cf-e935b875cf07	07fd7b3f-6dcc-4c9e-8cc6-f373b0536d74	\N		2026-05-09 22:12:56.36827+00	1025389a-0e27-4e08-b6a0-b188660bea57	
de644f7e-28e0-4aa9-8187-edf96abc644f	be3b69f0-57ca-423b-afed-c967177e1e94	\N		2026-05-09 22:12:57.006424+00	1025389a-0e27-4e08-b6a0-b188660bea57	
7cc89989-ad89-4e83-83ea-967b3b7ec9c3	31f832ea-6b0d-46f8-8b76-94e7ca5ef0c4	\N		2026-05-09 22:12:57.643281+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f9633e00-6439-4fca-98b2-02f59e1a693d	90b49d19-521b-4a80-b8c5-2b945c4c1265	\N		2026-05-09 22:12:58.279215+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ca2f7088-0396-4293-9067-a4b93924eee7	74b4c03d-e898-4ce3-bfd1-9c4ea27a46dc	\N		2026-05-09 22:12:58.91556+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e4851374-6cc8-47e9-988d-ae5292d92111	239cdbd3-fff3-4407-840f-391738b7276e	\N		2026-05-09 22:12:59.552071+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a86a23bf-fcf6-4795-9632-8c3b976ae315	4818fc9a-0577-432c-99ad-186d8a5fed2e	\N		2026-05-09 22:13:00.187383+00	1025389a-0e27-4e08-b6a0-b188660bea57	
44c86919-a62f-4efc-8d1c-6349f2731d54	7212c819-d4c0-49b4-974f-f6e8756e24d9	10	10	2026-05-09 22:56:17.192086+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5109f676-988e-4bac-ac5c-764e0233dc2e	7ab59975-151f-48da-bc4d-dcbddc950ee5	11	11	2026-05-09 22:56:17.562313+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3a2b0713-30d2-4163-8a2e-c5834887834d	e1d1386f-cf73-43b8-961b-cd899e64519a	11	11	2026-05-09 22:56:17.93035+00	1025389a-0e27-4e08-b6a0-b188660bea57	
48dcb587-f652-48a0-b5e1-4e6f322eee59	9de3c1c6-e87f-466b-9eca-787bf07a8dd7	11	11	2026-05-09 22:56:18.300212+00	1025389a-0e27-4e08-b6a0-b188660bea57	
9004580f-e307-4092-b879-1826df6941a0	a4ccc9a4-b045-4c5b-8ae2-d94350ecc167	11	11	2026-05-09 22:56:18.668703+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3915af99-c81d-4c62-a3a1-c4b35613dcd2	10333a80-4131-48ed-8e95-b8590c23829f	11	11	2026-05-09 22:56:19.038709+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ccc64341-25bf-4103-9abf-ffb22f816d2c	0aab7177-f4e8-4c13-9c55-0e31b0c4c90e	11	11	2026-05-09 22:56:19.405986+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a5a44a8f-e072-4954-8a94-9e15c0315494	ec986ad5-7f22-436a-92c4-f1d320d443ab	11	11	2026-05-09 22:56:19.773953+00	1025389a-0e27-4e08-b6a0-b188660bea57	
224d4813-302c-4f27-977f-145f53445379	827f53a5-1611-4e35-a160-3b6e20a56b2d	11	11	2026-05-09 22:56:20.142198+00	1025389a-0e27-4e08-b6a0-b188660bea57	
cea71ae0-2db5-4467-8051-fcfc93174f4e	69292957-328a-4138-a44f-ee09e5376a0a	11	11	2026-05-09 22:56:20.510938+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d231855d-91a3-4feb-9e38-b47258e97b5b	e160f0ff-d468-4c95-b370-2be8f4d38cc4	11	11	2026-05-09 22:56:20.878937+00	1025389a-0e27-4e08-b6a0-b188660bea57	
56ea3c37-2a31-4b78-8dbe-253f740cf1d2	07fd7b3f-6dcc-4c9e-8cc6-f373b0536d74			2026-05-09 22:56:21.249494+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a1213e4b-9f25-4542-91c7-acbabaea4c48	be3b69f0-57ca-423b-afed-c967177e1e94			2026-05-09 22:56:21.618115+00	1025389a-0e27-4e08-b6a0-b188660bea57	
1579d40d-bf72-4019-9cf1-5f4f2e3282bb	31f832ea-6b0d-46f8-8b76-94e7ca5ef0c4			2026-05-09 22:56:21.986377+00	1025389a-0e27-4e08-b6a0-b188660bea57	
acb6b52f-38cb-42d2-a682-59bef0011530	90b49d19-521b-4a80-b8c5-2b945c4c1265			2026-05-09 22:56:22.357013+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2b974883-e802-495f-8e54-9cb88d11cd5b	74b4c03d-e898-4ce3-bfd1-9c4ea27a46dc			2026-05-09 22:56:22.724517+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5ad70870-d410-4901-b014-fb40cfebc005	239cdbd3-fff3-4407-840f-391738b7276e			2026-05-09 22:56:23.090898+00	1025389a-0e27-4e08-b6a0-b188660bea57	
362e35f2-f95f-4f71-b878-d90f54f740c6	4818fc9a-0577-432c-99ad-186d8a5fed2e			2026-05-09 22:56:23.457919+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2b77213b-97e6-4531-9316-5de82ea08df3	7212c819-d4c0-49b4-974f-f6e8756e24d9	10	10	2026-05-09 22:57:23.83954+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2b96bccb-7b8a-4ac4-b3d5-2ecfe56865c6	7ab59975-151f-48da-bc4d-dcbddc950ee5	11	11	2026-05-09 22:57:24.206717+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6044c58e-cbf7-44de-b9c3-b794eb1acaa2	e1d1386f-cf73-43b8-961b-cd899e64519a	11	11	2026-05-09 22:57:24.61007+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f1e09ada-3cf2-4690-b81d-c0b4154278a3	9de3c1c6-e87f-466b-9eca-787bf07a8dd7	11	11	2026-05-09 22:57:24.983444+00	1025389a-0e27-4e08-b6a0-b188660bea57	
1e396573-f104-4379-8206-4e9f873f2e7d	a4ccc9a4-b045-4c5b-8ae2-d94350ecc167	11	11	2026-05-09 22:57:25.351313+00	1025389a-0e27-4e08-b6a0-b188660bea57	
1164ca56-ef97-4d66-bdd0-a00dd201a638	10333a80-4131-48ed-8e95-b8590c23829f	11	11	2026-05-09 22:57:25.719889+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b1b7df24-cd5c-4a28-bb49-e59ca61be4ed	0aab7177-f4e8-4c13-9c55-0e31b0c4c90e	11	11	2026-05-09 22:57:26.087758+00	1025389a-0e27-4e08-b6a0-b188660bea57	
8ee07b55-458f-4fc7-b901-a415ad8426c8	ec986ad5-7f22-436a-92c4-f1d320d443ab	11	11	2026-05-09 22:57:26.455273+00	1025389a-0e27-4e08-b6a0-b188660bea57	
115bc016-28c1-4c25-beab-b93fbefc4d9f	827f53a5-1611-4e35-a160-3b6e20a56b2d	11	11	2026-05-09 22:57:26.823715+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2734387a-cb50-4f50-9dcc-056f9e12d7a3	69292957-328a-4138-a44f-ee09e5376a0a	11	11	2026-05-09 22:57:27.190643+00	1025389a-0e27-4e08-b6a0-b188660bea57	
c751e44a-c5cb-41c6-a921-2394ad7e79bd	e160f0ff-d468-4c95-b370-2be8f4d38cc4	11	11	2026-05-09 22:57:27.561443+00	1025389a-0e27-4e08-b6a0-b188660bea57	
31091f3c-b010-45dc-bc21-b32c6a8e6e70	07fd7b3f-6dcc-4c9e-8cc6-f373b0536d74			2026-05-09 22:57:27.92978+00	1025389a-0e27-4e08-b6a0-b188660bea57	
620d64f5-f97a-44e5-b6bc-317912939bbf	be3b69f0-57ca-423b-afed-c967177e1e94			2026-05-09 22:57:28.297094+00	1025389a-0e27-4e08-b6a0-b188660bea57	
7b1e0d92-d1d9-4f13-a2ba-7c44c8e25ae4	31f832ea-6b0d-46f8-8b76-94e7ca5ef0c4			2026-05-09 22:57:28.665823+00	1025389a-0e27-4e08-b6a0-b188660bea57	
38596093-a425-495e-a81d-16a758db4951	90b49d19-521b-4a80-b8c5-2b945c4c1265			2026-05-09 22:57:29.033232+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6360f8f7-e916-4cd2-8d22-035cd4cde2d8	74b4c03d-e898-4ce3-bfd1-9c4ea27a46dc			2026-05-09 22:57:29.401364+00	1025389a-0e27-4e08-b6a0-b188660bea57	
41bfac40-8780-4505-8d2f-27aaba7b6d12	239cdbd3-fff3-4407-840f-391738b7276e			2026-05-09 22:57:29.769306+00	1025389a-0e27-4e08-b6a0-b188660bea57	
7dba59e8-119e-4ac4-954b-2138cb5448b1	4818fc9a-0577-432c-99ad-186d8a5fed2e			2026-05-09 22:57:30.136374+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ca57b9ed-0f94-441a-8901-6ccc042becde	7e955e5d-a0af-454c-9123-7b6182d436b1	\N	4345	2026-05-14 07:19:06.442104+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4c64f34c-462f-48c5-810d-75daf65825fe	8f49265b-75bb-458d-9ce8-bbb5fe28d746	\N	5345	2026-05-14 07:19:06.643081+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2250c318-5058-42f6-8b2b-3810bd871b3e	835f55e7-2cae-477f-a6e4-557780e63ce0	\N		2026-05-14 07:19:06.847178+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4bbfcc2d-9057-4ff2-a194-96e6073f0142	9efe3997-7f10-46d8-9693-4996909ff78c	\N		2026-05-14 07:19:07.044328+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ad942d6b-ddd1-4263-a257-1c5469b46835	2406cbff-7a42-4bfc-a83d-520319bbf20d	\N		2026-05-14 07:19:07.243844+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f116ddda-8854-4694-933f-36c5dc22bec2	28327614-06f0-4e3c-9b39-4b417188b781	\N		2026-05-14 07:19:07.445574+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3800ceac-fd62-47c5-b027-d9ba90e14345	96ad00f3-1506-4619-b3ad-d5d2c930cbe1	\N		2026-05-14 07:19:07.647941+00	1025389a-0e27-4e08-b6a0-b188660bea57	
14b92c46-3322-4e06-9cf8-76ffbebc55e3	630e3f6a-0366-48ec-8211-39964d47db2e	\N		2026-05-14 07:19:07.847053+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a0756eee-93d9-4ade-b13b-948d7b8a7a01	baae7db6-b589-4b42-8e47-40e717f94e02	\N		2026-05-14 07:19:08.050152+00	1025389a-0e27-4e08-b6a0-b188660bea57	
bf9f2a66-c1b3-4a63-9710-3a6a892870f3	ecfa1e1e-6b0c-4851-b596-12b936c77e6b	\N		2026-05-14 07:19:08.250452+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d6c49ae9-df17-42ac-8f90-552b66c2792d	0137b52d-f3d8-4337-a0f6-39708a426e54	\N		2026-05-14 07:19:08.455716+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ef24272b-e2ad-4699-97f1-a175522b5281	2759030a-5ab2-44fa-9594-7c0dbf814b74	\N		2026-05-14 07:19:08.660267+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5ce9ec6c-10f9-4cf5-9ea7-f8df9535276a	42c50a63-9173-4eb2-95c3-b1f081b8f840	\N		2026-05-14 07:19:08.859275+00	1025389a-0e27-4e08-b6a0-b188660bea57	
181868db-64ae-4e98-965b-6aacb00a81aa	acad1d59-85e0-4e11-8487-a90de4c3291b	\N		2026-05-14 07:19:09.054551+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f563d630-a8d2-4e46-bbae-fb543cc56521	16468348-ea56-456c-a088-6b705abc8645	\N		2026-05-14 07:19:09.248134+00	1025389a-0e27-4e08-b6a0-b188660bea57	
b4fc4c54-625f-4f13-b3d7-76496b8638c1	32df9e44-8fc0-41a2-a336-423f54672381	\N		2026-05-14 07:19:09.447427+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5b6dcac7-9340-486f-b4a5-0b6362758252	72ca4fcb-8628-4859-9663-d95993108e59	\N		2026-05-14 07:19:09.64081+00	1025389a-0e27-4e08-b6a0-b188660bea57	
db3dbace-7e42-49e7-954f-0e1bf9ca1454	ff2f988c-d6fe-42b5-bf43-f16943179e97	\N		2026-05-14 07:19:09.835314+00	1025389a-0e27-4e08-b6a0-b188660bea57	
115560ee-bb36-4069-b75b-075aad2ad3a1	93bb1281-16c9-4f71-bc84-cb5c36f9a3d1	\N	4345	2026-05-14 07:20:07.985319+00	1025389a-0e27-4e08-b6a0-b188660bea57	
687315d2-7792-4746-8a86-3a5b5e1a9550	9ee86747-fb93-429b-840b-05d4af0513c0	\N	5345	2026-05-14 07:20:08.169691+00	1025389a-0e27-4e08-b6a0-b188660bea57	
cd2f52bc-b26b-4a12-9802-f720bb0ac63b	1f661d2d-6f7f-46cc-91e6-7c7c549f18a3	\N		2026-05-14 07:20:08.356431+00	1025389a-0e27-4e08-b6a0-b188660bea57	
89d96de8-e510-4a07-9221-7b02106e753a	5e907cad-4a89-41f7-be0b-918082ac64b7	\N		2026-05-14 07:20:08.558313+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ca5550bf-6c02-4ece-9d54-b1d372873a26	c1b7c1f8-073a-4215-ade5-7a02af6caf17	\N		2026-05-14 07:20:08.74518+00	1025389a-0e27-4e08-b6a0-b188660bea57	
cc05e958-5ccf-43b6-a256-0044e554a4d0	3c28ffe4-a6ae-46ef-a62e-1a481361306f	\N		2026-05-14 07:20:08.922056+00	1025389a-0e27-4e08-b6a0-b188660bea57	
227c8b48-a156-4b6a-b68e-ff558837b791	ee1e0e30-1817-4e13-bcc4-4d191e65717f	\N		2026-05-14 07:20:09.122816+00	1025389a-0e27-4e08-b6a0-b188660bea57	
34cfcf93-c697-430c-801d-56d4b31b4899	19304a15-3627-4f87-ab31-58e8d710ac0a	\N		2026-05-14 07:20:09.319944+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a0ce5403-fbea-4fea-b76d-9c0d177b00f9	2c3f8516-899e-470d-980d-718d80cbec92	\N		2026-05-14 07:20:09.51884+00	1025389a-0e27-4e08-b6a0-b188660bea57	
709375d0-4906-4d0d-8dba-8f66765c2e2c	0bb8cea7-f0f0-43ad-893d-00838806c27c	\N		2026-05-14 07:20:09.709518+00	1025389a-0e27-4e08-b6a0-b188660bea57	
71b5787b-dfac-4bc3-a0e6-c8f89891598b	a393b046-5307-4ce8-8711-0dc0edfe9f9d	\N		2026-05-14 07:20:09.903795+00	1025389a-0e27-4e08-b6a0-b188660bea57	
09cd1ee6-439a-4275-a3e4-dc69050a25e6	5b4df87a-062e-4d5e-8345-15213f449180	\N		2026-05-14 07:20:10.092188+00	1025389a-0e27-4e08-b6a0-b188660bea57	
58738c63-d4a6-463d-a08c-08b23e33d986	a4369e80-217a-4ff7-9ae8-754803b0ec89	\N		2026-05-14 07:20:10.282047+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5600c134-a252-4f34-9cad-e6f6060f04b2	fc5022fc-b8f0-4ef5-a0f4-49aa2ac40601	\N		2026-05-14 07:20:10.468945+00	1025389a-0e27-4e08-b6a0-b188660bea57	
740fd4fa-40e2-441f-aa1d-2d962d09c8ca	bc04c2b8-f2f3-438b-9dd9-5439c45dcce2	\N		2026-05-14 07:20:10.659929+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4e760a8d-1c1b-445e-aa43-5855316cf491	9f28d0b7-aba9-4361-a43b-e79024cdc9ed	\N		2026-05-14 07:20:10.847502+00	1025389a-0e27-4e08-b6a0-b188660bea57	
5977454a-bd42-46e4-9a63-75abbdad9808	c733f10d-2711-41fd-9f1f-18242ed4263b	\N		2026-05-14 07:20:11.03917+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e6514e90-141c-42fb-af9d-485a69063523	b93a9d3a-bb86-4eb5-a417-f1870545117b	\N		2026-05-14 07:20:11.231318+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ba4f0092-6a94-4000-84ac-e8db89a9d046	6968400e-7810-4109-aa53-4dc9e592f2cf	\N		2026-05-29 12:00:05.227033+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e0cbd8b4-3a78-4369-b264-7f5230df9512	9819ef6e-3991-4ec7-bfa7-ef73f574fec5	\N		2026-05-29 12:00:06.065415+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0eb41710-f963-44d6-a8c7-c326b6643544	f56c9326-e5e4-4734-a32d-e76e3ced3a5b	\N		2026-05-29 12:00:06.895734+00	1025389a-0e27-4e08-b6a0-b188660bea57	
701f4094-e061-4c60-a782-7102524c60b3	1e7d73fb-32fc-4719-9612-dbe41b36e000	\N		2026-05-29 12:00:07.726412+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f2673198-10e6-4012-96c4-be48f208747e	a151628d-63e2-41ec-9d0c-9da67b8df88b	\N		2026-05-29 12:00:08.557481+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e4b6a288-e43b-4421-9c6f-1e3ff4799289	9f537405-2762-4644-b8b9-3bbed52dbdf6	\N		2026-05-29 12:00:09.387709+00	1025389a-0e27-4e08-b6a0-b188660bea57	
82685c9e-0d6f-4330-a2d4-d0b6fe75f145	fa551e90-1b5f-4d8b-909f-44b5cdfa252a	\N		2026-05-29 12:00:10.217437+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0015ff92-7bb6-4483-9950-e960b6cf8db6	d0c9effa-2909-45b8-b750-c94e2104c503	\N		2026-05-29 12:00:11.0458+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6541519f-6f6f-45b3-93d2-fc5710661567	f677f803-a3c4-4396-a952-de93945a3da2	\N		2026-05-29 12:00:11.874875+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4e4accb4-953f-45db-9aad-7a0e05ccf071	b9adb28d-819b-4283-96a4-86857d7b4076	\N		2026-05-29 12:00:12.704501+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e1f97129-f3d8-4c0c-8520-c7aa93291a18	991907d0-ab65-4053-aebc-9b25f9437240	\N		2026-05-29 12:00:13.534379+00	1025389a-0e27-4e08-b6a0-b188660bea57	
238763fb-8088-4808-8b75-89706bbee6ae	f6336741-e97d-4fb9-9bb3-193de911d735	\N		2026-05-29 12:00:14.362088+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d37c0337-b89e-43f0-85db-15b710f3e493	e7d6a49c-c07f-4a48-ac67-5ae877f64f96	\N		2026-05-29 12:00:15.189996+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ae806508-507c-48d4-a415-b1f0ebc80c6c	6aa235e0-5e1b-409e-a68b-4e4260152027	\N		2026-05-29 12:00:16.018443+00	1025389a-0e27-4e08-b6a0-b188660bea57	
555391aa-5686-433e-8164-bd1e9241ed86	ce857b67-3a08-406a-9497-e8c3134a3773	\N		2026-05-29 12:00:16.847749+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4c83795c-c164-4689-a290-9b4645ac90ac	fce4fad3-11a0-48d4-91a2-fc0105a95ea5	\N		2026-05-29 12:00:17.676242+00	1025389a-0e27-4e08-b6a0-b188660bea57	
bd47b55d-076e-40df-8496-e2e850552e79	dd150348-875b-4048-ad43-bea9b2c7c56d	\N		2026-05-29 12:00:18.504277+00	1025389a-0e27-4e08-b6a0-b188660bea57	
319bdf93-8875-4fcb-a709-ee3e81ab8656	3bef1bb2-4a96-4a00-9010-36b229880d02	\N		2026-05-29 12:00:19.332929+00	1025389a-0e27-4e08-b6a0-b188660bea57	
91d0bdae-5e00-4333-8cf1-b332f83d3947	6a5a659f-0a8f-437c-a0d8-10d53caa3698	\N	10	2026-05-30 04:00:46.846273+00	56d79006-412e-4a1a-ab42-da5509b64260	
277b751a-f417-4618-9375-d30eab1003c7	96f138bb-0020-4740-a344-1119d294aaae	\N	10	2026-05-30 04:00:47.352582+00	56d79006-412e-4a1a-ab42-da5509b64260	
6b14504f-f964-4c58-8618-6c64383a5f20	eebc91af-b893-43bc-880e-b658a2f3062b	\N	10	2026-05-30 04:00:47.858052+00	56d79006-412e-4a1a-ab42-da5509b64260	
0a5aa9b4-3fab-4240-a753-88bc0484ec96	7a3b06ba-968a-4238-8607-c0359e492c39	\N	10	2026-05-30 04:00:48.363463+00	56d79006-412e-4a1a-ab42-da5509b64260	
0587073b-dca3-42ef-86f6-89f66388fb61	1eab4ef2-ec46-47bd-a3a5-5e0ebeac78be	\N	10	2026-05-30 04:00:48.92075+00	56d79006-412e-4a1a-ab42-da5509b64260	
3531926d-f003-4dcc-803f-c636965410bb	c0d1e765-8f7f-4e4c-88d4-5646a5e64b94	\N	10	2026-05-30 04:00:49.427179+00	56d79006-412e-4a1a-ab42-da5509b64260	
2a249d80-f2ac-44d7-899d-cfffa3197ce5	0ee0cf2c-eb79-4eae-9eaf-101480036b82	\N	10	2026-05-30 04:00:49.939209+00	56d79006-412e-4a1a-ab42-da5509b64260	
338548fe-5729-4781-80ea-39c0200d507e	670b5e94-ff10-4d3b-860b-9d64ba220485	\N	10	2026-05-30 04:00:50.444522+00	56d79006-412e-4a1a-ab42-da5509b64260	
a9a76c14-6a77-4be8-908c-c4824e33ad60	855f7fb1-0333-4eac-81f7-67a7f299a077	\N		2026-05-30 04:00:50.950401+00	56d79006-412e-4a1a-ab42-da5509b64260	
298463ad-86a9-4bb6-8912-b3b3485f0c4f	cbf8e24c-9a97-4ca2-8fb9-f04c74ed47b4	\N		2026-05-30 04:00:51.456757+00	56d79006-412e-4a1a-ab42-da5509b64260	
97afc850-d215-43c9-b0f0-e6457e227ee9	385a0994-c14e-4fd5-845c-e3ef53d7ea97	\N		2026-05-30 04:00:51.959964+00	56d79006-412e-4a1a-ab42-da5509b64260	
e9a3123f-8f9d-417a-a20a-dad62d3389cb	3798923a-a661-43c9-8662-d6b640f6d370	\N		2026-05-30 04:00:52.464931+00	56d79006-412e-4a1a-ab42-da5509b64260	
02552404-21ae-4364-b825-8b4b4c9d4840	4fe4f665-8608-4cde-b750-77e38421b7d8	\N		2026-05-30 04:00:52.968458+00	56d79006-412e-4a1a-ab42-da5509b64260	
885ddbf8-7d14-4acc-aec2-48f10b800474	b41d05a6-d7a5-4737-893b-bb5bc82449e5	\N		2026-05-30 04:00:53.473927+00	56d79006-412e-4a1a-ab42-da5509b64260	
cadbd826-c49d-4f02-b592-620d9d9ac592	be20e633-b98c-4034-90de-bbe74cc43c06	\N		2026-05-30 04:00:53.979362+00	56d79006-412e-4a1a-ab42-da5509b64260	
eab3c03a-fc67-443e-9ded-4dda0556e78a	c2f5f5e5-2221-4565-a79a-0bc26d4fc375	\N		2026-05-30 04:00:54.487285+00	56d79006-412e-4a1a-ab42-da5509b64260	
90cd0a53-8f42-448f-a941-0395fb3bb21f	06e86f99-6d80-451a-819e-eccffd19829a	\N		2026-05-30 04:00:54.989702+00	56d79006-412e-4a1a-ab42-da5509b64260	
a5968747-25e2-4b3b-a660-db75e185117b	fdaf5aee-b2a4-4868-92d2-1d814c7a1f44	\N		2026-05-30 04:00:55.49277+00	56d79006-412e-4a1a-ab42-da5509b64260	
3a8468f3-c280-4859-8582-b51fd07aac17	6a5a659f-0a8f-437c-a0d8-10d53caa3698	10	10	2026-05-30 04:03:03.890089+00	56d79006-412e-4a1a-ab42-da5509b64260	
34d2412a-47e5-4c16-a7e5-ed882851ee89	96f138bb-0020-4740-a344-1119d294aaae	10	10	2026-05-30 04:03:04.193488+00	56d79006-412e-4a1a-ab42-da5509b64260	
7c2d36d0-bcec-4197-815d-740068c38018	eebc91af-b893-43bc-880e-b658a2f3062b	10	10	2026-05-30 04:03:04.49904+00	56d79006-412e-4a1a-ab42-da5509b64260	
d9886d2e-483d-45e8-a9c0-fd0a0a3eb9c6	7a3b06ba-968a-4238-8607-c0359e492c39	10	10	2026-05-30 04:03:04.802051+00	56d79006-412e-4a1a-ab42-da5509b64260	
0cb0ccc4-f590-4723-9e6a-3c931819646b	1eab4ef2-ec46-47bd-a3a5-5e0ebeac78be	10	10	2026-05-30 04:03:05.105378+00	56d79006-412e-4a1a-ab42-da5509b64260	
b46548f7-3ef8-4fa3-9bf2-081bb346950e	c0d1e765-8f7f-4e4c-88d4-5646a5e64b94	10	10	2026-05-30 04:03:05.409165+00	56d79006-412e-4a1a-ab42-da5509b64260	
b86b4adf-6fca-4fcf-97d3-c629e3ef89d2	0ee0cf2c-eb79-4eae-9eaf-101480036b82	10	10	2026-05-30 04:03:05.714526+00	56d79006-412e-4a1a-ab42-da5509b64260	
6face375-e326-4493-ab0d-c02775e99eca	670b5e94-ff10-4d3b-860b-9d64ba220485	10	10	2026-05-30 04:03:06.015648+00	56d79006-412e-4a1a-ab42-da5509b64260	
aeffe892-074e-4be7-80e5-5f2452ba06a2	855f7fb1-0333-4eac-81f7-67a7f299a077			2026-05-30 04:03:06.322414+00	56d79006-412e-4a1a-ab42-da5509b64260	
1f3b834c-4d43-4f16-bbea-a345cadb32b0	cbf8e24c-9a97-4ca2-8fb9-f04c74ed47b4			2026-05-30 04:03:06.632654+00	56d79006-412e-4a1a-ab42-da5509b64260	
2900e3f2-0e68-4267-bac2-6e378da8d3ba	385a0994-c14e-4fd5-845c-e3ef53d7ea97			2026-05-30 04:03:06.934488+00	56d79006-412e-4a1a-ab42-da5509b64260	
5714b6a1-0663-4a5d-a34c-37ffd837174e	3798923a-a661-43c9-8662-d6b640f6d370			2026-05-30 04:03:07.238682+00	56d79006-412e-4a1a-ab42-da5509b64260	
a66d40f0-6dbc-4756-b956-951053d689ae	4fe4f665-8608-4cde-b750-77e38421b7d8			2026-05-30 04:03:07.540005+00	56d79006-412e-4a1a-ab42-da5509b64260	
37210fed-94ae-4c0d-a263-824d0db885d8	b41d05a6-d7a5-4737-893b-bb5bc82449e5			2026-05-30 04:03:07.842034+00	56d79006-412e-4a1a-ab42-da5509b64260	
37e9de04-62b8-40a9-938b-5418ce372f33	be20e633-b98c-4034-90de-bbe74cc43c06			2026-05-30 04:03:08.143616+00	56d79006-412e-4a1a-ab42-da5509b64260	
7717c064-3f76-43a5-84be-50af5e3bfed8	c2f5f5e5-2221-4565-a79a-0bc26d4fc375			2026-05-30 04:03:08.445036+00	56d79006-412e-4a1a-ab42-da5509b64260	
44e09fcc-437d-4e4f-8407-37e253fcfd66	06e86f99-6d80-451a-819e-eccffd19829a			2026-05-30 04:03:08.751783+00	56d79006-412e-4a1a-ab42-da5509b64260	
d2ccfcae-3527-43f5-b72b-5dee5e3f961f	fdaf5aee-b2a4-4868-92d2-1d814c7a1f44			2026-05-30 04:03:09.053095+00	56d79006-412e-4a1a-ab42-da5509b64260	
de299838-ad86-4d69-9823-de606ddab3c4	1e87af3b-db39-49b6-8812-78371c0e9502	\N	11	2026-05-30 04:04:34.041972+00	56d79006-412e-4a1a-ab42-da5509b64260	
eb1ce943-49c8-4814-a19d-938c57bf905e	e2e8c435-c614-4480-a081-20dc6db7eefa	\N	11	2026-05-30 04:04:34.543658+00	56d79006-412e-4a1a-ab42-da5509b64260	
d2d1ec40-d278-4692-a66d-d14fc4310fc1	180f6e06-33bc-4d45-a688-9126358c9a56	\N	11	2026-05-30 04:04:35.046468+00	56d79006-412e-4a1a-ab42-da5509b64260	
0e766e72-486d-41a5-8100-89387bbea520	ad21d3ee-31c5-485e-9405-9f68cb78e51e	\N	11	2026-05-30 04:04:35.552593+00	56d79006-412e-4a1a-ab42-da5509b64260	
6d4e54be-18f6-43ea-8b71-0856e5c5947b	f546a592-8013-4b30-8dcb-32360c14664f	\N	11	2026-05-30 04:04:36.058698+00	56d79006-412e-4a1a-ab42-da5509b64260	
88dd6b43-b08f-4668-b60c-1467d8ef347a	d0d07f52-5012-47b4-b1b6-95cc298de2a5	\N	11	2026-05-30 04:04:36.55939+00	56d79006-412e-4a1a-ab42-da5509b64260	
13f85fcc-49e4-44e8-9843-aca0c6a5b9bc	f4a69501-df87-4868-a6bb-2f0f33e59741	\N	11	2026-05-30 04:04:37.062906+00	56d79006-412e-4a1a-ab42-da5509b64260	
3ebec8fb-ff00-44d3-b803-e32296674925	b87b4b7e-b4ab-4b43-bde7-49cb6546fc47	\N	11	2026-05-30 04:04:37.562903+00	56d79006-412e-4a1a-ab42-da5509b64260	
c2042d2b-aa7e-4c5f-9d06-315623251b1d	37e581b6-1cb8-4b60-8d3a-aa90ad479a29	\N		2026-05-30 04:04:38.064152+00	56d79006-412e-4a1a-ab42-da5509b64260	
265caf7c-4526-4d1a-83aa-184d5287001a	09e8d99d-715e-418e-81db-f489ef55357e	\N		2026-05-30 04:04:38.570442+00	56d79006-412e-4a1a-ab42-da5509b64260	
02c58c6a-b19d-489f-81db-a6f504eda2dc	77a1634f-a61d-4542-b3d1-1e190961e9ac	\N		2026-05-30 04:04:39.07161+00	56d79006-412e-4a1a-ab42-da5509b64260	
c9d54950-22ee-4f5f-a04f-35f0056fdf22	a3aedc0f-7937-4917-8875-43a890fc989e	\N		2026-05-30 04:04:39.576466+00	56d79006-412e-4a1a-ab42-da5509b64260	
ad312a12-c79e-4992-ae3e-eef63fc68194	bd2deb54-9697-469d-bae3-f366398c5659	\N		2026-05-30 04:04:40.076629+00	56d79006-412e-4a1a-ab42-da5509b64260	
2661ea27-7ab9-4a23-af4b-cfde2cca6be8	e7ecd027-bd38-456d-8e64-1516623a249e	\N		2026-05-30 04:04:40.587467+00	56d79006-412e-4a1a-ab42-da5509b64260	
4cf3fa1e-71ce-47de-9d87-0752b3d2d602	b6135674-0a96-48a0-b638-dc91598ab85b	\N		2026-05-30 04:04:41.09397+00	56d79006-412e-4a1a-ab42-da5509b64260	
de6a949b-84fb-4097-9ff8-b5ea10f6a87d	e037aef0-f662-44c7-9359-3fba8220cbda	\N		2026-05-30 04:04:41.59983+00	56d79006-412e-4a1a-ab42-da5509b64260	
d3257cbc-dffa-47c0-8c9d-57da00d728c7	3c850e71-88f8-4cab-b331-d0c94b6a0f09	\N		2026-05-30 04:04:42.105727+00	56d79006-412e-4a1a-ab42-da5509b64260	
c6c82b5d-bcd5-4d96-bce6-0fa8164cb207	aa500f0c-1f64-4a06-a5fa-0670026e58e5	\N		2026-05-30 04:04:42.612089+00	56d79006-412e-4a1a-ab42-da5509b64260	
c940bb8f-b6e2-40fc-88dd-2d4540ccbd61	c0ffdc03-90cd-40e9-bbe2-affebd37792b	\N	11	2026-05-30 04:07:22.638295+00	56d79006-412e-4a1a-ab42-da5509b64260	
bade4745-edd8-469b-ac40-6efed4cb5f57	28c28fb3-5aee-4454-9c41-dbda5ee67443	\N	11	2026-05-30 04:07:23.194823+00	56d79006-412e-4a1a-ab42-da5509b64260	
b0d94256-3332-45fe-8373-a8182b9ee251	a2c86782-f356-478a-b435-8365bba7536e	\N	11	2026-05-30 04:07:23.7046+00	56d79006-412e-4a1a-ab42-da5509b64260	
ce5721ba-3b11-4a49-841c-2d87e35aabb1	24a5454b-92d6-48ae-a02b-de8b0c5457dc	\N	11	2026-05-30 04:07:24.212013+00	56d79006-412e-4a1a-ab42-da5509b64260	
a25ef705-991c-452e-aef9-61c8145a2f50	47dab6b8-d896-424d-a14a-1cc56cf1f36f	\N	11	2026-05-30 04:07:24.721556+00	56d79006-412e-4a1a-ab42-da5509b64260	
0bc6cd55-b8cc-4c60-be19-d261e7066513	ff76e4e0-4ea9-4953-851c-99eb5aaa8c50	\N	11	2026-05-30 04:07:25.233575+00	56d79006-412e-4a1a-ab42-da5509b64260	
7b3d2967-f54f-48aa-82d1-0334b2a97bd7	3cfd26f5-9617-426f-8983-a99634024daf	\N	11	2026-05-30 04:07:25.739588+00	56d79006-412e-4a1a-ab42-da5509b64260	
b770bd45-ac48-427d-8e16-05f7ec3465cf	590cb9c4-c7dc-4adb-a5f0-6405d5696855	\N	11	2026-05-30 04:07:26.256739+00	56d79006-412e-4a1a-ab42-da5509b64260	
f6f31504-c502-4dd1-b40c-c5fca8628fad	4b7e34c4-819c-40c3-80f6-415eb36e5c74	\N		2026-05-30 04:07:26.774796+00	56d79006-412e-4a1a-ab42-da5509b64260	
7ceb6d07-7d78-47e4-ba94-af1207608bb8	cbf33380-271c-422d-a0db-cb44afacd5eb	\N		2026-05-30 04:07:27.283069+00	56d79006-412e-4a1a-ab42-da5509b64260	
53bceb23-2040-4649-af5e-e1a62b4cf6ff	aa77c129-a216-4e41-ad07-2814825f54bc	\N		2026-05-30 04:07:27.788862+00	56d79006-412e-4a1a-ab42-da5509b64260	
fc03beff-3cc6-4831-989d-de76c5c860f1	63c13870-f901-47ce-9a1f-1b12b3b2d598	\N		2026-05-30 04:07:28.295073+00	56d79006-412e-4a1a-ab42-da5509b64260	
cf533416-1d46-4c83-93ab-a0a098126c1d	aa21462c-9589-41be-a0dc-d058e2014318	\N		2026-05-30 04:07:28.798939+00	56d79006-412e-4a1a-ab42-da5509b64260	
9d78402d-1bd5-42b2-9cf4-6638b6571bfc	a1564990-5587-44ac-bcc9-16e9963d86a9	\N		2026-05-30 04:07:29.302786+00	56d79006-412e-4a1a-ab42-da5509b64260	
6f5bb3ea-afee-4512-8426-ba7883c1b5e8	af77c8bd-67cd-4617-a053-41b2b9811628	\N		2026-05-30 04:07:29.814985+00	56d79006-412e-4a1a-ab42-da5509b64260	
6992474f-bd90-4e27-a82d-6e706cbe1a22	fd1b1942-e49f-44e1-b85b-5ded40a3847e	\N		2026-05-30 04:07:30.32712+00	56d79006-412e-4a1a-ab42-da5509b64260	
1642d930-f1a8-4ca1-b407-3426ea2d943b	ca2180af-924d-4d23-abdc-d84431efcfb2	\N		2026-05-30 04:07:30.844004+00	56d79006-412e-4a1a-ab42-da5509b64260	
ee9a6c23-df8c-4a25-922a-51eb4b776f8f	e894b0d0-fec0-480f-8829-1604d821b240	\N		2026-05-30 04:07:31.350541+00	56d79006-412e-4a1a-ab42-da5509b64260	
02d15e2f-6444-46f8-ab43-70afc7aef74c	398de6d3-82c8-4271-a8db-ef04beec12dd	\N	11	2026-05-30 05:06:42.540954+00	56d79006-412e-4a1a-ab42-da5509b64260	
7da46b85-7cce-4505-9969-0d685da553aa	691097d2-b499-4330-9940-feef608b0785	\N	11	2026-05-30 05:06:43.0479+00	56d79006-412e-4a1a-ab42-da5509b64260	
8873c802-7569-41aa-a57b-d989e64a0caa	6c2e3257-7801-47b9-82bc-1e2cc6efc234	\N	11	2026-05-30 05:06:43.551139+00	56d79006-412e-4a1a-ab42-da5509b64260	
a7ab27f3-23c1-4459-a2b6-9cdcd1f705a4	c0b6d6dd-7724-4d87-8bf8-623c7f31a78b	\N	11	2026-05-30 05:06:44.055006+00	56d79006-412e-4a1a-ab42-da5509b64260	
8833d1d5-d0a8-4dfd-8da0-cdda241547da	edb8e434-6f30-431b-8d87-151c3dd75702	\N	11	2026-05-30 05:06:44.557129+00	56d79006-412e-4a1a-ab42-da5509b64260	
1dbe59f3-4425-458c-89ca-23a70656488d	4c82e4df-a263-4441-9ab9-d89d6d665ffb	\N	11	2026-05-30 05:06:45.060075+00	56d79006-412e-4a1a-ab42-da5509b64260	
39431312-889d-468a-af8b-c344e728616b	d3b27acf-8cea-4b72-a0a5-4d3917ad804d	\N	11	2026-05-30 05:06:45.563232+00	56d79006-412e-4a1a-ab42-da5509b64260	
97ff1de8-f900-42e5-83a9-d4a0bbf1b1d3	2f3ecb01-0149-453b-90e6-0a62c2b48b00	\N	11	2026-05-30 05:06:46.065472+00	56d79006-412e-4a1a-ab42-da5509b64260	
685f8811-279c-491a-8fea-886509decd7d	620a9ec8-8879-4a75-a1c5-55a9718371a6	\N	11	2026-05-30 05:06:46.566728+00	56d79006-412e-4a1a-ab42-da5509b64260	
c1de3943-95d2-46df-a7db-92367c3e27d8	4c36d620-5c0d-4029-90a3-c5d6bc221a74	\N	11	2026-05-30 05:06:47.071053+00	56d79006-412e-4a1a-ab42-da5509b64260	
c6923aff-ed0c-4a60-9218-89c640adb996	25948ef1-1dff-4477-904e-1f750caaebb2	\N	11	2026-05-30 05:06:47.572078+00	56d79006-412e-4a1a-ab42-da5509b64260	
c619aa6d-c218-4017-aee5-51cf145fa0c0	cf242bc4-ee6c-4ec9-9131-04993e9af56f	\N		2026-05-30 05:06:48.072479+00	56d79006-412e-4a1a-ab42-da5509b64260	
f95e7180-8978-49a2-b696-7cbc1bd46871	d734032b-f189-42aa-86a3-b45e2b132093	\N		2026-05-30 05:06:48.572807+00	56d79006-412e-4a1a-ab42-da5509b64260	
d0115969-6fc4-4b91-8c89-ccf08ab1e872	dbc3e1ae-5108-4084-8f7e-ca565d7153b9	\N		2026-05-30 05:06:49.073546+00	56d79006-412e-4a1a-ab42-da5509b64260	
50c0d402-fae9-4941-bc91-dde0869e8744	ed1ed8a2-5d46-4a91-8c65-b0e43cfff298	\N		2026-05-30 05:06:49.575495+00	56d79006-412e-4a1a-ab42-da5509b64260	
321cb22d-3119-49f6-ba32-348118c857d7	c0dd86fb-5c6c-49b3-9ec4-316f203b88a0	\N		2026-05-30 05:06:50.078318+00	56d79006-412e-4a1a-ab42-da5509b64260	
c39a2028-fc9d-4835-8ec5-1ee801c157cd	df508482-8a6b-4219-869f-7ed0b8eb5671	\N		2026-05-30 05:06:50.579522+00	56d79006-412e-4a1a-ab42-da5509b64260	
0212ad72-08a8-4f13-8d06-ee083248b9ae	9ce48ebc-2007-49ca-82d9-145eed19e080	\N		2026-05-30 05:06:51.081757+00	56d79006-412e-4a1a-ab42-da5509b64260	
b805df27-8faf-44ef-a673-bbc2c71f3b2b	b03000ec-6c30-4bac-8fa6-b24661da4b15	\N	11	2026-05-30 05:09:13.775223+00	56d79006-412e-4a1a-ab42-da5509b64260	
96e41111-4107-43c2-9796-fdd39e763da8	487867b4-e795-4dd4-bb9c-a57c67d8fec0	\N	11	2026-05-30 05:09:14.287427+00	56d79006-412e-4a1a-ab42-da5509b64260	
d7a4ae9f-b073-41b7-b645-ef379bc0a743	314af991-477d-4639-a9cb-1410cffa8de6	\N	11	2026-05-30 05:09:14.789938+00	56d79006-412e-4a1a-ab42-da5509b64260	
f81bc37b-49f6-44e8-9f33-6aea8a319532	1cd0fb11-51be-4388-847c-9ba6c6cf3dbc	\N	11	2026-05-30 05:09:15.302157+00	56d79006-412e-4a1a-ab42-da5509b64260	
593dcaa6-3d5c-4305-8f36-bb5e2f51c599	b5e94dad-1da0-4d08-bb96-ec27080966c2	\N	11	2026-05-30 05:09:15.812541+00	56d79006-412e-4a1a-ab42-da5509b64260	
f2845c30-a746-44f5-8199-3aec853d7cee	e803b127-4e64-4cc0-9252-196da8836db1	\N	11	2026-05-30 05:09:16.315051+00	56d79006-412e-4a1a-ab42-da5509b64260	
0c446a25-f4c2-4eb8-a3ce-9006b5ced926	13d3a7f4-6a91-43b3-a686-11888793ae22	\N	11	2026-05-30 05:09:16.817098+00	56d79006-412e-4a1a-ab42-da5509b64260	
b1dd3fdc-69f2-4920-8c47-c03a63c4ea57	0492b595-b288-469d-ad83-f67d86ca84d9	\N	11	2026-05-30 05:09:17.31803+00	56d79006-412e-4a1a-ab42-da5509b64260	
f4b80cd8-e98a-4555-b874-2a26f8daa1af	584994b5-bb1d-43b3-8cad-207f14d17997	\N	11	2026-05-30 05:09:17.819012+00	56d79006-412e-4a1a-ab42-da5509b64260	
60724afa-5ebc-4f3c-84d5-216916c4451b	934b03a7-4b76-4116-a44f-cd9a5cdcd7b7	\N	11	2026-05-30 05:09:18.32248+00	56d79006-412e-4a1a-ab42-da5509b64260	
15297c69-4609-4724-809b-9120b2643c83	48e0b781-3a8a-40c1-bf94-71f441e31614	\N	11	2026-05-30 05:09:18.828814+00	56d79006-412e-4a1a-ab42-da5509b64260	
3d7bae41-71db-4edb-8d9a-5bf195365d78	1ea7de41-462e-4440-a3e1-19db95c3a94a	\N		2026-05-30 05:09:19.329232+00	56d79006-412e-4a1a-ab42-da5509b64260	
c2c08001-095a-4138-aa41-608c46914fb6	e42d40c8-95f1-4c88-bca6-dabaaa047b94	\N		2026-05-30 05:09:19.829721+00	56d79006-412e-4a1a-ab42-da5509b64260	
d877f786-2530-4c92-b3ba-6acc839ac5df	14665b74-915a-4c6c-b8ff-28d8577af2ab	\N		2026-05-30 05:09:20.331283+00	56d79006-412e-4a1a-ab42-da5509b64260	
3094163e-03b4-4455-b8e4-8b970127a463	4e9aa3dd-1b17-4ca8-8558-a0dddc1da0fd	\N		2026-05-30 05:09:20.835878+00	56d79006-412e-4a1a-ab42-da5509b64260	
5fdb30c5-0246-42ea-b717-8f81435a4aa9	45cad878-6f60-4336-b911-c49852d46417	\N		2026-05-30 05:09:21.344297+00	56d79006-412e-4a1a-ab42-da5509b64260	
08930bea-07b1-43ae-b407-4c93f2ad72f2	a1dece92-6729-4ffb-951a-4278206004a0	\N		2026-05-30 05:09:21.846172+00	56d79006-412e-4a1a-ab42-da5509b64260	
2971e970-c6ac-4bef-b034-fdf11516de55	d4b62998-0889-4ea8-939f-0356836f42b0	\N		2026-05-30 05:09:22.34804+00	56d79006-412e-4a1a-ab42-da5509b64260	
163bbbd2-3123-401c-abf3-0721687585fd	732a7019-f524-43a0-ab1d-9bc99f2daafc	\N	11	2026-05-30 06:02:53.304474+00	56d79006-412e-4a1a-ab42-da5509b64260	
aa5b4023-d90b-4dce-b56b-96042dd98d6c	2529b027-8d47-47d1-a599-2df36b8249af	\N	11	2026-05-30 06:02:53.811627+00	56d79006-412e-4a1a-ab42-da5509b64260	
6f0e035c-2b00-4979-ba9f-5a514d2b8c46	128cd8f7-9f9e-4dce-98f1-18d7ed8f2c9e	\N	11	2026-05-30 06:02:54.313614+00	56d79006-412e-4a1a-ab42-da5509b64260	
0f32895f-9c15-443e-98ad-a7da8fb3a720	b8af7025-13ec-440d-a436-7a772fbaa486	\N	11	2026-05-30 06:02:54.817302+00	56d79006-412e-4a1a-ab42-da5509b64260	
cdc971ee-46cf-4e33-bfa7-5b195f82deb5	bdb3a6e1-764a-4870-8eff-93d3c7007472	\N	11	2026-05-30 06:02:55.319733+00	56d79006-412e-4a1a-ab42-da5509b64260	
b97b78e7-d831-4799-a4e6-faa22a3d9eba	a98bfc86-2abd-4ee5-b681-f4ca2f78367d	\N	11	2026-05-30 06:02:55.82136+00	56d79006-412e-4a1a-ab42-da5509b64260	
495f9402-675b-421a-89a1-5321fd50e51b	39c35642-026b-4170-94e4-501cb6a1999a	\N	11	2026-05-30 06:02:56.321508+00	56d79006-412e-4a1a-ab42-da5509b64260	
3c51ccce-f1a7-4a27-9a35-d273a5a5618b	68b60782-ece3-476d-9d6f-2ed597af6e1e	\N	11	2026-05-30 06:02:56.823237+00	56d79006-412e-4a1a-ab42-da5509b64260	
8bcd7631-0027-4e1a-ac5e-cd04360ff7fa	e4a84288-b4ca-4e94-be38-a06d7fa3793a	\N	11	2026-05-30 06:02:57.325143+00	56d79006-412e-4a1a-ab42-da5509b64260	
f92e0a09-b7b3-4a51-8c88-821701ba3506	fc8299f0-b4e3-4e4a-adbb-b05c7135857c	\N	11	2026-05-30 06:02:57.827529+00	56d79006-412e-4a1a-ab42-da5509b64260	
b3a7ad0d-d065-4ff7-922a-899b97c575aa	5b5f0403-7882-447f-9935-0f26077879f3	\N	11	2026-05-30 06:02:58.329607+00	56d79006-412e-4a1a-ab42-da5509b64260	
8b80c874-6bb0-47d0-ba0b-186020dd6067	cb7cc942-9ad1-48fb-aced-d8b4d20dbe97	\N		2026-05-30 06:02:58.829239+00	56d79006-412e-4a1a-ab42-da5509b64260	
25c25b28-1f60-4c66-9633-2d2835203f61	5c94d15c-0bef-4568-ab52-4b8704e1836b	\N		2026-05-30 06:02:59.329575+00	56d79006-412e-4a1a-ab42-da5509b64260	
bd1fb21e-37ab-449e-8c8f-b52c7e740320	121140e1-dda8-43eb-94c4-b2acf1b5c7d8	\N		2026-05-30 06:02:59.829758+00	56d79006-412e-4a1a-ab42-da5509b64260	
58ae92b2-06b7-4302-87e3-4419de9824f8	93cfc800-f8e5-4cdc-bbe3-2e3849b8750f	\N		2026-05-30 06:03:00.331463+00	56d79006-412e-4a1a-ab42-da5509b64260	
1aece17a-e94c-44eb-b886-4db820d5345b	d02750d8-52f0-4d0b-a90d-e79229ad7528	\N		2026-05-30 06:03:00.832544+00	56d79006-412e-4a1a-ab42-da5509b64260	
7d81971e-bfd8-4a51-8642-82904b71398c	205575c4-1b78-4c72-84f3-02c010a3e9d5	\N		2026-05-30 06:03:01.332718+00	56d79006-412e-4a1a-ab42-da5509b64260	
9547240a-57f7-4880-9e4c-20654ca68af2	5465bb58-2e79-4893-a34a-1400bfbe9a17	\N		2026-05-30 06:03:01.832464+00	56d79006-412e-4a1a-ab42-da5509b64260	
c2f0cc3a-7c07-4baa-aae5-10a11f333364	f1c1a125-9e3a-45a7-a29f-9022ef119ec7	\N	11	2026-05-30 09:58:24.994381+00	1025389a-0e27-4e08-b6a0-b188660bea57	
91195dac-8b4c-4c6c-afc8-d4f85e86ded8	7740c7e7-f847-41e9-a6b3-55180d080af1	\N	11	2026-05-30 09:58:25.157585+00	1025389a-0e27-4e08-b6a0-b188660bea57	
1c447100-c0b0-4dfe-86a1-924b0c1ce4da	3b0d0b3a-18fd-4037-a4f7-e920f6f057df	\N	12	2026-05-30 09:58:25.32143+00	1025389a-0e27-4e08-b6a0-b188660bea57	
640c3757-1f41-4d3f-b71b-0d5d93c00f17	67b0f5f8-e74b-4c66-b9be-d24bfc1159bc	\N		2026-05-30 09:58:25.488618+00	1025389a-0e27-4e08-b6a0-b188660bea57	
02592a48-8c37-48bc-9359-c5433dcbbc0f	9709f988-7779-4a1b-bf44-e19340d13c95	\N		2026-05-30 09:58:25.652778+00	1025389a-0e27-4e08-b6a0-b188660bea57	
22d5a8a3-69c0-46ce-b8e7-0a874faf6f8b	9c89768b-7202-41c4-ba8e-3998a98a29d4	\N		2026-05-30 09:58:25.816134+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4dfd8b3d-0b6f-4804-806a-46538b19daba	58a40fe7-0ea2-4401-bb08-979bbb7f1308	\N		2026-05-30 09:58:25.975774+00	1025389a-0e27-4e08-b6a0-b188660bea57	
ca0fd67a-2268-4ff2-bc60-6509b71abd38	f3370b47-3d20-415d-99da-92ebf3f54c59	\N		2026-05-30 09:58:26.135671+00	1025389a-0e27-4e08-b6a0-b188660bea57	
bc89421b-61b4-4780-a6fd-eec48c18b179	09fe19a4-a24b-4172-93b6-9483be893424	\N		2026-05-30 09:58:26.303402+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3545605f-cc9b-4c85-96ba-5321e5eeb85b	917a78bc-3729-48ba-9ff5-2db003b43b7b	\N		2026-05-30 09:58:26.468437+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a18a3434-bc62-4189-a3b1-6b48d7625cd9	3540a06c-8812-419d-aa4e-83ed00937814	\N		2026-05-30 09:58:26.637027+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0cbb01a3-e68e-4558-b2ea-bec04f0a8c3e	dd73bdd2-f0c4-4d1f-b3a9-f719695b8619	\N		2026-05-30 09:58:26.801636+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e95ba0bc-c094-4773-a9a4-d18001179289	a4021676-fdd8-4e34-838a-dd0c2eb9402a	\N		2026-05-30 09:58:26.958351+00	1025389a-0e27-4e08-b6a0-b188660bea57	
f901eb4c-6e0d-4ecd-bd9e-a9771dc491f7	ccd0ecbd-d6a0-4a04-a9fe-e95e0046476d	\N		2026-05-30 09:58:27.115639+00	1025389a-0e27-4e08-b6a0-b188660bea57	
c4c15116-60f6-4ebd-b636-73ead0b9ee0b	7f39e6da-03fc-474c-b18e-31bb580fed9c	\N		2026-05-30 09:58:27.27722+00	1025389a-0e27-4e08-b6a0-b188660bea57	
688d9634-ba5b-497b-90ef-f626af932d27	b6ddaa08-f3da-4ea3-a452-f7e9a7fb5e42	\N		2026-05-30 09:58:27.444569+00	1025389a-0e27-4e08-b6a0-b188660bea57	
e7926772-6ac7-40db-8223-b8c6dd01430e	b63a28a8-0638-4029-b917-0fea90bab49d	\N		2026-05-30 09:58:27.60212+00	1025389a-0e27-4e08-b6a0-b188660bea57	
408df432-9af2-478f-a972-743555ffe3a2	f7ad4c15-357c-49bb-95c5-94fd6e82589a	\N		2026-05-30 09:58:27.761566+00	1025389a-0e27-4e08-b6a0-b188660bea57	
a45ff40e-5a09-4a3c-9f63-02df4395d13b	f1c1a125-9e3a-45a7-a29f-9022ef119ec7	11	11	2026-05-30 09:58:32.68301+00	1025389a-0e27-4e08-b6a0-b188660bea57	
de91d42c-b7a0-423f-a5af-c79a9de9f921	7740c7e7-f847-41e9-a6b3-55180d080af1	11	11	2026-05-30 09:58:32.77961+00	1025389a-0e27-4e08-b6a0-b188660bea57	
8316eca6-610e-474f-8f12-bc852af71be2	3b0d0b3a-18fd-4037-a4f7-e920f6f057df	12	12	2026-05-30 09:58:32.875482+00	1025389a-0e27-4e08-b6a0-b188660bea57	
6e18be7e-5cb1-4252-9833-1f33c785e129	67b0f5f8-e74b-4c66-b9be-d24bfc1159bc			2026-05-30 09:58:32.968944+00	1025389a-0e27-4e08-b6a0-b188660bea57	
48d6406f-8519-4b25-9767-5ebee5003a8e	9709f988-7779-4a1b-bf44-e19340d13c95			2026-05-30 09:58:33.065121+00	1025389a-0e27-4e08-b6a0-b188660bea57	
06be2ee9-4e21-4f50-87e1-85030097a059	9c89768b-7202-41c4-ba8e-3998a98a29d4			2026-05-30 09:58:33.159254+00	1025389a-0e27-4e08-b6a0-b188660bea57	
96ef00a2-8380-4c43-b24a-fc4c3fb243a0	58a40fe7-0ea2-4401-bb08-979bbb7f1308			2026-05-30 09:58:33.259671+00	1025389a-0e27-4e08-b6a0-b188660bea57	
0dcc4d95-55b6-4845-beb7-83efea25dbaa	f3370b47-3d20-415d-99da-92ebf3f54c59			2026-05-30 09:58:33.359088+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4e42c3da-9929-4353-b9fb-4e0d33ac576e	09fe19a4-a24b-4172-93b6-9483be893424			2026-05-30 09:58:33.459871+00	1025389a-0e27-4e08-b6a0-b188660bea57	
11e3d10b-4673-4b05-8b3e-4733ba0dd2fe	917a78bc-3729-48ba-9ff5-2db003b43b7b			2026-05-30 09:58:33.559399+00	1025389a-0e27-4e08-b6a0-b188660bea57	
568d78ea-c7cb-4ff1-99c3-2f5d9597d446	3540a06c-8812-419d-aa4e-83ed00937814			2026-05-30 09:58:33.653043+00	1025389a-0e27-4e08-b6a0-b188660bea57	
2ffeb24c-c837-4d54-97d3-cc1d885ca75f	dd73bdd2-f0c4-4d1f-b3a9-f719695b8619			2026-05-30 09:58:33.762867+00	1025389a-0e27-4e08-b6a0-b188660bea57	
489bf026-0c08-4434-8819-08f1a575dc80	a4021676-fdd8-4e34-838a-dd0c2eb9402a			2026-05-30 09:58:33.859047+00	1025389a-0e27-4e08-b6a0-b188660bea57	
d86d3e53-f947-4bdf-ae1c-7751578928a0	ccd0ecbd-d6a0-4a04-a9fe-e95e0046476d			2026-05-30 09:58:33.954898+00	1025389a-0e27-4e08-b6a0-b188660bea57	
49c316ce-12b0-46f4-adfa-f19231384c08	7f39e6da-03fc-474c-b18e-31bb580fed9c			2026-05-30 09:58:34.049148+00	1025389a-0e27-4e08-b6a0-b188660bea57	
c2825fba-ec82-4ac0-92f7-9cd466d63b70	b6ddaa08-f3da-4ea3-a452-f7e9a7fb5e42			2026-05-30 09:58:34.145443+00	1025389a-0e27-4e08-b6a0-b188660bea57	
3bf0eadf-05bf-4394-bebf-3207e2c6cbb8	b63a28a8-0638-4029-b917-0fea90bab49d			2026-05-30 09:58:34.242874+00	1025389a-0e27-4e08-b6a0-b188660bea57	
4faa17ee-3e13-46be-a5e1-73e36135386e	f7ad4c15-357c-49bb-95c5-94fd6e82589a			2026-05-30 09:58:34.342894+00	1025389a-0e27-4e08-b6a0-b188660bea57	
c7d92f95-75fa-423b-a05f-1e3962aa6302	d8a49da8-77fa-4454-a075-55297abd7ee7	\N	11	2026-06-05 00:07:02.237+00	56d79006-412e-4a1a-ab42-da5509b64260	
bbf4732e-dc84-435b-a5e9-91b9748478bc	0ff58c27-e2db-4a95-a579-871028056281	\N	11	2026-06-05 00:07:02.399067+00	56d79006-412e-4a1a-ab42-da5509b64260	
4485a403-f397-468f-a709-be4fabf88297	c7a03bf7-7322-4a66-a2de-b6cfa6ece56d	\N	11	2026-06-05 00:07:02.556447+00	56d79006-412e-4a1a-ab42-da5509b64260	
495aacc9-99c1-4940-9fa6-d7fd3711491e	c2a23f52-443f-4ef4-b77c-805d6ba93221	\N	11	2026-06-05 00:07:02.714649+00	56d79006-412e-4a1a-ab42-da5509b64260	
d3a19cd6-e9d5-4e16-a277-62f3632b27f4	be2bbb0d-ec27-49e0-a0d2-289a6b954cb3	\N	11	2026-06-05 00:07:02.87251+00	56d79006-412e-4a1a-ab42-da5509b64260	
0d065dc6-0154-4507-a389-259eb57d5844	f769aad0-d6ba-4e3e-8b68-eb0c500b8601	\N	11	2026-06-05 00:07:03.064757+00	56d79006-412e-4a1a-ab42-da5509b64260	
5cd1f28f-0440-4937-ae39-19988e9390c3	6909156f-e05d-422d-a8ea-dc53664a6523	\N	11	2026-06-05 00:07:03.223385+00	56d79006-412e-4a1a-ab42-da5509b64260	
e38721be-f934-48cc-a88f-4eab9467ee93	3062bad7-36b7-4f00-bab6-403ac5f6a241	\N	11	2026-06-05 00:07:03.379512+00	56d79006-412e-4a1a-ab42-da5509b64260	
930fa4e5-a12c-4e8e-9303-f98ea760a3fa	d05da045-36f2-4fcc-b86e-1a02de788e97	\N	11	2026-06-05 00:07:03.539243+00	56d79006-412e-4a1a-ab42-da5509b64260	
90e4ef03-c9ed-4301-8048-7df2a2d27840	7d1608e0-63ca-4626-b4a9-d75e73fd5d1e	\N	11	2026-06-05 00:07:03.69839+00	56d79006-412e-4a1a-ab42-da5509b64260	
8bedd5d3-ba69-418d-8827-bdc5fde5ff3d	186b6f8d-a4b2-4f43-ac0e-cfa815e92f55	\N	11	2026-06-05 00:07:03.85787+00	56d79006-412e-4a1a-ab42-da5509b64260	
9ad45db5-8659-433f-8a8d-961cc3b975fb	f6d0543d-c61f-4038-8523-ebd4f93d752b	\N		2026-06-05 00:07:04.016062+00	56d79006-412e-4a1a-ab42-da5509b64260	
54dd31e1-638f-4e0d-831b-e75657ebdd09	99ec601b-8d91-4151-aac7-5da99b2a3e2f	\N		2026-06-05 00:07:04.172673+00	56d79006-412e-4a1a-ab42-da5509b64260	
d3d252bc-de37-4b5d-963d-b9548c37fdd6	ec462e01-8bb1-4a4a-a8b9-c80e0d651cfb	\N		2026-06-05 00:07:04.327132+00	56d79006-412e-4a1a-ab42-da5509b64260	
1fae226d-5c36-49c7-894e-d7a8456e1641	5280a7cf-a41c-463e-b570-56bdac1fa01f	\N		2026-06-05 00:07:04.482602+00	56d79006-412e-4a1a-ab42-da5509b64260	
439b91fc-80e3-45df-b297-96c3df56bb31	3f450177-5a53-4804-8a7d-5a60dc8faba6	\N		2026-06-05 00:07:04.638477+00	56d79006-412e-4a1a-ab42-da5509b64260	
e98ce213-03a2-4c7f-87de-8c827b6e05cb	6104f168-8bf1-4921-99d2-54e1d91ca459	\N		2026-06-05 00:07:04.793569+00	56d79006-412e-4a1a-ab42-da5509b64260	
328e6b86-0c7b-40c0-b800-9ad4711cb35f	d4faa406-7f48-4c8e-9517-02cb4c315ad4	\N		2026-06-05 00:07:04.948462+00	56d79006-412e-4a1a-ab42-da5509b64260	
5fca89e1-bb64-4431-8dec-d98e505bd9c9	d8a49da8-77fa-4454-a075-55297abd7ee7	11	11	2026-06-05 00:07:21.864921+00	56d79006-412e-4a1a-ab42-da5509b64260	
9324338b-2f48-420c-8ee4-5f38789616e7	0ff58c27-e2db-4a95-a579-871028056281	11	11	2026-06-05 00:07:21.958612+00	56d79006-412e-4a1a-ab42-da5509b64260	
78f2787a-24ae-49ea-9a55-a2360f58ffa3	c7a03bf7-7322-4a66-a2de-b6cfa6ece56d	11	11	2026-06-05 00:07:22.052495+00	56d79006-412e-4a1a-ab42-da5509b64260	
f6f19529-fec1-4f2f-9f1e-af3700abb56f	c2a23f52-443f-4ef4-b77c-805d6ba93221	11	11	2026-06-05 00:07:22.145527+00	56d79006-412e-4a1a-ab42-da5509b64260	
75004792-af34-4347-81e2-3c9055aeda18	be2bbb0d-ec27-49e0-a0d2-289a6b954cb3	11	11	2026-06-05 00:07:22.23966+00	56d79006-412e-4a1a-ab42-da5509b64260	
fbe46276-d25c-42b8-a450-f9991ca0bdc6	f769aad0-d6ba-4e3e-8b68-eb0c500b8601	11	11	2026-06-05 00:07:22.332787+00	56d79006-412e-4a1a-ab42-da5509b64260	
4c1b404b-883b-4bd2-8987-55f9842dd5aa	6909156f-e05d-422d-a8ea-dc53664a6523	11	11	2026-06-05 00:07:22.425875+00	56d79006-412e-4a1a-ab42-da5509b64260	
f3e40c9b-556d-45b5-9c2e-9d757801b27f	3062bad7-36b7-4f00-bab6-403ac5f6a241	11	11	2026-06-05 00:07:22.519104+00	56d79006-412e-4a1a-ab42-da5509b64260	
c7a7a19b-a2a0-4c82-8a0b-f56dead56313	d05da045-36f2-4fcc-b86e-1a02de788e97	11	11	2026-06-05 00:07:22.612276+00	56d79006-412e-4a1a-ab42-da5509b64260	
3cf4a83a-c950-4d1a-8280-c304923b65f9	7d1608e0-63ca-4626-b4a9-d75e73fd5d1e	11	11	2026-06-05 00:07:22.705442+00	56d79006-412e-4a1a-ab42-da5509b64260	
95582f80-425e-401a-b702-d0309bf7c97a	186b6f8d-a4b2-4f43-ac0e-cfa815e92f55	11	11	2026-06-05 00:07:22.798305+00	56d79006-412e-4a1a-ab42-da5509b64260	
21c563f6-08bd-418e-932f-2a10360a0a1f	f6d0543d-c61f-4038-8523-ebd4f93d752b			2026-06-05 00:07:22.891025+00	56d79006-412e-4a1a-ab42-da5509b64260	
9971c442-9022-442f-a78a-69aa7619ef2d	99ec601b-8d91-4151-aac7-5da99b2a3e2f			2026-06-05 00:07:22.985052+00	56d79006-412e-4a1a-ab42-da5509b64260	
98ced2b9-5702-44f5-b94c-df8c710a8b6a	ec462e01-8bb1-4a4a-a8b9-c80e0d651cfb			2026-06-05 00:07:23.079902+00	56d79006-412e-4a1a-ab42-da5509b64260	
e4b7be2d-4d41-41ac-ac4e-f67dce0928e0	5280a7cf-a41c-463e-b570-56bdac1fa01f			2026-06-05 00:07:23.173987+00	56d79006-412e-4a1a-ab42-da5509b64260	
211c72ef-d192-4593-8ab2-f8c813ab344c	3f450177-5a53-4804-8a7d-5a60dc8faba6			2026-06-05 00:07:23.268044+00	56d79006-412e-4a1a-ab42-da5509b64260	
ae992f94-d721-4611-8902-905267c7b843	6104f168-8bf1-4921-99d2-54e1d91ca459			2026-06-05 00:07:23.361741+00	56d79006-412e-4a1a-ab42-da5509b64260	
5fb7eda8-b9a4-405c-84cf-04bf0c6d49d7	d4faa406-7f48-4c8e-9517-02cb4c315ad4			2026-06-05 00:07:23.454709+00	56d79006-412e-4a1a-ab42-da5509b64260	
adb90c28-7f53-485b-9cba-523cfb503d84	7557a207-3d85-4a75-a3fd-05ed9a9051dc	\N	11	2026-06-05 02:20:36.469351+00	56d79006-412e-4a1a-ab42-da5509b64260	
93af908e-85b3-4924-a485-b8b2ea1f6c5b	7d3fb259-b209-4482-9b12-e5b1ade35d43	\N	11	2026-06-05 02:20:36.646173+00	56d79006-412e-4a1a-ab42-da5509b64260	
9b4b2af1-9a2a-4e15-8400-745f7d4344a5	32bce018-9d1d-4a2a-b745-edbef9fc270b	\N	11	2026-06-05 02:20:36.805965+00	56d79006-412e-4a1a-ab42-da5509b64260	
72ab57c0-8601-4e1d-9d34-f4ab3eb1f250	e1dbcb88-bea6-4b5c-b458-c9cad9c67c76	\N	11	2026-06-05 02:20:36.962397+00	56d79006-412e-4a1a-ab42-da5509b64260	
f2168627-9151-490a-bbfc-b20a7a89b514	fa3ada3d-be8b-4f5d-9d8c-169f49296e6c	\N	11	2026-06-05 02:20:37.118398+00	56d79006-412e-4a1a-ab42-da5509b64260	
2f132094-26b1-449c-a635-cadceb8f54e7	d04596d3-6921-47e0-b5fa-12e5ee60f6e0	\N	11	2026-06-05 02:20:37.273497+00	56d79006-412e-4a1a-ab42-da5509b64260	
bc41a539-3b53-4a98-84ce-53aba968bbfa	b5fb6390-1bf1-4395-9006-8487cb311ca1	\N	11	2026-06-05 02:20:37.42849+00	56d79006-412e-4a1a-ab42-da5509b64260	
845daca3-1520-4290-865e-2ac7bf07fade	98c76db9-331a-455c-9a3c-ee8aba7924e8	\N	11	2026-06-05 02:20:37.583801+00	56d79006-412e-4a1a-ab42-da5509b64260	
6b5b48cf-4625-4596-a083-b5027cd9c454	ff5bd2ef-f1cf-45ab-9739-84a37eef556b	\N	11	2026-06-05 02:20:37.740473+00	56d79006-412e-4a1a-ab42-da5509b64260	
d86c3dad-4152-4fa8-9bd9-de9d90873d19	fa98bf85-85f8-4e03-814b-accd348a741f	\N	11	2026-06-05 02:20:37.894424+00	56d79006-412e-4a1a-ab42-da5509b64260	
9602b336-b423-411d-a81e-085742f9b43a	4ec86ba0-beea-40eb-ac95-0343d952b59b	\N	11	2026-06-05 02:20:38.049036+00	56d79006-412e-4a1a-ab42-da5509b64260	
06f461cc-a3a1-4940-b489-f69824b7e3f1	0f2dd61e-5ba6-49ec-99ce-dd3cb6f5aed3	\N		2026-06-05 02:20:38.203553+00	56d79006-412e-4a1a-ab42-da5509b64260	
56d8724e-db4d-49e2-9cf9-9eafb4ce6a43	66eb3f07-65ca-419c-a9bf-69360747111b	\N		2026-06-05 02:20:38.358326+00	56d79006-412e-4a1a-ab42-da5509b64260	
ebbfde07-dfa0-4f11-942e-c22551c450df	c35a592b-5589-4a5a-9a37-e96b22e82eb4	\N		2026-06-05 02:20:38.513381+00	56d79006-412e-4a1a-ab42-da5509b64260	
71e8c6e4-f9d9-436d-8bcd-bf9cc7f4fae3	37e81e44-c8a8-41b8-ab8c-049d747d8616	\N		2026-06-05 02:20:38.670752+00	56d79006-412e-4a1a-ab42-da5509b64260	
d5e1e468-a3b0-4a2d-86bb-db58f0937a93	7f223d3c-2675-4382-8317-46dbbae35233	\N		2026-06-05 02:20:38.825047+00	56d79006-412e-4a1a-ab42-da5509b64260	
877a2f0b-8f5a-4608-a7c5-634737639001	47cfd3dd-709b-4fa5-b934-43c4c0f06928	\N		2026-06-05 02:20:38.978136+00	56d79006-412e-4a1a-ab42-da5509b64260	
cfe1300d-6ff3-42a6-91aa-7599d49b1c5f	936c2d20-1f8b-425b-a40b-e8da5cff29ba	\N		2026-06-05 02:20:39.132149+00	56d79006-412e-4a1a-ab42-da5509b64260	
7605a394-8488-4c7f-bea8-9619a52d42c9	7557a207-3d85-4a75-a3fd-05ed9a9051dc	11	11	2026-06-05 02:20:51.656428+00	56d79006-412e-4a1a-ab42-da5509b64260	
bbd51eb3-fd0a-48c1-9afd-c85c9b8d965d	7d3fb259-b209-4482-9b12-e5b1ade35d43	11	11	2026-06-05 02:20:51.749613+00	56d79006-412e-4a1a-ab42-da5509b64260	
be72b5f0-e575-4587-a106-462b21971ec1	32bce018-9d1d-4a2a-b745-edbef9fc270b	11	11	2026-06-05 02:20:51.842055+00	56d79006-412e-4a1a-ab42-da5509b64260	
d08c5e16-7b31-47ed-91f9-712607b202ba	e1dbcb88-bea6-4b5c-b458-c9cad9c67c76	11	11	2026-06-05 02:20:51.934269+00	56d79006-412e-4a1a-ab42-da5509b64260	
ed97a2f9-4292-497f-8503-168032abc84a	fa3ada3d-be8b-4f5d-9d8c-169f49296e6c	11	11	2026-06-05 02:20:52.027239+00	56d79006-412e-4a1a-ab42-da5509b64260	
a67ef7c9-edc2-4890-be25-a88be4ce6a37	d04596d3-6921-47e0-b5fa-12e5ee60f6e0	11	11	2026-06-05 02:20:52.119517+00	56d79006-412e-4a1a-ab42-da5509b64260	
21a1adcd-24c3-4011-8bd4-beec830f6682	b5fb6390-1bf1-4395-9006-8487cb311ca1	11	11	2026-06-05 02:20:52.21164+00	56d79006-412e-4a1a-ab42-da5509b64260	
762dcecc-cd33-4ae4-8014-976a9589d136	98c76db9-331a-455c-9a3c-ee8aba7924e8	11	11	2026-06-05 02:20:52.30432+00	56d79006-412e-4a1a-ab42-da5509b64260	
af5dab62-c8db-40ee-a32d-58ec5957617e	ff5bd2ef-f1cf-45ab-9739-84a37eef556b	11	11	2026-06-05 02:20:52.396295+00	56d79006-412e-4a1a-ab42-da5509b64260	
a230d941-3a8a-42fe-b9f1-ab708db4ec79	fa98bf85-85f8-4e03-814b-accd348a741f	11	11	2026-06-05 02:20:52.488235+00	56d79006-412e-4a1a-ab42-da5509b64260	
f2270da0-822f-44d7-83c4-6062a5b2f61e	4ec86ba0-beea-40eb-ac95-0343d952b59b	11	11	2026-06-05 02:20:52.581512+00	56d79006-412e-4a1a-ab42-da5509b64260	
e3f61cde-69d4-4b50-a5a6-1c03a525f609	0f2dd61e-5ba6-49ec-99ce-dd3cb6f5aed3			2026-06-05 02:20:52.673548+00	56d79006-412e-4a1a-ab42-da5509b64260	
d0cd210b-8fc1-4dee-afab-b6c45387d1d2	66eb3f07-65ca-419c-a9bf-69360747111b			2026-06-05 02:20:52.765844+00	56d79006-412e-4a1a-ab42-da5509b64260	
e1eb293f-dbcf-48e4-b449-492e46e2bac9	c35a592b-5589-4a5a-9a37-e96b22e82eb4			2026-06-05 02:20:52.857637+00	56d79006-412e-4a1a-ab42-da5509b64260	
3f23c9ff-cbc3-41ef-80ae-1264c671739f	37e81e44-c8a8-41b8-ab8c-049d747d8616			2026-06-05 02:20:52.949627+00	56d79006-412e-4a1a-ab42-da5509b64260	
d4a0b9c9-e3cb-43ef-a394-fb67eb8e41fa	7f223d3c-2675-4382-8317-46dbbae35233			2026-06-05 02:20:53.041754+00	56d79006-412e-4a1a-ab42-da5509b64260	
099e3963-d0f4-4a68-9662-ce74446acd90	47cfd3dd-709b-4fa5-b934-43c4c0f06928			2026-06-05 02:20:53.133669+00	56d79006-412e-4a1a-ab42-da5509b64260	
5a0703be-f33d-4a58-963c-8e9992440caa	936c2d20-1f8b-425b-a40b-e8da5cff29ba			2026-06-05 02:20:53.225731+00	56d79006-412e-4a1a-ab42-da5509b64260	
4843be6a-240a-4c8d-a443-23b9b25da80e	04484ca8-a655-4fea-8bcf-db6975196fec	\N	11	2026-06-05 03:14:55.771751+00	56d79006-412e-4a1a-ab42-da5509b64260	
58cc3239-ff21-4089-962b-a994faeca7c4	94850caa-a29a-49bc-a73d-a9fc1dacf5f3	\N	11	2026-06-05 03:14:55.936612+00	56d79006-412e-4a1a-ab42-da5509b64260	
6ed8435b-70e0-464f-854d-63ff421815f3	0550e03c-575b-4745-bffe-e2c503d33d57	\N	11	2026-06-05 03:14:56.096753+00	56d79006-412e-4a1a-ab42-da5509b64260	
93fef7de-eee3-4df5-9d67-6cdc7325c79f	154f2b9a-ecee-4321-9dbd-a28a9f6f6364	\N	11	2026-06-05 03:14:56.265724+00	56d79006-412e-4a1a-ab42-da5509b64260	
d72a39ed-5a35-41e0-9259-f22359845388	591c602f-da38-4156-941e-eb869bb30042	\N	11	2026-06-05 03:14:56.424969+00	56d79006-412e-4a1a-ab42-da5509b64260	
8f51b09d-4b2a-454e-abca-be0cf33e95e7	bb083f3e-4c00-4890-a7ac-33c6dd2c45f4	\N	11	2026-06-05 03:14:56.583657+00	56d79006-412e-4a1a-ab42-da5509b64260	
05192f58-8b16-459f-8b57-e19794e75b85	9173835c-9d98-481d-b993-0ccdb4e43240	\N	11	2026-06-05 03:14:56.742262+00	56d79006-412e-4a1a-ab42-da5509b64260	
055d601d-3183-4c37-abd4-182d24fedfd2	cd6d06b5-5db7-4526-8c65-233030b4684b	\N	11	2026-06-05 03:14:56.900234+00	56d79006-412e-4a1a-ab42-da5509b64260	
1d46ebcd-81f5-4b0e-a304-c00296d9d2fc	18670602-1741-4f6c-a208-906e7808a6c1	\N	11	2026-06-05 03:14:57.058375+00	56d79006-412e-4a1a-ab42-da5509b64260	
1d45d556-1bed-4cf8-9f0b-4a6ea35b235c	a373b9a9-6c4f-4f3a-ad7d-83d57522a724	\N	11	2026-06-05 03:14:57.21592+00	56d79006-412e-4a1a-ab42-da5509b64260	
77845855-c3bd-430d-9140-b167f243ffcb	3ec18161-39db-439a-bfc6-a34c74d30c5f	\N	11	2026-06-05 03:14:57.374129+00	56d79006-412e-4a1a-ab42-da5509b64260	
83086ea9-21c6-4d43-8de8-3bb00147f2d0	cd337b0f-77a3-4b54-acff-6232245e8814	\N		2026-06-05 03:14:57.532238+00	56d79006-412e-4a1a-ab42-da5509b64260	
55230479-6f7d-4b84-9a33-53587c5a6961	a83094b5-bf59-4a3b-9883-338e07e25785	\N		2026-06-05 03:14:57.695543+00	56d79006-412e-4a1a-ab42-da5509b64260	
6f1482b8-0f36-492f-b87b-a7d39f39ee71	908a0111-4f3e-4bc7-94b2-349608763cd8	\N		2026-06-05 03:14:57.854424+00	56d79006-412e-4a1a-ab42-da5509b64260	
92f2dbbb-946f-4930-8aea-a7568e5e91ae	aaec7a4e-df18-4fc1-aef9-06542d992961	\N		2026-06-05 03:14:58.014021+00	56d79006-412e-4a1a-ab42-da5509b64260	
318d819c-14f7-4f63-93c8-da4d284f8895	cab8a3fd-8f79-4b26-8405-faa6f10d9ce1	\N		2026-06-05 03:14:58.172164+00	56d79006-412e-4a1a-ab42-da5509b64260	
fa93c0f4-fc4b-44fb-8e65-4187419bc264	bdd9535b-7822-4f32-ad79-7c0d85e40619	\N		2026-06-05 03:14:58.330454+00	56d79006-412e-4a1a-ab42-da5509b64260	
fc56eb76-de36-4136-a9b3-195ff2385787	f1e4d050-c52a-4b15-8a16-6cd27ab7ced1	\N		2026-06-05 03:14:58.488322+00	56d79006-412e-4a1a-ab42-da5509b64260	
765ab751-7394-4263-99dd-d4f9c15835b7	c2028506-524f-4899-bd1e-b4a610820f41	\N	11	2026-06-05 05:09:39.808147+00	56d79006-412e-4a1a-ab42-da5509b64260	
192e4235-c153-4e84-9e60-1f22cc898e85	5045fa91-4a5e-49cb-b42e-51be02badc1a	\N	11	2026-06-05 05:09:39.974071+00	56d79006-412e-4a1a-ab42-da5509b64260	
28a72d73-deea-4d3d-83e4-6bc0f05de734	58e83c86-aa14-4be1-9f65-6be568ad8401	\N	11	2026-06-05 05:09:40.144562+00	56d79006-412e-4a1a-ab42-da5509b64260	
cbbc44d1-f3b2-47dc-a24c-f2cadd7101c9	8733dcbc-e94e-4779-bebf-a04b73031f52	\N	11	2026-06-05 05:09:40.320254+00	56d79006-412e-4a1a-ab42-da5509b64260	
69594552-b580-4eeb-89d7-9fdbd7326b2b	d9022386-2a3d-46a9-9cfe-b4f4f2f47c63	\N	11	2026-06-05 05:09:40.49335+00	56d79006-412e-4a1a-ab42-da5509b64260	
f3b784c4-fa41-4d3a-8150-88eca16dce18	1cbea1a7-41aa-41c3-a17d-ac45d5f32e05	\N	11	2026-06-05 05:09:40.66935+00	56d79006-412e-4a1a-ab42-da5509b64260	
3e2316dc-ebcd-4444-92ef-535577d0b856	c92dbbef-5a74-4ee1-9b83-73007a1cd9e6	\N	11	2026-06-05 05:09:40.83985+00	56d79006-412e-4a1a-ab42-da5509b64260	
fe0920c7-dc0b-4dd5-ba12-2e8e4b0505fc	2888e63d-84b7-4056-be86-ba187b5441dc	\N	11	2026-06-05 05:09:41.010825+00	56d79006-412e-4a1a-ab42-da5509b64260	
982bc800-76a3-4ee4-b4e8-f358472236e7	6b2f5ff6-6d7d-4321-87fd-ecab5eb0369c	\N	11	2026-06-05 05:09:41.183873+00	56d79006-412e-4a1a-ab42-da5509b64260	
219c1877-28c8-4ea8-a680-73ba499e39dc	f5a71a35-4063-445d-b456-6f0a7bcf7259	\N	11	2026-06-05 05:09:41.355594+00	56d79006-412e-4a1a-ab42-da5509b64260	
a424abf9-e967-467a-9524-080fd9f70e66	97f4c628-d46a-4f6e-94c0-aa8f03e22baf	\N	11	2026-06-05 05:09:41.532769+00	56d79006-412e-4a1a-ab42-da5509b64260	
37343b41-5b5a-4092-bb8d-afd916bec59f	3042c3da-c56f-4ea8-8461-a4353db85d0b	\N		2026-06-05 05:09:41.703269+00	56d79006-412e-4a1a-ab42-da5509b64260	
7680b419-c245-4d28-8b57-47a5494f7764	5f277d77-3a5a-43c5-8920-2cee3db34b7a	\N		2026-06-05 05:09:41.871943+00	56d79006-412e-4a1a-ab42-da5509b64260	
20619e10-34af-4708-a50b-7ee0104d05de	aa5b2446-b6b5-4628-a1a5-251f01efbd9d	\N		2026-06-05 05:09:42.038608+00	56d79006-412e-4a1a-ab42-da5509b64260	
faa9d101-58ce-4df9-b642-9936b45f4d95	923958c4-a3bd-403e-aab0-2c44f1b5e61d	\N		2026-06-05 05:09:42.205877+00	56d79006-412e-4a1a-ab42-da5509b64260	
847e932d-c2c5-421a-a4b4-399f86814173	0e50bfc8-c667-4413-b638-f67a96cff744	\N		2026-06-05 05:09:42.377775+00	56d79006-412e-4a1a-ab42-da5509b64260	
42058577-a649-46da-ba6f-2a9290af71a2	b8d764ee-3e35-4275-8aa4-d158bdc9a7b9	\N		2026-06-05 05:09:42.555637+00	56d79006-412e-4a1a-ab42-da5509b64260	
0cb24312-0357-4c18-b2ee-76c2bfd68e77	31e37611-0373-4391-8b6c-b17e341f0948	\N		2026-06-05 05:09:42.722974+00	56d79006-412e-4a1a-ab42-da5509b64260	
9679de4e-60cc-4535-9585-143cd74ab02a	c2028506-524f-4899-bd1e-b4a610820f41	11	11	2026-06-05 05:09:47.045953+00	56d79006-412e-4a1a-ab42-da5509b64260	
5fd1a1b9-1554-47a0-bea0-7960643211d0	5045fa91-4a5e-49cb-b42e-51be02badc1a	11	11	2026-06-05 05:09:47.144808+00	56d79006-412e-4a1a-ab42-da5509b64260	
c5022b92-b6df-4883-a8d0-3ab0c6366706	58e83c86-aa14-4be1-9f65-6be568ad8401	11	11	2026-06-05 05:09:47.244937+00	56d79006-412e-4a1a-ab42-da5509b64260	
538cad4b-b975-4e63-a079-edad8722ac29	8733dcbc-e94e-4779-bebf-a04b73031f52	11	11	2026-06-05 05:09:47.350217+00	56d79006-412e-4a1a-ab42-da5509b64260	
a2fafb44-17bb-4482-9aad-260d551ec3e6	d9022386-2a3d-46a9-9cfe-b4f4f2f47c63	11	11	2026-06-05 05:09:47.455716+00	56d79006-412e-4a1a-ab42-da5509b64260	
a2f8eaf0-29fe-4112-9a06-cb67edca7099	1cbea1a7-41aa-41c3-a17d-ac45d5f32e05	11	11	2026-06-05 05:09:47.559741+00	56d79006-412e-4a1a-ab42-da5509b64260	
156bb520-fd34-435c-a244-970807dd4615	c92dbbef-5a74-4ee1-9b83-73007a1cd9e6	11	11	2026-06-05 05:09:47.663064+00	56d79006-412e-4a1a-ab42-da5509b64260	
f3a58639-f23c-4bc2-8d05-1053f93528f3	2888e63d-84b7-4056-be86-ba187b5441dc	11	11	2026-06-05 05:09:47.768971+00	56d79006-412e-4a1a-ab42-da5509b64260	
e21a0c6f-2d22-49a5-9d4d-871726bc5012	6b2f5ff6-6d7d-4321-87fd-ecab5eb0369c	11	11	2026-06-05 05:09:47.876173+00	56d79006-412e-4a1a-ab42-da5509b64260	
bac76cfe-4e02-4695-9e88-24d080c1ab7a	f5a71a35-4063-445d-b456-6f0a7bcf7259	11	11	2026-06-05 05:09:47.982272+00	56d79006-412e-4a1a-ab42-da5509b64260	
05819541-8de0-46f1-a819-395043a60758	97f4c628-d46a-4f6e-94c0-aa8f03e22baf	11	11	2026-06-05 05:09:48.087913+00	56d79006-412e-4a1a-ab42-da5509b64260	
1f21e441-364a-4927-a924-b0910a8dd979	3042c3da-c56f-4ea8-8461-a4353db85d0b			2026-06-05 05:09:48.193494+00	56d79006-412e-4a1a-ab42-da5509b64260	
b60b7af6-e065-4f1b-8717-07043fe07fde	5f277d77-3a5a-43c5-8920-2cee3db34b7a			2026-06-05 05:09:48.297962+00	56d79006-412e-4a1a-ab42-da5509b64260	
9118e4df-ce6b-423c-8317-d52857120589	aa5b2446-b6b5-4628-a1a5-251f01efbd9d			2026-06-05 05:09:48.40622+00	56d79006-412e-4a1a-ab42-da5509b64260	
eeb01450-f6f8-4811-b0c7-0be8249a1b9f	923958c4-a3bd-403e-aab0-2c44f1b5e61d			2026-06-05 05:09:48.513974+00	56d79006-412e-4a1a-ab42-da5509b64260	
5d21cfdc-ba0d-49e7-9523-c0546cc85b26	0e50bfc8-c667-4413-b638-f67a96cff744			2026-06-05 05:09:48.619086+00	56d79006-412e-4a1a-ab42-da5509b64260	
61cf7c84-0769-4fd1-ac64-253710ba4382	b8d764ee-3e35-4275-8aa4-d158bdc9a7b9			2026-06-05 05:09:48.725614+00	56d79006-412e-4a1a-ab42-da5509b64260	
eb34a52b-f1d7-4d4f-ac6d-96b4836e02b1	31e37611-0373-4391-8b6c-b17e341f0948			2026-06-05 05:09:48.83095+00	56d79006-412e-4a1a-ab42-da5509b64260	
\.


--
-- Data for Name: attribute_values; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attribute_values (attribute_value_id, report_id, attribute_id, value_text, updated_at) FROM stdin;
4180eabf-6739-4e8c-b32a-b6339361af86	fe238c96-baa2-470b-9245-ccd49439b800	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	200	2026-04-06 21:01:56.744875+00
03da7a06-7cf0-4570-9fba-36bea3ab7727	fe238c96-baa2-470b-9245-ccd49439b800	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	201	2026-04-06 21:01:56.744875+00
7c5bab58-92bc-4fca-88a1-781b50276c9a	967e6f26-4e69-4da4-bdc5-ae119d5ad716	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-04-13 21:21:11.95807+00
582b0054-cac3-4d13-a39e-0cca8792c21e	967e6f26-4e69-4da4-bdc5-ae119d5ad716	cb2e05b8-5feb-47b8-933a-868b1e703342	13	2026-04-13 21:21:12.618649+00
12a89697-a746-4442-8613-737d7b74b82f	967e6f26-4e69-4da4-bdc5-ae119d5ad716	0efafdb9-d607-4960-97f7-4c93eebe8c54	12	2026-04-13 21:21:13.277569+00
5c8a72a3-7f74-4d01-bc22-950e5ca2bd89	967e6f26-4e69-4da4-bdc5-ae119d5ad716	05baf163-db0d-4b25-80ba-05b5b80e4c69	34	2026-04-13 21:21:13.935932+00
4e24db06-157c-4ad8-bb68-84039def8354	967e6f26-4e69-4da4-bdc5-ae119d5ad716	0b9672ca-b402-4b76-bd72-1957304940a1	15	2026-04-13 21:21:14.629293+00
ed507ff1-8492-4c8e-a617-048f9b6e97d5	967e6f26-4e69-4da4-bdc5-ae119d5ad716	b7e6b576-fc4d-453c-bdab-27dc5452157c	16	2026-04-13 21:21:15.289202+00
d2cd827a-c627-4d8e-8233-954c1462e567	967e6f26-4e69-4da4-bdc5-ae119d5ad716	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	11	2026-04-13 21:21:15.947372+00
daa78c73-a9fa-4822-8480-2bfc21e86fb9	967e6f26-4e69-4da4-bdc5-ae119d5ad716	7cc0365f-3df4-4389-93f7-6f3907b1d014	12	2026-04-13 21:21:16.605044+00
5bfbd450-962b-4619-ae8a-20b81bfebe8d	967e6f26-4e69-4da4-bdc5-ae119d5ad716	8f209177-d1f1-4419-bc20-707ccd166660	11	2026-04-13 21:21:17.26411+00
99cae024-3ae2-43d7-93d1-9bc5fe3db8f8	967e6f26-4e69-4da4-bdc5-ae119d5ad716	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	14	2026-04-13 21:21:17.926973+00
321e44ae-f314-4a33-8f7e-4f5538f911e9	967e6f26-4e69-4da4-bdc5-ae119d5ad716	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-13 21:21:18.586237+00
57611ad5-4be9-407b-a1d0-a1f9472674b0	967e6f26-4e69-4da4-bdc5-ae119d5ad716	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-13 21:21:19.241879+00
d47de7b4-9e9b-48c9-8c5f-bc14294dbbfb	967e6f26-4e69-4da4-bdc5-ae119d5ad716	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-13 21:21:19.899401+00
9cf70670-de59-4334-a928-d4ec846c8980	967e6f26-4e69-4da4-bdc5-ae119d5ad716	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-13 21:21:20.559888+00
9a365636-53a8-4662-98fa-afd334686e2b	967e6f26-4e69-4da4-bdc5-ae119d5ad716	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-13 21:21:21.218049+00
56e62ee3-bf07-47ea-aafa-5055d781093c	967e6f26-4e69-4da4-bdc5-ae119d5ad716	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-13 21:21:21.876631+00
a08a5023-f7c6-40cf-a1f2-c2efc166095b	967e6f26-4e69-4da4-bdc5-ae119d5ad716	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-13 21:21:22.534773+00
f8a2d5dc-ea1a-4ff4-bc86-58622148ac05	967e6f26-4e69-4da4-bdc5-ae119d5ad716	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-04-13 21:45:09.267725+00
4016ed77-1a98-4d6b-8817-bf1fb0633d26	4b690648-0503-432d-8f18-cdca84d07459	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	12312	2026-04-14 10:05:31.048148+00
e56f7eba-62ea-418a-b0eb-ed4a5f95918e	4b690648-0503-432d-8f18-cdca84d07459	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-04-14 10:05:31.309807+00
092ddee7-093b-45ee-a0af-b56b1cad3d77	4b690648-0503-432d-8f18-cdca84d07459	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-04-14 10:05:31.439312+00
244f920b-8241-4f13-96cf-0f5bf2b0fc49	4b690648-0503-432d-8f18-cdca84d07459	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-04-14 10:05:31.570033+00
50dd0eea-0972-45f1-9d98-2f490a85aee4	4b690648-0503-432d-8f18-cdca84d07459	0b9672ca-b402-4b76-bd72-1957304940a1		2026-04-14 10:05:31.70209+00
6e567c50-796d-4c39-b7c6-d8aa2be57e67	4b690648-0503-432d-8f18-cdca84d07459	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-04-14 10:05:31.831485+00
9c7bd5a4-2613-43f5-9f30-7e7b9c98abf2	4b690648-0503-432d-8f18-cdca84d07459	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-04-14 10:05:31.961473+00
7892338e-2b0a-43aa-8501-eab4b46635f5	4b690648-0503-432d-8f18-cdca84d07459	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-04-14 10:05:32.090719+00
5d497eb0-4237-4435-99e1-dacdc6d17c24	4b690648-0503-432d-8f18-cdca84d07459	8f209177-d1f1-4419-bc20-707ccd166660		2026-04-14 10:05:32.218892+00
02f19ddf-496b-416f-a427-06faef00312b	4b690648-0503-432d-8f18-cdca84d07459	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-04-14 10:05:32.34861+00
91671878-4349-46ce-85c4-3c5c9f1b1408	4b690648-0503-432d-8f18-cdca84d07459	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-14 10:05:32.477784+00
bff93eec-263e-4250-874e-2014d41b986f	4b690648-0503-432d-8f18-cdca84d07459	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-14 10:05:32.606694+00
a15431de-b67b-4976-b6d5-14f4d11026bb	4b690648-0503-432d-8f18-cdca84d07459	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-14 10:05:32.734318+00
cda3a6dc-a2b0-4fda-b320-6cec78c39fb3	4b690648-0503-432d-8f18-cdca84d07459	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-14 10:05:32.861466+00
9c76dbf2-f8cb-4873-b003-8aa82f9ba0d9	4b690648-0503-432d-8f18-cdca84d07459	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-14 10:05:32.989238+00
16c420fc-0f73-45bb-967f-2ab85ee65bc7	4b690648-0503-432d-8f18-cdca84d07459	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-14 10:05:33.117304+00
2e867df1-7f62-45b2-8bf2-eda75091d77d	4b690648-0503-432d-8f18-cdca84d07459	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-14 10:05:33.244624+00
6b3ef7eb-05f6-4bd8-9f01-8dd19f291c02	4b690648-0503-432d-8f18-cdca84d07459	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	1234	2026-04-14 10:06:18.49463+00
3eb26e58-d4df-4cfd-8282-9ceeecd17a39	f96b02fe-6fe2-475d-b707-1364344fc0e2	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-04-14 10:06:38.477528+00
0896be92-ff02-4d76-83ce-bd3cb0c780bd	f96b02fe-6fe2-475d-b707-1364344fc0e2	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-04-14 10:06:38.602597+00
bd11e2cd-83e8-4abd-ae6d-4e1d31348463	f96b02fe-6fe2-475d-b707-1364344fc0e2	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-04-14 10:06:38.727515+00
7ec9cbea-fd82-4673-b841-4722049ae25a	f96b02fe-6fe2-475d-b707-1364344fc0e2	0b9672ca-b402-4b76-bd72-1957304940a1		2026-04-14 10:06:38.853167+00
3be17c8c-b0d2-427c-9dab-6e751676c05f	f96b02fe-6fe2-475d-b707-1364344fc0e2	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-04-14 10:06:38.978485+00
a36c07c0-2761-498b-b78c-374a2d22f5ad	f96b02fe-6fe2-475d-b707-1364344fc0e2	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-04-14 10:06:39.103281+00
809e7d98-d767-4112-bf29-de2007829276	f96b02fe-6fe2-475d-b707-1364344fc0e2	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-04-14 10:06:39.228342+00
6b4f28f3-dfe3-4753-aa3e-7855bfe00ed3	f96b02fe-6fe2-475d-b707-1364344fc0e2	8f209177-d1f1-4419-bc20-707ccd166660		2026-04-14 10:06:39.353033+00
5f35b98c-5993-4fe9-ac0c-1093bbc70e65	f96b02fe-6fe2-475d-b707-1364344fc0e2	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-04-14 10:06:39.478914+00
2606fc49-b999-4495-ba5e-94b789f72f05	f96b02fe-6fe2-475d-b707-1364344fc0e2	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-14 10:06:39.603664+00
27ac0892-a967-41f8-9cc7-cc76586c6907	f96b02fe-6fe2-475d-b707-1364344fc0e2	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-14 10:06:39.728758+00
6bc6bd7c-52c5-4971-96df-82e29120ac06	f96b02fe-6fe2-475d-b707-1364344fc0e2	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-14 10:06:40.101843+00
d638262c-74d1-4f05-9535-54200b87900e	f96b02fe-6fe2-475d-b707-1364344fc0e2	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-14 10:06:40.227849+00
fa11dc7c-2ff7-44d7-985e-3e3a17c8df29	f96b02fe-6fe2-475d-b707-1364344fc0e2	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-14 10:06:40.355801+00
c0f2d474-631e-48b4-ab78-7e6ed8c717d7	f96b02fe-6fe2-475d-b707-1364344fc0e2	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-14 10:06:40.481107+00
0bc077c5-8842-4617-b756-e12a4aae9329	f96b02fe-6fe2-475d-b707-1364344fc0e2	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-14 10:06:40.60723+00
5a052d36-39f2-48ff-b178-ff1c745ccdf3	f96b02fe-6fe2-475d-b707-1364344fc0e2	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	123	2026-04-14 10:20:45.979999+00
c2ec2a3b-6624-4f34-aefb-0551e2c18603	f96b02fe-6fe2-475d-b707-1364344fc0e2	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	321	2026-04-14 10:20:46.105092+00
99b38cda-bc3e-4e08-9c4c-c9f6085906fc	f487a644-e906-44e5-bd04-b6976e8ed246	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-04-14 11:03:40.530669+00
2a12da85-2e0c-4cc9-bde6-1ee749895503	f487a644-e906-44e5-bd04-b6976e8ed246	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-04-14 11:03:40.902497+00
a3144950-2782-4c2b-a834-b196e52bc0e2	f487a644-e906-44e5-bd04-b6976e8ed246	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-04-14 11:03:41.028095+00
767e3e13-b162-4004-9dd9-e725294f8add	f487a644-e906-44e5-bd04-b6976e8ed246	0b9672ca-b402-4b76-bd72-1957304940a1		2026-04-14 11:03:41.153712+00
33edec4b-430e-45ac-ae1c-33df782737f8	f487a644-e906-44e5-bd04-b6976e8ed246	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-04-14 11:03:41.278803+00
02939f5c-b940-43f0-86b5-e367cf470f5d	f487a644-e906-44e5-bd04-b6976e8ed246	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-04-14 11:03:41.404412+00
d65b7f6d-e129-419b-8029-e1eeede2fdf8	f487a644-e906-44e5-bd04-b6976e8ed246	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-04-14 11:03:41.528942+00
b6948380-a1bf-4497-9c91-6629ef38bb2b	f487a644-e906-44e5-bd04-b6976e8ed246	8f209177-d1f1-4419-bc20-707ccd166660		2026-04-14 11:03:41.653841+00
54b8e3a7-8713-43ec-a9b9-749e5700641c	f487a644-e906-44e5-bd04-b6976e8ed246	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-04-14 11:03:41.777694+00
2ea2c4ff-93c2-446f-b7cd-8520a26a6de0	f487a644-e906-44e5-bd04-b6976e8ed246	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-14 11:03:41.902419+00
fb3c0bf3-9afc-4863-8d90-f9a5551e6a25	f487a644-e906-44e5-bd04-b6976e8ed246	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-14 11:03:42.026422+00
b7468503-985f-4866-8c13-915ce9cdd0c8	f487a644-e906-44e5-bd04-b6976e8ed246	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-14 11:03:42.150196+00
9b7c3e2f-f95b-4b71-9338-66c83c3ccb8b	f487a644-e906-44e5-bd04-b6976e8ed246	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-14 11:03:42.27334+00
d0f2f840-7ca4-45dd-b94a-22f9b6142b59	f487a644-e906-44e5-bd04-b6976e8ed246	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-14 11:03:42.396714+00
c09b96d1-e306-402c-b924-68a81d67f0bb	f487a644-e906-44e5-bd04-b6976e8ed246	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-14 11:03:42.520259+00
8e0d8c11-3475-4112-9812-ad38260253e5	f487a644-e906-44e5-bd04-b6976e8ed246	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-14 11:03:42.643124+00
2b65a8f2-48c5-4c60-84c5-3cfeefcd26c2	f487a644-e906-44e5-bd04-b6976e8ed246	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	111	2026-04-14 11:04:20.031427+00
770007d2-a817-4bb5-932d-1e4939a98074	f487a644-e906-44e5-bd04-b6976e8ed246	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	333	2026-04-14 11:04:20.155285+00
8210822a-5907-4b20-a638-cfc27a88e396	51de989d-f268-4549-9350-43368046090a	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-04-14 11:06:13.378061+00
3f9de40e-85f1-4580-b481-e0e090f40a34	51de989d-f268-4549-9350-43368046090a	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-04-14 11:06:13.503511+00
0eee0970-e218-4273-9e6a-84c09f0574b2	51de989d-f268-4549-9350-43368046090a	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-04-14 11:06:13.62979+00
dac8de11-a73d-4ee9-9069-80813b90d7da	51de989d-f268-4549-9350-43368046090a	0b9672ca-b402-4b76-bd72-1957304940a1		2026-04-14 11:06:13.755058+00
5d4531bf-262e-41d6-b914-d8b6682c28f1	51de989d-f268-4549-9350-43368046090a	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-04-14 11:06:13.879348+00
5712a8a6-a365-48f7-9245-1334335e221b	51de989d-f268-4549-9350-43368046090a	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-04-14 11:06:14.004212+00
05e64b4d-79e0-4bab-a305-cde96db384e7	51de989d-f268-4549-9350-43368046090a	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-04-14 11:06:14.128862+00
4fa496cc-bf14-461b-a84b-39866a7baf06	51de989d-f268-4549-9350-43368046090a	8f209177-d1f1-4419-bc20-707ccd166660		2026-04-14 11:06:14.252825+00
b63d8663-05a0-4a40-8ab9-1c41c82e64e6	51de989d-f268-4549-9350-43368046090a	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-04-14 11:06:14.376226+00
d7bb3452-1722-4b8b-9f37-731b10a68988	51de989d-f268-4549-9350-43368046090a	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-14 11:06:14.499866+00
09c76d2a-4dcf-4b06-b43a-8d1fecfc29e2	51de989d-f268-4549-9350-43368046090a	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-14 11:06:14.623429+00
43e4a9d7-5cee-4209-92c8-174868fdf10f	51de989d-f268-4549-9350-43368046090a	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-14 11:06:14.746203+00
34529858-f558-4137-96a4-1667602fdd97	51de989d-f268-4549-9350-43368046090a	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-14 11:06:14.86946+00
c9b41fd2-849a-43c0-bebd-1b0611dce08f	51de989d-f268-4549-9350-43368046090a	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-14 11:06:14.992891+00
c60c169b-0d4e-40eb-ac79-36f0fce2b018	51de989d-f268-4549-9350-43368046090a	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-14 11:06:15.116064+00
bfc96d9d-5651-446a-a3ff-a17d1f65215f	51de989d-f268-4549-9350-43368046090a	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-14 11:06:15.239014+00
759e2643-cb40-4f1f-8150-15446d3ce7ad	51de989d-f268-4549-9350-43368046090a	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	123	2026-04-14 11:08:00.553855+00
a3d04889-6f92-4640-b868-b4acd009a70b	51de989d-f268-4549-9350-43368046090a	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	333	2026-04-14 11:08:00.677723+00
8e020700-b48a-4625-bb92-86bcb9011505	cbcde15a-db1b-4483-b12c-730b591525d4	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-04-14 11:09:02.333266+00
aba4c830-724d-487f-a223-0fd3c0d867db	cbcde15a-db1b-4483-b12c-730b591525d4	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-04-14 11:09:02.457529+00
037c9bbd-cbd3-4693-98df-b4db5fcd9934	cbcde15a-db1b-4483-b12c-730b591525d4	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-04-14 11:09:02.582514+00
86bc3c61-94e3-45e4-ae73-ecbaf8ba096e	cbcde15a-db1b-4483-b12c-730b591525d4	0b9672ca-b402-4b76-bd72-1957304940a1		2026-04-14 11:09:02.706246+00
79eaf9ba-e9f1-47f0-bdf4-b9c15708ec93	cbcde15a-db1b-4483-b12c-730b591525d4	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-04-14 11:09:02.830049+00
c613b680-7ead-4686-af35-13f898070f47	cbcde15a-db1b-4483-b12c-730b591525d4	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-04-14 11:09:02.953934+00
f02793e8-cdb4-40b2-8a24-c3e50c7fb038	cbcde15a-db1b-4483-b12c-730b591525d4	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-04-14 11:09:03.077041+00
f83f8932-6bad-4c28-a9b0-bf2305d5c898	cbcde15a-db1b-4483-b12c-730b591525d4	8f209177-d1f1-4419-bc20-707ccd166660		2026-04-14 11:09:03.200071+00
e196da2b-5d17-439c-9980-1f5161f38b81	cbcde15a-db1b-4483-b12c-730b591525d4	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-04-14 11:09:03.324637+00
d5b0ff01-a4c6-4d08-af17-dec812f6b650	cbcde15a-db1b-4483-b12c-730b591525d4	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-14 11:09:03.448446+00
15dc55ed-ee62-4732-ba3e-9749b054afb9	cbcde15a-db1b-4483-b12c-730b591525d4	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-14 11:09:03.572488+00
e4e7406f-01b3-4ca8-bbbc-5a8d3929adfb	cbcde15a-db1b-4483-b12c-730b591525d4	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-14 11:09:03.696098+00
7e9f745b-0820-4211-b400-bdac30237da6	cbcde15a-db1b-4483-b12c-730b591525d4	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-14 11:09:03.818314+00
6009ae9e-2cee-40b7-aa47-bd5b25078e3b	cbcde15a-db1b-4483-b12c-730b591525d4	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-14 11:09:03.942959+00
56d8b218-382e-4435-a99c-5cfcc90927a5	cbcde15a-db1b-4483-b12c-730b591525d4	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-14 11:09:04.068094+00
c39ea8db-c7f7-49c7-9fc3-99911ea73587	cbcde15a-db1b-4483-b12c-730b591525d4	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-14 11:09:04.193963+00
2e39df6b-0cba-42ec-9548-463561043190	cbcde15a-db1b-4483-b12c-730b591525d4	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	1233	2026-04-14 11:09:13.079559+00
bbc93798-faad-44aa-823b-3f264698d6cb	cbcde15a-db1b-4483-b12c-730b591525d4	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	333	2026-04-14 11:09:13.202642+00
50c7b16e-601b-423c-8c06-b6fbc8c16b01	7cd40836-627b-40ff-9dc1-332d2b3092c9	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-04-14 11:12:13.397122+00
0daebd61-67b5-4021-9285-72058edf9c4e	7cd40836-627b-40ff-9dc1-332d2b3092c9	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-04-14 11:12:13.52239+00
7a4223ad-a980-4c32-8efd-9eb384161033	7cd40836-627b-40ff-9dc1-332d2b3092c9	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-04-14 11:12:13.646232+00
b458d2bd-e2ab-451e-9768-d3336122df44	7cd40836-627b-40ff-9dc1-332d2b3092c9	0b9672ca-b402-4b76-bd72-1957304940a1		2026-04-14 11:12:13.770982+00
655ecb0c-4edf-4063-a1dd-cbaacf0bed20	7cd40836-627b-40ff-9dc1-332d2b3092c9	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-04-14 11:12:13.894231+00
699cdefe-d5d1-4cbf-88a4-a025ab5c8a12	7cd40836-627b-40ff-9dc1-332d2b3092c9	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-04-14 11:12:14.016489+00
dff74af2-0e90-4ddd-954f-21e629271433	7cd40836-627b-40ff-9dc1-332d2b3092c9	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-04-14 11:12:14.139057+00
c973841b-b814-4e23-a0d2-04b8fba329f2	7cd40836-627b-40ff-9dc1-332d2b3092c9	8f209177-d1f1-4419-bc20-707ccd166660		2026-04-14 11:12:14.261324+00
fc000939-97b7-4d05-85a2-ffdff5756f4a	7cd40836-627b-40ff-9dc1-332d2b3092c9	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-04-14 11:12:14.383912+00
1a1bccd6-adfb-4569-b72f-a470556b049c	7cd40836-627b-40ff-9dc1-332d2b3092c9	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-14 11:12:14.506394+00
ffc84081-c35e-4b42-af96-cce916cd3d41	7cd40836-627b-40ff-9dc1-332d2b3092c9	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-14 11:12:14.628503+00
5574c2a7-b736-4ecd-b10f-9c0dcc7c278f	7cd40836-627b-40ff-9dc1-332d2b3092c9	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-14 11:12:14.750623+00
a6e65e18-c890-42a8-a443-e991794bb922	7cd40836-627b-40ff-9dc1-332d2b3092c9	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-14 11:12:14.873753+00
582fd56e-5f16-4968-8cd8-0921f109cd7b	7cd40836-627b-40ff-9dc1-332d2b3092c9	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-14 11:12:14.995615+00
500ec338-12b3-4e64-b059-f9cac86ea82c	7cd40836-627b-40ff-9dc1-332d2b3092c9	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-14 11:12:15.119984+00
389e4cae-aaae-4f0c-bc8b-7ccd73322bd9	7cd40836-627b-40ff-9dc1-332d2b3092c9	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-14 11:12:15.245113+00
14004acb-7e3f-4a09-9116-4da0ba31e18c	7cd40836-627b-40ff-9dc1-332d2b3092c9	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	12333	2026-04-14 11:12:22.348961+00
b2bfed10-12dc-454d-a83b-67332f41576d	7cd40836-627b-40ff-9dc1-332d2b3092c9	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	3333	2026-04-14 11:12:22.47219+00
6dfb33dc-0fbe-4ab2-9a31-35b4436c703c	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-04-14 11:12:49.297446+00
5b66d7ef-5a0e-4397-96cb-8b1c0ef39dd1	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-04-14 11:12:49.417924+00
40a2c5ca-1bfd-4050-92eb-2c26d47244d2	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-04-14 11:12:49.539583+00
8cf46715-a9dc-4c15-b622-8a1bc772220d	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	0b9672ca-b402-4b76-bd72-1957304940a1		2026-04-14 11:12:49.662504+00
4bc234b5-a27a-450c-80d5-8b7cfda61eb2	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-04-14 11:12:49.785374+00
e4d92cd0-8881-49fe-84d6-fadabf26e5e7	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-04-14 11:12:49.90733+00
02f825a2-12a7-4334-b949-329f34914b32	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-04-14 11:12:50.029714+00
a4d783fe-f9c0-423e-b35c-a8d493d48037	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	8f209177-d1f1-4419-bc20-707ccd166660		2026-04-14 11:12:50.152221+00
f38bfe36-86d3-4afd-a870-f545977f53af	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-04-14 11:12:50.27429+00
07f3cf1e-b6e4-443e-adcd-23426d7124a7	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-14 11:12:50.397122+00
2672fbe8-f295-4d8f-bcfe-85acabc485cc	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-14 11:12:50.519717+00
2be174f0-5921-4da8-966b-c449a1902906	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-14 11:12:50.642107+00
1db44d04-9d40-4997-8a74-bc4be1fcc87b	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-14 11:12:50.765238+00
8544bc09-d192-4bc7-af24-513ce20ed1a0	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-14 11:12:50.888802+00
042c98ed-bfc3-4509-9fb8-39197326f98f	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-14 11:12:51.012196+00
767d2fd0-fea5-40cc-802d-1d2db712876d	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-14 11:12:51.134724+00
d23ae784-7166-4213-8b0c-2d37341c0ec5	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-04-14 11:15:31.126451+00
4fe3b379-6e59-43e9-b294-6ebbe143a911	4269a9a3-5f0c-4373-8ea4-7fd4469cecce	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-04-14 11:15:31.248977+00
09503943-243e-4484-b88f-00cca66946a2	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	444	2026-04-14 11:20:28.745587+00
f40c3a72-63d9-4629-b350-3347295924c4	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	444	2026-04-14 11:20:28.867715+00
f45d561e-4dfc-4cbe-ac80-d7e95a24519c	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-04-14 11:20:28.991252+00
ff69f0fd-8a19-4470-a024-92e8ac8ae9dc	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-04-14 11:20:29.114517+00
f6c1d660-535d-488a-a8ea-307754f706cc	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-04-14 11:20:29.236768+00
4a158661-211f-4f49-85a2-96d8bb06afd7	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	0b9672ca-b402-4b76-bd72-1957304940a1		2026-04-14 11:20:29.359245+00
ae0357aa-56c7-4237-a392-9b225ae406b0	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-04-14 11:20:29.481307+00
abe1a8a1-a5c6-4818-ab14-06fa714b4e35	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-04-14 11:20:29.604908+00
4f2ca4e7-29b0-4aaf-b6ed-03a3f08c2794	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-04-14 11:20:29.727282+00
68852fcb-ea5b-4bab-9fd0-9303474c1185	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	8f209177-d1f1-4419-bc20-707ccd166660		2026-04-14 11:20:29.849266+00
a4a36749-19d0-41f4-a146-9c98875d6240	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-04-14 11:20:29.970954+00
ace44409-f055-4016-994a-6c40e91f6bef	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-14 11:20:30.093484+00
4854aa67-1e9a-40e4-ad06-01bfb5269847	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-14 11:20:30.215225+00
95eee469-dbe4-4789-8d60-ab302ccb7901	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-14 11:20:30.337181+00
135a6aa8-26e3-43c5-9936-a8edaae366d0	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-14 11:20:30.458919+00
14151898-3be1-45ff-9abc-269289880c9f	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-14 11:20:30.581167+00
c4b8d882-2ce4-4d2a-8138-cd67bcf70d96	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-14 11:20:30.702486+00
d304839d-b25e-4787-85b7-e98c45d2d334	9340618a-3c17-4cbd-ab2d-5e45b8e682dc	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-14 11:20:30.823888+00
a0fe7179-50d9-4dca-8302-e9cb36723bab	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	123	2026-04-14 20:50:25.012436+00
ac26b134-36a8-497e-9d7c-ca99392a86fe	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	123	2026-04-14 20:50:25.409971+00
1f0d1cad-867c-46b3-b6be-efff5bd2241a	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-04-14 20:50:25.850626+00
3c92b8e2-f1aa-4e7c-b91d-245b5f553211	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-04-14 20:50:26.246544+00
4d4276d3-b60d-498e-ad81-e7bc6394b85f	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-04-14 20:50:26.642862+00
fd59b6d7-5b1e-46bb-923b-71fb598db372	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	0b9672ca-b402-4b76-bd72-1957304940a1		2026-04-14 20:50:27.038993+00
4c0a0346-93b6-49e7-8a8a-8b5b1f0aec9c	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-04-14 20:50:27.434313+00
951d9f83-b8d0-4cba-80bf-97255a4edd25	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-04-14 20:50:27.830035+00
18b11bdc-ab6e-4efc-9df0-c5c27db100e6	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-04-14 20:50:28.224181+00
f2441b0e-e26f-48fc-b657-a185b06c96b1	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	8f209177-d1f1-4419-bc20-707ccd166660		2026-04-14 20:50:28.620259+00
e6cac9aa-345b-4f6d-804d-e3acaa335fa9	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-04-14 20:50:29.028354+00
882cc1bb-71c6-4260-ae67-21e1d25543b3	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-14 20:50:29.423324+00
c1605e34-a9a5-4fec-8b9f-e8cb0e2486e7	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-14 20:50:29.818343+00
0c5d9218-fb7c-4cc6-9e4d-f43a6ccacf70	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-14 20:50:30.214014+00
560c0811-31fa-4d12-97f0-ec8d5fea6616	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-14 20:50:30.608924+00
0842578a-7563-477a-9103-4e72af463dfb	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-14 20:50:31.003086+00
e68702a9-1a48-4bfa-9282-847860aa66c2	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-14 20:50:31.396846+00
b757a29c-b2ff-4604-a746-5f68c5c3daf1	6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-14 20:50:31.791188+00
326d95f4-8bab-4d22-8398-163310041933	21f0248c-6b10-4063-92d0-27817f8e09a7	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	333	2026-04-14 20:50:52.077176+00
b7bf2c4f-7ebf-43ad-ac25-da6ab5b0fbb8	21f0248c-6b10-4063-92d0-27817f8e09a7	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	333	2026-04-14 20:50:52.522197+00
f24d3ec7-71cc-416c-9666-9a151ed7a201	21f0248c-6b10-4063-92d0-27817f8e09a7	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-04-14 20:50:52.923604+00
4aebaf0b-e616-4e1b-8e1a-d8cb166a2238	21f0248c-6b10-4063-92d0-27817f8e09a7	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-04-14 20:50:53.323664+00
556d44dc-f3e8-41e0-a82a-0ef3bc0abf9c	21f0248c-6b10-4063-92d0-27817f8e09a7	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-04-14 20:50:53.724733+00
1c0f993c-418c-4ed1-85ea-a2f03752c82b	21f0248c-6b10-4063-92d0-27817f8e09a7	0b9672ca-b402-4b76-bd72-1957304940a1		2026-04-14 20:50:54.12494+00
e465e99a-de1c-40d1-abab-b2840263767f	21f0248c-6b10-4063-92d0-27817f8e09a7	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-04-14 20:50:54.524944+00
8b727485-6f09-4cf5-aca7-82f2fe91dc40	21f0248c-6b10-4063-92d0-27817f8e09a7	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-04-14 20:50:54.924779+00
a854cd29-abfb-4df1-91b7-be4a403d8b48	21f0248c-6b10-4063-92d0-27817f8e09a7	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-04-14 20:50:55.324114+00
c240cfb9-38ca-4ce4-9680-b38ba725381e	21f0248c-6b10-4063-92d0-27817f8e09a7	8f209177-d1f1-4419-bc20-707ccd166660		2026-04-14 20:50:55.725651+00
bb3e674e-d956-4c6e-a749-4ef6bebe3c41	21f0248c-6b10-4063-92d0-27817f8e09a7	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-04-14 20:50:56.126367+00
d44e2c7a-216f-4607-bf8f-5bb5687389b0	21f0248c-6b10-4063-92d0-27817f8e09a7	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-14 20:50:56.525874+00
30997fde-3ee8-458d-9645-0beacdb779bf	21f0248c-6b10-4063-92d0-27817f8e09a7	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-14 20:50:56.925589+00
1b342aab-9b27-4df2-9126-90d148f89c3a	21f0248c-6b10-4063-92d0-27817f8e09a7	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-14 20:50:57.324612+00
348097cc-3b69-4395-86a6-022c88790911	21f0248c-6b10-4063-92d0-27817f8e09a7	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-14 20:50:57.723111+00
dd46eef8-8579-4e2b-9006-fcca8a2ad2ea	21f0248c-6b10-4063-92d0-27817f8e09a7	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-14 20:50:58.122173+00
6b3003a8-011e-421b-bb2a-2f0ecc5c1755	21f0248c-6b10-4063-92d0-27817f8e09a7	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-14 20:50:58.521788+00
c37d4bb4-9822-441e-b0e0-0cd9e5b17ece	21f0248c-6b10-4063-92d0-27817f8e09a7	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-14 20:50:58.921407+00
eda4602c-60ad-4be5-89bb-74eed064fb10	8e252b7f-03d9-4371-8008-cefb05291a27	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	1	2026-04-22 12:02:24.434479+00
60ee9805-32d6-435e-87fd-3acf0819aa66	8e252b7f-03d9-4371-8008-cefb05291a27	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	1010	2026-04-22 12:02:24.700972+00
dadd53f7-3b71-4a6f-a81e-4e59ab1a07f5	8e252b7f-03d9-4371-8008-cefb05291a27	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-04-22 12:02:24.964728+00
2ddfb37d-7433-4c68-af3f-a858eb87c5d8	8e252b7f-03d9-4371-8008-cefb05291a27	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-04-22 12:02:25.235812+00
34a81a95-8bd8-4a39-8e91-850581d3d63c	8e252b7f-03d9-4371-8008-cefb05291a27	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-04-22 12:02:25.507169+00
be245b1c-c2db-40f4-b6c6-c5c474f29c2f	8e252b7f-03d9-4371-8008-cefb05291a27	0b9672ca-b402-4b76-bd72-1957304940a1		2026-04-22 12:02:25.776218+00
4e927d44-06be-433b-b0a6-1e19b25d5d77	8e252b7f-03d9-4371-8008-cefb05291a27	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-04-22 12:02:26.041133+00
60935777-f190-46e0-a3b3-150fc2fa141e	8e252b7f-03d9-4371-8008-cefb05291a27	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-04-22 12:02:26.317471+00
c1839b79-65ec-43dd-a303-001d188a998d	8e252b7f-03d9-4371-8008-cefb05291a27	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-04-22 12:02:26.582047+00
d72540b7-a29e-4df8-898a-1a237a9a2d58	8e252b7f-03d9-4371-8008-cefb05291a27	8f209177-d1f1-4419-bc20-707ccd166660		2026-04-22 12:02:26.845034+00
8cdaa054-fab0-4061-b493-c34532a6515d	8e252b7f-03d9-4371-8008-cefb05291a27	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-04-22 12:02:27.111563+00
c02a7772-216e-4638-ba2f-9a144f539135	8e252b7f-03d9-4371-8008-cefb05291a27	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-22 12:02:27.37732+00
269d3d1e-b2e5-4748-a29b-788c7e7694e9	8e252b7f-03d9-4371-8008-cefb05291a27	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-22 12:02:27.64222+00
4b009242-d70b-4950-8592-eb1433aa367e	8e252b7f-03d9-4371-8008-cefb05291a27	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-22 12:02:27.904906+00
c2c4c23b-14ae-4381-b201-889e134a1cd5	8e252b7f-03d9-4371-8008-cefb05291a27	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-22 12:02:28.170939+00
dd8ac262-bd4f-4b22-8a1f-549e542c66f0	8e252b7f-03d9-4371-8008-cefb05291a27	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-22 12:02:28.435345+00
b54f9a22-0cbe-488d-9188-10f2058f6a94	8e252b7f-03d9-4371-8008-cefb05291a27	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-22 12:02:28.696719+00
553024ba-7857-4c91-b4e2-db343665f5ac	8e252b7f-03d9-4371-8008-cefb05291a27	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-22 12:02:28.958252+00
bd709938-fb52-40a2-86bb-d8345a2cce04	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	1	2026-04-26 16:31:25.427969+00
a28dbf21-1da8-4cca-aa2d-eca7b5d2ae9d	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	1	2026-04-26 16:31:26.123082+00
042f9a82-2442-48d6-81f2-cc99d9d03b22	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	cb2e05b8-5feb-47b8-933a-868b1e703342	1	2026-04-26 16:31:26.811635+00
38f44b9d-4083-4849-b394-a42227337e57	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	0efafdb9-d607-4960-97f7-4c93eebe8c54	1	2026-04-26 16:31:27.499317+00
97a195f7-7df9-4285-9614-a6ab176a397a	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	05baf163-db0d-4b25-80ba-05b5b80e4c69	1	2026-04-26 16:31:28.187825+00
909c02b5-28d7-40ab-bf94-92e6a37b12f0	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	0b9672ca-b402-4b76-bd72-1957304940a1	1	2026-04-26 16:31:28.874945+00
395bc64a-4fb2-4561-a051-5b901f573bba	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	b7e6b576-fc4d-453c-bdab-27dc5452157c	1	2026-04-26 16:31:29.562359+00
e68a4ab1-c9d0-4560-ba4c-67d615d0ae0d	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	1	2026-04-26 16:31:30.248215+00
be779330-e202-4cd8-a341-12340bb62015	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	7cc0365f-3df4-4389-93f7-6f3907b1d014	1	2026-04-26 16:31:30.937725+00
b7e5f39a-9c31-4950-8bbf-77be6ed2d561	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	8f209177-d1f1-4419-bc20-707ccd166660	1	2026-04-26 16:31:31.623468+00
29818450-dd14-412c-996e-536807bd16da	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	1	2026-04-26 16:31:32.309989+00
3e78b743-841b-4bb6-975d-ae26afc7b47c	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	80497194-a652-4edc-9fcb-5c90d9e9d88f	1	2026-04-26 16:31:32.99615+00
dc5498d0-a04d-4bca-acaf-6333950fee8e	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5	1	2026-04-26 16:31:33.681235+00
e78b7258-41ce-44bf-9e03-f23d1b7eb120	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	734cd218-e0cc-4267-8226-8cafa57be5b9	1	2026-04-26 16:31:34.365121+00
2d56053d-1e2e-4a4c-896d-2128b6842c2a	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	cf3783f3-556c-4bf6-94ab-968d28be63d4	ё	2026-04-26 16:31:35.049936+00
1bb9f758-59a4-456a-966b-3d74034668ed	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	c3fe8886-d3f1-4972-9d51-901392b86864	1	2026-04-26 16:31:35.736399+00
804e8ef1-c84f-4b33-9a1a-a67c0392b18c	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	321d0540-1a62-4508-a5b4-f7bb9f2af4a0	ё	2026-04-26 16:31:36.423967+00
a0356cfe-0ed6-4979-9a87-15eadb3246be	629d9b0d-b1ae-423c-a73d-f2a6e27bf862	0e7cb6e2-86c6-469f-8520-c7d7d5029604	ё	2026-04-26 16:31:37.110025+00
48d2484c-2fb1-4cf0-a48d-3dc188585d64	bda56821-2734-4433-8acc-3372a1a5fbcb	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	2	2026-04-26 16:35:26.59624+00
cece681d-5fb6-43c7-9d21-1590a390c02f	bda56821-2734-4433-8acc-3372a1a5fbcb	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	2	2026-04-26 16:35:27.285039+00
7581ace3-b9cd-48c1-a2c3-2658dc77c0bb	bda56821-2734-4433-8acc-3372a1a5fbcb	cb2e05b8-5feb-47b8-933a-868b1e703342	2	2026-04-26 16:35:27.969834+00
f7564202-dc26-4e37-8993-1fe9c5ba489a	bda56821-2734-4433-8acc-3372a1a5fbcb	0efafdb9-d607-4960-97f7-4c93eebe8c54	2	2026-04-26 16:35:28.653384+00
787676d0-4acc-4bb3-8ccc-4e817afc6961	bda56821-2734-4433-8acc-3372a1a5fbcb	05baf163-db0d-4b25-80ba-05b5b80e4c69	2	2026-04-26 16:35:29.3395+00
d57d0d02-82bd-4acd-b6c6-589d85da01cf	bda56821-2734-4433-8acc-3372a1a5fbcb	0b9672ca-b402-4b76-bd72-1957304940a1	2	2026-04-26 16:35:30.025698+00
898fe4a8-c708-4736-87e8-164a66416e5f	bda56821-2734-4433-8acc-3372a1a5fbcb	b7e6b576-fc4d-453c-bdab-27dc5452157c	2	2026-04-26 16:35:30.713575+00
a8d2f16a-2561-47c7-b8ce-924edd6a31aa	bda56821-2734-4433-8acc-3372a1a5fbcb	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	2	2026-04-26 16:35:31.407619+00
bf431370-1b35-4f4b-bb34-5e667645252d	bda56821-2734-4433-8acc-3372a1a5fbcb	7cc0365f-3df4-4389-93f7-6f3907b1d014	2	2026-04-26 16:35:32.093813+00
95389d63-c700-4810-bc90-a032d04716de	bda56821-2734-4433-8acc-3372a1a5fbcb	8f209177-d1f1-4419-bc20-707ccd166660	2	2026-04-26 16:35:32.7789+00
3aa89133-aa8c-4d6e-b92f-5fd8a4f767e0	bda56821-2734-4433-8acc-3372a1a5fbcb	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	2	2026-04-26 16:35:33.467684+00
9441bbc4-b942-42f1-88ed-179138fcea3e	bda56821-2734-4433-8acc-3372a1a5fbcb	80497194-a652-4edc-9fcb-5c90d9e9d88f	2	2026-04-26 16:35:34.176139+00
533dd6f6-a1c7-4e7c-b8ea-cc8f46f800f9	bda56821-2734-4433-8acc-3372a1a5fbcb	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5	2	2026-04-26 16:35:34.892632+00
685bff93-5119-4491-b538-9acdfd7cd04c	bda56821-2734-4433-8acc-3372a1a5fbcb	734cd218-e0cc-4267-8226-8cafa57be5b9	2	2026-04-26 16:35:35.58472+00
6330fd8f-c320-457e-a3bc-eb14eb27c10a	bda56821-2734-4433-8acc-3372a1a5fbcb	cf3783f3-556c-4bf6-94ab-968d28be63d4	ж	2026-04-26 16:35:36.565684+00
ceab8680-cd07-4d8f-92ee-626ef7076cc8	bda56821-2734-4433-8acc-3372a1a5fbcb	c3fe8886-d3f1-4972-9d51-901392b86864	2	2026-04-26 16:35:37.25113+00
821aa5c5-1b79-460a-bde0-0527332794ea	bda56821-2734-4433-8acc-3372a1a5fbcb	321d0540-1a62-4508-a5b4-f7bb9f2af4a0	ж	2026-04-26 16:35:37.935003+00
fc645190-8813-4e94-bc9c-3e135da5fbe0	bda56821-2734-4433-8acc-3372a1a5fbcb	0e7cb6e2-86c6-469f-8520-c7d7d5029604	ж	2026-04-26 16:35:38.629552+00
51a0cd97-9caa-4536-bc05-771ba95e586c	3eff7af1-d40a-423c-9365-761ad005fea8	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	10	2026-04-26 16:42:47.626725+00
10cae8bd-ecce-4ae8-8b2f-f7384464bdba	3eff7af1-d40a-423c-9365-761ad005fea8	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	10	2026-04-26 16:42:48.31215+00
a1d208a3-4b68-44c8-b5c2-5dd3dea6f9d4	3eff7af1-d40a-423c-9365-761ad005fea8	cb2e05b8-5feb-47b8-933a-868b1e703342	10	2026-04-26 16:42:48.998281+00
60649fe7-1c42-45e4-9789-9e2d3075340f	3eff7af1-d40a-423c-9365-761ad005fea8	0efafdb9-d607-4960-97f7-4c93eebe8c54	10	2026-04-26 16:42:49.714105+00
e102a609-e5be-456f-8de9-0becf62fd989	3eff7af1-d40a-423c-9365-761ad005fea8	05baf163-db0d-4b25-80ba-05b5b80e4c69	10	2026-04-26 16:42:50.39918+00
d416df40-aeed-42c1-bc4a-91fd20b33c0b	3eff7af1-d40a-423c-9365-761ad005fea8	0b9672ca-b402-4b76-bd72-1957304940a1	10	2026-04-26 16:42:51.084689+00
36542684-6ba2-4ef0-a2e4-94f75eae7a6c	3eff7af1-d40a-423c-9365-761ad005fea8	b7e6b576-fc4d-453c-bdab-27dc5452157c	10	2026-04-26 16:42:51.775614+00
9e8a7ad8-e850-464e-9ed0-bffa6b85d49f	3eff7af1-d40a-423c-9365-761ad005fea8	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	10	2026-04-26 16:42:52.466754+00
2932f4ed-519e-4974-b29a-a398d1bd444d	3eff7af1-d40a-423c-9365-761ad005fea8	7cc0365f-3df4-4389-93f7-6f3907b1d014	10	2026-04-26 16:42:53.154257+00
72aba627-d8ae-48e9-81ad-22a1aa912e8e	3eff7af1-d40a-423c-9365-761ad005fea8	8f209177-d1f1-4419-bc20-707ccd166660	10	2026-04-26 16:42:53.840711+00
99e9b863-d37a-489c-bf31-7ab7f3514edd	3eff7af1-d40a-423c-9365-761ad005fea8	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	10	2026-04-26 16:42:54.525582+00
9f533a1c-8f63-43bc-9bfc-858aa7fd2881	3eff7af1-d40a-423c-9365-761ad005fea8	80497194-a652-4edc-9fcb-5c90d9e9d88f	10	2026-04-26 16:42:55.213211+00
a90da11e-3a47-410a-8247-58433f07081a	3eff7af1-d40a-423c-9365-761ad005fea8	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5	10	2026-04-26 16:42:55.897157+00
d5e03594-ff91-497d-8e9c-6c8214fc9d9e	3eff7af1-d40a-423c-9365-761ad005fea8	734cd218-e0cc-4267-8226-8cafa57be5b9	10	2026-04-26 16:42:56.584313+00
e099e49f-1841-4759-a4fa-81be61b0db42	3eff7af1-d40a-423c-9365-761ad005fea8	cf3783f3-556c-4bf6-94ab-968d28be63d4	з	2026-04-26 16:42:57.267961+00
7b718520-f477-4762-b1dd-4aea68bbd2a1	3eff7af1-d40a-423c-9365-761ad005fea8	c3fe8886-d3f1-4972-9d51-901392b86864	10	2026-04-26 16:42:57.951557+00
f20309df-8a09-4c4c-b00a-924f90e1e7d0	3eff7af1-d40a-423c-9365-761ad005fea8	321d0540-1a62-4508-a5b4-f7bb9f2af4a0	з	2026-04-26 16:42:58.63617+00
59897b9f-c661-45de-9521-5c38a2eb19d9	3eff7af1-d40a-423c-9365-761ad005fea8	0e7cb6e2-86c6-469f-8520-c7d7d5029604	з	2026-04-26 16:42:59.319684+00
14b2bbf2-9fc9-4cfe-a878-6d08cb0e3f0a	ab1c3abd-8560-481f-8970-89621dd41fef	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-04-27 17:23:19.726627+00
efaa21e1-fe47-4cd1-9bf8-c29d5e88cd83	ab1c3abd-8560-481f-8970-89621dd41fef	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	12	2026-04-27 17:23:20.401805+00
c482686b-165e-4e67-9d29-b8bfa6a8725a	ab1c3abd-8560-481f-8970-89621dd41fef	cb2e05b8-5feb-47b8-933a-868b1e703342	13	2026-04-27 17:23:21.330236+00
933316a6-6b90-4291-b598-5038f1c0097e	ab1c3abd-8560-481f-8970-89621dd41fef	0efafdb9-d607-4960-97f7-4c93eebe8c54	15	2026-04-27 17:23:21.995933+00
c5312b3e-d0b6-4eb4-90dc-4ddad151599b	ab1c3abd-8560-481f-8970-89621dd41fef	05baf163-db0d-4b25-80ba-05b5b80e4c69	10	2026-04-27 17:23:22.660261+00
24af9ecb-d37a-4cec-abf8-1e70b6cbc743	ab1c3abd-8560-481f-8970-89621dd41fef	0b9672ca-b402-4b76-bd72-1957304940a1	13	2026-04-27 17:23:23.322877+00
3faff43a-c917-44e9-ab72-7f439a0323ff	ab1c3abd-8560-481f-8970-89621dd41fef	b7e6b576-fc4d-453c-bdab-27dc5452157c	11	2026-04-27 17:23:23.99014+00
afc5eb45-acc3-4dc1-b755-3eebb6dd8948	ab1c3abd-8560-481f-8970-89621dd41fef	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	14	2026-04-27 17:23:24.656314+00
d8fde113-68f9-4e74-94ab-db4a0a6a5570	ab1c3abd-8560-481f-8970-89621dd41fef	7cc0365f-3df4-4389-93f7-6f3907b1d014	16	2026-04-27 17:23:25.317966+00
a20df019-724b-443c-9b87-fd141bdbda30	ab1c3abd-8560-481f-8970-89621dd41fef	8f209177-d1f1-4419-bc20-707ccd166660	14	2026-04-27 17:23:25.987596+00
3e470ec3-3fbb-4716-abe5-6e359d371a4c	ab1c3abd-8560-481f-8970-89621dd41fef	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	12	2026-04-27 17:23:26.658377+00
c45f6dfe-8bfc-4937-8141-650c2ca1aba4	ab1c3abd-8560-481f-8970-89621dd41fef	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-27 17:23:27.326189+00
4a1eb88c-5f79-460c-97af-fe831951cb5a	ab1c3abd-8560-481f-8970-89621dd41fef	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-27 17:23:27.991335+00
48470047-c88f-4efc-a94d-9070f2939b9e	ab1c3abd-8560-481f-8970-89621dd41fef	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-27 17:23:28.654798+00
63bc581b-6d25-4982-95c2-604da6a7e6da	ab1c3abd-8560-481f-8970-89621dd41fef	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-27 17:23:29.317366+00
5095a361-47a1-476c-a13f-034ed2305c51	ab1c3abd-8560-481f-8970-89621dd41fef	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-27 17:23:29.980386+00
c55639c2-51c7-4bea-aabf-5aac05fb7445	ab1c3abd-8560-481f-8970-89621dd41fef	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-27 17:23:30.643051+00
e08d7a28-2d52-4f42-887c-f822eb60ed07	ab1c3abd-8560-481f-8970-89621dd41fef	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-27 17:23:31.615059+00
564f8e12-aa10-4213-abe2-9625c7f217b2	55a3da89-fe54-4afb-8a30-ab63fef2ad76	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	123123	2026-04-28 10:36:14.14327+00
38917227-211d-4943-b8ba-7cb2c3393c0e	55a3da89-fe54-4afb-8a30-ab63fef2ad76	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	3123	2026-04-28 10:36:14.267411+00
a91f763e-597a-42a0-a90b-4f45f79180e1	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	1	2026-04-28 00:54:18.980008+00
3a5b439f-b03b-4d40-adb7-d69e1d13e66f	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	cb2e05b8-5feb-47b8-933a-868b1e703342	5	2026-04-28 00:54:19.118007+00
714c3cee-5a9c-42f6-a8c1-5794ef56cbc5	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	0efafdb9-d607-4960-97f7-4c93eebe8c54	1	2026-04-28 00:54:19.200006+00
d8ea369e-f182-4869-adb9-d7f76099959e	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	cf3783f3-556c-4bf6-94ab-968d28be63d4	нет	2026-04-28 00:54:20.706008+00
c40955f4-9bb8-464e-8dd0-50ffd679f2f8	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	321d0540-1a62-4508-a5b4-f7bb9f2af4a0	нет	2026-04-28 00:54:20.977299+00
4f30203d-7ed5-4630-b0e7-a4bc2935fca8	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	0e7cb6e2-86c6-469f-8520-c7d7d5029604	нет	2026-04-28 00:54:21.1143+00
27966476-b0eb-477a-9e9d-695e4cf0a0ef	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	1	2026-04-28 00:55:07.620324+00
bafb14c0-ca8e-4897-9e86-f70eb2be88f1	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	05baf163-db0d-4b25-80ba-05b5b80e4c69	1	2026-04-28 00:55:08.00132+00
1a78c3ec-e161-4009-b819-3435ba2bd48b	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	0b9672ca-b402-4b76-bd72-1957304940a1	2	2026-04-28 00:55:08.216321+00
d16d2fee-73ad-47b2-82f7-c1fb7015272d	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	b7e6b576-fc4d-453c-bdab-27dc5452157c	3	2026-04-28 00:55:08.350322+00
697818c6-b081-464c-9baa-72626106854b	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	3	2026-04-28 00:55:08.484322+00
30901703-1b6e-46e3-8ff0-753f7feb74cc	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	7cc0365f-3df4-4389-93f7-6f3907b1d014	4	2026-04-28 00:55:08.619319+00
63502327-0fa2-422e-bb09-c30252e4dd66	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	8f209177-d1f1-4419-bc20-707ccd166660	8	2026-04-28 00:55:08.755321+00
d11fdffe-6f35-43cc-a3b9-235a48bc28c9	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	10	2026-04-28 00:55:08.889322+00
a68285e9-c22f-4953-8909-c994d199e18d	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	80497194-a652-4edc-9fcb-5c90d9e9d88f	2	2026-04-28 00:55:09.024322+00
abcd4b22-a41a-4a51-8ac9-7949cdcf814a	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5	5	2026-04-28 00:55:09.160322+00
3631f7c4-5f04-405d-8ed2-2f785f11b5fc	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	734cd218-e0cc-4267-8226-8cafa57be5b9	2	2026-04-28 00:55:09.29632+00
496b4952-e403-44ca-948f-8cd472418a51	26e06d75-d6bf-4f48-8774-6c8b5eb2d102	c3fe8886-d3f1-4972-9d51-901392b86864	5	2026-04-28 00:55:09.513321+00
cba44c0e-12db-4ed5-afb6-6fe40b3120bd	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	12	2026-04-28 01:10:30.446773+00
a7749111-3824-47cb-a953-0f85e6ceee7b	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	14	2026-04-28 01:10:31.066059+00
00382468-14d0-4f3c-a684-47164f7f8608	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	cb2e05b8-5feb-47b8-933a-868b1e703342	20	2026-04-28 01:10:31.669687+00
8e61ecba-bc24-497f-993d-caafb64a5cdd	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	0efafdb9-d607-4960-97f7-4c93eebe8c54	10	2026-04-28 01:10:32.27292+00
a05449b5-aac3-47e1-a553-cdf056cd9b84	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	05baf163-db0d-4b25-80ba-05b5b80e4c69	24	2026-04-28 01:10:32.875759+00
4eea0cf4-cf3a-4cd0-8b55-3cd4401df749	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	0b9672ca-b402-4b76-bd72-1957304940a1	13	2026-04-28 01:10:33.479143+00
3e396474-4ce5-4df5-ac5e-6b1539cb3f47	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	b7e6b576-fc4d-453c-bdab-27dc5452157c	11	2026-04-28 01:10:34.082046+00
7665dabf-565a-4bcb-83bd-04718798d3b2	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	12	2026-04-28 01:10:34.685045+00
67175c6e-98e6-49d9-85f9-51afa619c367	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	7cc0365f-3df4-4389-93f7-6f3907b1d014	17	2026-04-28 01:10:35.288146+00
5fbba159-c0e1-428d-885e-8b36393b142a	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	8f209177-d1f1-4419-bc20-707ccd166660	15	2026-04-28 01:10:35.891198+00
e7bb7518-e6bf-4e1e-a17a-3e52ea3af84a	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	16	2026-04-28 01:10:36.495979+00
ff4dc068-53d2-462f-b8c9-442e3e641f46	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-28 01:10:37.099936+00
457e6aca-2f53-48e2-af80-d5d051112d16	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-28 01:10:37.714091+00
5a860c90-1941-42b4-b110-447ecd1b2574	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-28 01:10:38.316175+00
8bf8dfcd-78a6-407d-9f28-6f367bb693fb	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-28 01:10:38.918232+00
89178d4f-c2ff-4222-aa73-03c610697e5c	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-28 01:10:39.521642+00
74ef35c2-e7ce-443e-aea6-4b406a4bd4ae	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-28 01:10:40.125067+00
963fbe56-2c84-4d51-abd1-1072fd6d1213	9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-28 01:10:40.728629+00
316158de-e6ed-4845-8979-e458553faefd	55a3da89-fe54-4afb-8a30-ab63fef2ad76	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-04-28 10:36:14.38874+00
23313888-8441-4779-bd79-83ee4cb3948e	55a3da89-fe54-4afb-8a30-ab63fef2ad76	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-04-28 10:36:14.510661+00
7f7cc120-bc89-45cd-9240-ce8f230f91ba	55a3da89-fe54-4afb-8a30-ab63fef2ad76	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-04-28 10:36:14.632132+00
fe7c5c96-b9ff-459c-adb9-49ead1205e2f	55a3da89-fe54-4afb-8a30-ab63fef2ad76	0b9672ca-b402-4b76-bd72-1957304940a1		2026-04-28 10:36:14.754371+00
09dcd708-fc87-456b-b4c6-8a6099de8c77	55a3da89-fe54-4afb-8a30-ab63fef2ad76	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-04-28 10:36:14.875002+00
4c1c9272-ea1a-4658-ae13-65edbec5b97d	55a3da89-fe54-4afb-8a30-ab63fef2ad76	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-04-28 10:36:14.996363+00
3d727c5d-a4ae-4c25-9615-42f892a7d485	55a3da89-fe54-4afb-8a30-ab63fef2ad76	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-04-28 10:36:15.117753+00
3ba2543c-ebed-47b1-b756-a64a32d97d53	55a3da89-fe54-4afb-8a30-ab63fef2ad76	8f209177-d1f1-4419-bc20-707ccd166660		2026-04-28 10:36:15.483345+00
9ba5e13a-e165-49a1-9dcc-c493828b38a8	55a3da89-fe54-4afb-8a30-ab63fef2ad76	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-04-28 10:36:15.604426+00
d5e2236c-c61f-4a93-920a-4f2d409eba40	55a3da89-fe54-4afb-8a30-ab63fef2ad76	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-04-28 10:36:15.725417+00
86f97f78-30cb-4721-8cfc-68a8d93fd835	55a3da89-fe54-4afb-8a30-ab63fef2ad76	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-04-28 10:36:15.845779+00
6826e559-c971-49d0-ad9b-1071144594c0	55a3da89-fe54-4afb-8a30-ab63fef2ad76	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-04-28 10:36:15.966204+00
a4d23417-9064-4fb2-9849-08e89d03946c	55a3da89-fe54-4afb-8a30-ab63fef2ad76	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-04-28 10:36:16.336662+00
f81149a7-adce-46a4-9d46-79b5c8d219bd	55a3da89-fe54-4afb-8a30-ab63fef2ad76	c3fe8886-d3f1-4972-9d51-901392b86864		2026-04-28 10:36:16.456786+00
96eefe11-90b8-4c82-923b-0e327cb0045f	55a3da89-fe54-4afb-8a30-ab63fef2ad76	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-04-28 10:36:16.577503+00
e23ef766-2b99-4a56-8b6b-82d066fb85c5	55a3da89-fe54-4afb-8a30-ab63fef2ad76	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-04-28 10:36:16.697335+00
7212c819-d4c0-49b4-974f-f6e8756e24d9	aaa661c8-f662-4ddb-8998-f3bc3d060630	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	10	2026-05-09 22:12:49.343419+00
7ab59975-151f-48da-bc4d-dcbddc950ee5	aaa661c8-f662-4ddb-8998-f3bc3d060630	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-05-09 22:12:49.982413+00
e1d1386f-cf73-43b8-961b-cd899e64519a	aaa661c8-f662-4ddb-8998-f3bc3d060630	cb2e05b8-5feb-47b8-933a-868b1e703342	11	2026-05-09 22:12:50.619776+00
9de3c1c6-e87f-466b-9eca-787bf07a8dd7	aaa661c8-f662-4ddb-8998-f3bc3d060630	0efafdb9-d607-4960-97f7-4c93eebe8c54	11	2026-05-09 22:12:51.258685+00
a4ccc9a4-b045-4c5b-8ae2-d94350ecc167	aaa661c8-f662-4ddb-8998-f3bc3d060630	05baf163-db0d-4b25-80ba-05b5b80e4c69	11	2026-05-09 22:12:51.900301+00
10333a80-4131-48ed-8e95-b8590c23829f	aaa661c8-f662-4ddb-8998-f3bc3d060630	0b9672ca-b402-4b76-bd72-1957304940a1	11	2026-05-09 22:12:52.539158+00
0aab7177-f4e8-4c13-9c55-0e31b0c4c90e	aaa661c8-f662-4ddb-8998-f3bc3d060630	b7e6b576-fc4d-453c-bdab-27dc5452157c	11	2026-05-09 22:12:53.175579+00
ec986ad5-7f22-436a-92c4-f1d320d443ab	aaa661c8-f662-4ddb-8998-f3bc3d060630	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	11	2026-05-09 22:12:53.813176+00
827f53a5-1611-4e35-a160-3b6e20a56b2d	aaa661c8-f662-4ddb-8998-f3bc3d060630	7cc0365f-3df4-4389-93f7-6f3907b1d014	11	2026-05-09 22:12:54.451045+00
69292957-328a-4138-a44f-ee09e5376a0a	aaa661c8-f662-4ddb-8998-f3bc3d060630	8f209177-d1f1-4419-bc20-707ccd166660	11	2026-05-09 22:12:55.090536+00
e160f0ff-d468-4c95-b370-2be8f4d38cc4	aaa661c8-f662-4ddb-8998-f3bc3d060630	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	11	2026-05-09 22:12:55.728625+00
07fd7b3f-6dcc-4c9e-8cc6-f373b0536d74	aaa661c8-f662-4ddb-8998-f3bc3d060630	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-05-09 22:12:56.368118+00
be3b69f0-57ca-423b-afed-c967177e1e94	aaa661c8-f662-4ddb-8998-f3bc3d060630	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-05-09 22:12:57.006243+00
31f832ea-6b0d-46f8-8b76-94e7ca5ef0c4	aaa661c8-f662-4ddb-8998-f3bc3d060630	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-05-09 22:12:57.643059+00
90b49d19-521b-4a80-b8c5-2b945c4c1265	aaa661c8-f662-4ddb-8998-f3bc3d060630	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-05-09 22:12:58.279058+00
74b4c03d-e898-4ce3-bfd1-9c4ea27a46dc	aaa661c8-f662-4ddb-8998-f3bc3d060630	c3fe8886-d3f1-4972-9d51-901392b86864		2026-05-09 22:12:58.9153+00
239cdbd3-fff3-4407-840f-391738b7276e	aaa661c8-f662-4ddb-8998-f3bc3d060630	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-05-09 22:12:59.551884+00
4818fc9a-0577-432c-99ad-186d8a5fed2e	aaa661c8-f662-4ddb-8998-f3bc3d060630	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-05-09 22:13:00.187218+00
7e955e5d-a0af-454c-9123-7b6182d436b1	cf228ded-a494-4dc9-a345-7174b0f7d783	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	4345	2026-05-14 07:19:06.440121+00
8f49265b-75bb-458d-9ce8-bbb5fe28d746	cf228ded-a494-4dc9-a345-7174b0f7d783	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	5345	2026-05-14 07:19:06.642409+00
835f55e7-2cae-477f-a6e4-557780e63ce0	cf228ded-a494-4dc9-a345-7174b0f7d783	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-05-14 07:19:06.846163+00
9efe3997-7f10-46d8-9693-4996909ff78c	cf228ded-a494-4dc9-a345-7174b0f7d783	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-05-14 07:19:07.043178+00
2406cbff-7a42-4bfc-a83d-520319bbf20d	cf228ded-a494-4dc9-a345-7174b0f7d783	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-05-14 07:19:07.243392+00
28327614-06f0-4e3c-9b39-4b417188b781	cf228ded-a494-4dc9-a345-7174b0f7d783	0b9672ca-b402-4b76-bd72-1957304940a1		2026-05-14 07:19:07.444985+00
96ad00f3-1506-4619-b3ad-d5d2c930cbe1	cf228ded-a494-4dc9-a345-7174b0f7d783	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-05-14 07:19:07.647516+00
630e3f6a-0366-48ec-8211-39964d47db2e	cf228ded-a494-4dc9-a345-7174b0f7d783	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-05-14 07:19:07.846497+00
baae7db6-b589-4b42-8e47-40e717f94e02	cf228ded-a494-4dc9-a345-7174b0f7d783	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-05-14 07:19:08.049549+00
ecfa1e1e-6b0c-4851-b596-12b936c77e6b	cf228ded-a494-4dc9-a345-7174b0f7d783	8f209177-d1f1-4419-bc20-707ccd166660		2026-05-14 07:19:08.249439+00
0137b52d-f3d8-4337-a0f6-39708a426e54	cf228ded-a494-4dc9-a345-7174b0f7d783	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-05-14 07:19:08.455137+00
2759030a-5ab2-44fa-9594-7c0dbf814b74	cf228ded-a494-4dc9-a345-7174b0f7d783	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-05-14 07:19:08.659479+00
42c50a63-9173-4eb2-95c3-b1f081b8f840	cf228ded-a494-4dc9-a345-7174b0f7d783	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-05-14 07:19:08.858916+00
acad1d59-85e0-4e11-8487-a90de4c3291b	cf228ded-a494-4dc9-a345-7174b0f7d783	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-05-14 07:19:09.053851+00
16468348-ea56-456c-a088-6b705abc8645	cf228ded-a494-4dc9-a345-7174b0f7d783	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-05-14 07:19:09.247602+00
32df9e44-8fc0-41a2-a336-423f54672381	cf228ded-a494-4dc9-a345-7174b0f7d783	c3fe8886-d3f1-4972-9d51-901392b86864		2026-05-14 07:19:09.44687+00
72ca4fcb-8628-4859-9663-d95993108e59	cf228ded-a494-4dc9-a345-7174b0f7d783	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-05-14 07:19:09.64015+00
ff2f988c-d6fe-42b5-bf43-f16943179e97	cf228ded-a494-4dc9-a345-7174b0f7d783	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-05-14 07:19:09.834752+00
93bb1281-16c9-4f71-bc84-cb5c36f9a3d1	21e0e354-aa47-49b0-8876-f82d1f90d15f	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	4345	2026-05-14 07:20:07.984736+00
9ee86747-fb93-429b-840b-05d4af0513c0	21e0e354-aa47-49b0-8876-f82d1f90d15f	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	5345	2026-05-14 07:20:08.169423+00
1f661d2d-6f7f-46cc-91e6-7c7c549f18a3	21e0e354-aa47-49b0-8876-f82d1f90d15f	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-05-14 07:20:08.355965+00
5e907cad-4a89-41f7-be0b-918082ac64b7	21e0e354-aa47-49b0-8876-f82d1f90d15f	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-05-14 07:20:08.557305+00
c1b7c1f8-073a-4215-ade5-7a02af6caf17	21e0e354-aa47-49b0-8876-f82d1f90d15f	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-05-14 07:20:08.744889+00
3c28ffe4-a6ae-46ef-a62e-1a481361306f	21e0e354-aa47-49b0-8876-f82d1f90d15f	0b9672ca-b402-4b76-bd72-1957304940a1		2026-05-14 07:20:08.921579+00
ee1e0e30-1817-4e13-bcc4-4d191e65717f	21e0e354-aa47-49b0-8876-f82d1f90d15f	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-05-14 07:20:09.122567+00
19304a15-3627-4f87-ab31-58e8d710ac0a	21e0e354-aa47-49b0-8876-f82d1f90d15f	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-05-14 07:20:09.319221+00
2c3f8516-899e-470d-980d-718d80cbec92	21e0e354-aa47-49b0-8876-f82d1f90d15f	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-05-14 07:20:09.517918+00
0bb8cea7-f0f0-43ad-893d-00838806c27c	21e0e354-aa47-49b0-8876-f82d1f90d15f	8f209177-d1f1-4419-bc20-707ccd166660		2026-05-14 07:20:09.708991+00
a393b046-5307-4ce8-8711-0dc0edfe9f9d	21e0e354-aa47-49b0-8876-f82d1f90d15f	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-05-14 07:20:09.903427+00
5b4df87a-062e-4d5e-8345-15213f449180	21e0e354-aa47-49b0-8876-f82d1f90d15f	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-05-14 07:20:10.091612+00
a4369e80-217a-4ff7-9ae8-754803b0ec89	21e0e354-aa47-49b0-8876-f82d1f90d15f	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-05-14 07:20:10.281689+00
fc5022fc-b8f0-4ef5-a0f4-49aa2ac40601	21e0e354-aa47-49b0-8876-f82d1f90d15f	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-05-14 07:20:10.468438+00
bc04c2b8-f2f3-438b-9dd9-5439c45dcce2	21e0e354-aa47-49b0-8876-f82d1f90d15f	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-05-14 07:20:10.659497+00
9f28d0b7-aba9-4361-a43b-e79024cdc9ed	21e0e354-aa47-49b0-8876-f82d1f90d15f	c3fe8886-d3f1-4972-9d51-901392b86864		2026-05-14 07:20:10.846958+00
c733f10d-2711-41fd-9f1f-18242ed4263b	21e0e354-aa47-49b0-8876-f82d1f90d15f	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-05-14 07:20:11.038666+00
b93a9d3a-bb86-4eb5-a417-f1870545117b	21e0e354-aa47-49b0-8876-f82d1f90d15f	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-05-14 07:20:11.230528+00
6968400e-7810-4109-aa53-4dc9e592f2cf	0972ec40-39b9-4c45-a38d-77c0bf8915c1	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1		2026-05-29 12:00:05.224533+00
9819ef6e-3991-4ec7-bfa7-ef73f574fec5	0972ec40-39b9-4c45-a38d-77c0bf8915c1	f28188e3-fdb9-4d41-9a5a-2d3ff2730842		2026-05-29 12:00:06.064914+00
f56c9326-e5e4-4734-a32d-e76e3ced3a5b	0972ec40-39b9-4c45-a38d-77c0bf8915c1	cb2e05b8-5feb-47b8-933a-868b1e703342		2026-05-29 12:00:06.895734+00
1e7d73fb-32fc-4719-9612-dbe41b36e000	0972ec40-39b9-4c45-a38d-77c0bf8915c1	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-05-29 12:00:07.726412+00
a151628d-63e2-41ec-9d0c-9da67b8df88b	0972ec40-39b9-4c45-a38d-77c0bf8915c1	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-05-29 12:00:08.557481+00
9f537405-2762-4644-b8b9-3bbed52dbdf6	0972ec40-39b9-4c45-a38d-77c0bf8915c1	0b9672ca-b402-4b76-bd72-1957304940a1		2026-05-29 12:00:09.387709+00
fa551e90-1b5f-4d8b-909f-44b5cdfa252a	0972ec40-39b9-4c45-a38d-77c0bf8915c1	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-05-29 12:00:10.217437+00
d0c9effa-2909-45b8-b750-c94e2104c503	0972ec40-39b9-4c45-a38d-77c0bf8915c1	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-05-29 12:00:11.0458+00
f677f803-a3c4-4396-a952-de93945a3da2	0972ec40-39b9-4c45-a38d-77c0bf8915c1	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-05-29 12:00:11.874875+00
b9adb28d-819b-4283-96a4-86857d7b4076	0972ec40-39b9-4c45-a38d-77c0bf8915c1	8f209177-d1f1-4419-bc20-707ccd166660		2026-05-29 12:00:12.703992+00
991907d0-ab65-4053-aebc-9b25f9437240	0972ec40-39b9-4c45-a38d-77c0bf8915c1	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-05-29 12:00:13.53388+00
f6336741-e97d-4fb9-9bb3-193de911d735	0972ec40-39b9-4c45-a38d-77c0bf8915c1	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-05-29 12:00:14.362088+00
e7d6a49c-c07f-4a48-ac67-5ae877f64f96	0972ec40-39b9-4c45-a38d-77c0bf8915c1	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-05-29 12:00:15.189996+00
6aa235e0-5e1b-409e-a68b-4e4260152027	0972ec40-39b9-4c45-a38d-77c0bf8915c1	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-05-29 12:00:16.018443+00
ce857b67-3a08-406a-9497-e8c3134a3773	0972ec40-39b9-4c45-a38d-77c0bf8915c1	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-05-29 12:00:16.847249+00
fce4fad3-11a0-48d4-91a2-fc0105a95ea5	0972ec40-39b9-4c45-a38d-77c0bf8915c1	c3fe8886-d3f1-4972-9d51-901392b86864		2026-05-29 12:00:17.676242+00
dd150348-875b-4048-ad43-bea9b2c7c56d	0972ec40-39b9-4c45-a38d-77c0bf8915c1	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-05-29 12:00:18.504277+00
3bef1bb2-4a96-4a00-9010-36b229880d02	0972ec40-39b9-4c45-a38d-77c0bf8915c1	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-05-29 12:00:19.332929+00
6a5a659f-0a8f-437c-a0d8-10d53caa3698	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	10	2026-05-30 04:00:46.845822+00
96f138bb-0020-4740-a344-1119d294aaae	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	10	2026-05-30 04:00:47.352405+00
eebc91af-b893-43bc-880e-b658a2f3062b	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	cb2e05b8-5feb-47b8-933a-868b1e703342	10	2026-05-30 04:00:47.857892+00
7a3b06ba-968a-4238-8607-c0359e492c39	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	0efafdb9-d607-4960-97f7-4c93eebe8c54	10	2026-05-30 04:00:48.363135+00
1eab4ef2-ec46-47bd-a3a5-5e0ebeac78be	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	05baf163-db0d-4b25-80ba-05b5b80e4c69	10	2026-05-30 04:00:48.920543+00
c0d1e765-8f7f-4e4c-88d4-5646a5e64b94	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	0b9672ca-b402-4b76-bd72-1957304940a1	10	2026-05-30 04:00:49.426977+00
0ee0cf2c-eb79-4eae-9eaf-101480036b82	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	b7e6b576-fc4d-453c-bdab-27dc5452157c	10	2026-05-30 04:00:49.938974+00
670b5e94-ff10-4d3b-860b-9d64ba220485	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	10	2026-05-30 04:00:50.444275+00
855f7fb1-0333-4eac-81f7-67a7f299a077	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-05-30 04:00:50.950134+00
cbf8e24c-9a97-4ca2-8fb9-f04c74ed47b4	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	8f209177-d1f1-4419-bc20-707ccd166660		2026-05-30 04:00:51.456535+00
385a0994-c14e-4fd5-845c-e3ef53d7ea97	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-05-30 04:00:51.959788+00
3798923a-a661-43c9-8662-d6b640f6d370	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-05-30 04:00:52.464742+00
4fe4f665-8608-4cde-b750-77e38421b7d8	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-05-30 04:00:52.968264+00
b41d05a6-d7a5-4737-893b-bb5bc82449e5	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-05-30 04:00:53.473702+00
be20e633-b98c-4034-90de-bbe74cc43c06	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-05-30 04:00:53.979184+00
c2f5f5e5-2221-4565-a79a-0bc26d4fc375	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	c3fe8886-d3f1-4972-9d51-901392b86864		2026-05-30 04:00:54.487079+00
06e86f99-6d80-451a-819e-eccffd19829a	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-05-30 04:00:54.9895+00
fdaf5aee-b2a4-4868-92d2-1d814c7a1f44	a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-05-30 04:00:55.492602+00
1e87af3b-db39-49b6-8812-78371c0e9502	e870bc11-2c3b-49df-a086-8443d6f716fc	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-05-30 04:04:34.041749+00
e2e8c435-c614-4480-a081-20dc6db7eefa	e870bc11-2c3b-49df-a086-8443d6f716fc	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-05-30 04:04:34.543447+00
180f6e06-33bc-4d45-a688-9126358c9a56	e870bc11-2c3b-49df-a086-8443d6f716fc	cb2e05b8-5feb-47b8-933a-868b1e703342	11	2026-05-30 04:04:35.046217+00
ad21d3ee-31c5-485e-9405-9f68cb78e51e	e870bc11-2c3b-49df-a086-8443d6f716fc	0efafdb9-d607-4960-97f7-4c93eebe8c54	11	2026-05-30 04:04:35.552429+00
f546a592-8013-4b30-8dcb-32360c14664f	e870bc11-2c3b-49df-a086-8443d6f716fc	05baf163-db0d-4b25-80ba-05b5b80e4c69	11	2026-05-30 04:04:36.058507+00
d0d07f52-5012-47b4-b1b6-95cc298de2a5	e870bc11-2c3b-49df-a086-8443d6f716fc	0b9672ca-b402-4b76-bd72-1957304940a1	11	2026-05-30 04:04:36.559225+00
f4a69501-df87-4868-a6bb-2f0f33e59741	e870bc11-2c3b-49df-a086-8443d6f716fc	b7e6b576-fc4d-453c-bdab-27dc5452157c	11	2026-05-30 04:04:37.062769+00
b87b4b7e-b4ab-4b43-bde7-49cb6546fc47	e870bc11-2c3b-49df-a086-8443d6f716fc	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	11	2026-05-30 04:04:37.562727+00
37e581b6-1cb8-4b60-8d3a-aa90ad479a29	e870bc11-2c3b-49df-a086-8443d6f716fc	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-05-30 04:04:38.063892+00
09e8d99d-715e-418e-81db-f489ef55357e	e870bc11-2c3b-49df-a086-8443d6f716fc	8f209177-d1f1-4419-bc20-707ccd166660		2026-05-30 04:04:38.570284+00
77a1634f-a61d-4542-b3d1-1e190961e9ac	e870bc11-2c3b-49df-a086-8443d6f716fc	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-05-30 04:04:39.071384+00
a3aedc0f-7937-4917-8875-43a890fc989e	e870bc11-2c3b-49df-a086-8443d6f716fc	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-05-30 04:04:39.576143+00
bd2deb54-9697-469d-bae3-f366398c5659	e870bc11-2c3b-49df-a086-8443d6f716fc	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-05-30 04:04:40.07642+00
e7ecd027-bd38-456d-8e64-1516623a249e	e870bc11-2c3b-49df-a086-8443d6f716fc	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-05-30 04:04:40.587263+00
b6135674-0a96-48a0-b638-dc91598ab85b	e870bc11-2c3b-49df-a086-8443d6f716fc	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-05-30 04:04:41.093791+00
e037aef0-f662-44c7-9359-3fba8220cbda	e870bc11-2c3b-49df-a086-8443d6f716fc	c3fe8886-d3f1-4972-9d51-901392b86864		2026-05-30 04:04:41.599693+00
3c850e71-88f8-4cab-b331-d0c94b6a0f09	e870bc11-2c3b-49df-a086-8443d6f716fc	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-05-30 04:04:42.105609+00
aa500f0c-1f64-4a06-a5fa-0670026e58e5	e870bc11-2c3b-49df-a086-8443d6f716fc	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-05-30 04:04:42.611951+00
c0ffdc03-90cd-40e9-bbe2-affebd37792b	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-05-30 04:07:22.638098+00
28c28fb3-5aee-4454-9c41-dbda5ee67443	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-05-30 04:07:23.194615+00
a2c86782-f356-478a-b435-8365bba7536e	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	cb2e05b8-5feb-47b8-933a-868b1e703342	11	2026-05-30 04:07:23.70448+00
24a5454b-92d6-48ae-a02b-de8b0c5457dc	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	0efafdb9-d607-4960-97f7-4c93eebe8c54	11	2026-05-30 04:07:24.211876+00
47dab6b8-d896-424d-a14a-1cc56cf1f36f	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	05baf163-db0d-4b25-80ba-05b5b80e4c69	11	2026-05-30 04:07:24.721335+00
ff76e4e0-4ea9-4953-851c-99eb5aaa8c50	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	0b9672ca-b402-4b76-bd72-1957304940a1	11	2026-05-30 04:07:25.233384+00
3cfd26f5-9617-426f-8983-a99634024daf	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	b7e6b576-fc4d-453c-bdab-27dc5452157c	11	2026-05-30 04:07:25.739299+00
590cb9c4-c7dc-4adb-a5f0-6405d5696855	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	11	2026-05-30 04:07:26.256603+00
4b7e34c4-819c-40c3-80f6-415eb36e5c74	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-05-30 04:07:26.77461+00
cbf33380-271c-422d-a0db-cb44afacd5eb	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	8f209177-d1f1-4419-bc20-707ccd166660		2026-05-30 04:07:27.2829+00
aa77c129-a216-4e41-ad07-2814825f54bc	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-05-30 04:07:27.788723+00
63c13870-f901-47ce-9a1f-1b12b3b2d598	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-05-30 04:07:28.294941+00
aa21462c-9589-41be-a0dc-d058e2014318	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-05-30 04:07:28.798781+00
a1564990-5587-44ac-bcc9-16e9963d86a9	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-05-30 04:07:29.302586+00
af77c8bd-67cd-4617-a053-41b2b9811628	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-05-30 04:07:29.814626+00
fd1b1942-e49f-44e1-b85b-5ded40a3847e	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	c3fe8886-d3f1-4972-9d51-901392b86864		2026-05-30 04:07:30.32699+00
ca2180af-924d-4d23-abdc-d84431efcfb2	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-05-30 04:07:30.843857+00
e894b0d0-fec0-480f-8829-1604d821b240	9a8ec876-c7fd-45b6-8e3d-75c6277a9362	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-05-30 04:07:31.350409+00
398de6d3-82c8-4271-a8db-ef04beec12dd	80a845b6-050e-456a-876c-040edd54ce45	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-05-30 05:06:42.538428+00
691097d2-b499-4330-9940-feef608b0785	80a845b6-050e-456a-876c-040edd54ce45	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-05-30 05:06:43.047781+00
6c2e3257-7801-47b9-82bc-1e2cc6efc234	80a845b6-050e-456a-876c-040edd54ce45	cb2e05b8-5feb-47b8-933a-868b1e703342	11	2026-05-30 05:06:43.551026+00
c0b6d6dd-7724-4d87-8bf8-623c7f31a78b	80a845b6-050e-456a-876c-040edd54ce45	0efafdb9-d607-4960-97f7-4c93eebe8c54	11	2026-05-30 05:06:44.054813+00
edb8e434-6f30-431b-8d87-151c3dd75702	80a845b6-050e-456a-876c-040edd54ce45	05baf163-db0d-4b25-80ba-05b5b80e4c69	11	2026-05-30 05:06:44.556904+00
4c82e4df-a263-4441-9ab9-d89d6d665ffb	80a845b6-050e-456a-876c-040edd54ce45	0b9672ca-b402-4b76-bd72-1957304940a1	11	2026-05-30 05:06:45.059966+00
d3b27acf-8cea-4b72-a0a5-4d3917ad804d	80a845b6-050e-456a-876c-040edd54ce45	b7e6b576-fc4d-453c-bdab-27dc5452157c	11	2026-05-30 05:06:45.563086+00
2f3ecb01-0149-453b-90e6-0a62c2b48b00	80a845b6-050e-456a-876c-040edd54ce45	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	11	2026-05-30 05:06:46.065324+00
620a9ec8-8879-4a75-a1c5-55a9718371a6	80a845b6-050e-456a-876c-040edd54ce45	7cc0365f-3df4-4389-93f7-6f3907b1d014	11	2026-05-30 05:06:46.566569+00
4c36d620-5c0d-4029-90a3-c5d6bc221a74	80a845b6-050e-456a-876c-040edd54ce45	8f209177-d1f1-4419-bc20-707ccd166660	11	2026-05-30 05:06:47.070946+00
25948ef1-1dff-4477-904e-1f750caaebb2	80a845b6-050e-456a-876c-040edd54ce45	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	11	2026-05-30 05:06:47.571968+00
cf242bc4-ee6c-4ec9-9131-04993e9af56f	80a845b6-050e-456a-876c-040edd54ce45	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-05-30 05:06:48.07233+00
d734032b-f189-42aa-86a3-b45e2b132093	80a845b6-050e-456a-876c-040edd54ce45	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-05-30 05:06:48.572629+00
dbc3e1ae-5108-4084-8f7e-ca565d7153b9	80a845b6-050e-456a-876c-040edd54ce45	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-05-30 05:06:49.07343+00
ed1ed8a2-5d46-4a91-8c65-b0e43cfff298	80a845b6-050e-456a-876c-040edd54ce45	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-05-30 05:06:49.575352+00
c0dd86fb-5c6c-49b3-9ec4-316f203b88a0	80a845b6-050e-456a-876c-040edd54ce45	c3fe8886-d3f1-4972-9d51-901392b86864		2026-05-30 05:06:50.078067+00
df508482-8a6b-4219-869f-7ed0b8eb5671	80a845b6-050e-456a-876c-040edd54ce45	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-05-30 05:06:50.579377+00
9ce48ebc-2007-49ca-82d9-145eed19e080	80a845b6-050e-456a-876c-040edd54ce45	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-05-30 05:06:51.081558+00
b03000ec-6c30-4bac-8fa6-b24661da4b15	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-05-30 05:09:13.774736+00
487867b4-e795-4dd4-bb9c-a57c67d8fec0	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-05-30 05:09:14.287321+00
314af991-477d-4639-a9cb-1410cffa8de6	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	cb2e05b8-5feb-47b8-933a-868b1e703342	11	2026-05-30 05:09:14.789813+00
1cd0fb11-51be-4388-847c-9ba6c6cf3dbc	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	0efafdb9-d607-4960-97f7-4c93eebe8c54	11	2026-05-30 05:09:15.302042+00
b5e94dad-1da0-4d08-bb96-ec27080966c2	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	05baf163-db0d-4b25-80ba-05b5b80e4c69	11	2026-05-30 05:09:15.81235+00
e803b127-4e64-4cc0-9252-196da8836db1	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	0b9672ca-b402-4b76-bd72-1957304940a1	11	2026-05-30 05:09:16.314942+00
13d3a7f4-6a91-43b3-a686-11888793ae22	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	b7e6b576-fc4d-453c-bdab-27dc5452157c	11	2026-05-30 05:09:16.816972+00
0492b595-b288-469d-ad83-f67d86ca84d9	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	11	2026-05-30 05:09:17.317867+00
584994b5-bb1d-43b3-8cad-207f14d17997	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	7cc0365f-3df4-4389-93f7-6f3907b1d014	11	2026-05-30 05:09:17.8189+00
934b03a7-4b76-4116-a44f-cd9a5cdcd7b7	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	8f209177-d1f1-4419-bc20-707ccd166660	11	2026-05-30 05:09:18.322355+00
48e0b781-3a8a-40c1-bf94-71f441e31614	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	11	2026-05-30 05:09:18.828658+00
1ea7de41-462e-4440-a3e1-19db95c3a94a	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-05-30 05:09:19.329106+00
e42d40c8-95f1-4c88-bca6-dabaaa047b94	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-05-30 05:09:19.829551+00
14665b74-915a-4c6c-b8ff-28d8577af2ab	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-05-30 05:09:20.331178+00
4e9aa3dd-1b17-4ca8-8558-a0dddc1da0fd	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-05-30 05:09:20.835688+00
45cad878-6f60-4336-b911-c49852d46417	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	c3fe8886-d3f1-4972-9d51-901392b86864		2026-05-30 05:09:21.34413+00
a1dece92-6729-4ffb-951a-4278206004a0	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-05-30 05:09:21.846067+00
d4b62998-0889-4ea8-939f-0356836f42b0	3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-05-30 05:09:22.347754+00
732a7019-f524-43a0-ab1d-9bc99f2daafc	ee58c222-f6a4-4f01-9756-3af88b448875	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-05-30 06:02:53.303474+00
2529b027-8d47-47d1-a599-2df36b8249af	ee58c222-f6a4-4f01-9756-3af88b448875	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-05-30 06:02:53.811513+00
128cd8f7-9f9e-4dce-98f1-18d7ed8f2c9e	ee58c222-f6a4-4f01-9756-3af88b448875	cb2e05b8-5feb-47b8-933a-868b1e703342	11	2026-05-30 06:02:54.313478+00
b8af7025-13ec-440d-a436-7a772fbaa486	ee58c222-f6a4-4f01-9756-3af88b448875	0efafdb9-d607-4960-97f7-4c93eebe8c54	11	2026-05-30 06:02:54.817181+00
bdb3a6e1-764a-4870-8eff-93d3c7007472	ee58c222-f6a4-4f01-9756-3af88b448875	05baf163-db0d-4b25-80ba-05b5b80e4c69	11	2026-05-30 06:02:55.319618+00
a98bfc86-2abd-4ee5-b681-f4ca2f78367d	ee58c222-f6a4-4f01-9756-3af88b448875	0b9672ca-b402-4b76-bd72-1957304940a1	11	2026-05-30 06:02:55.821248+00
39c35642-026b-4170-94e4-501cb6a1999a	ee58c222-f6a4-4f01-9756-3af88b448875	b7e6b576-fc4d-453c-bdab-27dc5452157c	11	2026-05-30 06:02:56.321307+00
68b60782-ece3-476d-9d6f-2ed597af6e1e	ee58c222-f6a4-4f01-9756-3af88b448875	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	11	2026-05-30 06:02:56.822871+00
e4a84288-b4ca-4e94-be38-a06d7fa3793a	ee58c222-f6a4-4f01-9756-3af88b448875	7cc0365f-3df4-4389-93f7-6f3907b1d014	11	2026-05-30 06:02:57.325036+00
fc8299f0-b4e3-4e4a-adbb-b05c7135857c	ee58c222-f6a4-4f01-9756-3af88b448875	8f209177-d1f1-4419-bc20-707ccd166660	11	2026-05-30 06:02:57.827367+00
5b5f0403-7882-447f-9935-0f26077879f3	ee58c222-f6a4-4f01-9756-3af88b448875	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	11	2026-05-30 06:02:58.329375+00
cb7cc942-9ad1-48fb-aced-d8b4d20dbe97	ee58c222-f6a4-4f01-9756-3af88b448875	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-05-30 06:02:58.829102+00
5c94d15c-0bef-4568-ab52-4b8704e1836b	ee58c222-f6a4-4f01-9756-3af88b448875	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-05-30 06:02:59.329147+00
121140e1-dda8-43eb-94c4-b2acf1b5c7d8	ee58c222-f6a4-4f01-9756-3af88b448875	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-05-30 06:02:59.829628+00
93cfc800-f8e5-4cdc-bbe3-2e3849b8750f	ee58c222-f6a4-4f01-9756-3af88b448875	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-05-30 06:03:00.331334+00
d02750d8-52f0-4d0b-a90d-e79229ad7528	ee58c222-f6a4-4f01-9756-3af88b448875	c3fe8886-d3f1-4972-9d51-901392b86864		2026-05-30 06:03:00.832416+00
205575c4-1b78-4c72-84f3-02c010a3e9d5	ee58c222-f6a4-4f01-9756-3af88b448875	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-05-30 06:03:01.332604+00
5465bb58-2e79-4893-a34a-1400bfbe9a17	ee58c222-f6a4-4f01-9756-3af88b448875	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-05-30 06:03:01.832291+00
f1c1a125-9e3a-45a7-a29f-9022ef119ec7	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-05-30 09:58:24.993384+00
7740c7e7-f847-41e9-a6b3-55180d080af1	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-05-30 09:58:25.157585+00
3b0d0b3a-18fd-4037-a4f7-e920f6f057df	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	cb2e05b8-5feb-47b8-933a-868b1e703342	12	2026-05-30 09:58:25.32143+00
67b0f5f8-e74b-4c66-b9be-d24bfc1159bc	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	0efafdb9-d607-4960-97f7-4c93eebe8c54		2026-05-30 09:58:25.488618+00
9709f988-7779-4a1b-bf44-e19340d13c95	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	05baf163-db0d-4b25-80ba-05b5b80e4c69		2026-05-30 09:58:25.652778+00
9c89768b-7202-41c4-ba8e-3998a98a29d4	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	0b9672ca-b402-4b76-bd72-1957304940a1		2026-05-30 09:58:25.816134+00
58a40fe7-0ea2-4401-bb08-979bbb7f1308	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	b7e6b576-fc4d-453c-bdab-27dc5452157c		2026-05-30 09:58:25.974775+00
f3370b47-3d20-415d-99da-92ebf3f54c59	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	c334d16b-aaff-4d34-88ef-61f95cbe7e3a		2026-05-30 09:58:26.134699+00
09fe19a4-a24b-4172-93b6-9483be893424	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	7cc0365f-3df4-4389-93f7-6f3907b1d014		2026-05-30 09:58:26.303402+00
917a78bc-3729-48ba-9ff5-2db003b43b7b	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	8f209177-d1f1-4419-bc20-707ccd166660		2026-05-30 09:58:26.467431+00
3540a06c-8812-419d-aa4e-83ed00937814	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	55f17e1c-4c8a-4983-8c8c-06e26dac38b4		2026-05-30 09:58:26.637027+00
dd73bdd2-f0c4-4d1f-b3a9-f719695b8619	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-05-30 09:58:26.801636+00
a4021676-fdd8-4e34-838a-dd0c2eb9402a	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-05-30 09:58:26.958351+00
ccd0ecbd-d6a0-4a04-a9fe-e95e0046476d	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-05-30 09:58:27.115639+00
7f39e6da-03fc-474c-b18e-31bb580fed9c	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-05-30 09:58:27.276217+00
b6ddaa08-f3da-4ea3-a452-f7e9a7fb5e42	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	c3fe8886-d3f1-4972-9d51-901392b86864		2026-05-30 09:58:27.443571+00
b63a28a8-0638-4029-b917-0fea90bab49d	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-05-30 09:58:27.60212+00
f7ad4c15-357c-49bb-95c5-94fd6e82589a	0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-05-30 09:58:27.760566+00
d8a49da8-77fa-4454-a075-55297abd7ee7	93916b99-dbf9-42d3-8747-80eafb2d976f	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-06-05 00:07:02.236347+00
0ff58c27-e2db-4a95-a579-871028056281	93916b99-dbf9-42d3-8747-80eafb2d976f	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-06-05 00:07:02.398847+00
c7a03bf7-7322-4a66-a2de-b6cfa6ece56d	93916b99-dbf9-42d3-8747-80eafb2d976f	cb2e05b8-5feb-47b8-933a-868b1e703342	11	2026-06-05 00:07:02.556247+00
c2a23f52-443f-4ef4-b77c-805d6ba93221	93916b99-dbf9-42d3-8747-80eafb2d976f	0efafdb9-d607-4960-97f7-4c93eebe8c54	11	2026-06-05 00:07:02.714452+00
be2bbb0d-ec27-49e0-a0d2-289a6b954cb3	93916b99-dbf9-42d3-8747-80eafb2d976f	05baf163-db0d-4b25-80ba-05b5b80e4c69	11	2026-06-05 00:07:02.872315+00
f769aad0-d6ba-4e3e-8b68-eb0c500b8601	93916b99-dbf9-42d3-8747-80eafb2d976f	0b9672ca-b402-4b76-bd72-1957304940a1	11	2026-06-05 00:07:03.064525+00
6909156f-e05d-422d-a8ea-dc53664a6523	93916b99-dbf9-42d3-8747-80eafb2d976f	b7e6b576-fc4d-453c-bdab-27dc5452157c	11	2026-06-05 00:07:03.223068+00
3062bad7-36b7-4f00-bab6-403ac5f6a241	93916b99-dbf9-42d3-8747-80eafb2d976f	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	11	2026-06-05 00:07:03.379224+00
d05da045-36f2-4fcc-b86e-1a02de788e97	93916b99-dbf9-42d3-8747-80eafb2d976f	7cc0365f-3df4-4389-93f7-6f3907b1d014	11	2026-06-05 00:07:03.539017+00
7d1608e0-63ca-4626-b4a9-d75e73fd5d1e	93916b99-dbf9-42d3-8747-80eafb2d976f	8f209177-d1f1-4419-bc20-707ccd166660	11	2026-06-05 00:07:03.698181+00
186b6f8d-a4b2-4f43-ac0e-cfa815e92f55	93916b99-dbf9-42d3-8747-80eafb2d976f	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	11	2026-06-05 00:07:03.857648+00
f6d0543d-c61f-4038-8523-ebd4f93d752b	93916b99-dbf9-42d3-8747-80eafb2d976f	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-06-05 00:07:04.015795+00
99ec601b-8d91-4151-aac7-5da99b2a3e2f	93916b99-dbf9-42d3-8747-80eafb2d976f	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-06-05 00:07:04.172486+00
ec462e01-8bb1-4a4a-a8b9-c80e0d651cfb	93916b99-dbf9-42d3-8747-80eafb2d976f	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-06-05 00:07:04.326966+00
5280a7cf-a41c-463e-b570-56bdac1fa01f	93916b99-dbf9-42d3-8747-80eafb2d976f	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-06-05 00:07:04.482421+00
3f450177-5a53-4804-8a7d-5a60dc8faba6	93916b99-dbf9-42d3-8747-80eafb2d976f	c3fe8886-d3f1-4972-9d51-901392b86864		2026-06-05 00:07:04.638256+00
6104f168-8bf1-4921-99d2-54e1d91ca459	93916b99-dbf9-42d3-8747-80eafb2d976f	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-06-05 00:07:04.793349+00
d4faa406-7f48-4c8e-9517-02cb4c315ad4	93916b99-dbf9-42d3-8747-80eafb2d976f	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-06-05 00:07:04.948289+00
7557a207-3d85-4a75-a3fd-05ed9a9051dc	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-06-05 02:20:36.467709+00
7d3fb259-b209-4482-9b12-e5b1ade35d43	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-06-05 02:20:36.645996+00
32bce018-9d1d-4a2a-b745-edbef9fc270b	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	cb2e05b8-5feb-47b8-933a-868b1e703342	11	2026-06-05 02:20:36.805841+00
e1dbcb88-bea6-4b5c-b458-c9cad9c67c76	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	0efafdb9-d607-4960-97f7-4c93eebe8c54	11	2026-06-05 02:20:36.962272+00
fa3ada3d-be8b-4f5d-9d8c-169f49296e6c	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	05baf163-db0d-4b25-80ba-05b5b80e4c69	11	2026-06-05 02:20:37.118279+00
d04596d3-6921-47e0-b5fa-12e5ee60f6e0	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	0b9672ca-b402-4b76-bd72-1957304940a1	11	2026-06-05 02:20:37.273331+00
b5fb6390-1bf1-4395-9006-8487cb311ca1	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	b7e6b576-fc4d-453c-bdab-27dc5452157c	11	2026-06-05 02:20:37.42808+00
98c76db9-331a-455c-9a3c-ee8aba7924e8	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	11	2026-06-05 02:20:37.583678+00
ff5bd2ef-f1cf-45ab-9739-84a37eef556b	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	7cc0365f-3df4-4389-93f7-6f3907b1d014	11	2026-06-05 02:20:37.739778+00
fa98bf85-85f8-4e03-814b-accd348a741f	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	8f209177-d1f1-4419-bc20-707ccd166660	11	2026-06-05 02:20:37.894307+00
4ec86ba0-beea-40eb-ac95-0343d952b59b	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	11	2026-06-05 02:20:38.048847+00
0f2dd61e-5ba6-49ec-99ce-dd3cb6f5aed3	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-06-05 02:20:38.203444+00
66eb3f07-65ca-419c-a9bf-69360747111b	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-06-05 02:20:38.358121+00
c35a592b-5589-4a5a-9a37-e96b22e82eb4	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-06-05 02:20:38.51326+00
37e81e44-c8a8-41b8-ab8c-049d747d8616	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-06-05 02:20:38.670549+00
7f223d3c-2675-4382-8317-46dbbae35233	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	c3fe8886-d3f1-4972-9d51-901392b86864		2026-06-05 02:20:38.824926+00
47cfd3dd-709b-4fa5-b934-43c4c0f06928	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-06-05 02:20:38.978028+00
936c2d20-1f8b-425b-a40b-e8da5cff29ba	f2501cb3-72a7-49ec-9d9b-36d06caf8e18	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-06-05 02:20:39.13193+00
04484ca8-a655-4fea-8bcf-db6975196fec	e3be5ed6-88d2-49cc-9e34-845d47496c50	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-06-05 03:14:55.771631+00
94850caa-a29a-49bc-a73d-a9fc1dacf5f3	e3be5ed6-88d2-49cc-9e34-845d47496c50	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-06-05 03:14:55.936467+00
0550e03c-575b-4745-bffe-e2c503d33d57	e3be5ed6-88d2-49cc-9e34-845d47496c50	cb2e05b8-5feb-47b8-933a-868b1e703342	11	2026-06-05 03:14:56.096637+00
154f2b9a-ecee-4321-9dbd-a28a9f6f6364	e3be5ed6-88d2-49cc-9e34-845d47496c50	0efafdb9-d607-4960-97f7-4c93eebe8c54	11	2026-06-05 03:14:56.265515+00
591c602f-da38-4156-941e-eb869bb30042	e3be5ed6-88d2-49cc-9e34-845d47496c50	05baf163-db0d-4b25-80ba-05b5b80e4c69	11	2026-06-05 03:14:56.424874+00
bb083f3e-4c00-4890-a7ac-33c6dd2c45f4	e3be5ed6-88d2-49cc-9e34-845d47496c50	0b9672ca-b402-4b76-bd72-1957304940a1	11	2026-06-05 03:14:56.58355+00
9173835c-9d98-481d-b993-0ccdb4e43240	e3be5ed6-88d2-49cc-9e34-845d47496c50	b7e6b576-fc4d-453c-bdab-27dc5452157c	11	2026-06-05 03:14:56.742172+00
cd6d06b5-5db7-4526-8c65-233030b4684b	e3be5ed6-88d2-49cc-9e34-845d47496c50	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	11	2026-06-05 03:14:56.900129+00
18670602-1741-4f6c-a208-906e7808a6c1	e3be5ed6-88d2-49cc-9e34-845d47496c50	7cc0365f-3df4-4389-93f7-6f3907b1d014	11	2026-06-05 03:14:57.058281+00
a373b9a9-6c4f-4f3a-ad7d-83d57522a724	e3be5ed6-88d2-49cc-9e34-845d47496c50	8f209177-d1f1-4419-bc20-707ccd166660	11	2026-06-05 03:14:57.215725+00
3ec18161-39db-439a-bfc6-a34c74d30c5f	e3be5ed6-88d2-49cc-9e34-845d47496c50	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	11	2026-06-05 03:14:57.373988+00
cd337b0f-77a3-4b54-acff-6232245e8814	e3be5ed6-88d2-49cc-9e34-845d47496c50	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-06-05 03:14:57.532105+00
a83094b5-bf59-4a3b-9883-338e07e25785	e3be5ed6-88d2-49cc-9e34-845d47496c50	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-06-05 03:14:57.695408+00
908a0111-4f3e-4bc7-94b2-349608763cd8	e3be5ed6-88d2-49cc-9e34-845d47496c50	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-06-05 03:14:57.854291+00
aaec7a4e-df18-4fc1-aef9-06542d992961	e3be5ed6-88d2-49cc-9e34-845d47496c50	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-06-05 03:14:58.013858+00
cab8a3fd-8f79-4b26-8405-faa6f10d9ce1	e3be5ed6-88d2-49cc-9e34-845d47496c50	c3fe8886-d3f1-4972-9d51-901392b86864		2026-06-05 03:14:58.172039+00
bdd9535b-7822-4f32-ad79-7c0d85e40619	e3be5ed6-88d2-49cc-9e34-845d47496c50	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-06-05 03:14:58.330305+00
f1e4d050-c52a-4b15-8a16-6cd27ab7ced1	e3be5ed6-88d2-49cc-9e34-845d47496c50	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-06-05 03:14:58.488112+00
c2028506-524f-4899-bd1e-b4a610820f41	6def5cb3-6822-4ef6-a3a5-f52977685d8b	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	11	2026-06-05 05:09:39.807112+00
5045fa91-4a5e-49cb-b42e-51be02badc1a	6def5cb3-6822-4ef6-a3a5-f52977685d8b	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	11	2026-06-05 05:09:39.974071+00
58e83c86-aa14-4be1-9f65-6be568ad8401	6def5cb3-6822-4ef6-a3a5-f52977685d8b	cb2e05b8-5feb-47b8-933a-868b1e703342	11	2026-06-05 05:09:40.143561+00
8733dcbc-e94e-4779-bebf-a04b73031f52	6def5cb3-6822-4ef6-a3a5-f52977685d8b	0efafdb9-d607-4960-97f7-4c93eebe8c54	11	2026-06-05 05:09:40.319258+00
d9022386-2a3d-46a9-9cfe-b4f4f2f47c63	6def5cb3-6822-4ef6-a3a5-f52977685d8b	05baf163-db0d-4b25-80ba-05b5b80e4c69	11	2026-06-05 05:09:40.492354+00
1cbea1a7-41aa-41c3-a17d-ac45d5f32e05	6def5cb3-6822-4ef6-a3a5-f52977685d8b	0b9672ca-b402-4b76-bd72-1957304940a1	11	2026-06-05 05:09:40.668344+00
c92dbbef-5a74-4ee1-9b83-73007a1cd9e6	6def5cb3-6822-4ef6-a3a5-f52977685d8b	b7e6b576-fc4d-453c-bdab-27dc5452157c	11	2026-06-05 05:09:40.83985+00
2888e63d-84b7-4056-be86-ba187b5441dc	6def5cb3-6822-4ef6-a3a5-f52977685d8b	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	11	2026-06-05 05:09:41.009822+00
6b2f5ff6-6d7d-4321-87fd-ecab5eb0369c	6def5cb3-6822-4ef6-a3a5-f52977685d8b	7cc0365f-3df4-4389-93f7-6f3907b1d014	11	2026-06-05 05:09:41.182877+00
f5a71a35-4063-445d-b456-6f0a7bcf7259	6def5cb3-6822-4ef6-a3a5-f52977685d8b	8f209177-d1f1-4419-bc20-707ccd166660	11	2026-06-05 05:09:41.354597+00
97f4c628-d46a-4f6e-94c0-aa8f03e22baf	6def5cb3-6822-4ef6-a3a5-f52977685d8b	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	11	2026-06-05 05:09:41.531772+00
3042c3da-c56f-4ea8-8461-a4353db85d0b	6def5cb3-6822-4ef6-a3a5-f52977685d8b	80497194-a652-4edc-9fcb-5c90d9e9d88f		2026-06-05 05:09:41.702271+00
5f277d77-3a5a-43c5-8920-2cee3db34b7a	6def5cb3-6822-4ef6-a3a5-f52977685d8b	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5		2026-06-05 05:09:41.871943+00
aa5b2446-b6b5-4628-a1a5-251f01efbd9d	6def5cb3-6822-4ef6-a3a5-f52977685d8b	734cd218-e0cc-4267-8226-8cafa57be5b9		2026-06-05 05:09:42.038608+00
923958c4-a3bd-403e-aab0-2c44f1b5e61d	6def5cb3-6822-4ef6-a3a5-f52977685d8b	cf3783f3-556c-4bf6-94ab-968d28be63d4		2026-06-05 05:09:42.204875+00
0e50bfc8-c667-4413-b638-f67a96cff744	6def5cb3-6822-4ef6-a3a5-f52977685d8b	c3fe8886-d3f1-4972-9d51-901392b86864		2026-06-05 05:09:42.37678+00
b8d764ee-3e35-4275-8aa4-d158bdc9a7b9	6def5cb3-6822-4ef6-a3a5-f52977685d8b	321d0540-1a62-4508-a5b4-f7bb9f2af4a0		2026-06-05 05:09:42.554641+00
31e37611-0373-4391-8b6c-b17e341f0948	6def5cb3-6822-4ef6-a3a5-f52977685d8b	0e7cb6e2-86c6-469f-8520-c7d7d5029604		2026-06-05 05:09:42.721968+00
\.


--
-- Data for Name: attributes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attributes (attribute_id, name, node_type, group_id, data_type_id, unit_id, is_required, is_active, created_at, updated_at) FROM stdin;
7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	Количество принятых и переработанных методом аммиачного осаждения растворов	metric	5d7a62ca-b9e2-4a95-9f8b-fca0468925eb	9283b1ba-f4eb-4e4c-b0f3-b839697dbe88	6c87c859-a336-4be6-8012-0686ba1ac3c3	t	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
f28188e3-fdb9-4d41-9a5a-2d3ff2730842	Количество прокаленной пульпы	metric	5d7a62ca-b9e2-4a95-9f8b-fca0468925eb	9283b1ba-f4eb-4e4c-b0f3-b839697dbe88	6c87c859-a336-4be6-8012-0686ba1ac3c3	t	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
cb2e05b8-5feb-47b8-933a-868b1e703342	Количество принятых и переработанных методом известкования растворов	metric	99b8f618-66d8-4404-8f33-b08bb581ce19	9283b1ba-f4eb-4e4c-b0f3-b839697dbe88	6c87c859-a336-4be6-8012-0686ba1ac3c3	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
0efafdb9-d607-4960-97f7-4c93eebe8c54	Отфильтровано пульпы	metric	99b8f618-66d8-4404-8f33-b08bb581ce19	9283b1ba-f4eb-4e4c-b0f3-b839697dbe88	6c87c859-a336-4be6-8012-0686ba1ac3c3	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
05baf163-db0d-4b25-80ba-05b5b80e4c69	Получено контейнеров	metric	99b8f618-66d8-4404-8f33-b08bb581ce19	180a8774-1e05-49b2-a2f1-5a8f32cb65ad	7d8bcd14-90e1-4bd9-9da2-196259225651	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
f03b4d94-e4cd-4814-bd63-de7697ac3f75	Сжигание отходов	section	3ce4f7d3-703b-433a-8ab5-f96f894b7ef0	\N	\N	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
0b9672ca-b402-4b76-bd72-1957304940a1	переработано отходов	metric	3ce4f7d3-703b-433a-8ab5-f96f894b7ef0	180a8774-1e05-49b2-a2f1-5a8f32cb65ad	4db0d219-5238-463f-b0f8-191e4ab9ade3	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
b7e6b576-fc4d-453c-bdab-27dc5452157c	получено емкостей с золой	metric	3ce4f7d3-703b-433a-8ab5-f96f894b7ef0	180a8774-1e05-49b2-a2f1-5a8f32cb65ad	7d8bcd14-90e1-4bd9-9da2-196259225651	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
bae050ac-dc2c-4894-9779-a527fc4914af	Прессование отходов	section	3ce4f7d3-703b-433a-8ab5-f96f894b7ef0	\N	\N	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
c334d16b-aaff-4d34-88ef-61f95cbe7e3a	получено бочек	metric	3ce4f7d3-703b-433a-8ab5-f96f894b7ef0	180a8774-1e05-49b2-a2f1-5a8f32cb65ad	7d8bcd14-90e1-4bd9-9da2-196259225651	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
e4e1de79-6696-4db5-94c6-c6debb80ede4	Измельчение фильтров на шредере	section	b98e8641-f7ba-407c-bbc5-1784d36a5ccc	\N	\N	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
7cc0365f-3df4-4389-93f7-6f3907b1d014	количество	metric	b98e8641-f7ba-407c-bbc5-1784d36a5ccc	180a8774-1e05-49b2-a2f1-5a8f32cb65ad	7d8bcd14-90e1-4bd9-9da2-196259225651	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
8f209177-d1f1-4419-bc20-707ccd166660	получено мешков	metric	b98e8641-f7ba-407c-bbc5-1784d36a5ccc	180a8774-1e05-49b2-a2f1-5a8f32cb65ad	7d8bcd14-90e1-4bd9-9da2-196259225651	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
55f17e1c-4c8a-4983-8c8c-06e26dac38b4	Освобождение контейнеров	metric	b98e8641-f7ba-407c-bbc5-1784d36a5ccc	180a8774-1e05-49b2-a2f1-5a8f32cb65ad	7d8bcd14-90e1-4bd9-9da2-196259225651	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
80497194-a652-4edc-9fcb-5c90d9e9d88f	Выявленные замечания по механическому оборудованию	metric	a8c8179b-5e14-4851-b59d-f2ab12ffda74	180a8774-1e05-49b2-a2f1-5a8f32cb65ad	\N	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
5f3148ed-7aaf-4da2-98a1-4b1025edd7a5	Выявленные замечания по электротехническому оборудованию	metric	a8c8179b-5e14-4851-b59d-f2ab12ffda74	180a8774-1e05-49b2-a2f1-5a8f32cb65ad	\N	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
734cd218-e0cc-4267-8226-8cafa57be5b9	Выявленные замечания по приборному оборудованию	metric	a8c8179b-5e14-4851-b59d-f2ab12ffda74	180a8774-1e05-49b2-a2f1-5a8f32cb65ad	\N	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
cf3783f3-556c-4bf6-94ab-968d28be63d4	Отклонения по установкам	metric	a8c8179b-5e14-4851-b59d-f2ab12ffda74	55e33974-3518-47d5-80ab-07e6dca4f681	\N	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
c3fe8886-d3f1-4972-9d51-901392b86864	Количество превышений контрольных показателей	metric	a8c8179b-5e14-4851-b59d-f2ab12ffda74	180a8774-1e05-49b2-a2f1-5a8f32cb65ad	\N	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
321d0540-1a62-4508-a5b4-f7bb9f2af4a0	Замечания по персоналу	metric	a8c8179b-5e14-4851-b59d-f2ab12ffda74	55e33974-3518-47d5-80ab-07e6dca4f681	\N	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
0e7cb6e2-86c6-469f-8520-c7d7d5029604	Замечания по оборудованию	metric	a8c8179b-5e14-4851-b59d-f2ab12ffda74	55e33974-3518-47d5-80ab-07e6dca4f681	\N	f	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00
\.


--
-- Data for Name: credentials; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.credentials (user_id, login, password_hash, last_login_at, failed_login_attempts, updated_at) FROM stdin;
5f3381f0-eda8-407c-a7e2-bc0fb324d9b7	глава	$2a$12$xZCWrxquAxjFrSA/LlGnNOWAwfgabBiaVjcvCTWGsPhbVO2WcJPza	2026-06-05 05:37:16.013165+00	0	2026-06-05 05:37:16.013165+00
d50ee4f5-95b0-48e5-9b8e-a178e94d5726	testov	$2a$10$mhN3vMKOgJqj13GMP5grMeOKzqqHuNrB10zFUV40q.r8vj2ma1D9C	\N	0	2026-04-27 19:26:05.692307+00
2ffeea8c-8e42-4e78-86f3-be2c246c336c	6	$2a$10$psPBxj7KlFyL0ldiO1apfuj25MuFVHyshiclP97mV9QrlQeWXsyh6	\N	0	2026-04-27 19:36:11.41996+00
5fd777be-ad62-429b-8536-aab7eee8bc3c	инван	$2a$10$vNEs9Jn.QUwGTjX018LyPeb0m.O8DSIh3vhUJnfUMf6ICyW5SCzzi	\N	0	2026-05-30 10:21:49.49275+00
05c2fa4a-5bd9-4ccc-9fa7-76e6fb907ed7	alldeactivated	$2a$12$mJpkZQ7EKbf/pEN.eMV3GuzkFvio8qtYxhpIZlGLWaF9AjH/SDWLu	2026-05-22 12:06:05.606046+00	0	2026-05-22 12:06:05.606546+00
e171393e-2def-4ab1-9a58-1c68afaf2ac4	ivanov	$2a$12$MQKM42xg9gFj8gZYg.B8j.SUnYTQj3ZiHrWhjuYIFs2lXwV382Tvu	2026-04-26 12:06:48.990588+00	0	2026-04-26 12:06:48.990588+00
a63b3b95-7582-4703-b1f7-02eab61f2ac6	deletetemp	$2a$10$i.k.UedsPrpUFat0/AG1Zumv4QE4Q3FyJhAUa3IoAtHFeEkn1c1Ai	2026-04-26 13:12:55.237395+00	0	2026-04-26 13:12:55.237895+00
90a9153e-1f5f-4f8c-a26f-41291c4e145c	alldeactivated1	$2a$10$.3IIjtAx5tHDvKED4jxzeuJe8T9Ddj0Mvl85owfct84I31/5qFmf.	\N	0	2026-04-26 14:47:15.613614+00
9b1421a8-95d4-4788-9b10-d69cd18e44e1	тестовый	$2a$12$f1LEi3eEG6Sf1gcIv3I7FOBvND3Jiu2mMbblzijQcOiUsOWapLZhi	\N	0	2026-04-28 07:05:52.959315+00
9585624f-08db-4888-bbef-1cd8da817e83	1233	$2a$10$vpJIE2OYk1cz3FZlXJ/F3.Cfbeeyow/ZUdwIt.mPerTR0/D8KCY.C	\N	0	2026-04-28 10:33:39.990674+00
c9284809-ba16-4cae-94ab-c2f65a7c8f12	кирилл	$2a$10$uHgQLz886Owxp1kATxl68uT5Caz9iiHqNGwraHa7fY8QUe4XI.BTq	\N	0	2026-05-23 17:38:18.853256+00
7ee6d9fa-b56c-4f7a-9396-b8f829502eab	армений	$2a$10$IBDBVvaws0NYZEpUKfQ9/exY.RCsR10blD7wxMKoo6g.djMz5g5KS	\N	0	2026-05-23 17:39:53.770174+00
090ea126-5c8e-49b8-84da-d399ec3256f2	5555	$2a$10$jljPu5ucR1j7hV2FnuGq2umHW6/kRJi3An/C6qQsUA3NYDpY2.UGa	\N	0	2026-05-13 21:10:51.40868+00
00713118-3702-43b9-b786-1f5326c5bd0f	666	$2a$10$6CjXf1ITlxKqph2EbSzvCOstO6jt97Ixw4K0QAqLwhFngM2UOB90u	\N	0	2026-05-13 21:17:28.637199+00
057368a9-b0a0-4a58-ab6c-52028bbd86c9	7	$2a$10$qoyRl9CntKoOtM2.6fDRTOOZE3hq1qDXiDjPIWR38Dia57esReQEi	\N	0	2026-05-13 21:23:33.72173+00
531b8d0b-c469-49f1-9f24-597b741b3bf5	начальник	$2a$12$tTZ9gaGHLrRxncV5ma194eQKflWEQEcOhjg4VVjv1rsnCTt4GB2n.	2026-06-05 05:11:55.484375+00	0	2026-06-05 05:11:55.484375+00
56d79006-412e-4a1a-ab42-da5509b64260	админ	$2a$12$mJpkZQ7EKbf/pEN.eMV3GuzkFvio8qtYxhpIZlGLWaF9AjH/SDWLu	2026-06-05 05:13:05.776121+00	0	2026-06-05 05:13:05.776121+00
72a358d2-454d-4910-bfbb-fd49af8bae9b	999	$2a$10$ZLJXzr14QhJ8ihQZVPZlSO.QsHGiuQjHpUQbn8QAFrAbmTdSA9snO	\N	0	2026-05-15 12:14:51.188341+00
46bd2c34-8e55-41f9-b4d5-f313792dd364	999999	$2a$10$cD3fjccyQG8gmWXAknfDruuLI/lnDD7.xUjFwUqNmwuNvcK.63e8u	\N	0	2026-05-15 12:15:45.90999+00
7bd656a4-fc9d-4a48-b66c-78ee74487323	andr1	$2a$10$a/ogHgSSEsVEY2VEqbWACu9Ggr10hsYNljA8h.n/bLbm4ue/FYT1.	\N	0	2026-06-05 05:25:02.103657+00
1025389a-0e27-4e08-b6a0-b188660bea57	инженер	$2a$12$oxx1uBZmAOfzA2lu6xSgRO8fhWqFxRGjSWGgBb/xs3ugz1V4B4KyC	2026-06-05 05:36:54.962933+00	0	2026-06-05 05:36:54.96393+00
\.


--
-- Data for Name: data_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.data_types (data_type_id, name, base_type) FROM stdin;
ac61e40f-acd4-4aab-9aad-3849218649da	Малое целое	smallint
180a8774-1e05-49b2-a2f1-5a8f32cb65ad	Целое число	integer
1802200c-e274-4a02-827e-e85c21737ef1	Большое целое	bigint
9283b1ba-f4eb-4e4c-b0f3-b839697dbe88	Число с фиксированной точностью	numeric
2dfb3f08-2ad8-476f-9858-a073b6b8be18	Число с плавающей точкой	real
d1eb1091-cbea-4fa7-b2de-9520f754c23c	Число двойной точности	double precision
2d5882cd-1649-4707-9b75-f1ac59ec2bc4	Булево	boolean
55e33974-3518-47d5-80ab-07e6dca4f681	Текст	text
4628c77a-1b16-466c-96fc-cfb5374fe74f	Дата	date
409f8bac-c0c0-48ea-9c64-55e109d5b994	Дата и время	timestamp
4478f94f-67a5-4b96-831e-6fd6060bd440	Дата и время с часовым поясом	timestamptz
\.


--
-- Data for Name: department_schedules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.department_schedules (schedule_id, department_id, name, sort_order, start_time, end_time, crosses_midnight) FROM stdin;
7d94106f-01ca-40ca-b260-3673c0f41c0a	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	1 смена	1	07:00:00	15:30:00	f
33c5b11e-13c4-4755-bd73-671f34fcea98	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	2 смена	2	15:30:00	00:00:00	t
96e70ab9-2fd7-4727-ab81-20c3edd34159	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	3 смена	3	00:00:00	07:30:00	f
\.


--
-- Data for Name: department_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.department_templates (department_id, template_id) FROM stdin;
e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	a28e06e4-b250-40f9-ae25-17db1db01534
\.


--
-- Data for Name: department_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.department_users (department_id, user_id) FROM stdin;
e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	1025389a-0e27-4e08-b6a0-b188660bea57
e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	531b8d0b-c469-49f1-9f24-597b741b3bf5
e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	56d79006-412e-4a1a-ab42-da5509b64260
3650aab8-254a-440e-9665-e4af33584faa	5f3381f0-eda8-407c-a7e2-bc0fb324d9b7
a2641f9a-865e-4071-b251-f0c943117370	a63b3b95-7582-4703-b1f7-02eab61f2ac6
a2641f9a-865e-4071-b251-f0c943117370	05c2fa4a-5bd9-4ccc-9fa7-76e6fb907ed7
e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	d50ee4f5-95b0-48e5-9b8e-a178e94d5726
e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	2ffeea8c-8e42-4e78-86f3-be2c246c336c
37515fef-14f2-4c55-8076-7836d0c96a5d	e171393e-2def-4ab1-9a58-1c68afaf2ac4
37515fef-14f2-4c55-8076-7836d0c96a5d	90a9153e-1f5f-4f8c-a26f-41291c4e145c
e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	9b1421a8-95d4-4788-9b10-d69cd18e44e1
a2641f9a-865e-4071-b251-f0c943117370	9585624f-08db-4888-bbef-1cd8da817e83
a2641f9a-865e-4071-b251-f0c943117370	090ea126-5c8e-49b8-84da-d399ec3256f2
e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	00713118-3702-43b9-b786-1f5326c5bd0f
a2641f9a-865e-4071-b251-f0c943117370	057368a9-b0a0-4a58-ab6c-52028bbd86c9
a2641f9a-865e-4071-b251-f0c943117370	72a358d2-454d-4910-bfbb-fd49af8bae9b
a2641f9a-865e-4071-b251-f0c943117370	46bd2c34-8e55-41f9-b4d5-f313792dd364
3650aab8-254a-440e-9665-e4af33584faa	c9284809-ba16-4cae-94ab-c2f65a7c8f12
e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7ee6d9fa-b56c-4f7a-9396-b8f829502eab
a2641f9a-865e-4071-b251-f0c943117370	5fd777be-ad62-429b-8536-aab7eee8bc3c
e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7bd656a4-fc9d-4a48-b66c-78ee74487323
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.departments (department_id, parent_department_id, hierarchy_level, name, short_name, is_active, created_at) FROM stdin;
3650aab8-254a-440e-9665-e4af33584faa	\N	0	УралВагонЗавод	УВЗ	t	2026-03-22 20:42:49.309829+00
a2641f9a-865e-4071-b251-f0c943117370	3650aab8-254a-440e-9665-e4af33584faa	1	Цех 2	Ц2	t	2026-03-22 20:42:49.309829+00
e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	a2641f9a-865e-4071-b251-f0c943117370	2	Участок № 7	Участок 7	t	2026-03-22 20:29:30.552516+00
37515fef-14f2-4c55-8076-7836d0c96a5d	3650aab8-254a-440e-9665-e4af33584faa	1	ДЕАКТИВИРОВАННОЕ ПОДРАЗДЕЛЕНИЕ	ДЕАКТ	f	2026-04-27 20:28:27.333234+00
\.


--
-- Data for Name: measurement_units; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.measurement_units (unit_id, name, short_name) FROM stdin;
6c87c859-a336-4be6-8012-0686ba1ac3c3	Кубический метр	м3
4db0d219-5238-463f-b0f8-191e4ab9ade3	Килограмм	кг
7d8bcd14-90e1-4bd9-9da2-196259225651	Штука	шт
\.


--
-- Data for Name: modules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modules (module_id, display_name, created_at, description, is_active, slug) FROM stdin;
7188abbd-de97-4647-8eee-9b3fae6f7c92	Главная	2026-04-09 18:15:31.085106+00	Главный экран системы	t	HOME
36bacdd3-9b89-42ae-b440-6691d864a061	Рапорты	2026-04-09 18:15:31.085106+00	Работа с рапортами	t	SHIFT_REPORTS
a3465e35-7f70-47f3-8374-472a9b17c2ff	Шаблоны	2026-04-09 18:15:31.085106+00	Управление шаблонами	t	TEMPLATES
a6f1a402-e3b9-4235-8025-0d8ddfc7a2aa	Сотрудники	2026-04-09 18:15:31.085106+00	Управление сотрудниками	t	EMPLOYEES
e2e30f53-a2d5-4a2d-924e-f4215c28a2d2	Структура предприятия	2026-04-09 18:15:31.085106+00	Управление структурой предприятия	t	ORG_STRUCTURE
fd36417c-ff36-4471-b7d6-6297311679e9	Ролевая система	2026-04-09 18:15:31.085106+00	Управление ролями и правами доступа	t	ROLES
6bc59da2-9ba6-4614-9073-ea7b48ce2a93	Отчеты	2026-04-09 18:15:31.085106+00	Просмотр и анализ отчетов	f	ANALYTICS
\.


--
-- Data for Name: report_instances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.report_instances (report_id, template_id, shift_id, created_at, closed_at, status) FROM stdin;
967e6f26-4e69-4da4-bdc5-ae119d5ad716	a28e06e4-b250-40f9-ae25-17db1db01534	1f13812a-18de-4a17-afdb-08edd618ddaa	2026-04-13 21:19:50.338595+00	2026-04-13 21:46:25.79824+00	ready
9a7f2e98-62a0-4da7-aa47-ac51085ffd66	a28e06e4-b250-40f9-ae25-17db1db01534	4999f1bb-9edd-4f07-ac73-873cf6c42a1f	2026-04-07 13:49:58.861101+00	2026-04-14 09:58:42.26981+00	not_ready
fe238c96-baa2-470b-9245-ccd49439b800	a28e06e4-b250-40f9-ae25-17db1db01534	96554daf-3b3f-4967-844b-0245a2e72f78	2026-03-23 11:18:47.963223+00	2026-04-14 09:58:42.529957+00	not_ready
4b690648-0503-432d-8f18-cdca84d07459	a28e06e4-b250-40f9-ae25-17db1db01534	d9d1a124-bc0c-474e-b4ce-0d154a5c6819	2026-04-14 10:05:20.120276+00	2026-04-14 10:06:21.614933+00	ready
f96b02fe-6fe2-475d-b707-1364344fc0e2	a28e06e4-b250-40f9-ae25-17db1db01534	5e2ba4f8-3458-4c18-82ff-e633bb16590d	2026-04-14 10:06:27.191066+00	2026-04-14 10:20:48.393521+00	ready
f487a644-e906-44e5-bd04-b6976e8ed246	a28e06e4-b250-40f9-ae25-17db1db01534	c6c0a51c-2b92-435f-a583-eeeb2b10d099	2026-04-14 10:21:57.587145+00	2026-04-14 11:04:23.406593+00	ready
0bc63a1c-e7b7-40e2-a810-c4e7cd2482ee	a28e06e4-b250-40f9-ae25-17db1db01534	b47468b4-2d88-45fa-9715-f44478477478	2026-04-14 11:04:48.819873+00	2026-04-14 11:04:49.026451+00	not_ready
1ac3118d-9cae-4efa-8bc6-200e247b9f17	a28e06e4-b250-40f9-ae25-17db1db01534	d7759873-eea6-497d-93ff-7b4c35f57a77	2026-04-14 11:05:00.670742+00	2026-04-14 11:05:01.141049+00	not_ready
4fbf3b69-764f-4de5-ba99-3465bd2a4bca	a28e06e4-b250-40f9-ae25-17db1db01534	fda6c393-c5eb-47a7-b8a9-27f592f15737	2026-04-14 11:05:07.475017+00	2026-04-14 11:05:07.703913+00	not_ready
51de989d-f268-4549-9350-43368046090a	a28e06e4-b250-40f9-ae25-17db1db01534	ac1a659f-5001-405e-a979-e459b9fbe686	2026-04-14 11:05:12.361267+00	2026-04-14 11:08:02.947246+00	ready
c5b31830-68b5-4d0d-8985-d85c0a558f79	a28e06e4-b250-40f9-ae25-17db1db01534	8cb1d9c2-181f-4f78-ae80-5bc39591bbd9	2026-04-14 10:25:43.986454+00	2026-04-14 11:08:19.268249+00	not_ready
3e37bddc-6e72-40f1-ba98-21e5b111c3b6	a28e06e4-b250-40f9-ae25-17db1db01534	ad44a91f-534e-497e-bcac-fc7016236f3f	2026-04-14 10:26:00.341717+00	2026-04-14 11:08:19.762212+00	not_ready
ceea4489-b71f-43b1-8fc1-a4de52bbb227	a28e06e4-b250-40f9-ae25-17db1db01534	8b862153-ef58-4266-b730-4c3456e677de	2026-04-14 11:08:22.850006+00	2026-04-14 11:08:23.051597+00	not_ready
969dc91b-44f2-46ef-b4e8-579a574ef8a5	a28e06e4-b250-40f9-ae25-17db1db01534	2548d4cf-890e-4b35-8a68-027004d34b3e	2026-04-14 11:08:29.662963+00	2026-04-14 11:08:29.867467+00	not_ready
cbcde15a-db1b-4483-b12c-730b591525d4	a28e06e4-b250-40f9-ae25-17db1db01534	c8db0baa-e389-473a-aa67-f3cc4926b316	2026-04-14 11:08:39.482265+00	2026-04-14 11:09:15.470565+00	ready
6e707aec-1027-483c-a875-ca4a95632965	a28e06e4-b250-40f9-ae25-17db1db01534	b4af5760-975f-41f4-af99-6ccbd600b7f5	2026-04-14 11:09:39.072586+00	2026-04-14 11:09:39.281723+00	not_ready
0058f0d8-5383-449d-b5f0-0f6e851f37fc	a28e06e4-b250-40f9-ae25-17db1db01534	8b1de6e1-9f56-4b90-94c7-3a9617bc9351	2026-04-14 11:09:47.803097+00	2026-04-14 11:09:48.243396+00	not_ready
7cd40836-627b-40ff-9dc1-332d2b3092c9	a28e06e4-b250-40f9-ae25-17db1db01534	f4ede4ae-fcff-4d8e-9b19-51ad38b9d079	2026-04-14 11:09:55.311185+00	2026-04-14 11:12:24.735468+00	ready
caa9f71f-e486-45f2-babc-641080b95342	a28e06e4-b250-40f9-ae25-17db1db01534	91d0a830-86f8-4be0-b549-1b477e948e33	2026-04-14 11:12:31.748176+00	2026-04-14 11:12:31.978198+00	not_ready
a702848c-2d70-499e-9cf0-f62e89f148db	a28e06e4-b250-40f9-ae25-17db1db01534	17b91502-0916-4a81-b13e-da20b5b0aeff	2026-04-14 11:12:35.641815+00	2026-04-14 11:12:35.867111+00	not_ready
4269a9a3-5f0c-4373-8ea4-7fd4469cecce	a28e06e4-b250-40f9-ae25-17db1db01534	0db7f968-4c5f-4b92-b019-c18f376a72e5	2026-04-14 11:12:39.075395+00	2026-04-14 11:15:33.506819+00	ready
cb2d84f5-e70d-42b9-ae9c-69cd7bf523d1	a28e06e4-b250-40f9-ae25-17db1db01534	2f7681e2-c99e-4e0b-bec2-f60cc4adf5b6	2026-04-14 11:15:37.128794+00	2026-04-14 11:15:37.377132+00	not_ready
b50fcfc4-f61a-4e20-bb65-c20246a0fe6c	a28e06e4-b250-40f9-ae25-17db1db01534	dc725bc7-2b4d-4ef5-ae1e-fde7cc119e11	2026-04-14 11:19:07.021068+00	2026-04-14 11:19:07.269933+00	not_ready
6db7cb2d-7082-4cdf-bf6c-22eb007b1bbf	a28e06e4-b250-40f9-ae25-17db1db01534	dd2ffd3e-2422-4a9c-85f9-f91251b36769	2026-04-14 11:20:19.692492+00	2026-04-14 11:20:19.91599+00	not_ready
9340618a-3c17-4cbd-ab2d-5e45b8e682dc	a28e06e4-b250-40f9-ae25-17db1db01534	26b314cc-790e-4f7c-9f84-5ec5907e4c9c	2026-04-14 11:20:23.258738+00	2026-04-14 11:20:31.559938+00	ready
6e16bb2a-1bed-491b-bc76-8a9faa76e2a3	a28e06e4-b250-40f9-ae25-17db1db01534	3cc46193-a8fb-40b9-aecc-7aa2425886f5	2026-04-14 20:50:08.41689+00	2026-04-14 20:50:34.38573+00	ready
21f0248c-6b10-4063-92d0-27817f8e09a7	a28e06e4-b250-40f9-ae25-17db1db01534	9f02c8fd-9015-42a6-8284-25302d63bb23	2026-04-14 20:50:40.076948+00	2026-04-14 20:51:01.648297+00	ready
19f6928f-b6ce-48fd-8660-3d2f7b48e160	a28e06e4-b250-40f9-ae25-17db1db01534	9842f7b8-fcee-4046-9271-28bb4157ee40	2026-04-14 20:51:08.646603+00	2026-04-15 13:09:42.038664+00	not_ready
9a10f89b-1b4a-4817-a8e7-bd3de9ac2be5	a28e06e4-b250-40f9-ae25-17db1db01534	3b153a93-68af-40b3-b5b4-e61475581327	2026-04-14 11:22:03.881816+00	2026-04-21 14:39:03.425513+00	not_ready
3d15c36b-4024-46cf-936f-283a83205366	a28e06e4-b250-40f9-ae25-17db1db01534	f0cef2f1-7b47-4bce-b915-e1d74c168c01	2026-04-14 11:21:49.508889+00	2026-04-21 14:39:04.406538+00	not_ready
c198d54c-958f-4d1b-8f97-b09bb4d4d882	a28e06e4-b250-40f9-ae25-17db1db01534	fd404a98-38dd-48d0-ae0a-287d4f994307	2026-04-14 11:18:52.623356+00	2026-04-21 20:02:07.474713+00	not_ready
bfcf21ec-bd55-4cef-a859-12e810a6a826	a28e06e4-b250-40f9-ae25-17db1db01534	336a8171-14b8-49f9-a3de-9f4228b1dce5	2026-04-22 12:00:53.864732+00	2026-04-22 12:00:54.572468+00	not_ready
8e252b7f-03d9-4371-8008-cefb05291a27	a28e06e4-b250-40f9-ae25-17db1db01534	0d4b53d4-dd5e-4ddb-a09b-99891a18603b	2026-04-22 12:01:09.277867+00	2026-04-22 12:02:30.700561+00	ready
629d9b0d-b1ae-423c-a73d-f2a6e27bf862	a28e06e4-b250-40f9-ae25-17db1db01534	6209939d-6926-4cf5-b280-07d5d7ab334d	2026-04-26 16:25:24.638215+00	2026-04-26 16:33:39.642496+00	ready
bda56821-2734-4433-8acc-3372a1a5fbcb	a28e06e4-b250-40f9-ae25-17db1db01534	24bd9273-1a0b-45f5-a470-6890f2a959b3	2026-04-26 16:34:24.880893+00	2026-04-26 16:35:51.082974+00	ready
3eff7af1-d40a-423c-9365-761ad005fea8	a28e06e4-b250-40f9-ae25-17db1db01534	ea0c59db-4e4a-4b96-baac-461f7a5582c4	2026-04-26 16:40:51.490935+00	2026-04-26 16:43:15.756854+00	ready
d5d35fa8-8adc-4679-88f0-79f54ed9046b	a28e06e4-b250-40f9-ae25-17db1db01534	ac909895-3b11-4615-9aa0-21c75ee44b15	2026-04-26 16:07:06.137294+00	2026-04-27 10:19:40.899624+00	not_ready
ab1c3abd-8560-481f-8970-89621dd41fef	a28e06e4-b250-40f9-ae25-17db1db01534	1dec5b2d-6696-433b-afaa-9cc3f61ec67e	2026-04-27 17:21:57.788337+00	2026-04-27 17:38:38.030618+00	ready
9b6c9b64-9ab3-42a5-b61b-adf762a4d8a7	a28e06e4-b250-40f9-ae25-17db1db01534	97c94fd5-0690-4e2b-be21-107e649bd528	2026-04-27 22:41:46.362249+00	2026-04-28 01:11:16.663184+00	ready
0117d4f1-74a5-4fab-b494-34cc679e1415	a28e06e4-b250-40f9-ae25-17db1db01534	9bfb866c-12c2-4a48-bb7e-59207fa71bfd	2026-04-28 00:52:38.974117+00	2026-04-28 01:11:17.941586+00	not_ready
26e06d75-d6bf-4f48-8774-6c8b5eb2d102	a28e06e4-b250-40f9-ae25-17db1db01534	9f1b6f4f-fde9-4485-bd59-85607bc9a7cd	2026-04-27 23:11:08.953923+00	2026-04-28 01:21:31.321529+00	not_ready
55a3da89-fe54-4afb-8a30-ab63fef2ad76	a28e06e4-b250-40f9-ae25-17db1db01534	9962b83d-0986-4fa6-a0f2-e1df8b30b977	2026-04-28 10:35:52.543405+00	2026-04-28 10:36:23.727087+00	ready
aaa661c8-f662-4ddb-8998-f3bc3d060630	a28e06e4-b250-40f9-ae25-17db1db01534	78833f86-8b19-4f90-b7dc-d4410369a515	2026-05-09 22:03:24.738245+00	2026-05-09 22:57:35.767482+00	ready
018905ac-c860-42b3-bca3-9404ac3a9787	a28e06e4-b250-40f9-ae25-17db1db01534	5d8a9d55-58d4-4058-bf6f-3b4c9c04cf5b	2026-05-10 00:16:51.549353+00	2026-05-14 07:18:04.209141+00	not_ready
cf228ded-a494-4dc9-a345-7174b0f7d783	a28e06e4-b250-40f9-ae25-17db1db01534	2804abd0-0bae-49a4-a594-33e2d2076a6d	2026-05-14 07:18:18.405312+00	2026-05-14 07:19:11.015913+00	ready
21e0e354-aa47-49b0-8876-f82d1f90d15f	a28e06e4-b250-40f9-ae25-17db1db01534	3edd269c-f847-4476-a06f-a1d52ebe952a	2026-05-14 07:19:39.815678+00	2026-05-14 07:20:12.399083+00	ready
de795eb2-c618-42f0-bb3a-e8bfe1f25258	a28e06e4-b250-40f9-ae25-17db1db01534	3826ccb4-ddda-4cab-a206-416f16aa7b48	2026-05-19 20:38:15.657847+00	2026-05-29 11:49:58.597289+00	not_ready
0972ec40-39b9-4c45-a38d-77c0bf8915c1	a28e06e4-b250-40f9-ae25-17db1db01534	a81129a9-5f70-44c6-8f19-d52d53690e7c	2026-05-29 11:51:25.708927+00	2026-05-30 03:38:34.609173+00	not_ready
e127fc81-a29d-443f-a766-dd03ee49f332	a28e06e4-b250-40f9-ae25-17db1db01534	1c1e313a-40a1-4452-8ac5-247181658b3b	2026-05-29 11:50:18.431537+00	2026-05-30 03:38:35.717554+00	not_ready
69138454-c596-4e60-8065-3282720c46a4	a28e06e4-b250-40f9-ae25-17db1db01534	7fe16c76-feb6-4a96-bfab-7ae29ffd8acb	2026-05-29 11:52:20.639308+00	2026-05-30 03:49:54.444135+00	not_ready
a3873c60-9f59-4ee6-bbb9-ce55d1f608e9	a28e06e4-b250-40f9-ae25-17db1db01534	ae6d63ba-903d-4a6d-9aff-a1d1c01c3a7e	2026-05-30 03:51:30.359969+00	2026-05-30 04:03:13.953273+00	ready
e870bc11-2c3b-49df-a086-8443d6f716fc	a28e06e4-b250-40f9-ae25-17db1db01534	23abf0e4-4389-4f41-aba3-fb892779f8d9	2026-05-30 04:03:37.963269+00	2026-05-30 04:04:45.823638+00	ready
aaaa832b-c288-4d32-a056-5b75a366c163	a28e06e4-b250-40f9-ae25-17db1db01534	3a3bcff4-6e43-425d-ab5a-845ad4115de6	2026-05-30 04:05:18.488301+00	2026-05-30 04:05:19.508258+00	not_ready
2d8ac693-4b0a-4c2b-a3ac-c4577fbf7f86	a28e06e4-b250-40f9-ae25-17db1db01534	69d4c4dd-e2ab-4544-921a-8ac145316335	2026-05-30 04:05:47.22397+00	2026-05-30 04:05:48.247753+00	not_ready
9a8ec876-c7fd-45b6-8e3d-75c6277a9362	a28e06e4-b250-40f9-ae25-17db1db01534	3c28db80-cfaf-49c9-aedb-306144f7fb78	2026-05-30 04:06:12.736305+00	2026-05-30 04:07:34.630331+00	ready
fbf9f6e2-2027-4721-966c-b9f85ebed91a	a28e06e4-b250-40f9-ae25-17db1db01534	0017e062-7ddf-4c90-b116-b1a9c51f986f	2026-05-30 04:07:42.383142+00	2026-05-30 04:07:43.398669+00	not_ready
80a845b6-050e-456a-876c-040edd54ce45	a28e06e4-b250-40f9-ae25-17db1db01534	7eeee52b-2fab-4e3a-b78e-e5c68289c1f3	2026-05-30 04:48:21.634232+00	2026-05-30 05:06:54.353964+00	ready
3035abd5-82e7-4d81-b1e4-cee54fbd1d0f	a28e06e4-b250-40f9-ae25-17db1db01534	1ba902db-c8ea-42a7-8e95-01877d351c20	2026-05-30 05:07:30.184159+00	2026-05-30 05:09:25.590299+00	ready
ee58c222-f6a4-4f01-9756-3af88b448875	a28e06e4-b250-40f9-ae25-17db1db01534	40f50327-6a4b-4e8c-b5a0-1a057a8c428d	2026-05-30 05:13:59.889601+00	2026-05-30 06:03:05.086944+00	ready
0dbc6e8b-a2ce-4bd7-ae2f-47195d038eab	a28e06e4-b250-40f9-ae25-17db1db01534	96a6f2c9-3a14-445d-bd72-1a032992f764	2026-05-30 09:58:01.831694+00	2026-05-30 09:58:35.798746+00	ready
93916b99-dbf9-42d3-8747-80eafb2d976f	a28e06e4-b250-40f9-ae25-17db1db01534	482d66ca-db68-470b-b719-0476ac45c382	2026-06-05 00:06:23.72434+00	2026-06-05 00:07:24.860317+00	ready
f2501cb3-72a7-49ec-9d9b-36d06caf8e18	a28e06e4-b250-40f9-ae25-17db1db01534	f3a2c56b-9a22-49f8-9dc4-b5b97ea0341c	2026-06-05 01:18:03.116554+00	2026-06-05 02:20:54.63657+00	ready
e3be5ed6-88d2-49cc-9e34-845d47496c50	a28e06e4-b250-40f9-ae25-17db1db01534	b15dd50c-a1ee-4f0d-8301-53d0b4131208	2026-06-05 03:14:48.715611+00	2026-06-05 03:14:59.434444+00	ready
6def5cb3-6822-4ef6-a3a5-f52977685d8b	a28e06e4-b250-40f9-ae25-17db1db01534	e12eb26b-d4ba-4643-b473-9572e5f40914	2026-06-05 05:09:18.739503+00	2026-06-05 05:09:50.38893+00	ready
\.


--
-- Data for Name: report_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.report_templates (template_id, name, is_active, created_at, updated_at, version) FROM stdin;
a28e06e4-b250-40f9-ae25-17db1db01534	Шаблон рапорта начальнику цеха Х по участку № 7	t	2026-03-22 20:29:30.552516+00	2026-03-22 20:29:30.552516+00	1
\.


--
-- Data for Name: role_modules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_modules (role_id, module_id) FROM stdin;
023170ef-7ff6-4bab-96e4-08548dfb8d5d	a6f1a402-e3b9-4235-8025-0d8ddfc7a2aa
023170ef-7ff6-4bab-96e4-08548dfb8d5d	e2e30f53-a2d5-4a2d-924e-f4215c28a2d2
023170ef-7ff6-4bab-96e4-08548dfb8d5d	fd36417c-ff36-4471-b7d6-6297311679e9
3023d52d-936a-4284-9f13-75fd97542569	7188abbd-de97-4647-8eee-9b3fae6f7c92
3023d52d-936a-4284-9f13-75fd97542569	36bacdd3-9b89-42ae-b440-6691d864a061
3023d52d-936a-4284-9f13-75fd97542569	a3465e35-7f70-47f3-8374-472a9b17c2ff
3023d52d-936a-4284-9f13-75fd97542569	a6f1a402-e3b9-4235-8025-0d8ddfc7a2aa
3023d52d-936a-4284-9f13-75fd97542569	e2e30f53-a2d5-4a2d-924e-f4215c28a2d2
3023d52d-936a-4284-9f13-75fd97542569	fd36417c-ff36-4471-b7d6-6297311679e9
a22f7db9-19f5-4129-9085-fff5c60c4363	7188abbd-de97-4647-8eee-9b3fae6f7c92
a22f7db9-19f5-4129-9085-fff5c60c4363	36bacdd3-9b89-42ae-b440-6691d864a061
a22f7db9-19f5-4129-9085-fff5c60c4363	a3465e35-7f70-47f3-8374-472a9b17c2ff
a22f7db9-19f5-4129-9085-fff5c60c4363	a6f1a402-e3b9-4235-8025-0d8ddfc7a2aa
6601261e-1952-4078-a225-ef1b5276f143	e2e30f53-a2d5-4a2d-924e-f4215c28a2d2
6601261e-1952-4078-a225-ef1b5276f143	fd36417c-ff36-4471-b7d6-6297311679e9
3e67d907-8570-4902-939a-0903c632d7a9	7188abbd-de97-4647-8eee-9b3fae6f7c92
3e67d907-8570-4902-939a-0903c632d7a9	36bacdd3-9b89-42ae-b440-6691d864a061
5f1bab97-fcf1-4fad-b34d-35f35097b5f1	7188abbd-de97-4647-8eee-9b3fae6f7c92
5f1bab97-fcf1-4fad-b34d-35f35097b5f1	36bacdd3-9b89-42ae-b440-6691d864a061
5f1bab97-fcf1-4fad-b34d-35f35097b5f1	a3465e35-7f70-47f3-8374-472a9b17c2ff
15fc7a36-de24-4a51-aeb6-5cc2fd5ae726	7188abbd-de97-4647-8eee-9b3fae6f7c92
15fc7a36-de24-4a51-aeb6-5cc2fd5ae726	36bacdd3-9b89-42ae-b440-6691d864a061
15fc7a36-de24-4a51-aeb6-5cc2fd5ae726	a3465e35-7f70-47f3-8374-472a9b17c2ff
2d45bca5-c273-4610-af33-d06f4df08d50	a6f1a402-e3b9-4235-8025-0d8ddfc7a2aa
2d45bca5-c273-4610-af33-d06f4df08d50	e2e30f53-a2d5-4a2d-924e-f4215c28a2d2
2d45bca5-c273-4610-af33-d06f4df08d50	fd36417c-ff36-4471-b7d6-6297311679e9
411c233d-e9d6-45fa-b275-d8ee6f09ccc5	a6f1a402-e3b9-4235-8025-0d8ddfc7a2aa
411c233d-e9d6-45fa-b275-d8ee6f09ccc5	e2e30f53-a2d5-4a2d-924e-f4215c28a2d2
411c233d-e9d6-45fa-b275-d8ee6f09ccc5	fd36417c-ff36-4471-b7d6-6297311679e9
ce1dcb8c-0ca5-4a10-b0a9-2f8745a134ea	e2e30f53-a2d5-4a2d-924e-f4215c28a2d2
ce1dcb8c-0ca5-4a10-b0a9-2f8745a134ea	fd36417c-ff36-4471-b7d6-6297311679e9
19402253-261a-4072-932b-8fb9d72abdc5	fd36417c-ff36-4471-b7d6-6297311679e9
7c2a211a-e4fb-4b96-b89e-cbb60c92fcdd	fd36417c-ff36-4471-b7d6-6297311679e9
8aeb45aa-59c3-4200-a934-19e8ba175ec7	7188abbd-de97-4647-8eee-9b3fae6f7c92
8aeb45aa-59c3-4200-a934-19e8ba175ec7	36bacdd3-9b89-42ae-b440-6691d864a061
8aeb45aa-59c3-4200-a934-19e8ba175ec7	6bc59da2-9ba6-4614-9073-ea7b48ce2a93
8aeb45aa-59c3-4200-a934-19e8ba175ec7	a3465e35-7f70-47f3-8374-472a9b17c2ff
3f1eae43-5abf-408d-ace9-b415ccfc9544	7188abbd-de97-4647-8eee-9b3fae6f7c92
3f1eae43-5abf-408d-ace9-b415ccfc9544	36bacdd3-9b89-42ae-b440-6691d864a061
ab33754c-6c75-4b4a-b466-30d3753104ed	7188abbd-de97-4647-8eee-9b3fae6f7c92
ab33754c-6c75-4b4a-b466-30d3753104ed	36bacdd3-9b89-42ae-b440-6691d864a061
ab33754c-6c75-4b4a-b466-30d3753104ed	a3465e35-7f70-47f3-8374-472a9b17c2ff
ab33754c-6c75-4b4a-b466-30d3753104ed	a6f1a402-e3b9-4235-8025-0d8ddfc7a2aa
ab33754c-6c75-4b4a-b466-30d3753104ed	e2e30f53-a2d5-4a2d-924e-f4215c28a2d2
ab33754c-6c75-4b4a-b466-30d3753104ed	fd36417c-ff36-4471-b7d6-6297311679e9
3f1eae43-5abf-408d-ace9-b415ccfc9544	a3465e35-7f70-47f3-8374-472a9b17c2ff
3f1eae43-5abf-408d-ace9-b415ccfc9544	a6f1a402-e3b9-4235-8025-0d8ddfc7a2aa
a83a1fc8-0c1c-448a-a0e2-ac7f828557c1	7188abbd-de97-4647-8eee-9b3fae6f7c92
a83a1fc8-0c1c-448a-a0e2-ac7f828557c1	36bacdd3-9b89-42ae-b440-6691d864a061
a83a1fc8-0c1c-448a-a0e2-ac7f828557c1	a3465e35-7f70-47f3-8374-472a9b17c2ff
a83a1fc8-0c1c-448a-a0e2-ac7f828557c1	a6f1a402-e3b9-4235-8025-0d8ddfc7a2aa
a83a1fc8-0c1c-448a-a0e2-ac7f828557c1	e2e30f53-a2d5-4a2d-924e-f4215c28a2d2
0db923ab-ee42-4cd2-91bc-e8a8d897b542	7188abbd-de97-4647-8eee-9b3fae6f7c92
0db923ab-ee42-4cd2-91bc-e8a8d897b542	36bacdd3-9b89-42ae-b440-6691d864a061
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (role_id, name, is_active, description) FROM stdin;
ab33754c-6c75-4b4a-b466-30d3753104ed	Админ	t	Полный доступ ко всем модулям системы
e39392b1-4f2e-4ac8-a1ea-4811fa5e6ed9	Все еще тестовая роль	f	Доступ ко всякому разному
023170ef-7ff6-4bab-96e4-08548dfb8d5d	как то ее назвать	f	\N
3e67d907-8570-4902-939a-0903c632d7a9	Инженер	t	\N
a83a1fc8-0c1c-448a-a0e2-ac7f828557c1	Начальник цеха	t	\N
ce1dcb8c-0ca5-4a10-b0a9-2f8745a134ea	эта роль деактивирована	f	деактивовал для тестов
a22f7db9-19f5-4129-9085-fff5c60c4363	Начальник цеха (копия)	f	\N
6601261e-1952-4078-a225-ef1b5276f143	эта роль деактивирована (копия)	f	деактивовал для тестов
3023d52d-936a-4284-9f13-75fd97542569	1	f	\N
15fc7a36-de24-4a51-aeb6-5cc2fd5ae726	название	f	\N
19402253-261a-4072-932b-8fb9d72abdc5	попытка переименовать	f	\N
8aeb45aa-59c3-4200-a934-19e8ba175ec7	какое то название1	f	\N
5f1bab97-fcf1-4fad-b34d-35f35097b5f1	тест	f	\N
3f1eae43-5abf-408d-ace9-b415ccfc9544	Начальник цеха (копия) 2	f	\N
0db923ab-ee42-4cd2-91bc-e8a8d897b542	Инженер (копия)	t	\N
411c233d-e9d6-45fa-b275-d8ee6f09ccc5	какое то название (копия)	f	\N
7c2a211a-e4fb-4b96-b89e-cbb60c92fcdd	создал через интерфейс (копия)	f	\N
2d45bca5-c273-4610-af33-d06f4df08d50	какое то название	f	\N
\.


--
-- Data for Name: shift_handoffs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shift_handoffs (handoff_id, from_shift_id, to_shift_id, handoff_status, message) FROM stdin;
\.


--
-- Data for Name: shifts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shifts (shift_id, started_at, ended_at, status, department_id, schedule_id, engineer_user_id) FROM stdin;
1f13812a-18de-4a17-afdb-08edd618ddaa	2026-04-13 21:19:48.572+00	2026-04-13 21:46:25.798247+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	56d79006-412e-4a1a-ab42-da5509b64260
4999f1bb-9edd-4f07-ac73-873cf6c42a1f	2026-04-04 15:00:00+00	2026-04-14 09:58:42.26981+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
96554daf-3b3f-4967-844b-0245a2e72f78	2026-03-22 02:00:00+00	2026-04-14 09:58:42.529957+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
d9d1a124-bc0c-474e-b4ce-0d154a5c6819	2026-04-14 10:05:19.757+00	2026-04-14 10:06:21.61494+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	56d79006-412e-4a1a-ab42-da5509b64260
5e2ba4f8-3458-4c18-82ff-e633bb16590d	2026-04-14 10:06:26.927+00	2026-04-14 10:20:48.393534+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	56d79006-412e-4a1a-ab42-da5509b64260
c6c0a51c-2b92-435f-a583-eeeb2b10d099	2026-04-14 10:21:57.301+00	2026-04-14 11:04:23.406619+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	56d79006-412e-4a1a-ab42-da5509b64260
b47468b4-2d88-45fa-9715-f44478477478	2026-04-14 11:04:48.539+00	2026-04-14 11:04:49.026451+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	56d79006-412e-4a1a-ab42-da5509b64260
d7759873-eea6-497d-93ff-7b4c35f57a77	2026-04-14 11:05:00.407+00	2026-04-14 11:05:01.141049+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	56d79006-412e-4a1a-ab42-da5509b64260
fda6c393-c5eb-47a7-b8a9-27f592f15737	2026-04-14 11:05:07.22+00	2026-04-14 11:05:07.703913+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	56d79006-412e-4a1a-ab42-da5509b64260
ac1a659f-5001-405e-a979-e459b9fbe686	2026-04-14 11:05:11.835+00	2026-04-14 11:08:02.947247+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	56d79006-412e-4a1a-ab42-da5509b64260
8cb1d9c2-181f-4f78-ae80-5bc39591bbd9	2020-04-04 15:00:00+00	2026-04-14 11:08:19.268249+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
ad44a91f-534e-497e-bcac-fc7016236f3f	2020-04-04 14:53:00+00	2026-04-14 11:08:19.762212+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
8b862153-ef58-4266-b730-4c3456e677de	2026-04-14 11:08:22.542+00	2026-04-14 11:08:23.051597+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	1025389a-0e27-4e08-b6a0-b188660bea57
2548d4cf-890e-4b35-8a68-027004d34b3e	2026-04-14 11:08:29.406+00	2026-04-14 11:08:29.867467+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	1025389a-0e27-4e08-b6a0-b188660bea57
c8db0baa-e389-473a-aa67-f3cc4926b316	2026-04-14 11:08:39.201+00	2026-04-14 11:09:15.470567+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
b4af5760-975f-41f4-af99-6ccbd600b7f5	2026-04-14 11:09:38.792+00	2026-04-14 11:09:39.281723+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	1025389a-0e27-4e08-b6a0-b188660bea57
8b1de6e1-9f56-4b90-94c7-3a9617bc9351	2026-04-14 11:09:47.522+00	2026-04-14 11:09:48.243396+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
f4ede4ae-fcff-4d8e-9b19-51ad38b9d079	2026-04-14 11:09:55.032+00	2026-04-14 11:12:24.73547+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
91d0a830-86f8-4be0-b549-1b477e948e33	2026-04-14 11:12:31.474+00	2026-04-14 11:12:31.978198+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
17b91502-0916-4a81-b13e-da20b5b0aeff	2026-04-14 11:12:35.345+00	2026-04-14 11:12:35.867111+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	1025389a-0e27-4e08-b6a0-b188660bea57
0db7f968-4c5f-4b92-b019-c18f376a72e5	2026-04-14 11:12:38.777+00	2026-04-14 11:15:33.50682+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
2f7681e2-c99e-4e0b-bec2-f60cc4adf5b6	2026-04-14 11:15:36.83+00	2026-04-14 11:15:37.377132+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
dc725bc7-2b4d-4ef5-ae1e-fde7cc119e11	2026-04-14 11:19:06.744+00	2026-04-14 11:19:07.269933+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
dd2ffd3e-2422-4a9c-85f9-f91251b36769	2026-04-14 11:20:19.392+00	2026-04-14 11:20:19.91599+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	56d79006-412e-4a1a-ab42-da5509b64260
26b314cc-790e-4f7c-9f84-5ec5907e4c9c	2026-04-14 11:20:22.963+00	2026-04-14 11:20:31.559939+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	56d79006-412e-4a1a-ab42-da5509b64260
3cc46193-a8fb-40b9-aecc-7aa2425886f5	2026-04-14 20:50:07.289+00	2026-04-14 20:50:34.385735+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	56d79006-412e-4a1a-ab42-da5509b64260
9f02c8fd-9015-42a6-8284-25302d63bb23	2026-04-14 20:50:39.102+00	2026-04-14 20:51:01.6483+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	56d79006-412e-4a1a-ab42-da5509b64260
9842f7b8-fcee-4046-9271-28bb4157ee40	2026-04-14 20:51:07.678+00	2026-04-15 13:09:42.038664+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	56d79006-412e-4a1a-ab42-da5509b64260
3b153a93-68af-40b3-b5b4-e61475581327	2026-04-14 11:23:06+00	2026-04-21 14:39:03.425513+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
f0cef2f1-7b47-4bce-b915-e1d74c168c01	2026-04-14 11:23:05+00	2026-04-21 14:39:04.406538+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
fd404a98-38dd-48d0-ae0a-287d4f994307	2026-04-14 06:18:05+00	2026-04-21 20:02:07.474713+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
336a8171-14b8-49f9-a3de-9f4228b1dce5	2026-04-22 12:00:53.13+00	2026-04-22 12:00:54.572468+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
0d4b53d4-dd5e-4ddb-a09b-99891a18603b	2026-04-22 12:01:08.597+00	2026-04-22 12:02:30.700567+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
6209939d-6926-4cf5-b280-07d5d7ab334d	2000-01-01 02:05:00+00	2026-04-26 16:33:39.642496+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
24bd9273-1a0b-45f5-a470-6890f2a959b3	2000-01-01 10:30:03+00	2026-04-26 16:35:51.082974+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
ea0c59db-4e4a-4b96-baac-461f7a5582c4	1999-12-31 19:00:02+00	2026-04-26 16:43:15.756854+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	1025389a-0e27-4e08-b6a0-b188660bea57
ac909895-3b11-4615-9aa0-21c75ee44b15	2026-04-26 16:07:04.689+00	2026-04-27 10:19:40.899624+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
1dec5b2d-6696-433b-afaa-9cc3f61ec67e	2026-04-27 17:21:56.358+00	2026-04-27 17:38:38.03063+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
97c94fd5-0690-4e2b-be21-107e649bd528	2026-04-27 22:41:44.853+00	2026-04-28 01:11:16.663192+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	1025389a-0e27-4e08-b6a0-b188660bea57
9bfb866c-12c2-4a48-bb7e-59207fa71bfd	2025-09-01 10:30:00+00	2026-04-28 01:11:17.941586+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
9f1b6f4f-fde9-4485-bd59-85607bc9a7cd	2025-09-01 02:00:00+00	2026-04-28 01:21:31.321529+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
9962b83d-0986-4fa6-a0f2-e1df8b30b977	2026-04-28 10:35:52.265+00	2026-04-28 10:36:23.727087+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
78833f86-8b19-4f90-b7dc-d4410369a515	2026-05-09 22:03:23.215+00	2026-05-09 22:57:35.76749+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	1025389a-0e27-4e08-b6a0-b188660bea57
5d8a9d55-58d4-4058-bf6f-3b4c9c04cf5b	2026-05-10 00:16:51.286+00	2026-05-14 07:18:04.209141+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	1025389a-0e27-4e08-b6a0-b188660bea57
2804abd0-0bae-49a4-a594-33e2d2076a6d	2026-05-14 07:18:17.863+00	2026-05-14 07:19:11.015923+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
3edd269c-f847-4476-a06f-a1d52ebe952a	2026-05-14 07:19:39.36+00	2026-05-14 07:20:12.399092+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
3826ccb4-ddda-4cab-a206-416f16aa7b48	2026-05-19 20:38:13.906+00	2026-05-29 11:49:58.597289+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	1025389a-0e27-4e08-b6a0-b188660bea57
a81129a9-5f70-44c6-8f19-d52d53690e7c	2026-05-29 11:51:24.031+00	2026-05-30 03:38:34.609173+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
1c1e313a-40a1-4452-8ac5-247181658b3b	2026-05-29 11:50:16.573+00	2026-05-30 03:38:35.717554+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	1025389a-0e27-4e08-b6a0-b188660bea57
7fe16c76-feb6-4a96-bfab-7ae29ffd8acb	2026-05-29 11:52:18.798+00	2026-05-30 03:49:54.444135+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	56d79006-412e-4a1a-ab42-da5509b64260
ae6d63ba-903d-4a6d-9aff-a1d1c01c3a7e	2026-05-30 03:51:29.02+00	2026-05-30 04:03:13.95328+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	56d79006-412e-4a1a-ab42-da5509b64260
23abf0e4-4389-4f41-aba3-fb892779f8d9	2026-05-30 04:03:36.863+00	2026-05-30 04:04:45.823644+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	56d79006-412e-4a1a-ab42-da5509b64260
3a3bcff4-6e43-425d-ab5a-845ad4115de6	2026-05-30 04:05:17.268+00	2026-05-30 04:05:19.508258+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	56d79006-412e-4a1a-ab42-da5509b64260
69d4c4dd-e2ab-4544-921a-8ac145316335	2026-05-30 04:05:46.117+00	2026-05-30 04:05:48.247753+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	56d79006-412e-4a1a-ab42-da5509b64260
3c28db80-cfaf-49c9-aedb-306144f7fb78	2026-05-30 04:06:11.538+00	2026-05-30 04:07:34.630336+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	33c5b11e-13c4-4755-bd73-671f34fcea98	56d79006-412e-4a1a-ab42-da5509b64260
0017e062-7ddf-4c90-b116-b1a9c51f986f	2026-05-30 04:07:41.074+00	2026-05-30 04:07:43.398669+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	56d79006-412e-4a1a-ab42-da5509b64260
7eeee52b-2fab-4e3a-b78e-e5c68289c1f3	2026-05-30 04:48:20.31+00	2026-05-30 05:06:54.353968+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	56d79006-412e-4a1a-ab42-da5509b64260
1ba902db-c8ea-42a7-8e95-01877d351c20	2026-05-30 05:07:29.065+00	2026-05-30 05:09:25.590301+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	56d79006-412e-4a1a-ab42-da5509b64260
40f50327-6a4b-4e8c-b5a0-1a057a8c428d	2026-05-30 05:13:58.777+00	2026-05-30 06:03:05.086946+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	56d79006-412e-4a1a-ab42-da5509b64260
96a6f2c9-3a14-445d-bd72-1a032992f764	2026-05-30 09:58:01.158+00	2026-05-30 09:58:35.798746+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	1025389a-0e27-4e08-b6a0-b188660bea57
482d66ca-db68-470b-b719-0476ac45c382	2026-06-05 00:06:23.315+00	2026-06-05 00:07:24.860325+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	56d79006-412e-4a1a-ab42-da5509b64260
f3a2c56b-9a22-49f8-9dc4-b5b97ea0341c	2026-06-05 01:18:02.008+00	2026-06-05 02:20:54.636596+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	96e70ab9-2fd7-4727-ab81-20c3edd34159	56d79006-412e-4a1a-ab42-da5509b64260
b15dd50c-a1ee-4f0d-8301-53d0b4131208	2026-06-05 03:14:48.366+00	2026-06-05 03:14:59.434446+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	56d79006-412e-4a1a-ab42-da5509b64260
e12eb26b-d4ba-4643-b473-9572e5f40914	2026-06-05 05:09:18.328+00	2026-06-05 05:09:50.38893+00	closed	e7648a66-d84e-4e37-bfc5-7d760a6ecdd8	7d94106f-01ca-40ca-b260-3673c0f41c0a	56d79006-412e-4a1a-ab42-da5509b64260
\.


--
-- Data for Name: template_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.template_attributes (template_id, attribute_id, sort_order, is_numbered, display_style, added_at) FROM stdin;
a28e06e4-b250-40f9-ae25-17db1db01534	7b0ebbf2-cf8f-47ac-923b-2bda30dc1eb1	1	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	f28188e3-fdb9-4d41-9a5a-2d3ff2730842	2	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	cb2e05b8-5feb-47b8-933a-868b1e703342	3	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	0efafdb9-d607-4960-97f7-4c93eebe8c54	4	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	05baf163-db0d-4b25-80ba-05b5b80e4c69	5	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	f03b4d94-e4cd-4814-bd63-de7697ac3f75	6	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	0b9672ca-b402-4b76-bd72-1957304940a1	7	f	normal	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	b7e6b576-fc4d-453c-bdab-27dc5452157c	8	f	normal	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	bae050ac-dc2c-4894-9779-a527fc4914af	9	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	c334d16b-aaff-4d34-88ef-61f95cbe7e3a	10	f	normal	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	e4e1de79-6696-4db5-94c6-c6debb80ede4	11	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	7cc0365f-3df4-4389-93f7-6f3907b1d014	12	f	normal	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	8f209177-d1f1-4419-bc20-707ccd166660	13	f	normal	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	55f17e1c-4c8a-4983-8c8c-06e26dac38b4	14	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	80497194-a652-4edc-9fcb-5c90d9e9d88f	15	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	5f3148ed-7aaf-4da2-98a1-4b1025edd7a5	16	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	734cd218-e0cc-4267-8226-8cafa57be5b9	17	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	cf3783f3-556c-4bf6-94ab-968d28be63d4	18	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	c3fe8886-d3f1-4972-9d51-901392b86864	19	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	321d0540-1a62-4508-a5b4-f7bb9f2af4a0	20	t	bold	2026-03-22 20:29:30.552516+00
a28e06e4-b250-40f9-ae25-17db1db01534	0e7cb6e2-86c6-469f-8520-c7d7d5029604	21	t	bold	2026-03-22 20:29:30.552516+00
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (user_id, role_id, assigned_at) FROM stdin;
56d79006-412e-4a1a-ab42-da5509b64260	ab33754c-6c75-4b4a-b466-30d3753104ed	2026-04-09 18:45:08.932786+00
5f3381f0-eda8-407c-a7e2-bc0fb324d9b7	ab33754c-6c75-4b4a-b466-30d3753104ed	2026-04-22 10:21:03.968332+00
1025389a-0e27-4e08-b6a0-b188660bea57	3e67d907-8570-4902-939a-0903c632d7a9	2026-04-26 03:24:20.467927+00
05c2fa4a-5bd9-4ccc-9fa7-76e6fb907ed7	ce1dcb8c-0ca5-4a10-b0a9-2f8745a134ea	2026-04-26 14:41:37.501656+00
531b8d0b-c469-49f1-9f24-597b741b3bf5	a83a1fc8-0c1c-448a-a0e2-ac7f828557c1	2026-04-27 00:08:26.332752+00
d50ee4f5-95b0-48e5-9b8e-a178e94d5726	3e67d907-8570-4902-939a-0903c632d7a9	2026-04-27 19:26:05.76069+00
2ffeea8c-8e42-4e78-86f3-be2c246c336c	e39392b1-4f2e-4ac8-a1ea-4811fa5e6ed9	2026-04-27 19:37:47.967295+00
e171393e-2def-4ab1-9a58-1c68afaf2ac4	ce1dcb8c-0ca5-4a10-b0a9-2f8745a134ea	2026-04-27 20:30:31.252368+00
90a9153e-1f5f-4f8c-a26f-41291c4e145c	ce1dcb8c-0ca5-4a10-b0a9-2f8745a134ea	2026-04-27 20:40:40.965666+00
9b1421a8-95d4-4788-9b10-d69cd18e44e1	e39392b1-4f2e-4ac8-a1ea-4811fa5e6ed9	2026-04-28 07:05:53.198692+00
9585624f-08db-4888-bbef-1cd8da817e83	023170ef-7ff6-4bab-96e4-08548dfb8d5d	2026-04-28 10:35:31.262696+00
090ea126-5c8e-49b8-84da-d399ec3256f2	3023d52d-936a-4284-9f13-75fd97542569	2026-05-13 21:10:51.484053+00
00713118-3702-43b9-b786-1f5326c5bd0f	023170ef-7ff6-4bab-96e4-08548dfb8d5d	2026-05-13 21:17:28.699065+00
057368a9-b0a0-4a58-ab6c-52028bbd86c9	3e67d907-8570-4902-939a-0903c632d7a9	2026-05-13 21:23:33.783818+00
72a358d2-454d-4910-bfbb-fd49af8bae9b	3e67d907-8570-4902-939a-0903c632d7a9	2026-05-15 12:14:51.253356+00
46bd2c34-8e55-41f9-b4d5-f313792dd364	e39392b1-4f2e-4ac8-a1ea-4811fa5e6ed9	2026-05-15 12:15:45.981403+00
c9284809-ba16-4cae-94ab-c2f65a7c8f12	3023d52d-936a-4284-9f13-75fd97542569	2026-05-23 17:38:20.652522+00
7ee6d9fa-b56c-4f7a-9396-b8f829502eab	ab33754c-6c75-4b4a-b466-30d3753104ed	2026-05-23 17:39:53.85827+00
5fd777be-ad62-429b-8536-aab7eee8bc3c	a83a1fc8-0c1c-448a-a0e2-ac7f828557c1	2026-05-30 10:21:49.560592+00
7bd656a4-fc9d-4a48-b66c-78ee74487323	3e67d907-8570-4902-939a-0903c632d7a9	2026-06-05 05:24:29.437306+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, last_name, first_name, middle_name, registered_at, is_active, created_at, updated_at) FROM stdin;
56d79006-412e-4a1a-ab42-da5509b64260	Степанов	Степан	Степанович	2026-04-09 18:36:21.800815+00	t	2026-04-09 18:36:21.800815+00	2026-04-09 18:36:21.800815+00
5fd777be-ad62-429b-8536-aab7eee8bc3c	Иваноы	Иван	Иванович	2026-05-30 10:21:49.43587+00	t	2026-05-30 10:21:49.43587+00	2026-05-30 10:21:49.43587+00
531b8d0b-c469-49f1-9f24-597b741b3bf5	Петров	Юрий	Петрович	2026-04-09 18:34:24.186357+00	t	2026-04-09 18:34:24.186357+00	2026-04-09 18:34:24.186357+00
d50ee4f5-95b0-48e5-9b8e-a178e94d5726	Очередной	Тест	Тестович	2026-04-27 19:26:05.619582+00	t	2026-04-27 19:26:05.619582+00	2026-04-27 19:26:05.619582+00
7bd656a4-fc9d-4a48-b66c-78ee74487323	Андреев	Андрей	Андреевич	2026-06-05 05:24:29.31255+00	t	2026-06-05 05:24:29.31255+00	2026-06-05 05:24:29.31255+00
1025389a-0e27-4e08-b6a0-b188660bea57	Иванов	Иван	Иванович	2026-03-22 22:06:04.594554+00	t	2026-03-22 22:06:04.594554+00	2026-03-22 22:06:04.594554+00
90a9153e-1f5f-4f8c-a26f-41291c4e145c	у меня	подраделение и роль	деактивированы	2026-04-26 14:47:15.544615+00	f	2026-04-26 14:47:15.544615+00	2026-04-26 14:47:15.544615+00
a63b3b95-7582-4703-b1f7-02eab61f2ac6	безроли	безроли	безроли	2026-04-26 13:10:02.723502+00	t	2026-04-26 13:10:02.723502+00	2026-04-26 13:10:02.723502+00
5f3381f0-eda8-407c-a7e2-bc0fb324d9b7	Витальев	Виталий	Витальевич	2026-04-22 10:21:03.968332+00	t	2026-04-22 10:21:03.968332+00	2026-04-22 10:21:03.968332+00
c9284809-ba16-4cae-94ab-c2f65a7c8f12	Кириллов	Кирилл	Кирилович	2026-05-23 17:38:17.033141+00	f	2026-05-23 17:38:17.033141+00	2026-05-23 17:38:17.033141+00
7ee6d9fa-b56c-4f7a-9396-b8f829502eab	Арсенн	Арсений	Арсенович	2026-05-23 17:39:53.712826+00	f	2026-05-23 17:39:53.712826+00	2026-05-23 17:39:53.712826+00
2ffeea8c-8e42-4e78-86f3-be2c246c336c	4	4	4	2026-04-27 19:36:11.331558+00	f	2026-04-27 19:36:11.331558+00	2026-04-27 19:36:11.331558+00
9b1421a8-95d4-4788-9b10-d69cd18e44e1	новый	польщзовалеть	какоето	2026-04-28 07:05:52.884813+00	f	2026-04-28 07:05:52.884813+00	2026-04-28 07:05:52.884813+00
00713118-3702-43b9-b786-1f5326c5bd0f	6	6	6	2026-05-13 21:17:28.580605+00	f	2026-05-13 21:17:28.580605+00	2026-05-13 21:17:28.580605+00
090ea126-5c8e-49b8-84da-d399ec3256f2	5	5	5	2026-05-13 21:10:51.350016+00	f	2026-05-13 21:10:51.350016+00	2026-05-13 21:10:51.350016+00
72a358d2-454d-4910-bfbb-fd49af8bae9b	0	0	0	2026-05-15 12:14:51.130451+00	f	2026-05-15 12:14:51.130451+00	2026-05-15 12:14:51.130451+00
057368a9-b0a0-4a58-ab6c-52028bbd86c9	7	7	7	2026-05-13 21:23:33.664909+00	f	2026-05-13 21:23:33.664909+00	2026-05-13 21:23:33.664909+00
05c2fa4a-5bd9-4ccc-9fa7-76e6fb907ed7	возможно	я	поломан	2026-04-26 14:41:37.145077+00	f	2026-04-26 14:41:37.145077+00	2026-04-26 14:41:37.145077+00
9585624f-08db-4888-bbef-1cd8da817e83	1233	123	123	2026-04-28 10:33:39.918673+00	f	2026-04-28 10:33:39.918673+00	2026-04-28 10:33:39.918673+00
46bd2c34-8e55-41f9-b4d5-f313792dd364	9	9	9	2026-05-15 12:15:45.849918+00	f	2026-05-15 12:15:45.849918+00	2026-05-15 12:15:45.849918+00
e171393e-2def-4ab1-9a58-1c68afaf2ac4	Тестов	Тест	Тестович	2026-04-22 10:21:55.05922+00	f	2026-04-22 10:21:55.05922+00	2026-04-22 10:21:55.05922+00
\.


--
-- Name: attribute_groups attribute_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribute_groups
    ADD CONSTRAINT attribute_groups_pkey PRIMARY KEY (group_id);


--
-- Name: attribute_value_history attribute_value_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribute_value_history
    ADD CONSTRAINT attribute_value_history_pkey PRIMARY KEY (history_id);


--
-- Name: attribute_values attribute_values_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribute_values
    ADD CONSTRAINT attribute_values_pkey PRIMARY KEY (attribute_value_id);


--
-- Name: attribute_values attribute_values_report_id_attribute_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribute_values
    ADD CONSTRAINT attribute_values_report_id_attribute_id_key UNIQUE (report_id, attribute_id);


--
-- Name: attributes attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attributes
    ADD CONSTRAINT attributes_pkey PRIMARY KEY (attribute_id);


--
-- Name: credentials credentials_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_login_key UNIQUE (login);


--
-- Name: credentials credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_pkey PRIMARY KEY (user_id);


--
-- Name: data_types data_types_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.data_types
    ADD CONSTRAINT data_types_name_key UNIQUE (name);


--
-- Name: data_types data_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.data_types
    ADD CONSTRAINT data_types_pkey PRIMARY KEY (data_type_id);


--
-- Name: department_schedules department_schedules_department_id_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_schedules
    ADD CONSTRAINT department_schedules_department_id_name_key UNIQUE (department_id, name);


--
-- Name: department_schedules department_schedules_department_id_sort_order_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_schedules
    ADD CONSTRAINT department_schedules_department_id_sort_order_key UNIQUE (department_id, sort_order);


--
-- Name: department_schedules department_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_schedules
    ADD CONSTRAINT department_schedules_pkey PRIMARY KEY (schedule_id);


--
-- Name: department_templates department_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_templates
    ADD CONSTRAINT department_templates_pkey PRIMARY KEY (department_id, template_id);


--
-- Name: department_users department_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_users
    ADD CONSTRAINT department_users_pkey PRIMARY KEY (department_id, user_id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);


--
-- Name: measurement_units measurement_units_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_units
    ADD CONSTRAINT measurement_units_name_key UNIQUE (name);


--
-- Name: measurement_units measurement_units_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_units
    ADD CONSTRAINT measurement_units_pkey PRIMARY KEY (unit_id);


--
-- Name: measurement_units measurement_units_short_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.measurement_units
    ADD CONSTRAINT measurement_units_short_name_key UNIQUE (short_name);


--
-- Name: modules modules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (module_id);


--
-- Name: report_instances report_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_instances
    ADD CONSTRAINT report_instances_pkey PRIMARY KEY (report_id);


--
-- Name: report_instances report_instances_template_id_shift_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_instances
    ADD CONSTRAINT report_instances_template_id_shift_id_key UNIQUE (template_id, shift_id);


--
-- Name: report_templates report_templates_name_version_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_templates
    ADD CONSTRAINT report_templates_name_version_key UNIQUE (name, version);


--
-- Name: report_templates report_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_templates
    ADD CONSTRAINT report_templates_pkey PRIMARY KEY (template_id);


--
-- Name: role_modules role_modules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_modules
    ADD CONSTRAINT role_modules_pkey PRIMARY KEY (role_id, module_id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- Name: shift_handoffs shift_handoffs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shift_handoffs
    ADD CONSTRAINT shift_handoffs_pkey PRIMARY KEY (handoff_id);


--
-- Name: shifts shifts_department_id_schedule_id_started_at_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shifts
    ADD CONSTRAINT shifts_department_id_schedule_id_started_at_key UNIQUE (department_id, schedule_id, started_at);


--
-- Name: shifts shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shifts
    ADD CONSTRAINT shifts_pkey PRIMARY KEY (shift_id);


--
-- Name: template_attributes template_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.template_attributes
    ADD CONSTRAINT template_attributes_pkey PRIMARY KEY (template_id, attribute_id);


--
-- Name: template_attributes template_attributes_template_id_sort_order_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.template_attributes
    ADD CONSTRAINT template_attributes_template_id_sort_order_key UNIQUE (template_id, sort_order);


--
-- Name: modules uq_modules_slug; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT uq_modules_slug UNIQUE (slug);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: attribute_value_history attribute_value_history_attribute_value_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribute_value_history
    ADD CONSTRAINT attribute_value_history_attribute_value_id_fkey FOREIGN KEY (attribute_value_id) REFERENCES public.attribute_values(attribute_value_id) ON DELETE CASCADE;


--
-- Name: attribute_value_history attribute_value_history_changed_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribute_value_history
    ADD CONSTRAINT attribute_value_history_changed_by_user_id_fkey FOREIGN KEY (changed_by_user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: attribute_values attribute_values_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribute_values
    ADD CONSTRAINT attribute_values_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.attributes(attribute_id);


--
-- Name: attribute_values attribute_values_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attribute_values
    ADD CONSTRAINT attribute_values_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.report_instances(report_id) ON DELETE CASCADE;


--
-- Name: attributes attributes_data_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attributes
    ADD CONSTRAINT attributes_data_type_id_fkey FOREIGN KEY (data_type_id) REFERENCES public.data_types(data_type_id);


--
-- Name: attributes attributes_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attributes
    ADD CONSTRAINT attributes_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.attribute_groups(group_id);


--
-- Name: attributes attributes_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attributes
    ADD CONSTRAINT attributes_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.measurement_units(unit_id);


--
-- Name: credentials credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: department_schedules department_schedules_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_schedules
    ADD CONSTRAINT department_schedules_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id) ON DELETE CASCADE;


--
-- Name: department_templates department_templates_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_templates
    ADD CONSTRAINT department_templates_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id) ON DELETE CASCADE;


--
-- Name: department_templates department_templates_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_templates
    ADD CONSTRAINT department_templates_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.report_templates(template_id) ON DELETE CASCADE;


--
-- Name: department_users department_users_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_users
    ADD CONSTRAINT department_users_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id) ON DELETE CASCADE;


--
-- Name: department_users department_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_users
    ADD CONSTRAINT department_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: departments departments_parent_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_parent_department_id_fkey FOREIGN KEY (parent_department_id) REFERENCES public.departments(department_id) ON DELETE SET NULL;


--
-- Name: report_instances report_instances_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_instances
    ADD CONSTRAINT report_instances_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.shifts(shift_id);


--
-- Name: report_instances report_instances_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_instances
    ADD CONSTRAINT report_instances_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.report_templates(template_id);


--
-- Name: role_modules role_modules_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_modules
    ADD CONSTRAINT role_modules_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.modules(module_id) ON DELETE CASCADE;


--
-- Name: role_modules role_modules_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_modules
    ADD CONSTRAINT role_modules_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE CASCADE;


--
-- Name: shift_handoffs shift_handoffs_from_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shift_handoffs
    ADD CONSTRAINT shift_handoffs_from_shift_id_fkey FOREIGN KEY (from_shift_id) REFERENCES public.shifts(shift_id);


--
-- Name: shift_handoffs shift_handoffs_to_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shift_handoffs
    ADD CONSTRAINT shift_handoffs_to_shift_id_fkey FOREIGN KEY (to_shift_id) REFERENCES public.shifts(shift_id);


--
-- Name: shifts shifts_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shifts
    ADD CONSTRAINT shifts_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- Name: shifts shifts_engineer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shifts
    ADD CONSTRAINT shifts_engineer_user_id_fkey FOREIGN KEY (engineer_user_id) REFERENCES public.users(user_id);


--
-- Name: shifts shifts_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shifts
    ADD CONSTRAINT shifts_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.department_schedules(schedule_id);


--
-- Name: template_attributes template_attributes_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.template_attributes
    ADD CONSTRAINT template_attributes_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.attributes(attribute_id) ON DELETE CASCADE;


--
-- Name: template_attributes template_attributes_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.template_attributes
    ADD CONSTRAINT template_attributes_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.report_templates(template_id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict ScKTEsNYQhgDqHqTLfE6y2HjWotMN5PcW7ceOMz5F0lBHlt7i8wOlevSI6JSok5

