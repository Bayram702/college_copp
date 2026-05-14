--
-- PostgreSQL database dump
--

\restrict ZvsJMQUSwa17xNfP5Io3dbaXBx0YeBiu2IcF5zPYTbNH0UsadmPqtnZd9It5ZET

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

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
-- Name: applications_set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.applications_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


--
-- Name: enforce_applications_constraints(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_applications_constraints() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  application_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO application_count
  FROM applications
  WHERE applicant_id = NEW.applicant_id;

  IF application_count >= 5 THEN
    RAISE EXCEPTION 'Превышен лимит: максимум 5 заявок на одного абитуриента';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM users u
    JOIN roles r ON r.id = u.role_id
    WHERE u.id = NEW.applicant_id
      AND r.name = 'applicant'
  ) THEN
    RAISE EXCEPTION 'Подача заявлений доступна только пользователям с ролью applicant';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM college_specialties cs
    JOIN specialties s ON s.id = cs.specialty_id
    JOIN colleges c ON c.id = cs.college_id
    WHERE cs.college_id = NEW.college_id
      AND cs.specialty_id = NEW.specialty_id
      AND cs.is_active = true
      AND s.status = 'active'
      AND c.status = 'active'
  ) THEN
    RAISE EXCEPTION 'Выбранная специальность не принадлежит колледжу или недоступна';
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id integer NOT NULL,
    entity_name character varying(255),
    user_id integer NOT NULL,
    action character varying(20) NOT NULL,
    changes jsonb,
    previous_state jsonb,
    new_state jsonb,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: cities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cities (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    type character varying(50),
    region character varying(100),
    population integer,
    coordinates character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: cities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cities_id_seq OWNED BY public.cities.id;


--
-- Name: college_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.college_addresses (
    id integer NOT NULL,
    college_id integer NOT NULL,
    name character varying(100) NOT NULL,
    address text NOT NULL,
    phone character varying(50),
    email character varying(255),
    coordinates character varying(100),
    photo_url character varying(255),
    is_main boolean DEFAULT false,
    sort_order integer DEFAULT 0,
    address_type character varying(50) DEFAULT 'educational'::character varying,
    working_hours character varying(100),
    contact_person character varying(255)
);


--
-- Name: college_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.college_addresses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: college_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.college_addresses_id_seq OWNED BY public.college_addresses.id;


--
-- Name: college_specialties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.college_specialties (
    id integer NOT NULL,
    college_id integer NOT NULL,
    specialty_id integer NOT NULL,
    budget_places integer,
    commercial_places integer,
    price_per_year numeric(10,2),
    avg_score numeric(3,2),
    is_active boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    teaching_address character varying(500),
    admission_method character varying(50),
    admission_link character varying(500),
    admission_instructions text
);


--
-- Name: college_specialties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.college_specialties_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: college_specialties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.college_specialties_id_seq OWNED BY public.college_specialties.id;


--
-- Name: colleges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.colleges (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    short_name character varying(100),
    description text,
    status character varying(20) DEFAULT 'active'::character varying,
    city_id integer,
    budget_places integer DEFAULT 0,
    commercial_places integer DEFAULT 0,
    avg_score numeric(3,2),
    min_score numeric(3,2),
    phone character varying(50),
    email character varying(255),
    website character varying(255),
    social_vk character varying(255),
    social_max character varying(255),
    social_other jsonb,
    is_professionalitet boolean DEFAULT false,
    professionalitet_cluster character varying(100),
    logo_image_url character varying(255),
    main_image_url character varying(255),
    opportunities jsonb,
    employers jsonb,
    workshops jsonb,
    professions jsonb,
    ovz_programs jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer,
    updated_by integer,
    admission_method character varying(50),
    admission_link character varying(500),
    admission_instructions text
);


--
-- Name: colleges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.colleges_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: colleges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.colleges_id_seq OWNED BY public.colleges.id;


--
-- Name: login_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login_logs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    login_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ip_address character varying(45),
    user_agent text,
    success boolean NOT NULL,
    failure_reason character varying(255),
    session_id character varying(255)
);


--
-- Name: login_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.login_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: login_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.login_logs_id_seq OWNED BY public.login_logs.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    id integer NOT NULL,
    filename character varying(255) NOT NULL,
    applied_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: schema_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.schema_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schema_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.schema_migrations_id_seq OWNED BY public.schema_migrations.id;


--
-- Name: sectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sectors (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(50),
    description text,
    image_url character varying(255),
    sort_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: sectors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sectors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sectors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sectors_id_seq OWNED BY public.sectors.id;


--
-- Name: site_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_settings (
    id integer NOT NULL,
    setting_key character varying(100) NOT NULL,
    setting_value jsonb NOT NULL,
    setting_type character varying(20) DEFAULT 'string'::character varying,
    description text,
    updated_by integer,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: site_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.site_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: site_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.site_settings_id_seq OWNED BY public.site_settings.id;


--
-- Name: specialties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialties (
    id integer NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    qualification character varying(100),
    duration character varying(50),
    base_education character varying(2) NOT NULL,
    form character varying(20) DEFAULT 'full-time'::character varying,
    budget_places integer DEFAULT 0,
    commercial_places integer DEFAULT 0,
    price_per_year numeric(10,2),
    exams text,
    avg_score_last_year numeric(3,2),
    status character varying(20) DEFAULT 'draft'::character varying,
    is_professionalitet boolean DEFAULT false,
    sort_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: specialties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.specialties_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: specialties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.specialties_id_seq OWNED BY public.specialties.id;


--
-- Name: specialty_sectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialty_sectors (
    specialty_id integer NOT NULL,
    sector_id integer NOT NULL
);


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    id character varying(255) NOT NULL,
    user_id integer NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_activity timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ip_address character varying(45),
    user_agent text,
    is_active boolean DEFAULT true
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    login character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    role_id integer NOT NULL,
    college_id integer,
    status character varying(20) DEFAULT 'active'::character varying,
    last_login_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    phone character varying(50)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: cities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cities ALTER COLUMN id SET DEFAULT nextval('public.cities_id_seq'::regclass);


--
-- Name: college_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.college_addresses ALTER COLUMN id SET DEFAULT nextval('public.college_addresses_id_seq'::regclass);


--
-- Name: college_specialties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.college_specialties ALTER COLUMN id SET DEFAULT nextval('public.college_specialties_id_seq'::regclass);


--
-- Name: colleges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.colleges ALTER COLUMN id SET DEFAULT nextval('public.colleges_id_seq'::regclass);


--
-- Name: login_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_logs ALTER COLUMN id SET DEFAULT nextval('public.login_logs_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: schema_migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations ALTER COLUMN id SET DEFAULT nextval('public.schema_migrations_id_seq'::regclass);


--
-- Name: sectors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sectors ALTER COLUMN id SET DEFAULT nextval('public.sectors_id_seq'::regclass);


--
-- Name: site_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_settings ALTER COLUMN id SET DEFAULT nextval('public.site_settings_id_seq'::regclass);


--
-- Name: specialties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialties ALTER COLUMN id SET DEFAULT nextval('public.specialties_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_logs (id, entity_type, entity_id, entity_name, user_id, action, changes, previous_state, new_state, ip_address, user_agent, created_at) FROM stdin;
65	user	37	admin	3	update	{"role": "college_rep", "status": "active", "college_id": 210}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:17:57.079927
66	user	37	admin	3	update	{"role": "college_rep", "status": "inactive", "college_id": 210}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:18:05.592183
67	user	37	admin	3	update	{"role": "college_rep", "status": "inactive", "college_id": null}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:18:08.816653
72	college	225	E2E College mobile-chrome-1778739837455-5dcf9906fbd0b8	3	create	{"city": "Ufa", "name": "E2E College mobile-chrome-1778739837455-5dcf9906fbd0b8", "email": "college-mobile-chrome-1778739837455-5dcf9906fbd0b8@example.com", "phone": "+7 (347) 200-00-00", "website": "https://example.com", "shortName": "E2E-fbd0b8", "description": "Created by Playwright e2e tests"}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:23:59.519481
73	college	225	E2E College mobile-chrome-1778739837455-5dcf9906fbd0b8 Updated	3	update	{"city": "Sterlitamak", "name": "E2E College mobile-chrome-1778739837455-5dcf9906fbd0b8 Updated", "email": "college-updated-mobile-chrome-1778739837455-5dcf9906fbd0b8@example.com", "phone": "+7 (347) 200-00-01", "status": "active", "website": "https://example.org", "shortName": "E2E-fbd0b8U", "description": "Updated by Playwright e2e tests"}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:23:59.542336
75	user	41	E2E Active College Representative Edited	3	update	{"role": "college_rep", "status": "active", "college_id": 225}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:24:01.021543
79	user	43	E2E Representative Without College Edited	3	update	{"role": "college_rep", "status": "inactive", "college_id": null}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:25:28.772578
80	college	227	E2E College mobile-chrome-1778739924670-88f18898767b	3	create	{"city": "Ufa", "name": "E2E College mobile-chrome-1778739924670-88f18898767b", "email": "college-mobile-chrome-1778739924670-88f18898767b@example.com", "phone": "+7 (347) 200-00-00", "website": "https://example.com", "shortName": "E2E-98767b", "description": "Created by Playwright e2e tests"}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:25:28.799921
81	college	227	E2E College mobile-chrome-1778739924670-88f18898767b Updated	3	update	{"city": "Sterlitamak", "name": "E2E College mobile-chrome-1778739924670-88f18898767b Updated", "email": "college-updated-mobile-chrome-1778739924670-88f18898767b@example.com", "phone": "+7 (347) 200-00-01", "status": "active", "website": "https://example.org", "shortName": "E2E-98767bU", "description": "Updated by Playwright e2e tests"}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:25:28.811078
68	user	38	E2E Representative Without College Edited	3	update	{"role": "college_rep", "status": "inactive", "college_id": null}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:23:59.231219
32	college	19	Уфимский колледж статистики и вычислительной техники	3	create	{"city": "Уфа", "name": "Уфимский колледж статистики и вычислительной техники", "email": "", "phone": "", "website": "", "shortName": "УКСИВТ", "description": ""}	\N	\N	::ffff:127.0.0.1	\N	2026-05-08 01:45:18.730264
33	user	3	Администратор	3	update	{"role": "admin", "status": "active", "college_id": null}	\N	\N	::ffff:127.0.0.1	\N	2026-05-08 12:18:53.759122
70	college	224	E2E College chromium-1778739837428-c22a5dd37da65	3	create	{"city": "Ufa", "name": "E2E College chromium-1778739837428-c22a5dd37da65", "email": "college-chromium-1778739837428-c22a5dd37da65@example.com", "phone": "+7 (347) 200-00-00", "website": "https://example.com", "shortName": "E2E-37da65", "description": "Created by Playwright e2e tests"}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:23:59.299871
71	college	224	E2E College chromium-1778739837428-c22a5dd37da65 Updated	3	update	{"city": "Sterlitamak", "name": "E2E College chromium-1778739837428-c22a5dd37da65 Updated", "email": "college-updated-chromium-1778739837428-c22a5dd37da65@example.com", "phone": "+7 (347) 200-00-01", "status": "active", "website": "https://example.org", "shortName": "E2E-37da65U", "description": "Updated by Playwright e2e tests"}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:23:59.325804
74	user	40	E2E Active College Representative Edited	3	update	{"role": "college_rep", "status": "active", "college_id": 224}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:24:00.743737
83	user	45	E2E Active College Representative Edited	3	update	{"role": "college_rep", "status": "active", "college_id": 227}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:25:32.568798
69	user	39	E2E Representative Without College Edited	3	update	{"role": "college_rep", "status": "inactive", "college_id": null}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:23:59.232708
76	user	42	E2E Representative Without College Edited	3	update	{"role": "college_rep", "status": "inactive", "college_id": null}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:25:27.957571
77	college	226	E2E College chromium-1778739924671-0b2a481bc9fb88	3	create	{"city": "Ufa", "name": "E2E College chromium-1778739924671-0b2a481bc9fb88", "email": "college-chromium-1778739924671-0b2a481bc9fb88@example.com", "phone": "+7 (347) 200-00-00", "website": "https://example.com", "shortName": "E2E-c9fb88", "description": "Created by Playwright e2e tests"}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:25:27.982179
58	user	37	admin	3	update	{"role": "college_rep", "status": "inactive", "college_id": null}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:11:49.956175
59	user	37	admin	3	update	{"role": "college_rep", "status": "inactive", "college_id": null}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:15:19.355764
60	user	37	admin	3	update	{"role": "college_rep", "status": "inactive", "college_id": null}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:15:27.496263
61	user	37	admin	3	update	{"role": "college_rep", "status": "inactive", "college_id": null}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:15:48.204936
62	user	37	admin	3	update	{"role": "college_rep", "status": "inactive", "college_id": null}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:15:51.214374
63	user	37	admin	3	update	{"role": "college_rep", "status": "inactive", "college_id": 210}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:15:54.535707
64	user	37	admin	3	update	{"role": "college_rep", "status": "inactive", "college_id": null}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:15:57.916183
78	college	226	E2E College chromium-1778739924671-0b2a481bc9fb88 Updated	3	update	{"city": "Sterlitamak", "name": "E2E College chromium-1778739924671-0b2a481bc9fb88 Updated", "email": "college-updated-chromium-1778739924671-0b2a481bc9fb88@example.com", "phone": "+7 (347) 200-00-01", "status": "active", "website": "https://example.org", "shortName": "E2E-c9fb88U", "description": "Updated by Playwright e2e tests"}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:25:27.99392
82	user	44	E2E Active College Representative Edited	3	update	{"role": "college_rep", "status": "active", "college_id": 226}	\N	\N	::ffff:127.0.0.1	\N	2026-05-14 11:25:31.256335
\.


--
-- Data for Name: cities; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cities (id, name, type, region, population, coordinates, created_at) FROM stdin;
1	Уфа	город	Республика Башкортостан	\N	\N	2026-04-10 01:03:20.082257
2	Стерлитамак	город	Республика Башкортостан	\N	\N	2026-04-10 01:03:20.082257
3	Салават	город	Республика Башкортостан	\N	\N	2026-04-10 01:03:20.082257
4	Нефтекамск	город	Республика Башкортостан	\N	\N	2026-04-10 01:03:20.082257
5	Октябрьский	город	Республика Башкортостан	\N	\N	2026-04-10 01:03:20.082257
6	Ufa	\N	Республика Башкортостан	\N	\N	2026-05-06 01:48:54.134463
7	Sterlitamak	\N	Республика Башкортостан	\N	\N	2026-05-06 01:56:55.418557
\.


--
-- Data for Name: college_addresses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.college_addresses (id, college_id, name, address, phone, email, coordinates, photo_url, is_main, sort_order, address_type, working_hours, contact_person) FROM stdin;
23	226	Main campus edited	Ufa, Test street, 2	+7 (347) 200-00-04	address-edited-chromium-1778739924671-0b2a481bc9fb88@example.com	54.7352,55.9588	\N	t	0	educational	10:00-17:00	E2E Contact Edited
24	227	Main campus edited	Ufa, Test street, 2	+7 (347) 200-00-04	address-edited-mobile-chrome-1778739924670-88f18898767b@example.com	54.7352,55.9588	\N	t	0	educational	10:00-17:00	E2E Contact Edited
21	224	Main campus edited	Ufa, Test street, 2	+7 (347) 200-00-04	address-edited-chromium-1778739837428-c22a5dd37da65@example.com	54.7352,55.9588	\N	t	0	educational	10:00-17:00	E2E Contact Edited
22	225	Main campus edited	Ufa, Test street, 2	+7 (347) 200-00-04	address-edited-mobile-chrome-1778739837455-5dcf9906fbd0b8@example.com	54.7352,55.9588	\N	t	0	educational	10:00-17:00	E2E Contact Edited
\.


--
-- Data for Name: college_specialties; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.college_specialties (id, college_id, specialty_id, budget_places, commercial_places, price_per_year, avg_score, is_active, sort_order, created_at, updated_at, teaching_address, admission_method, admission_link, admission_instructions) FROM stdin;
44	224	26	12	8	55000.00	4.40	f	0	2026-05-14 11:24:00.903386	2026-05-14 11:24:00.965718	г. Уфа, ул. Тестовая, 12	platform	https://example.com/apply	Заполните форму на платформе
45	225	26	12	8	55000.00	4.40	f	0	2026-05-14 11:24:01.803647	2026-05-14 11:24:01.83629	г. Уфа, ул. Тестовая, 12	platform	https://example.com/apply	Заполните форму на платформе
46	226	26	12	8	55000.00	4.40	f	0	2026-05-14 11:25:31.396015	2026-05-14 11:25:31.439671	г. Уфа, ул. Тестовая, 12	platform	https://example.com/apply	Заполните форму на платформе
47	227	26	12	8	55000.00	4.40	f	0	2026-05-14 11:25:32.725568	2026-05-14 11:25:32.761154	г. Уфа, ул. Тестовая, 12	platform	https://example.com/apply	Заполните форму на платформе
\.


--
-- Data for Name: colleges; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.colleges (id, name, short_name, description, status, city_id, budget_places, commercial_places, avg_score, min_score, phone, email, website, social_vk, social_max, social_other, is_professionalitet, professionalitet_cluster, logo_image_url, main_image_url, opportunities, employers, workshops, professions, ovz_programs, created_at, updated_at, created_by, updated_by, admission_method, admission_link, admission_instructions) FROM stdin;

179	ГБПОУ Уфимский автотранспортный колледж	УАК		active	\N	0	0	0.00	0.00	8 (347) 223-93-49	uatk02@yandex.ru	https://uatk.ru/	https://vk.com/uatk_official	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://uatk.ru/abitur/	\N
154	ГБПОУ Месягутовский педагогический колледж	МПК		active	\N	0	0	0.00	0.00	8 (347) 983-33-07	mespedkol@yandex.ru	http://mespedkol.ru/	https://vk.com/mespedkol_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://mespedkol.ru/abiturentu.html	\N
130	ГБПОУ Башкирский колледж сварочно-монтажного и промышленного производства	БКСМиПП		active	\N	0	0	0.00	0.00	8 (347) 260-00-17	pu-13@bk.ru	https://bksmpp.ru/	https://vk.com/bksm_i_pp	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://bksmpp.ru/priyomnaya-komissiya/	\N
131	ГБПОУ Башкирский сельскохозяйственный профессиональный колледж	БСХПК		active	\N	0	0	0.00	0.00	8 (347) 712-09-35	pu96@rambler.ru	http://bashpk.ru/	https://vk.com/bashpk	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://bashpk.ru/category/abiturientam/	\N
132	ГБПОУ Башкирский колледж архитектуры, строительства и коммунального хозяйства	БАСК		active	\N	0	0	0.00	0.00	8 (347) 284-56-22	Bask-ufa@yandex.ru	http://bask-rb.ru/	https://vk.com/bask.college	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://bask-rb.ru/%d0%b0%d0%b1%d0%b8%d1%82%d1%83%d1%80%d0%b8%d0%b5%d0%bd%d1%82%d0%b0%d0%bc	\N
133	ГАПОУ Башкирский северо-западный сельскохозяйственный колледж	БССК		active	\N	0	0	0.00	0.00	8 (347) 532-11-42	npo111morb@yandex.ru	https://bssk.profiedu.ru/	https://vk.com/public216843539	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://bssk.profiedu.ru/?section_id=8	\N
134	ГБПОУ Бирский многопрофильный профессиональный колледж	БМПК		active	\N	0	0	0.00	0.00	8 (347) 843-66-00	pl31_birsk@ufamts.ru	http://birskpl31.ucoz.ru/	https://vk.com/club194351704	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://birskpl31.ucoz.ru/index/abiturientu/0-65	\N
135	ГБПОУ Благовещенский многопрофильный профессиональный колледж	БМПК		active	\N	0	0	0.00	0.00	8 (347) 662-32-89	BPGTnew@yandex.ru	https://bpgt-edu.ucoz.ru/	https://vk.com/bmpk_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://bpgt-edu.ucoz.ru/index/abiturientam_2021_goda/0-31	\N
136	ГБПОУ Белебеевский гуманитарно-технический колледж	БГТК		active	\N	0	0	0.00	0.00	8 (347) 863-08-22	gou_bmst@rambler.ru	http://www.fgoubmst.ru/	https://vk.com/belgtk	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://www.fgoubmst.ru/abitur	\N
137	ГБПОУ Белебеевский колледж механизации и электрификации	БКМЭ		active	\N	0	0	0.00	0.00	8 (347) 865-34-39	bel_sel_tex@mail.ru	https://belkome.ru/	https://vk.com/club142949910	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://belkome.ru/abiturientu/pravila-priema/	\N
138	ГБПОУ Белорецкий металлургический колледж	БМК		active	\N	0	0	0.00	0.00	8 (347) 925-95-29	metallcolledge1933@yandex.ru	https://belcol.wixsite.com/belcol	https://vk.com/belcol_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://xn----9sbkcabimjidgga1bg1a3i.xn--p1ai/abiturientam/priemnaya-kompaniya/	\N
139	ГБПОУ Белорецкий многопрофильный профессиональный колледж	БПК		active	\N	0	0	0.00	0.00	8 (347) 923-32-76	bpk1932@mail.ru	https://bpcollege.ru	https://vk.com/beloreck_bpk	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://bpcollege.ru/abitur/	\N
140	ГБПОУ Буздякский сельскохозяйственный колледж	БСК		active	\N	0	0	0.00	0.00	8 (347) 474-01-37	goynpopy94@yandex.ru	http://goynpopy94.ucoz.ru/	https://vk.com/filaial_buzdyak_shk	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	Срок действия тарифа сайта истёк	\N
141	ГБПОУ Дуванский многопрофильный колледж	ДМК		active	\N	0	0	0.00	0.00	8 (347) 982-35-12	duv01@mail.ru	https://dat-duvan.ru/	https://vk.com/dmk_duvan	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://dat-duvan.ru/abitur/	\N
142	ГБПОУ Дюртюлинский многопрофильный колледж	ДМК		active	\N	0	0	0.00	0.00	8 (347) 873-71-44	ptu157@mail.ru	https://gbpoudmk.ru/	https://vk.com/gbpoudmk	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://gbpoudmk.ru/%d0%bf%d1%80%d0%b8%d0%b5%d0%bc%d0%bd%d0%b0%d1%8f-%d0%ba%d0%be%d0%bc%d0%b8%d1%81%d1%81%d0%b8%d1%8f/	\N
143	ГБПОУ Зауральский агропромышленный колледж	ЗАПК		active	\N	0	0	0.00	0.00	8 (347) 512-22-18	bsxk@bk.ru	http://zapkollege.ru/	https://vk.com/club128342188	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://zapkollege.ru/priemka	\N
144	ГБПОУ Зауральский колледж агроинженерии	ЗКА		active	\N	0	0	0.00	0.00	8 (347) 522-73-46	pl80.00@mail.ru	https://zkagro.ru/	https://vk.com/public187907853	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://zkagro.ru/reception-commission	\N
145	ГАПОУ Зианчуринский агропромышленный колледж	ЗАК		active	\N	0	0	0.00	0.00	8 (347) 852-71-45	pl116@yandex.ru	http://pl116.ru/	https://vk.com/gapoy_zak	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://pl116.ru/education/4797/	\N
146	ГАПОУ Ишимбайский нефтяной колледж	ИНК		active	\N	0	0	0.00	0.00	8 (347) 943-24-72	sekr@ishnk.ru	http://www.ishnk.ru/	https://vk.com/ishnkru	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://www.ishnk.ru/menu/1/2	\N
147	ГБПОУ Ишимбайский профессиональный колледж	ИПК		active	\N	0	0	0.00	0.00	8 (347) 944-07-51	ipk-ishimbai@mail.ru	https://ipk-ishimbai.ucoz.net/	https://vk.com/club122001386	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://ipk-ishimbai.ucoz.net/index/abiturientu/0-105	\N
148	ГБПОУ Кумертауский педагогический колледж	КПК		active	\N	0	0	0.00	0.00	8 (347) 614-40-60	kumpedcoll@mail.ru	http://kpkrb.ru/index.php/ru/	https://vk.com/kumertau_kpk_professionalitet	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://kpkrb.ru/index.php/ru/abiturientu-2022	\N
149	ГАПОУ Кумертауский горный колледж	КГК		active	\N	0	0	0.00	0.00	8 (347) 614-31-31	secr-kgk@mail.ru	https://kumgk.ru/	https://vk.com/kumgornycollege_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://kumgk.ru/abiturientam/prijomnaya-komissiya	\N
150	ГБПОУ Кушнаренковский многопрофильный профессиональный колледж	КМПК		active	\N	0	0	0.00	0.00	8 (347) 805-73-00	info-kmpk@yandex.ru	http://xn----gtbdvaletlkdi.xn--p1ai/	https://vk.com/public194358954	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://xn----gtbdvaletlkdi.xn--p1ai/index/prijomnaja_komissija/0-29	\N
151	ГБПОУ Кушнаренковский сельскохозяйственный колледж	КСК		active	\N	0	0	0.00	0.00	8 (347) 805-94-64	kushteh@yandex.ru	http://kushkolledg.ru/	https://vk.com/club163118827	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://sites.google.com/view/priem2022	\N
152	ГБПОУ Мелеузовский индустриальный колледж	МИК		active	\N	0	0	0.00	0.00	8 (347) 645-25-19	pl42@bk.ru	https://mic.siteedu.ru/	https://vk.com/public121956295	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://mic.siteedu.ru/abitur/#megamenu	\N
153	ГБПОУ Мелеузовский многопрофильный профессиональный колледж	ММПК		active	\N	0	0	0.00	0.00	8 (347) 645-33-90	mmtt2@yandex.ru	https://mmpkmlz.ru/	https://vk.com/mmpkmlz	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://mmpkmlz.ru/abiturientu	\N
125	ГБПОУ Аксеновский агропромышленный колледж	ААПК		active	\N	0	0	0.00	0.00	8 (347) 543-60-47	acxt@mail.ru	https://acxt.ru/	https://vk.com/aapk_acxt?ysclid=m6hib3zca2607959828	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://acxt.ru/%d0%b0%d0%b1%d0%b8%d1%82%d1%83%d1%80%d0%b8%d0%b5%d0%bd%d1%82%d1%83/	\N
126	ГБПОУ Акъярский горный колледж имени И.Тасимова	АГК		active	\N	0	0	0.00	0.00	8 (347) 582-14-44	agk.02@mail.ru	https://agk102.ru/	https://vk.com/agk102_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://agk102.ru/%d0%bf%d1%80%d0%b8%d0%b5%d0%bc%d0%bd%d0%b0%d1%8f-%d0%ba%d0%be%d0%bc%d0%b8%d1%81%d1%81%d0%b8%d1%8f-2024-2025-%d1%83%d1%87%d0%b5%d0%b1%d0%bd%d1%8b%d0%b8-%d0%b3%d0%be%d0%b4/	\N
127	ГБПОУ Аургазинский многопрофильный колледж	АМК		active	\N	0	0	0.00	0.00	8 (347) 218-03-15	\N	https://aurgazy-college.ru/	https://vk.com/gbpoy_amk	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://aurgazy-college.ru/abitur	\N
128	ГБПОУ Башкирский аграрно-технологический колледж	БАТК		active	\N	0	0	0.00	0.00	8 (347) 625-15-33	pl-086@mail.ru	http://pl86.ucoz.ru/	https://vk.com/club163036230	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://pl86.ucoz.ru/index/priemnaja_komissija/0-140	\N
129	ГАПОУ Башкирский агропромышленный колледж	БАК		active	\N	0	0	0.00	0.00	8 (347) 200-93-65	pu_83@mail.ru	http://xn--80aabkffi3aja4abx3i.xn--p1ai/	https://vk.com/public175226349	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://xn--80aabkffi3aja4abx3i.xn--p1ai/index.php?cat=5	\N
155	ГБПОУ Мишкинский агропромышленный колледж	МАК		active	\N	0	0	0.00	0.00	8 (347) 492-45-81	pu_150@mail.ru Р	https://prof-licei150.ucoz.ru/	https://vk.com/gbpoumak	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://prof-licei150.ucoz.ru/forum/	\N
156	ГБПОУ Нефтекамский машиностроительный колледж	НМК		active	\N	0	0	0.00	0.00	8 (347) 835-00-76	post@nmknf.ru	https://nmknf.ru/	https://vk.com/nmk_nsk	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://nmknf.ru/index.php?option=com_content&view=article&id=11&Itemid=135	\N
157	ГАПОУ Нефтекамский нефтяной колледж	ННК		active	\N	0	0	0.00	0.00	8 (347) 834-49-72	nnkfree@yandex.ru	https://www.nnkinfo.ru/	https://vk.com/nnkneft	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://www.nnkinfo.ru/abitur/glavpriem.php	\N
158	ГБПОУ Нефтекамский многопрофильный колледж	НМПК		active	\N	0	0	0.00	0.00	8 (347) 835-36-18	pl27@ufamts.ru	https://www.xn--j1adcj.xn--p1ai/	https://vk.com/nmpkneft	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://www.xn--j1adcj.xn--p1ai/magicpage.html?page=228453	\N
159	ГБПОУ Нефтекамский педагогический колледж	НПК		active	\N	0	0	0.00	0.00	8 (347) 832-04-42	npkneftekamsk@yandex.ru	https://neftekamsk-npk.ru/	https://vk.com/neftekamsknpk_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://neftekamsk-npk.ru/professionalitet/priyomnaya-kompanya	\N
160	ГБПОУ Октябрьский коммунально-строительный колледж	ОКСК		active	\N	0	0	0.00	0.00	8 (347) 674-04-16	okst44@mail.ru	https://okt-okst.edusite.ru/	https://vk.com/oksk_rb	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://okt-okst.edusite.ru/magicpage.html?page=67026	\N
161	ГБПОУ Октябрьский многопрофильный профессиональный колледж	ОМПК		active	\N	0	0	0.00	0.00	8 (347) 273–39–24	py22rbok@mail.ru	https://oktmpk.ru/	https://vk.com/onk_rb	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://oktmpk.ru/	\N
162	ГБПОУ Октябрьский нефтяной колледж им. С.И.Кувыкина	ОНК		active	\N	0	0	0.00	0.00	8 (347) 674-05-87	onk@onk-rb.ru	https://www.onk-rb.ru/	https://vk.com/onk_rb	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://onk-rb.ru/index.php?cnt=rcomiss	\N
163	ГБПОУ Салаватский индустриальный колледж	СИК		active	\N	0	0	0.00	0.00	8 (3476) 35-23-34	fgousposic@mail.ru	https://salinc.ru/	https://vk.com/salinc_ru	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://salinc.ru/%d0%bf%d0%be%d1%81%d1%82%d1%83%d0%bf%d0%bb%d0%b5%d0%bd%d0%b8%d0%b5/	\N
164	ГАПОУ Салаватский колледж образования и профессиональных технологий	СКОиПТ		active	\N	0	0	0.00	0.00	8 (347) 634-28-49	salpedkol@mail.ru	https://www.skoipt.ru/ru/	https://vk.com/skoipt_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://www.skoipt.ru/ru/priemnaya-komissiya	\N
165	ГБПОУ Сибайский колледж строительства и сервиса	СКСС		active	\N	0	0	0.00	0.00	8(347) 755-90-30	skss-sibay@mail.ru	https://xn--j1anba.xn--p1ai/	https://vk.com/skss_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://xn--j1anba.xn--p1ai/index.php/admission/full-time-study	\N
166	ГБПОУ Сибайский многопрофильный профессиональный колледж	СМПК		active	\N	0	0	0.00	0.00	8 (347) 752-42-57	SibaiPolitech@bk.ru	https://sibaipolitech.ucoz.ru/	https://vk.com/sibaismpk_professionalitet	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://sibaipolitech.ucoz.ru/index/priemnaja_komissija/0-282	\N
167	ГБПОУ Сибайский педагогический колледж	СПК		active	\N	0	0	0.00	0.00	8 (347) 755-94-19	sibay.ped.col@yandex.ru	https://sibped.ru/	https://vk.com/sibpedcollege_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://sibped.ru/abitur	\N
168	ГАПОУ Стерлитамакский колледж строительства и профессиональных технологий	СКСиПТ		active	\N	0	0	0.00	0.00	8 (3473) 43-97-27	kolstrbux@mail.ru	https://ckstr.ru/	https://vk.com/ckstr	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://ckstr.ru/?page_id=61	\N
169	ГАПОУ Стерлитамакский колледж физической культуры, управления и сервиса	СКФКУиС		active	\N	0	0	0.00	0.00	8 (347) 321-92-00	fiz_tech@mail.ru	https://stfk-rb.ru/	https://vk.com/public216591191	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://stfk-rb.ru/abitur/	\N
170	ГБПОУ Стерлитамакский межотраслевой колледж	СМК		active	\N	0	0	0.00	0.00	8 (347) 327-43-58	spo2032@mail.ru	http://cmk.su/	https://vk.com/gbpou_cmk	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://cmk.su/%d0%b0%d0%b1%d0%b8%d1%82%d1%83%d1%80%d0%b8%d0%b5%d0%bd%d1%82%d0%b0%d0%bc/	\N
171	ГАПОУ Стерлитамакский многопрофильный профессиональный колледж	СМПК		active	\N	0	0	0.00	0.00	8 (347) 343-64-84	spc-s@mail.ru	https://www.mirsmpc.ru/	https://vk.com/mirsmpc_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://mirsmpc.ru/index.php/abiturientu/informatsiya-po-prijomnoj-kampanii	\N
172	ГБПОУ Стерлитамакский политехнический колледж	СПК		active	\N	0	0	0.00	0.00	8 (347) 330-30-05	ssst-b@mail.ru	https://str-spc.ru/	https://vk.com/politeh_professionalitet?ysclid=m6hk4446c4471742784	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://str-spc.ru/abiturientu	\N
173	ГБПОУ Стерлитамакский профессионально-технический колледж	СПТК		active	\N	0	0	0.00	0.00	8 (347) 324-16-52	pu18sterlitamak@rambler.ru	http://gbpousptk.ru/	https://vk.com/cptk_str	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://gbpousptk.ru/?section_id=66	\N
174	ГБПОУ Стерлитамакский химико-технологический колледж	СХТК		active	\N	0	0	0.00	0.00	8(347)330-50-12	sxtt02@bk.ru	https://sxtk.ru/4857/	https://vk.com/sxtk_gbpou_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://sxtk.ru/4747/	\N
175	ГБПОУ Туймазинский агропромышленный колледж	ТАК		active	\N	0	0	0.00	0.00	8 (347) 824-41-88	goupu43@mail.ru	https://agrocollege.nubex.ru/	https://vk.com/pub91173	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://agrocollege.nubex.ru/abityr/	\N
176	ГАПОУ Туймазинский государственный юридический колледж	ТГЮК		active	\N	0	0	0.00	0.00	8 (347) 218-03-15	tguk@rambler.ru	тгюк.рф	https://vk.com/gapoutguk	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://xn--c1aow3c.xn--p1ai/%d0%b3%d0%bb%d0%b0%d0%b2%d0%bd%d0%b0%d1%8f/%d0%b0%d0%b1%d0%b8%d1%82%d1%83%d1%80%d0%b8%d0%b5%d0%bd%d1%82%d1%83/	\N
177	ГАПОУ Туймазинский индустриальный колледж	ТИК		active	\N	0	0	0.00	0.00	8 (347) 825-80-52	tit-rb@mail.ru	http://tit-rb.ru/	https://vk.com/titrb	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://tit-rb.ru/abiturientu/	\N
178	ГБПОУ Туймазинский педагогический колледж	ТПК		active	\N	0	0	0.00	0.00	8 (347) 827-16-97	tpedkolledg@mail.ru	https://xn----7sbndgchafejdnaftw2cmu.xn--p1ai/	https://vk.com/tpedkolledg_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://xn----7sbndgchafejdnaftw2cmu.xn--p1ai/about/admission/	\N
180	ГБПОУ Уфимский государственный колледж технологии и дизайна	УГКТиД		active	\N	0	0	0.00	0.00	8 (347) 252-97-46	ugktid@bk.ru	http://ugktid.ru/	https://vk.com/ugktid_professionalitet?ysclid=m6hklhy529518330880	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://ugktid.ru/abiturientu.html	\N
181	ГБПОУ Уфимский колледж отраслевых технологий	УКОТ		active	\N	0	0	0.00	0.00	8 (347) 237-08-80	umtk@ufanet.ru	https://укот.рф/?ysclid=m6hksqfpov299846806	https://vk.com/ucot_umtk	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://xn--j1aimb.xn--p1ai/index.php/abiturientu/priemnaya-komissiya-2024-2025-uchebnyj-god	\N
182	ГАПОУ Уфимский колледж предпринимательства, экологии и дизайна	УКПЭД		active	\N	0	0	0.00	0.00	8 (347) 228-52-10	ucped@yandex.ru	https://ucped.ru/	https://vk.com/public154792423	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://ucped.ru/%d0%b0%d0%b1%d0%b8%d1%82%d1%83%d1%80%d0%b8%d0%b5%d0%bd%d1%82%d0%b0%d0%bc/	\N
183	ГБПОУ Уфимский колледж радиоэлектроники, телекоммуникаций и безопасности	УКРТБ		active	\N	0	0	0.00	0.00	\N	info@ukrtb.ru	https://ukrtb.ru/	https://vk.com/club1929026	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://ukrtb.ru/entrant	\N
184	ГАПОУ Уфимский колледж статистики, информатики и вычислительной техники	УКСИВТ		active	\N	0	0	0.00	0.00	8 (347) 286-00-06	uksivt@uksivt.ru	https://www.uksivt.ru/	https://vk.com/uksivt_gbpou	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://www.uksivt.ru/postupayushchim	\N
185	ГБПОУ Уфимский машиностроительный колледж	УМК		active	\N	0	0	0.00	0.00	8 (347) 263-5225	pu-2@mail.ru	https://umkufa.ru/	https://vk.com/umkcollege	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://umkufa.ru/abitur/spo/	\N
186	ГБПОУ Уфимский многопрофильный профессиональный колледж	УМПК		active	\N	0	0	0.00	0.00	8 (347) 262-91-90	pedkolledj-1@yandex.ru	https://ufampk.ru/	https://vk.com/umpk_professionalitet?ysclid=m6hl4nt9ql448692897	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://ufampk.ru/page6	\N
187	ГБПОУ Уфимский профессиональный колледж имени Героя Советского Союза Султана Бикеева	УПК		active	\N	0	0	0.00	0.00	8 (347) 246-18-11	pl1ufa@mail.ru	https://upkisb.ru/	https://vk.com/upkisb?ysclid=m6hl72fonf743308365	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://upkisb.ru/abiturientam.html	\N
188	ГАПОУ Уфимский топливно-энергетический колледж	УТЭК		active	\N	0	0	0.00	0.00	8 (917) 450-14-75	uecoll_rb@mail.ru	https://uecoll.ru/	https://vk.com/uecoll	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://uecoll.ru/?page_id=17	\N
189	ГБПОУ Уфимский торгово-экономический колледж	УТЭК		active	\N	0	0	0.00	0.00	8 (347) 228-83-18	utec@mail.ru	https://utecrb.ru/	https://vk.com/torgovyi_college_utec	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://uecoll.ru/?page_id=17	\N
190	ГБПОУ Уфимский художественно-промышленный колледж	УХПК		active	\N	0	0	0.00	0.00	8 347 284-98-58	proflic64@rambler.ru	https://uhpk.ru/	https://vk.com/uhpk_rb	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://uhpk.ru/abitur/	\N
191	ГАПОУ Учалинский колледж горной промышленности	УКГБ		active	\N	0	0	0.00	0.00	8 (347) 916-25-00	ugmt@mail.ru	https://xn--c1anqn.xn--p1ai/	https://vk.com/ukgp_uchaly	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://xn--c1anqn.xn--p1ai/index.php?id=306	\N
192	ГАПОУ РБ Уфимский медицинский колледж	УМК		active	\N	0	0	0.00	0.00	8 (347) 223-07-42	ufa.umk@doctorrb.ru	http://umkufa.bashmed.ru/	https://vk.com/club131180816	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://umkufa.bashmed.ru/abiturient/	\N
193	ГАПОУ РБ Белебеевский медицинский колледж	БМК		active	\N	0	0	0.00	0.00	8 (347) 863-40-57\r\n8 (347) 863-23-68	belebey.mk@doctorrb.ru	http://www.belmedkol.bashmed.ru/	https://vk.com/belmedcolleg	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://www.belmedkol.bashmed.ru/abiturient/	\N
194	ГАПОУ РБ Белорецкий медицинский колледж	БМК		active	\N	0	0	0.00	0.00	8 (347) 923-12-65	beloreck.mk@doctorrb.ru	https://www.belormedkol.ru/	https://vk.com/belormedkol	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://www.belormedkol.ru/%D0%B0%D0%B1%D0%B8%D1%82%D1%83%D1%80%D0%B8%D0%B5%D0%BD%D1%82%D1%83	\N
195	ГАПОУ РБ Бирский медико-фармацевтический колледж	БМФК		active	\N	0	0	0.00	0.00	8 (347) 844-00-41	birsk.mk@doctorrb.ru	http://bmfk-birsk.ru/	https://vk.com/bmfk_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://bmfk-birsk.ru/abiturient/	\N
196	ГАПОУ РБ Салаватский медицинский колледж	СМК		active	\N	0	0	0.00	0.00	8 (347) 638-78-83	slv.mk@doctorrb.ru	http://salavatmk.ru/	https://vk.com/slv_mk	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://salavatmk.ru/abiturient/	\N
197	ГАПОУ РБ Сибайский медицинский колледж	СМК		active	\N	0	0	0.00	0.00	8(347) 752-74-74, 8(347) 752-74-71	sibaymed@mail.ru	http://www.sibaymed.ru/	https://vk.com/club216368051	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://www.sibaymed.ru/index/priem_abiturientov/0-106	\N
198	ГАПОУ РБ Стерлитамакский медицинский колледж	СМК		active	\N	0	0	0.00	0.00	8 (347) 330-93-39	str.med@doctorrb.ru	https://ster-mk.ru/	https://vk.com/club175144139	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://ster-mk.ru/abiturient/	\N
199	ГАПОУ РБ Туймазинский медицинский колледж	ТМК		active	\N	0	0	0.00	0.00	8 (347) 827-10-44	tuymazy.mk@doctorrb.ru	https://tmk-rb.ucoz.ru/	https://vk.com/officialtmk_professionalitet	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://tmk-rb.ucoz.ru/index/abiturientu/0-54	\N
200	ГБПОУ РБ Башкирский республиканский колледж культуры и искусства	БРККиИ		active	\N	0	0	0.00	0.00	8 (347) 333-93-53	sttkultura@mail.ru	https://xn--90asri.xn--p1ai/	https://vk.com/brkkii_str	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://xn--90asri.xn--p1ai/abitur/#megamenu	\N
201	ГБПОУ РБ Башкирский хореографический колледж имени Рудольфа Нуреева	БХК		active	\N	0	0	0.00	0.00	8 (347) 251-19-88	bhu2006@yandex.ru	https://nureev-academy.ru/?ysclid=lfhtvrgwk7647502626	https://vk.com/public217362452?ysclid=lfhtvqzcnl615042292	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://nureevacademy.ru/abiturientu/	\N
202	ГБПОУ РБ Октябрьский музыкальный колледж	ОМК		active	\N	0	0	0.00	0.00	8 (347) 677-09-54	muzuch@rambler.ru	https://okmuz.ru/?ysclid=lfhtuwp5a6505086185	https://vk.com/cluboktmuz?from=search	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://okmuz.ru/category/abiturientu/	\N
203	ГБПОУ РБ Салаватский музыкальный колледж	СМК		active	\N	0	0	0.00	0.00	8 (347) 633-59-30	muzuch@mail.ru	https://slvmuzkol.ru	https://vk.com/public217537719	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://slvmuzkol.ru/category/abiturientu/	\N
204	ГБПОУ РБ Сибайский колледж искусств	СКИ		active	\N	0	0	0.00	0.00	8 (347) 752-46-32	skisibay@mail.ru	https://skisibay.ru/?ysclid=lfhts3nk1z839140760	https://vk.com/skisibay_news	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://skisibay.ru/abitur/priem/	\N
205	ГБПОУ РБ Средний специальный музыкальный колледж	ССМК		active	\N	0	0	0.00	0.00	8 (347) 272-43-45	ccmk50@yandex.ru	https://ssmuzk.ru/	https://vk.com/public219274441	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://ssmuzk.ru/category/abiturientu/	\N
206	ГБПОУ РБ Уфимское училище искусств (колледж)	УУИ		active	\N	0	0	0.00	0.00	8 (347) 272-18-61	gou_spoki_uui@mail.ru	uui-rb.ru	https://vk.com/uui_college	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://uui-rb.ru/priemnaya-komissiya2024/	\N
207	ГБПОУ РБ Учалинский колледж искусств и культуры имени Салавата Низаметдинова	УКИиК		active	\N	0	0	0.00	0.00	8 (347) 916-16-90	uiik_priemnaya@mail.ru	https://ukiik.ru	https://vk.com/ukipisufarb?reactions_opened=wall-182574797_1090	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://ukiik.ru/priemnyie-trebovaniya/	\N
208	ГБПОУ Уфимский лесотехнический техникум	УЛТ		active	\N	0	0	0.00	0.00	8 (347) 228-80-30	ylxt@mail.ru	https://www.ultt.ru/	https://vk.com/ylxtclub	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://www.ultt.ru/abitur/khod-priemnoy-kompanii-2016/	\N
209	ГБПОУ Уфимский колледж индустрии, питания и сервиса	УКИПиС		active	\N	0	0	0.00	0.00	8 (347) 295-94-04	ukipis@mail.ru	https://ukipis.ru/ru/	https://vk.com/ukipisufarb	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://ukipis.ru/ru/abitur/	\N
210	АНО ПО Башкирский кооперативный техникум	БКТ		active	\N	0	0	0.00	0.00	8 (347) 272-34-72	bktufa@yandex.ru	http://bktufa.ru/	https://vk.com/bktufa	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://bktufa.ru/abitur/spo/	\N
211	АНО СПО Бирский кооперативный техникум	БКТ		active	\N	0	0	0.00	0.00	8 (347) 842-11-65, 8 (987) 055-59-07	birsk.kt@mail.ru zao.bkt@gmail.com	http://birskcoop.ru/	https://vk.com/birskcoop	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	http://birskcoop.ru/index/abiturientu/0-96	\N
212	ЧПОУ Башкирский экономико-юридический колледж	БЭК		active	\N	0	0	0.00	0.00	8 800 201-82-02	uo@bek-ufa.ru oz@bek-ufa.ru eo@bek-ufa.ru ood@bek-ufa.ru	https://www.bek-ufa.ru/	https://vk.com/bek_ufa	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://www.bek-ufa.ru/entrant/commission/	\N
213	АНО ПО Октябрьский экономический техникум	ОЭТ		active	\N	0	0	0.00	0.00	8 (347) 677-22-00	nouoet@yandex.ru	https://www.nouoet.ru/	https://vk.com/club50943436	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://www.nouoet.ru/?sel=top&id=9	\N
214	АНПОО Уфимский политехнический техникум	УПТ		active	\N	0	0	0.00	0.00	8 (347) 283-42-94	ufa-politech@mail.ru	https://politech.pro/	https://vk.com/public182391798	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://politech.pro/%d0%b0%d0%b1%d0%b8%d1%82%d1%83%d1%80%d0%b8%d0%b5%d0%bd%d1%82%d1%83	\N
215	Уфимский филиал ВГУВТ	ВГУВТ		active	\N	0	0	0.00	0.00	8 (347) 215-14-00	uf-vsuwt@uf-vsuwt.ru	rivercollege.ru	https://vk.com/uf_vsuwt	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	не открывается сайт(	\N
216	УТЖТ УфИПС - филиал СамГУПС	ГУПС		active	\N	0	0	0.00	0.00	8 800-775-23-25	utgt@uftgt.ru	samgups.ru	https://vk.com/ufatgt	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://www.samgups.ru/education/abiturientam/	\N
217	Кумертауский филиал ОГУ	ОГУ		active	\N	0	0	0.00	0.00	8 (347) 612-18-38	post@mail.osu.ru	osu.ru	https://vk.com/orenburg_university	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://kf.osu.ru/Abitur/#vo3	\N
218	Уфимский филиал Фин университета	Финуниверситет		active	\N	0	0	0.00	0.00	8 (347) 251-08-23	academy@fa.ru	fa.ru	https://vk.com/fin_ufa?ysclid=lfht9rtlek230355539	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://ufa.fa.ru/for-applicants/	\N
219	Башкирский государственный университет	БашГУ		active	\N	0	0	0.00	0.00	8 (347) 273-67-34	pk2299721@bashedu.ru	bashedu.ru	https://vk.com/kollejestr?ysclid=lfht8ipzry18465272	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://abitur.bspu.ru/college	\N
220	Башкирский государственный педагогический университет им. М. Акмуллы	БГПУ		active	\N	0	0	0.00	0.00	8 (347) 246-66-25	office@bspu.ru	bspu.ru	https://vk.com/collegebspu?ysclid=lfht2onpsp75500029	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://abitur.bspu.ru/college	\N
221	Уфимский авиационный техникум ФГБОУ ВО "УУНит"	УАТ		active	\N	0	0	0.00	0.00	8 (908) 350-49-84	uat@ugatu.su	https://uust.ru/education/uat/	https://vk.com/uustufa	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://uust.ru/admission/	\N
222	Московский международный колледж цифровых технологий, филиал г. Уфа	ММКЦТ		active	\N	0	0	0.00	0.00	83472252510\r\n89373029011	distant_ru@top-academy.ru	https://online.top-academy.ru/college	https://vk.com/it_top_college_ufa	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	https://online.top-academy.ru/education/it-college	\N
223	Бирский филиал СПО УУНиТ	\N		active	\N	0	0	0.00	0.00	\N	\N	\N	\N	\N	\N	f	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-14 10:35:48.714233	2026-05-14 10:35:48.714233	\N	\N	\N	\N	\N
\.


--
-- Data for Name: login_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.login_logs (id, user_id, login_time, ip_address, user_agent, success, failure_reason, session_id) FROM stdin;
1	3	2026-04-10 22:14:21.408215	::ffff:127.0.0.1	\N	f	Неверный пароль	\N
2	3	2026-04-10 22:42:14.539748	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
3	3	2026-04-10 22:42:27.611547	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
4	3	2026-04-10 22:43:19.767382	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
5	3	2026-04-10 22:53:04.831064	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
6	3	2026-04-10 22:56:04.81555	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
7	3	2026-04-10 22:56:36.061695	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
8	3	2026-04-10 23:46:00.737027	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTg0Njc2MCwiZXhwIjoxNzc1OTMzMTYwfQ.yEVDnHYEQQMn8DwZPdi0OJFT-nrJNBWXMoaFXB6_Fu8
9	3	2026-04-11 00:29:15.921405	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTg0OTM1NSwiZXhwIjoxNzc1OTM1NzU1fQ.LOC9vuq8X9bjLLYuFZhn22K10gFhM7zkz5JFYnYU9zs
10	3	2026-04-11 00:34:17.885868	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTg0OTY1NywiZXhwIjoxNzc1OTM2MDU3fQ.gmpImvLc0dDYx9BT_XLCzcxU4GKWJoFnbUGMRUAXE7w
11	3	2026-04-11 00:59:01.277454	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTg1MTE0MSwiZXhwIjoxNzc1OTM3NTQxfQ.K2aIav-9jfJPWHMSwsDfWI43QKkZunA6X91PmbrxEFc
12	3	2026-04-11 06:53:19.631753	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTg3MjM5OSwiZXhwIjoxNzc1OTU4Nzk5fQ.4INvS1dEqDYd6p_YDzBvtoAVzUXcF6KN7rOC7mjm_6w
13	3	2026-04-12 02:29:52.549785	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk0Mjk5MiwiZXhwIjoxNzc2MDI5MzkyfQ.xscpR5neG3_j4cdqUR35ZExaHzEDqY-OZbczSAyWaXY
14	3	2026-04-12 13:08:55.936476	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4MTMzNSwiZXhwIjoxNzc2MDY3NzM1fQ.CNIsxlJksRc4mkUoFvjn7TfF3bD4OAZvnq27mwPBd3o
15	3	2026-04-12 13:16:40.175271	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
16	3	2026-04-12 13:16:41.606846	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
17	3	2026-04-12 13:16:47.144132	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4MTgwNywiZXhwIjoxNzc2MDY4MjA3fQ.UrmBL8b_ocGinPjgm6quktEMr4qCthHOARPN84pWgWo
18	3	2026-04-12 13:16:57.473253	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4MTgxNywiZXhwIjoxNzc2MDY4MjE3fQ.4bZpxpWt3e6v92du8lh2H5Ru62XLEAoLKuT12GZ66x4
19	3	2026-04-12 13:17:10.433792	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4MTgzMCwiZXhwIjoxNzc2MDY4MjMwfQ.2Eu3oPFJsltEgLIPlvOD-k1InV1vnQTBkP7spQsg3qc
20	3	2026-04-12 13:17:16.54813	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
21	3	2026-04-12 13:25:26.385053	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
22	3	2026-04-12 13:25:33.88612	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4MjMzMywiZXhwIjoxNzc2MDY4NzMzfQ.Rlh5wItLTN8mKdhbwtXhmqFca_rVjxfarjdzWvxW-h8
23	3	2026-04-12 13:25:52.260453	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4MjM1MiwiZXhwIjoxNzc2MDY4NzUyfQ.hbEYnhbVADU8K4cjrAmvaiW5ADMWWy0JKVBp7tpHrH8
24	3	2026-04-12 13:33:51.795074	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
25	3	2026-04-12 13:33:57.424209	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4MjgzNywiZXhwIjoxNzc2MDY5MjM3fQ.iGo3FTZ6FZCys1F6xD3h2_wQQJ6rptq3WMVn1KK1ytA
26	3	2026-04-12 13:39:51.542363	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4MzE5MSwiZXhwIjoxNzc2MDY5NTkxfQ.Oli3zGa5JQzYhLcl0rpf5-N5g4hVLMMgH1Y7Di94NCA
27	3	2026-04-12 13:45:02.667077	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4MzUwMiwiZXhwIjoxNzc2MDY5OTAyfQ.M4xpd4WzEozFG7AvTYSbOcXMBUvtJbNWmhOvx4bc3IY
28	3	2026-04-12 13:59:48.653572	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4NDM4OCwiZXhwIjoxNzc2MDcwNzg4fQ.WnQZDv5cbVQE1cjn7miNNSya-CdUJgnP2sUG48MPhs4
29	3	2026-04-12 14:00:02.557719	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4NDQwMiwiZXhwIjoxNzc2MDcwODAyfQ.dBppjGD9SvCThNI29GQC81VRLlvHzn7eSHM5ZLHHYyo
31	3	2026-04-12 14:04:57.06696	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4NDY5NywiZXhwIjoxNzc2MDcxMDk3fQ.sxEeKBhZLINPnEcUt4mtacHT4dg8WkfYeo5Vy6QBw4o
32	3	2026-04-12 14:05:11.242707	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4NDcxMSwiZXhwIjoxNzc2MDcxMTExfQ.0Es46s6lcjO62wAsorbgQJ5sRDy36MnCKbmPd3BsvU0
33	3	2026-04-12 14:05:16.079428	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4NDcxNiwiZXhwIjoxNzc2MDcxMTE2fQ.NK2QBEKkz6QaRzkR0DYKq6ceSJaaFokF_cSZyp90Wx4
35	3	2026-04-12 14:22:41.556801	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4NTc2MSwiZXhwIjoxNzc2MDcyMTYxfQ.RqroonOqG8bvndLhReJRbUTXXH2qE2CoDKQlt2fo1Uo
36	3	2026-04-12 14:22:46.957	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk4NTc2NiwiZXhwIjoxNzc2MDcyMTY2fQ.wRxT0aRRmPsxwc8AO6ER-Bno204r0EbzrYZSunrAfrk
70	3	2026-04-12 17:00:18.700378	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
71	3	2026-04-12 17:00:23.277059	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk5NTIyMywiZXhwIjoxNzc2MDgxNjIzfQ.Yp1u1TD6gmVyNrObqgOpCcbA77KTxiYRbbkKnXpzajg
72	3	2026-04-12 17:00:41.890383	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
73	3	2026-04-12 17:00:47.228166	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk5NTI0NywiZXhwIjoxNzc2MDgxNjQ3fQ.A3VnsJ3xa_5QMq-trm-xO9-BURahpq7SFs_ctwblirQ
77	3	2026-04-12 17:51:28.832714	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk5ODI4OCwiZXhwIjoxNzc2MDg0Njg4fQ.KTqtSKM0ZB6Yf6uriujNWuIcmrhJMYayZ3CbP1Jf_Tc
78	3	2026-04-12 17:52:28.751896	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk5ODM0OCwiZXhwIjoxNzc2MDg0NzQ4fQ.5PnGejgwOvaaKER-mYAgtOIxQPLTDpESF7l8E_GNNBk
79	3	2026-04-12 17:53:15.675349	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk5ODM5NSwiZXhwIjoxNzc2MDg0Nzk1fQ.HTyvy1Fe7q81lYnPUl7yVdLs0kUX4UEKU9XSnmx_XgM
84	3	2026-04-12 18:02:48.547092	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NTk5ODk2OCwiZXhwIjoxNzc2MDg1MzY4fQ.-TFzznzq6FGFHFZXmDZpNxESfg15qEJijLJ7Yk0rBr8
85	3	2026-04-12 18:20:12.50986	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjAwMDAxMiwiZXhwIjoxNzc2MDg2NDEyfQ.uoDLtiMNrKeXQe5ZI3I9HIkRiBEFE1TFbPdH2nc4DYc
86	3	2026-04-12 18:20:23.265163	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjAwMDAyMywiZXhwIjoxNzc2MDg2NDIzfQ.dflgaRBj3gzyo4NQjPa-p3oLAhV8wxxGx7l029mQbo8
87	3	2026-04-12 18:25:43.92627	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjAwMDM0MywiZXhwIjoxNzc2MDg2NzQzfQ.CwyTXBpX5zxwfmywQnX0I4tLb1aDsMEivPKqoZPKFcg
88	3	2026-04-12 18:25:46.45881	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjAwMDM0NiwiZXhwIjoxNzc2MDg2NzQ2fQ.lOX_ED-6B_aKxYFagBI0S-AIdoQ3bU8n8Km7NPCWqoU
89	3	2026-04-12 18:26:00.517132	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjAwMDM2MCwiZXhwIjoxNzc2MDg2NzYwfQ.R0Uu_bc84kdxFJ4IX9VDf0gdA2-Ea8LHcLiaasVsjUA
90	3	2026-04-12 18:27:51.540667	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjAwMDQ3MSwiZXhwIjoxNzc2MDg2ODcxfQ.otSBQh5mFP9aI_zWZBnIRbOTPJfp2Xnc8SGfQSPo3tc
91	3	2026-04-12 18:40:42.094389	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjAwMTI0MiwiZXhwIjoxNzc2MDg3NjQyfQ.NfGiN8gL0PahXKpTMVE2r07PgrWsAqBoXwlXsbg6YXQ
99	3	2026-04-13 01:42:18.439628	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjAyNjUzOCwiZXhwIjoxNzc2MTEyOTM4fQ.B05Wlx_qG7022_fjhSloZZgBOEeFrQE1OYgD2N-rISQ
100	3	2026-04-13 02:12:42.912645	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjAyODM2MiwiZXhwIjoxNzc2MTE0NzYyfQ.H17MHaWTz_3CTCJR5tu2a4KmRgqND7yvFs1ovPEdp4o
101	3	2026-04-13 02:15:30.87903	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjAyODUzMCwiZXhwIjoxNzc2MTE0OTMwfQ.1zujrcW37cneIOFNtidQDsJ17iQbiq_kManVQWrcG54
103	3	2026-04-13 02:19:15.086766	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjAyODc1NSwiZXhwIjoxNzc2MTE1MTU1fQ.Xbi23xy8ZwF5OI67NSPJLSEWDm3a-c_BcWa2qCd2bu8
104	3	2026-04-13 11:20:58.979275	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjA2MTI1OCwiZXhwIjoxNzc2MTQ3NjU4fQ.bmW6-kocdsHQaY0HmjrR9VfCoNgCInEGCrQA9wiQ3tU
105	3	2026-04-13 11:30:58.287033	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjA2MTg1OCwiZXhwIjoxNzc2MTQ4MjU4fQ.peysccavXUELxb0bmzOJ1xZjWvmwZDFElKyKpIhfar8
109	3	2026-04-13 22:13:09.579813	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
110	3	2026-04-13 22:13:14.414772	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjEwMDM5NCwiZXhwIjoxNzc2MTg2Nzk0fQ.l1pCJM7EacliqV0lm3TFATwJo8QNs-gKlHZ9AGfaHpM
113	3	2026-04-13 23:40:33.160673	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	f	Неверный пароль	\N
114	3	2026-04-13 23:40:43.112566	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjEwNTY0MywiZXhwIjoxNzc2MTkyMDQzfQ.fZOmKL42mG8_em_gzSL-RRktfKbHcWKtyPb7a2PiNyU
115	3	2026-04-13 23:48:03.991579	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjEwNjA4MywiZXhwIjoxNzc2MTkyNDgzfQ.2ScQKWR9L0rDeaFTL1MSUrSMmA7Q6gG_ijpqq0TX6mc
117	3	2026-04-14 05:03:45.282854	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NjEyNTAyNSwiZXhwIjoxNzc2MjExNDI1fQ.C7TWWKvzlwf8Y0gnN_KmSWf36MapcW5v7leOz3UQvaA
118	3	2026-04-25 17:30:47.443251	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NzEyMDI0NywiZXhwIjoxNzc3MjA2NjQ3fQ.QfGMdqDml8bY3SlGenZJQVn8LJ1QFD-wBhoKRS0FFts
119	3	2026-04-25 19:35:43.693085	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	Неверный пароль	\N
120	3	2026-04-25 19:35:50.014447	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NzEyNzc1MCwiZXhwIjoxNzc3MjE0MTUwfQ.EsK4kNft3xDDCvrdbYifuk8cZIa6P9Wp1DkCiK669Ng
166	3	2026-04-29 16:27:42.597297	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	Неверный пароль	\N
167	3	2026-04-29 16:27:48.323654	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	\N	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsImxvZ2luIjoiYWRtaW4iLCJyb2xlSWQiOjEsInJvbGVOYW1lIjoiYWRtaW4iLCJjb2xsZWdlSWQiOm51bGwsImlhdCI6MTc3NzQ2MjA2OCwiZXhwIjoxNzc3NTQ4NDY4fQ.Swp3fy-G9ADRk0AMDVoa3Cb0X9ojihCWZqihb8DjUiA
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (id, name, description, created_at, updated_at) FROM stdin;
1	admin	Полный доступ ко всем функциям системы	2026-04-10 01:03:20.082257	2026-04-10 01:03:20.082257
2	college_rep	Представитель колледжа: управление своим колледжем	2026-04-10 01:03:20.082257	2026-04-10 01:03:20.082257
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schema_migrations (id, filename, applied_at) FROM stdin;
1	2026-04-25-sector-specialty-api.sql	2026-04-27 00:26:03.977461
2	2026-04-26-online-applications.sql	2026-04-27 00:26:04.036247
3	2026-04-27-applications-unique-specialty.sql	2026-04-27 00:53:04.424362
4	2026-04-28-favorites.sql	2026-04-28 00:10:05.811338
\.


--
-- Data for Name: sectors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sectors (id, name, code, description, image_url, sort_order, is_active, created_at, updated_at) FROM stdin;
33	ИНФОРМАЦИОННАЯ БЕЗОПАСНОСТЬ	10.00.00	Специальности направления "информационная безопасность".	\N	5	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
34	ЭЛЕКТРОНИКА, РАДИОТЕХНИКА И СИСТЕМЫ СВЯЗИ	11.00.00	Специальности направления "электроника, радиотехника и системы связи".	\N	6	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
35	ФОТОНИКА, ПРИБОРОСТРОЕНИЕ, ОПТИЧЕСКИЕ И БИОТЕХНИЧЕСКИЕ СИСТЕМЫ И ТЕХНОЛОГИИ	12.00.00	Специальности направления "фотоника, приборостроение, оптические и биотехнические системы и технологии".	\N	7	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
22	ЭЛЕКТРО- И ТЕПЛОЭНЕРГЕТИКА	13.00.00	Специальности направления "электро- и теплоэнергетика".	\N	8	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
36	ЯДЕРНАЯ ЭНЕРГЕТИКА И ТЕХНОЛОГИИ	14.00.00	Специальности направления "ядерная энергетика и технологии".	\N	9	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
32	МАШИНОСТРОЕНИЕ	15.00.00	Специальности направления "машиностроение".	\N	10	t	2026-05-14 00:39:40.283817	2026-05-14 11:17:13.398499
23	ХИМИЧЕСКИЕ ТЕХНОЛОГИИ	18.00.00	Специальности направления "химические технологии".	\N	11	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
37	ПРОМЫШЛЕННАЯ ЭКОЛОГИЯ И БИОТЕХНОЛОГИИ	19.00.00	Специальности направления "промышленная экология и биотехнологии".	\N	12	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
39	ТЕХНОЛОГИИ МАТЕРИАЛОВ	22.00.00	Специальности направления "технологии материалов".	\N	15	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
18	НАУКИ О ЗЕМЛЕ	05.00.00	Специальности направления "науки о земле".	\N	1	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
19	АРХИТЕКТУРА	07.00.00	Специальности направления "архитектура".	\N	2	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
20	ТЕХНИКА И ТЕХНОЛОГИИ СТРОИТЕЛЬСТВА	08.00.00	Специальности направления "техника и технологии строительства".	\N	3	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
21	ИНФОРМАТИКА И ВЫЧИСЛИТЕЛЬНАЯ ТЕХНИКА	09.00.00	Специальности направления "информатика и вычислительная техника".	\N	4	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
47	СЕСТРИНСКОЕ ДЕЛО	34.00.00	Специальности направления "сестринское дело".	\N	25	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
27	СЕЛЬСКОЕ, ЛЕСНОЕ И РЫБНОЕ ХОЗЯЙСТВО	35.00.00	Специальности направления "сельское, лесное и рыбное хозяйство".	\N	26	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
48	ВЕТЕРИНАРИЯ И ЗООТЕХНИЯ	36.00.00	Специальности направления "ветеринария и зоотехния".	\N	27	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
28	ЭКОНОМИКА И УПРАВЛЕНИЕ	38.00.00	Специальности направления "экономика и управление".	\N	28	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
49	СОЦИОЛОГИЯ И СОЦИАЛЬНАЯ РАБОТА	39.00.00	Специальности направления "социология и социальная работа".	\N	29	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
29	ЮРИСПРУДЕНЦИЯ	40.00.00	Специальности направления "юриспруденция".	\N	30	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
50	СРЕДСТВА МАССОВОЙ ИНФОРМАЦИИ И ИНФОРМАЦИОННО-БИБЛИОТЕЧНОЕ ДЕЛО	42.00.00	Специальности направления "средства массовой информации и информационно-библиотечное дело".	\N	31	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
30	СЕРВИС И ТУРИЗМ	43.00.00	Специальности направления "сервис и туризм".	\N	32	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
31	ОБРАЗОВАНИЕ И ПЕДАГОГИЧЕСКИЕ НАУКИ	44.00.00	Специальности направления "образование и педагогические науки".	\N	33	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
51	ИСТОРИЯ И АРХЕОЛОГИЯ	46.00.00	Специальности направления "история и археология".	\N	34	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
52	ФИЗИЧЕСКАЯ КУЛЬТУРА И СПОРТ	49.00.00	Специальности направления "физическая культура и спорт".	\N	35	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
53	ИСКУССТВОЗНАНИЕ	50.00.00	Специальности направления "искусствознание".	\N	36	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
54	КУЛЬТУРОВЕДЕНИЕ И СОЦИОКУЛЬТУРНЫЕ ПРОЕКТЫ	51.00.00	Специальности направления "культуроведение и социокультурные проекты".	\N	37	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
55	СЦЕНИЧЕСКИЕ ИСКУССТВА И ЛИТЕРАТУРНОЕ ТВОРЧЕСТВО	52.00.00	Специальности направления "сценические искусства и литературное творчество".	\N	38	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
56	МУЗЫКАЛЬНОЕ ИСКУССТВО	53.00.00	Специальности направления "музыкальное искусство".	\N	39	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
58	ЭКРАННЫЕ ИСКУССТВА	55.00.00	Специальности направления "экранные искусства".	\N	41	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
57	ИЗОБРАЗИТЕЛЬНОЕ И ПРИКЛАДНЫЕ ВИДЫ ИСКУССТВ	54.00.00	Специальности направления "изобразительное и прикладные виды искусств".	\N	40	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
59	ОБЕСПЕЧЕНИЕ ГОСУДАРСТВЕННОЙ БЕЗОПАСНОСТИ	57.00.00	Специальности направления "обеспечение государственной безопасности".	\N	42	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
38	ТЕХНОСФЕРНАЯ БЕЗОПАСНОСТЬ И ПРИРОДООБУСТРОЙСТВО	20.00.00	Специальности направления "техносферная безопасность и природообустройство".	\N	13	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
41	АЭРОНАВИГАЦИЯ И ЭКСПЛУАТАЦИЯ АВИАЦИОННОЙ И РАКЕТНО-КОСМИЧЕСКОЙ ТЕХНИКИ	25.00.00	Специальности направления "аэронавигация и эксплуатация авиационной и ракетно-космической техники".	\N	18	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
42	ТЕХНИКА И ТЕХНОЛОГИИ КОРАБЛЕСТРОЕНИЯ И ВОДНОГО ТРАНСПОРТА	26.00.00	Специальности направления "техника и технологии кораблестроения и водного транспорта".	\N	19	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
43	УПРАВЛЕНИЕ В ТЕХНИЧЕСКИХ СИСТЕМАХ	27.00.00	Специальности направления "управление в технических системах".	\N	20	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
44	ТЕХНОЛОГИИ ЛЕГКОЙ ПРОМЫШЛЕННОСТИ	29.00.00	Специальности направления "технологии легкой промышленности".	\N	21	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
26	КЛИНИЧЕСКАЯ МЕДИЦИНА	31.00.00	Специальности направления "клиническая медицина".	\N	22	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
45	НАУКИ О ЗДОРОВЬЕ И ПРОФИЛАКТИЧЕСКАЯ МЕДИЦИНА	32.00.00	Специальности направления "науки о здоровье и профилактическая медицина".	\N	23	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
24	ПРИКЛАДНАЯ ГЕОЛОГИЯ, ГОРНОЕ ДЕЛО, НЕФТЕГАЗОВОЕ ДЕЛО И ГЕОДЕЗИЯ	21.00.00	Специальности направления "прикладная геология, горное дело, нефтегазовое дело и геодезия".	\N	14	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
25	ТЕХНИКА И ТЕХНОЛОГИИ НАЗЕМНОГО ТРАНСПОРТА	23.00.00	Специальности направления "техника и технологии наземного транспорта".	\N	16	t	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
40	АВИАЦИОННАЯ И РАКЕТНО-КОСМИЧЕСКАЯ ТЕХНИКА	24.00.00	Специальности направления "авиационная и ракетно-космическая техника".	\N	17	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
46	ФАРМАЦИЯ	33.00.00	Специальности направления "фармация".	\N	24	t	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
\.


--
-- Data for Name: site_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.site_settings (id, setting_key, setting_value, setting_type, description, updated_by, updated_at) FROM stdin;
1	hero.title	"Выбери специальность"	string	Заголовок герой-секции	\N	2026-04-10 01:03:20.082257
2	hero.subtitle	"Поступи в колледж"	string	Подзаголовок герой-секции	\N	2026-04-10 01:03:20.082257
3	hero.description	"Найдите свою будущую профессию среди сотен специальностей, доступных в колледжах Башкортостана. Начните свой путь к успешной карьере уже сегодня!"	string	Описание	\N	2026-04-10 01:03:20.082257
4	cta.title	"Готовы выбрать свою профессию?"	string	Заголовок CTA	\N	2026-04-10 01:03:20.082257
5	cta.button_text	"Смотреть все отрасли"	string	Текст кнопки CTA	\N	2026-04-10 01:03:20.082257
6	pagination.per_page	12	number	Записей на страницу	\N	2026-04-10 01:03:20.082257
7	site_title	"Колледжи Республики Башкортостан"	string	Заголовок главной страницы	\N	2026-04-12 03:00:42.813801
8	site_description	"Портал среднего профессионального образования Республики Башкортостан"	string	Описание портала	\N	2026-04-12 03:00:42.813801
12	hero_title	"Колледжи Башкортостана"	string	Заголовок hero-секции	\N	2026-04-12 03:00:42.813801
13	hero_subtitle	"Найди свой путь в профессии"	string	Подзаголовок hero-секции	\N	2026-04-12 03:00:42.813801
14	stats_title	"Портал в цифрах"	string	Заголовок секции статистики	\N	2026-04-12 03:00:42.813801
9	footer_address	"Юридический адрес:\\n450001, Республика Башкортостан, город Уфа, Проспект Октября, д. 4."	string	Адрес в футере	\N	2026-05-08 11:56:20.758425
10	footer_phone	"+7‒987‒254‒51‒00"	string	Телефон в футере	\N	2026-05-08 11:56:20.758425
11	footer_email	"copp_rb@mail.ru"	string	Email в футере	\N	2026-05-08 11:56:20.758425
\.


--
-- Data for Name: specialties; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.specialties (id, code, name, description, qualification, duration, base_education, form, budget_places, commercial_places, price_per_year, exams, avg_score_last_year, status, is_professionalitet, sort_order, created_at, updated_at) FROM stdin;
20	43.01.09	Повар, кондитер	Подготовка квалифицированных рабочих в области приготовления блюд и кондитерских изделий.	Повар, кондитер	1 год 10 мес	9	full-time	30	15	0.00	\N	3.50	inactive	f	20	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
7	43.01.02	Парикмахер	Подготовка парикмахеров широкого профиля для салонов красоты и индивидуальных предпринимателей.	Парикмахер	1 год 10 мес	9	full-time	25	15	45000.00	\N	3.50	inactive	f	7	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
8	08.02.01	Строительство и эксплуатация зданий и сооружений	Подготовка техников-строителей для строительных организаций, управляющих компаний и проектных бюро.		3 года 10 мес	9	full-time	30	15	65000.00	\N	3.60	active	f	8	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
30	08.02.02	Строительство и эксплуатация инженерных сооружений				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
31	08.02.03	Производство неметаллических строительных изделий и конструкций				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
32	08.02.04	Водоснабжение и водоотведение				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
33	08.02.05	Строительство и эксплуатация автомобильных дорог и аэродромов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
34	08.02.06	Строительство и эксплуатация городских путей сообщения				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
35	08.02.07	Монтаж и эксплуатация внутренних сантехнических устройств, кондиционирования воздуха и вентиляции				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
36	08.02.08	Монтаж и эксплуатация оборудования и систем газоснабжения				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
37	08.02.09	Монтаж, наладка и эксплуатация электрооборудования промышленных и гражданских зданий				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
38	08.02.10	Строительство железных дорог, путь и путевое хозяйство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
39	08.02.11	Управление, эксплуатация и обслуживание многоквартирного дома				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
78	13.02.04	Гидроэлектроэнергетические установки				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
125	20.02.04	Пожарная безопасность				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
133	21.02.08	Прикладная геодезия				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
26	05.02.01	Картография				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
27	05.02.02	Гидрология				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
21	09.02.07	Информационные системы и программирование	Тут надо будет много сидеть и программировать 		3 года 10 мес	9	full-time	0	0	\N	Информатика	4.00	inactive	f	0	2026-04-12 16:14:48.558078	2026-04-13 01:17:29.540485
28	05.02.03	Метеорология				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
29	07.02.01	Архитектура				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 00:13:35.03362	2026-05-14 11:17:13.398499
43	09.02.04	Информационные системы (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
44	09.02.05	Прикладная информатика (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
45	10.02.01	Организация и технология защиты информации				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
50	11.02.01	Радиоаппаратостроение				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
117	19.02.06	Технология консервов и пищеконцентратов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
157	24.02.01	Производство летательных аппаратов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
179	27.02.07	Управление качеством продукции, процессов и услуг (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
180	29.02.01	Конструирование, моделирование и технология изделий из кожи				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
181	29.02.02	Технология кожи и меха				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
182	29.02.03	Конструирование, моделирование и технология изделий из меха				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
9	15.02.17	Монтаж, техническое обслуживание, эксплуатация и ремонт промышленного оборудования	Подготовка техников по монтажу и обслуживанию электрооборудования промышленных и гражданских объектов.	Техник-механик	3 года 10 мес	9	full-time	30	10	0.00		3.80	inactive	f	9	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
11	18.02.08	Химическая технология органических веществ	Подготовка техников-технологов для нефтехимической и химической промышленности.	Техник-технолог	3 года 10 мес	9	full-time	40	10	0.00	\N	3.90	inactive	t	11	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
19	09.02.06	Сетевое и системное администрирование	Подготовка системных и сетевых администраторов для IT-инфраструктуры организаций.		3 года 10 мес	9	full-time	50	20	70000.00	\N	4.20	active	f	19	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
65	11.02.16	Монтаж, техническое обслуживание и ремонт электронных приборов и устройств				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
66	12.02.01	Авиационные приборы и комплексы				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
67	12.02.03	Радиоэлектронные приборные устройства				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
68	12.02.04	Электромеханические приборные устройства				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
69	12.02.05	Оптические и оптико-электронные приборы и системы				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
118	19.02.07	Технология молока и молочных продуктов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
159	25.02.01	Техническая эксплуатация летательных аппаратов и двигателей				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
160	25.02.02	Обслуживание летательных аппаратов горюче-смазочными материалами				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
162	25.02.04	Летная эксплуатация летательных аппаратов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
168	26.02.02	Судостроение				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
175	27.02.03	Автоматика и телемеханика на транспорте (железнодорожном транспорте)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
177	27.02.05	Системы и средства диспетчерского управления				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
178	27.02.06	Контроль работы измерительных приборов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
183	29.02.04	Конструирование, моделирование и технология швейных изделий				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
76	13.02.02	Теплоснабжение и теплотехническое оборудование				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
79	13.02.05	Технология воды, топлива и смазочных материалов на электрических станциях				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
80	13.02.06	Релейная защита и автоматизация электроэнергетических систем				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
81	13.02.07	Электроснабжение (по отраслям)		Техник		9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
82	13.02.08	Электроизоляционная, кабельная и конденсаторная техника				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
83	13.02.09	Монтаж и эксплуатация линий электропередачи				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
84	13.02.10	Электрические машины и аппараты				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
18	13.02.11	Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)	Подготовка техников-электриков для промышленных предприятий, энергетических компаний и организаций ЖКХ.		3 года 10 мес	9	full-time	30	10	0.00	\N	3.80	active	f	18	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
85	14.02.01	Атомные электрические станции и установки				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
86	14.02.02	Радиационная безопасность				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
87	15.02.01	Монтаж и техническая эксплуатация промышленного оборудования (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
88	15.02.02	Техническая эксплуатация оборудования для производства электронной техники				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
119	19.02.08	Технология мяса и мясных продуктов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
120	19.02.09	Технология жиров и жирозаменителей				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
121	19.02.10	Технология продукции общественного питания				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
122	20.02.01	Рациональное использование природохозяйственных комплексов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
124	20.02.03	Природоохранное обустройство территорий				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
184	29.02.05	Технология текстильных изделий (по видам)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
185	29.02.06	Полиграфическое производство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
134	21.02.09	Гидрогеология и инженерная геология				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
135	21.02.10	Геология и разведка нефтяных и газовых месторождений				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
136	21.02.11	Геофизические методы поисков и разведки месторождений полезных ископаемых				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
137	21.02.12	Технология и техника разведки месторождений полезных ископаемых				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
138	21.02.13	Геологическая съемка, поиски и разведка месторождений полезных ископаемых				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
139	21.02.14	Маркшейдерское дело				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
140	21.02.15	Открытые горные работы				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
141	21.02.16	Шахтное строительство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
142	21.02.17	Подземная разработка месторождений полезных ископаемых				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
143	21.02.18	Обогащение полезных ископаемых				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
144	22.02.01	Металлургия черных металлов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
154	23.02.04	Техническая эксплуатация подъемно-транспортных, строительных, дорожных машин и оборудования (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
155	23.02.05	Эксплуатация транспортного электрооборудования и автоматики (по видам транспорта, за исключением водного)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
12	23.02.07	Техническое обслуживание и ремонт двигателей, систем и агрегатов автомобилей	Подготовка специалистов по техническому обслуживанию автомобилей, в том числе на предприятиях автопрома.		3 года 10 мес	9	full-time	30	10	0.00	\N	3.60	active	f	12	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
158	24.02.02	Производство авиационных двигателей				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
186	29.02.07	Производство изделий из бумаги и картона				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
188	29.02.09	Печатное дело				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
4	31.02.01	Лечебное дело	Подготовка фельдшеров для оказания первичной медико-санитарной помощи, работы в лечебно-профилактических учреждениях.		3 года 10 мес	9	full-time	50	10	0.00	\N	4.50	active	f	4	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
196	34.02.02	Медицинский массаж (для обучения лиц с ограниченными возможностями здоровья по зрению)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
89	15.02.03	Техническая эксплуатация гидравлических машин, гидроприводов и гидропневмоавтоматики				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
90	15.02.04	Специальные машины и устройства				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
91	15.02.05	Техническая эксплуатация оборудования в торговле и общественном питании				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
92	15.02.06	Монтаж и техническая эксплуатация холодильно-компрессорных машин и установок (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
93	15.02.07	Автоматизация технологических процессов и производств (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
1	15.02.08	Технология машиностроения	Подготовка техников-технологов для машиностроительных предприятий. Освоение современных технологий обработки металлов, работы на станках с ЧПУ.		3 года 10 мес	9	full-time	50	15	85000.00	\N	4.30	active	t	1	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
95	15.02.10	Мехатроника и мобильная робототехника (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
96	15.02.11	Техническая эксплуатация и обслуживание роботизированного производства				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
113	19.02.02	Технология хранения и переработки зерна				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
114	19.02.03	Технология хлеба, кондитерских и макаронных изделий				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
115	19.02.04	Технология сахаристых продуктов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
116	19.02.05	Технология бродильных производств и виноделие				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
176	27.02.04	Автоматические системы управления				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
189	31.02.02	Акушерское дело				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
16	35.02.01	Лесное и лесопарковое хозяйство	Подготовка техников лесного хозяйства для лесничеств, лесопарковых хозяйств и природоохранных организаций.		3 года 10 мес	9	full-time	20	5	0.00	\N	3.40	active	f	16	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
197	35.02.02	Технология лесозаготовок				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
198	35.02.03	Технология деревообработки				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
199	35.02.04	Технология комплексной переработки древесины				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
14	38.02.04	Коммерция (по отраслям)	Подготовка менеджеров по продажам, специалистов по коммерческой деятельности и маркетингу.		2 года 10 мес	11	full-time	25	15	55000.00	\N	3.80	active	f	14	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
217	38.02.06	Финансы				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
218	38.02.07	Банковское дело				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
97	15.02.12	Монтаж, техническое обслуживание и ремонт промышленного оборудования (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
98	15.02.13	Техническое обслуживание и ремонт систем вентиляции и кондиционирования				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
99	15.02.14	Оснащение средствами автоматизации технологических процессов и производств (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
100	15.02.15	Технология металлообрабатывающего производства				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
101	18.02.01	Аналитический контроль качества химических соединений				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
102	18.02.03	Химическая технология неорганических веществ				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
104	18.02.05	Производство тугоплавких неметаллических и силикатных материалов и изделий				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
105	18.02.06	Химическая технология органических веществ				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
106	18.02.07	Технология производства и переработки пластических масс и эластомеров				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
108	18.02.10	Коксохимическое производство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
109	18.02.11	Технология пиротехнических составов и изделий				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
110	18.02.12	Технология аналитического контроля химических соединений				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
111	18.02.13	Технология производства изделий из полимерных композитов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
187	29.02.08	Технология обработки алмазов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
3	38.02.01	Экономика и бухгалтерский учет (по отраслям)	Подготовка бухгалтеров, экономистов и специалистов по финансовому учёту для предприятий различных отраслей.		2 года 10 мес	11	full-time	30	20	60000.00	\N	4.00	active	f	3	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
216	38.02.05	Товароведение и экспертиза качества потребительских товаров				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
70	12.02.06	Биотехнические и медицинские аппараты и системы				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
71	12.02.07	Монтаж, техническое обслуживание и ремонт медицинской техники				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
72	12.02.08	Протезно-ортопедическая и реабилитационная техника				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
73	12.02.09	Производство и эксплуатация оптических и оптико-электронных приборов и систем				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
74	12.02.10	Монтаж, техническое обслуживание и ремонт биотехнических и медицинских аппаратов и систем				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
75	13.02.01	Тепловые электрические станции				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
77	13.02.03	Электрические станции, сети и системы				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
123	20.02.02	Защита в чрезвычайных ситуациях				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
126	20.02.05	Организация оперативного (экстренного) реагирования в чрезвычайных ситуациях				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
10	21.02.01	Разработка и эксплуатация нефтяных и газовых месторождений	Подготовка специалистов для нефтегазовой отрасли: операторов по добыче нефти и газа, техников по бурению.		3 года 10 мес	9	full-time	50	10	0.00	\N	4.00	active	t	10	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
127	21.02.02	Бурение нефтяных и газовых скважин				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
128	21.02.03	Сооружение и эксплуатация газонефтепроводов и газонефтехранилищ				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
130	21.02.05	Земельно-имущественные отношения				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
131	21.02.06	Информационные системы обеспечения градостроительной деятельности				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
132	21.02.07	Аэрофотогеодезия				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
219	39.02.01	Социальная работа				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
220	39.02.02	Организация сурдокоммуникации				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
237	44.02.02	Преподавание в начальных классах				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
238	44.02.03	Педагогика дополнительного образования				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
239	44.02.04	Специальное дошкольное образование				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
240	44.02.05	Коррекционная педагогика в начальном образовании				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
241	44.02.06	Профессиональное обучение (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
242	46.02.01	Документационное обеспечение управления и архивоведение				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
273	55.02.02	Анимация (по видам)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
40	09.02.01	Компьютерные системы и комплексы				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
41	09.02.02	Компьютерные сети				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
42	09.02.03	Программирование в компьютерных системах				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
2	09.02.07	Информационные системы и программирование	Подготовка специалистов в области разработки, тестирования и сопровождения информационных систем.		3 года 10 мес	9	full-time	50	25	75000.00	\N	4.40	active	f	2	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
46	10.02.02	Информационная безопасность телекоммуникационных систем				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
47	10.02.03	Информационная безопасность автоматизированных систем				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
48	10.02.04	Обеспечение информационной безопасности телекоммуникационных систем				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
49	10.02.05	Обеспечение информационной безопасности автоматизированных систем				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
51	11.02.02	Техническое обслуживание и ремонт радиоэлектронной техники (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
52	11.02.03	Эксплуатация оборудования радиосвязи и электрорадионавигации судов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
53	11.02.04	Радиотехнические комплексы и системы управления космических летательных аппаратов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
54	11.02.05	Аудиовизуальная техника				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
55	11.02.06	Техническая эксплуатация транспортного радиоэлектронного оборудования (по видам транспорта)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
56	11.02.07	Радиотехнические информационные системы				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
57	11.02.08	Средства связи с подвижными объектами				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
103	18.02.04	Электрохимическое производство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
161	25.02.03	Техническая эксплуатация электрифицированных и пилотажно-навигационных комплексов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
163	25.02.05	Управление движением воздушного транспорта				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
164	25.02.06	Производство и обслуживание авиационной техники				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
165	25.02.07	Техническое обслуживание авиационных двигателей				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
166	25.02.08	Эксплуатация беспилотных авиационных систем				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
167	26.02.01	Эксплуатация внутренних водных путей				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
169	26.02.03	Судовождение				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
170	26.02.04	Монтаж и техническое обслуживание судовых машин и механизмов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
171	26.02.05	Эксплуатация судовых энергетических установок				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
172	26.02.06	Эксплуатация судового электрооборудования и средств автоматики				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
174	27.02.02	Техническое регулирование и управление качеством				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
200	35.02.05	Агрономия				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
107	18.02.09	Переработка нефти и газа				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
112	19.02.01	Биохимическое производство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
201	35.02.06	Технология производства и переработки сельскохозяйственной продукции				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
202	35.02.07	Механизация сельского хозяйства				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
203	35.02.08	Электрификация и автоматизация сельского хозяйства				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
204	35.02.09	Ихтиология и рыбоводство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
205	35.02.10	Обработка водных биоресурсов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
208	35.02.13	Пчеловодство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
248	51.02.02	Социально-культурная деятельность (по видам)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
249	51.02.03	Библиотековедение				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
251	52.02.02	Искусство танца (по видам)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
252	52.02.03	Цирковое искусство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
253	52.02.04	Актерское искусство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
268	54.02.05	Живопись с присвоением квалификаций художник-живописец, преподаватель				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
270	54.02.07	Скульптура				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
271	54.02.08	Техника и искусство фотографии				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
272	55.02.01	Театральная и аудиовизуальная техника (по видам)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
274	57.02.01	Пограничная деятельность (по видам деятельности)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
145	22.02.02	Металлургия цветных металлов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
146	22.02.03	Литейное производство черных и цветных металлов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
147	22.02.04	Металловедение и термическая обработка металлов				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
148	22.02.05	Обработка металлов давлением				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
149	22.02.06	Сварочное производство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
150	22.02.07	Порошковая металлургия, композиционные материалы, покрытия				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
151	23.02.01	Организация перевозок и управление на транспорте (по видам)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
152	23.02.02	Автомобиле- и тракторостроение				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
153	23.02.03	Техническое обслуживание и ремонт автомобильного транспорта				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
190	31.02.04	Медицинская оптика				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
206	35.02.11	Промышленное рыболовство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
207	35.02.12	Садово-парковое и ландшафтное строительство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
209	35.02.14	Охотоведение и звероводство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
210	35.02.15	Кинология				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
211	35.02.16	Эксплуатация и ремонт сельскохозяйственной техники и оборудования				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
213	36.02.02	Зоотехния				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
214	38.02.02	Страховое дело (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
215	38.02.03	Операционная деятельность в логистике				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
156	23.02.06	Техническая эксплуатация подвижного состава железных дорог				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
13	40.02.01	Право и организация социального обеспечения	Подготовка специалистов по правовому обеспечению и социальному страхованию.		2 года 10 мес	11	full-time	25	15	55000.00	\N	4.00	active	f	13	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
221	40.02.02	Правоохранительная деятельность				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
222	40.02.03	Право и судебное администрирование				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
223	42.02.01	Реклама				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
224	42.02.02	Издательское дело		Редактор		9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
15	43.02.14	Гостиничное дело	Подготовка специалистов для гостиничного бизнеса: администраторов, менеджеров, организаторов гостиничного сервиса.		2 года 10 мес	11	full-time	20	15	58000.00	\N	3.70	active	f	15	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
6	43.02.15	Поварское и кондитерское дело	Подготовка поваров и кондитеров для предприятий общественного питания, ресторанов и пищевого производства.		3 года 10 мес	9	full-time	30	20	55000.00	\N	3.70	active	f	6	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
17	44.02.01	Дошкольное образование	Подготовка воспитателей для дошкольных образовательных учреждений: детских садов, центров развития ребёнка.		3 года 10 мес	9	full-time	30	10	50000.00	\N	4.10	active	f	17	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
250	52.02.01	Искусство балета				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
58	11.02.09	Многоканальные телекоммуникационные системы				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
59	11.02.10	Радиосвязь, радиовещание и телевидение				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
60	11.02.11	Сети связи и системы коммутации				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
61	11.02.12	Почтовая связь				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
62	11.02.13	Твердотельная электроника				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
63	11.02.14	Электронные приборы и устройства				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
64	11.02.15	Инфокоммуникационные сети и системы связи				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
5	31.02.03	Лабораторная диагностика	Подготовка лаборантов для проведения клинических и биохимических исследований в медицинских учреждениях.		2 года 10 мес	11	full-time	25	10	0.00	\N	4.30	active	f	5	2026-04-12 02:30:54.79911	2026-05-14 11:17:13.398499
191	31.02.05	Стоматология ортопедическая				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
192	31.02.06	Стоматология профилактическая				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
193	32.02.01	Медико-профилактическое дело				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
194	33.02.01	Фармация				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
195	34.02.01	Сестринское дело				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
212	36.02.01	Ветеринария				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
225	43.02.01	Организация обслуживания в общественном питании				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
226	43.02.02	Парикмахерское искусство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
227	43.02.03	Стилистика и искусство визажа				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
228	43.02.04	Прикладная эстетика				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
229	43.02.05	Флористика				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
230	43.02.06	Сервис на транспорте (по видам транспорта)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
231	43.02.07	Сервис по химической обработке изделий				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
232	43.02.08	Сервис домашнего и коммунального хозяйства				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
233	43.02.10	Туризм				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
234	43.02.11	Гостиничный сервис				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
235	43.02.12	Технология эстетических услуг				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
236	43.02.13	Технология парикмахерского искусства				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
94	15.02.09	Аддитивные технологии				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
129	21.02.04	Землеустройство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
173	27.02.01	Метрология				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
243	49.02.01	Физическая культура				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
244	49.02.02	Адаптивная физическая культура				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
245	49.02.03	Спорт				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
246	50.02.01	Мировая художественная культура				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
247	51.02.01	Народное художественное творчество (по видам)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
254	52.02.05	Искусство эстрады				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
255	53.02.01	Музыкальное образование				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
256	53.02.02	Музыкальное искусство эстрады (по видам)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
257	53.02.03	Инструментальное исполнительство (по видам инструментов)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
258	53.02.04	Вокальное искусство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
259	53.02.05	Сольное и хоровое народное пение				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
260	53.02.06	Хоровое дирижирование с присвоением квалификаций хормейстер, преподаватель				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
261	53.02.07	Теория музыки				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
262	53.02.08	Музыкальное звукооператорское мастерство				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
263	53.02.09	Театрально-декорационное искусство (по видам)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
264	54.02.01	Дизайн (по отраслям)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
265	54.02.02	Декоративно-прикладное искусство и народные промыслы (по видам)				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
266	54.02.03	Художественное оформление изделий текстильной и легкой промышленности				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
267	54.02.04	Реставрация				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
269	54.02.06	Изобразительное искусство и черчение				9	full-time	0	0	0.00	\N	0.00	active	f	0	2026-05-14 08:16:36.14395	2026-05-14 11:17:13.398499
\.


--
-- Data for Name: specialty_sectors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.specialty_sectors (specialty_id, sector_id) FROM stdin;
26	18
27	18
28	18
29	19
8	20
30	20
31	20
32	20
33	20
34	20
35	20
36	20
37	20
38	20
39	20
40	21
41	21
42	21
43	21
44	21
19	21
2	21
45	33
46	33
47	33
48	33
49	33
50	34
51	34
52	34
53	34
54	34
55	34
56	34
57	34
58	34
59	34
60	34
61	34
62	34
63	34
64	34
65	34
66	35
67	35
68	35
69	35
70	35
71	35
72	35
73	35
74	35
75	22
76	22
77	22
78	22
79	22
80	22
81	22
82	22
83	22
84	22
18	22
85	36
86	36
87	32
88	32
89	32
90	32
91	32
92	32
93	32
1	32
94	32
95	32
96	32
97	32
98	32
99	32
100	32
101	23
102	23
103	23
104	23
105	23
106	23
107	23
108	23
109	23
110	23
111	23
112	37
113	37
114	37
115	37
116	37
117	37
118	37
119	37
120	37
121	37
122	38
123	38
124	38
125	38
126	38
10	24
127	24
128	24
129	24
130	24
131	24
132	24
133	24
134	24
135	24
136	24
137	24
138	24
139	24
140	24
141	24
142	24
143	24
144	39
145	39
146	39
147	39
148	39
149	39
150	39
151	25
152	25
153	25
154	25
155	25
156	25
12	25
157	40
158	40
159	41
160	41
161	41
162	41
163	41
164	41
165	41
166	41
167	42
168	42
169	42
170	42
171	42
172	42
173	43
174	43
175	43
176	43
177	43
178	43
179	43
180	44
181	44
182	44
183	44
184	44
185	44
186	44
187	44
188	44
4	26
189	26
5	26
190	26
191	26
192	26
193	45
194	46
195	47
196	47
16	27
197	27
198	27
199	27
200	27
201	27
202	27
203	27
204	27
205	27
206	27
207	27
208	27
209	27
210	27
211	27
212	48
213	48
3	28
214	28
215	28
14	28
216	28
217	28
218	28
219	49
220	49
13	29
221	29
222	29
223	50
224	50
225	30
226	30
227	30
228	30
229	30
230	30
231	30
232	30
233	30
234	30
235	30
236	30
15	30
6	30
17	31
237	31
238	31
239	31
240	31
241	31
242	51
243	52
244	52
245	52
246	53
247	54
248	54
249	54
250	55
251	55
252	55
253	55
254	55
255	56
256	56
257	56
258	56
259	56
260	56
261	56
262	56
263	56
264	57
265	57
266	57
267	57
268	57
269	57
270	57
271	57
272	58
273	58
274	59
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_sessions (id, user_id, expires_at, created_at, last_activity, ip_address, user_agent, is_active) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, login, email, password_hash, name, role_id, college_id, status, last_login_at, created_at, updated_at, phone) FROM stdin;
38	e2e_no_college_no_college_um_1778739837428_c22a5dd	no-college-chromium-1778739837428-c22a5dd37da65@example.com	$2b$10$itGcp/NpV.NUIk.zOTQ52u2qDtr2SnlIpjmmOf.3l0/UGE4aeDUOy	E2E Representative Without College Edited	2	\N	inactive	\N	2026-05-14 11:23:57.893095	2026-05-14 11:23:59.230139	+7 (999) 111-22-34
39	e2e_no_college_no_college_e_1778739837455_5dcf9906	no-college-mobile-chrome-1778739837455-5dcf9906fbd0b8@example.com	$2b$10$94SHOUUQAX1KFSzT/NyNeOJa6fL7BdpES7jK/XG53IyiF5HxLZV/O	E2E Representative Without College Edited	2	\N	inactive	\N	2026-05-14 11:23:58.044792	2026-05-14 11:23:59.231884	+7 (999) 111-22-34
40	e2e_college_rep_chromium_1778739837428_c22a5dd37da	active-rep-edited-chromium-1778739837428-c22a5dd37da65@example.com	$2b$10$/mbYI0jHrTiE/YpzCm/bQuxr7Y.TfgeO5qQOytEwzK4OSCxWWr6De	E2E Active College Representative Edited	2	224	active	2026-05-14 11:24:00.965208	2026-05-14 11:23:59.531531	2026-05-14 11:24:00.965208	+7 (999) 333-44-55
45	e2e_college_rep_mobile_chrome_1778739924670_88f188	active-rep-edited-mobile-chrome-1778739924670-88f18898767b@example.com	$2b$10$a5WKdFsu0UshujxxmVS2fexj/XFk..i5kgumXZDNVrwvCq6M.AK8.	E2E Active College Representative Edited	2	227	active	2026-05-14 11:25:32.760689	2026-05-14 11:25:28.913635	2026-05-14 11:25:32.760689	+7 (999) 333-44-55
44	e2e_college_rep_chromium_1778739924671_0b2a481bc9f	active-rep-edited-chromium-1778739924671-0b2a481bc9fb88@example.com	$2b$10$jJAAb64Qnndcjvn.zc2TK.GSUyYliQ821KWNsrhnC1Xc2y912bM5S	E2E Active College Representative Edited	2	226	active	2026-05-14 11:25:31.438823	2026-05-14 11:25:28.123881	2026-05-14 11:25:31.438823	+7 (999) 333-44-55
3	admin	admin@college-rb.ru	$2b$10$QMJbh0o52yHjaylnRKZNdepELqnh66LZpwxLlQEDdaRUH2Yjcxq7e	Администратор	1	\N	active	2026-05-14 11:25:35.603053	2026-04-10 22:12:52.435068	2026-05-14 11:25:35.603053	\N
41	e2e_college_rep_mobile_chrome_1778739837455_5dcf99	active-rep-edited-mobile-chrome-1778739837455-5dcf9906fbd0b8@example.com	$2b$10$s0DUf33A8iaycGQAGM9VveIeXzYaGzJJahngeOL33eX98ADVnsIiW	E2E Active College Representative Edited	2	225	active	2026-05-14 11:24:01.835926	2026-05-14 11:23:59.667956	2026-05-14 11:24:01.835926	+7 (999) 333-44-55
42	e2e_no_college_no_college_m_1778739924671_0b2a481b	no-college-chromium-1778739924671-0b2a481bc9fb88@example.com	$2b$10$/vGuzOtAeZ5sIGDLDw098eQOzf.s8Vf9CMFBnYruDnwN/aZoWyWSm	E2E Representative Without College Edited	2	\N	inactive	\N	2026-05-14 11:25:25.14768	2026-05-14 11:25:27.956898	+7 (999) 111-22-34
37	admin1	bigdadsuper@gmail.com	$2b$10$H049dctaVNUWUChuj5ncsOnBHyBwz3mFYS6T3dy4FBgm663q.EbiO	admin	2	\N	inactive	\N	2026-05-14 10:53:52.690392	2026-05-14 11:18:08.816348	+7 (324) 324-32-43
43	e2e_no_college_no_college_ome_1778739924670_88f188	no-college-mobile-chrome-1778739924670-88f18898767b@example.com	$2b$10$2uvSjJ07lf90vC/IWpLapuy0OILV4nNdad1CIiiIDU0d7ZZw5iajC	E2E Representative Without College Edited	2	\N	inactive	\N	2026-05-14 11:25:25.228506	2026-05-14 11:25:28.772098	+7 (999) 111-22-34
\.


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 83, true);


--
-- Name: cities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cities_id_seq', 7, true);


--
-- Name: college_addresses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.college_addresses_id_seq', 24, true);


--
-- Name: college_specialties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.college_specialties_id_seq', 47, true);


--
-- Name: colleges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.colleges_id_seq', 227, true);


--
-- Name: login_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.login_logs_id_seq', 167, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.roles_id_seq', 7, true);


--
-- Name: schema_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.schema_migrations_id_seq', 4, true);


--
-- Name: sectors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sectors_id_seq', 59, true);


--
-- Name: site_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.site_settings_id_seq', 15, true);


--
-- Name: specialties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.specialties_id_seq', 274, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 45, true);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: cities cities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cities
    ADD CONSTRAINT cities_pkey PRIMARY KEY (id);


--
-- Name: college_addresses college_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.college_addresses
    ADD CONSTRAINT college_addresses_pkey PRIMARY KEY (id);


--
-- Name: college_specialties college_specialties_college_id_specialty_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.college_specialties
    ADD CONSTRAINT college_specialties_college_id_specialty_id_key UNIQUE (college_id, specialty_id);


--
-- Name: college_specialties college_specialties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.college_specialties
    ADD CONSTRAINT college_specialties_pkey PRIMARY KEY (id);


--
-- Name: colleges colleges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.colleges
    ADD CONSTRAINT colleges_pkey PRIMARY KEY (id);


--
-- Name: login_logs login_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_logs
    ADD CONSTRAINT login_logs_pkey PRIMARY KEY (id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_filename_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_filename_key UNIQUE (filename);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (id);


--
-- Name: sectors sectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sectors
    ADD CONSTRAINT sectors_pkey PRIMARY KEY (id);


--
-- Name: site_settings site_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_settings
    ADD CONSTRAINT site_settings_pkey PRIMARY KEY (id);


--
-- Name: site_settings site_settings_setting_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_settings
    ADD CONSTRAINT site_settings_setting_key_key UNIQUE (setting_key);


--
-- Name: specialties specialties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialties
    ADD CONSTRAINT specialties_pkey PRIMARY KEY (id);


--
-- Name: specialty_sectors specialty_sectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialty_sectors
    ADD CONSTRAINT specialty_sectors_pkey PRIMARY KEY (specialty_id, sector_id);


--
-- Name: specialty_sectors specialty_sectors_specialty_sector_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialty_sectors
    ADD CONSTRAINT specialty_sectors_specialty_sector_key UNIQUE (specialty_id, sector_id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_login_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_login_key UNIQUE (login);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_audit_logs_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_entity ON public.audit_logs USING btree (entity_type, entity_id);


--
-- Name: idx_audit_logs_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_time ON public.audit_logs USING btree (created_at DESC);


--
-- Name: idx_audit_logs_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_user ON public.audit_logs USING btree (user_id);


--
-- Name: idx_cities_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cities_name ON public.cities USING btree (name);


--
-- Name: idx_college_addresses_college; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_college_addresses_college ON public.college_addresses USING btree (college_id);


--
-- Name: idx_college_specialties_college; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_college_specialties_college ON public.college_specialties USING btree (college_id);


--
-- Name: idx_college_specialties_college_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_college_specialties_college_id ON public.college_specialties USING btree (college_id);


--
-- Name: idx_college_specialties_college_id_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_college_specialties_college_id_active ON public.college_specialties USING btree (college_id, is_active);


--
-- Name: idx_college_specialties_specialty; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_college_specialties_specialty ON public.college_specialties USING btree (specialty_id);


--
-- Name: idx_college_specialties_specialty_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_college_specialties_specialty_id ON public.college_specialties USING btree (specialty_id);


--
-- Name: idx_college_specialties_specialty_id_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_college_specialties_specialty_id_active ON public.college_specialties USING btree (specialty_id, is_active);


--
-- Name: idx_college_specialty_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_college_specialty_search ON public.college_specialties USING btree (college_id, is_active, sort_order);


--
-- Name: idx_colleges_city; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colleges_city ON public.colleges USING btree (city_id);


--
-- Name: idx_colleges_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colleges_name ON public.colleges USING btree (name);


--
-- Name: idx_colleges_professionalitet; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colleges_professionalitet ON public.colleges USING btree (is_professionalitet);


--
-- Name: idx_colleges_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colleges_search ON public.colleges USING gin (to_tsvector('russian'::regconfig, (((name)::text || ' '::text) || COALESCE(description, ''::text))));


--
-- Name: idx_colleges_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colleges_status ON public.colleges USING btree (status);


--
-- Name: idx_login_logs_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_logs_time ON public.login_logs USING btree (login_time);


--
-- Name: idx_login_logs_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_logs_user ON public.login_logs USING btree (user_id, login_time);


--
-- Name: idx_login_security; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_security ON public.login_logs USING btree (user_id, success, login_time DESC);


--
-- Name: idx_sectors_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sectors_active ON public.sectors USING btree (is_active);


--
-- Name: idx_sectors_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sectors_code ON public.sectors USING btree (code);


--
-- Name: idx_sessions_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_expires ON public.user_sessions USING btree (expires_at);


--
-- Name: idx_sessions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_user ON public.user_sessions USING btree (user_id);


--
-- Name: idx_site_settings_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_site_settings_key ON public.site_settings USING btree (setting_key);


--
-- Name: idx_specialties_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_specialties_code ON public.specialties USING btree (code);


--
-- Name: idx_specialties_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_specialties_name ON public.specialties USING btree (name);


--
-- Name: idx_specialties_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_specialties_search ON public.specialties USING gin (to_tsvector('russian'::regconfig, (((name)::text || ' '::text) || COALESCE(description, ''::text))));


--
-- Name: idx_specialties_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_specialties_status ON public.specialties USING btree (status);


--
-- Name: idx_specialties_status_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_specialties_status_code ON public.specialties USING btree (status, code);


--
-- Name: idx_specialty_filter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_specialty_filter ON public.specialties USING btree (status, base_education, form);


--
-- Name: idx_specialty_sectors_sector_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_specialty_sectors_sector_id ON public.specialty_sectors USING btree (sector_id);


--
-- Name: idx_specialty_sectors_specialty_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_specialty_sectors_specialty_id ON public.specialty_sectors USING btree (specialty_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_login; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_login ON public.users USING btree (login);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_role ON public.users USING btree (role_id);


--
-- Name: college_specialties trg_college_specialties_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_college_specialties_updated BEFORE UPDATE ON public.college_specialties FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: colleges trg_colleges_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_colleges_updated BEFORE UPDATE ON public.colleges FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: roles trg_roles_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_roles_updated BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: sectors trg_sectors_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sectors_updated BEFORE UPDATE ON public.sectors FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: site_settings trg_site_settings_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_site_settings_updated BEFORE UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: specialties trg_specialties_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_specialties_updated BEFORE UPDATE ON public.specialties FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users trg_users_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_users_updated BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: college_addresses college_addresses_college_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.college_addresses
    ADD CONSTRAINT college_addresses_college_id_fkey FOREIGN KEY (college_id) REFERENCES public.colleges(id) ON DELETE CASCADE;


--
-- Name: college_specialties college_specialties_college_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.college_specialties
    ADD CONSTRAINT college_specialties_college_id_fkey FOREIGN KEY (college_id) REFERENCES public.colleges(id) ON DELETE CASCADE;


--
-- Name: college_specialties college_specialties_specialty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.college_specialties
    ADD CONSTRAINT college_specialties_specialty_id_fkey FOREIGN KEY (specialty_id) REFERENCES public.specialties(id) ON DELETE CASCADE;


--
-- Name: colleges colleges_city_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.colleges
    ADD CONSTRAINT colleges_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.cities(id);


--
-- Name: colleges fk_colleges_created_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.colleges
    ADD CONSTRAINT fk_colleges_created_by FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: colleges fk_colleges_updated_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.colleges
    ADD CONSTRAINT fk_colleges_updated_by FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: users fk_users_college; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_college FOREIGN KEY (college_id) REFERENCES public.colleges(id) ON DELETE SET NULL;


--
-- Name: login_logs login_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_logs
    ADD CONSTRAINT login_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: site_settings site_settings_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_settings
    ADD CONSTRAINT site_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: specialty_sectors specialty_sectors_sector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialty_sectors
    ADD CONSTRAINT specialty_sectors_sector_id_fkey FOREIGN KEY (sector_id) REFERENCES public.sectors(id) ON DELETE CASCADE;


--
-- Name: specialty_sectors specialty_sectors_specialty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialty_sectors
    ADD CONSTRAINT specialty_sectors_specialty_id_fkey FOREIGN KEY (specialty_id) REFERENCES public.specialties(id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- PostgreSQL database dump complete
--

\unrestrict ZvsJMQUSwa17xNfP5Io3dbaXBx0YeBiu2IcF5zPYTbNH0UsadmPqtnZd9It5ZET

