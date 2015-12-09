--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE accounts (
    id integer NOT NULL,
    name character varying(255),
    address1 character varying(255),
    address2 character varying(255),
    city character varying(255),
    state character varying(255),
    zipcode character varying(255),
    phone character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    stripe_id character varying(255),
    billing_email character varying(255),
    affiliate_id integer DEFAULT (-1) NOT NULL,
    affiliate_time date,
    affiliate_referrer character varying(255),
    brands_carried hstore,
    status integer DEFAULT 0 NOT NULL,
    financial_info hstore
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE accounts_id_seq OWNED BY accounts.id;


--
-- Name: affiliates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE affiliates (
    id integer NOT NULL,
    name character varying(255),
    address character varying(255),
    city character varying(255),
    state character varying(255),
    zipcode character varying(255),
    affiliate_tag character varying(255),
    contact_name character varying(255),
    contact_email character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: affiliates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE affiliates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: affiliates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE affiliates_id_seq OWNED BY affiliates.id;


--
-- Name: appointments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE appointments (
    id integer NOT NULL,
    tire_store_id integer NOT NULL,
    tire_listing_id integer,
    reservation_id integer NOT NULL,
    user_id integer,
    buyer_email character varying(255),
    buyer_phone character varying(255),
    buyer_name character varying(255),
    buyer_address character varying(255) NOT NULL,
    buyer_city character varying(255) NOT NULL,
    buyer_state character varying(255) NOT NULL,
    buyer_zip character varying(255) NOT NULL,
    preferred_contact_path integer NOT NULL,
    services hstore,
    notes text,
    confirmed_flag boolean NOT NULL,
    rejected_flag boolean NOT NULL,
    request_date_primary date NOT NULL,
    request_hour_primary character varying(255) NOT NULL,
    request_date_secondary date NOT NULL,
    request_hour_secondary character varying(255) NOT NULL,
    confirm_date date NOT NULL,
    confirm_hour character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    auto_year_id integer,
    auto_option_id integer,
    auto_model_id integer,
    auto_manufacturer_id integer,
    vehicle_mileage character varying(255),
    quantity integer,
    price integer
);


--
-- Name: appointments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE appointments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE appointments_id_seq OWNED BY appointments.id;


--
-- Name: asset_usages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE asset_usages (
    id integer NOT NULL,
    tire_store_id integer,
    branding_id integer,
    asset_id integer,
    usage_name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: asset_usages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE asset_usages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_usages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE asset_usages_id_seq OWNED BY asset_usages.id;


--
-- Name: assets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assets (
    id integer NOT NULL,
    image_file_name character varying(255),
    image_content_type character varying(255),
    image_file_size integer,
    image_updated_at timestamp without time zone,
    branding_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    url character varying(255),
    caption character varying(255)
);


--
-- Name: assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assets_id_seq OWNED BY assets.id;


--
-- Name: auto_manufacturers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE auto_manufacturers (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: auto_manufacturers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE auto_manufacturers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auto_manufacturers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE auto_manufacturers_id_seq OWNED BY auto_manufacturers.id;


--
-- Name: auto_models; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE auto_models (
    id integer NOT NULL,
    name character varying(255),
    auto_manufacturer_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: auto_models_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE auto_models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auto_models_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE auto_models_id_seq OWNED BY auto_models.id;


--
-- Name: auto_options; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE auto_options (
    id integer NOT NULL,
    name character varying(255),
    auto_year_id integer,
    tire_size_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: auto_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE auto_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auto_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE auto_options_id_seq OWNED BY auto_options.id;


--
-- Name: auto_years; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE auto_years (
    id integer NOT NULL,
    modelyear character varying(255),
    auto_model_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: auto_years_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE auto_years_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auto_years_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE auto_years_id_seq OWNED BY auto_years.id;


--
-- Name: brandings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE brandings (
    id integer NOT NULL,
    tire_store_id integer,
    expiration_date timestamp without time zone,
    listing_html text,
    store_html text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    logo_file_name character varying(255),
    logo_content_type character varying(255),
    logo_file_size integer,
    logo_updated_at timestamp without time zone,
    tab1title character varying(255),
    tab1content text,
    tab2title character varying(255),
    tab2content text,
    tab3title character varying(255),
    tab3content text,
    tab4title character varying(255),
    tab4content text,
    tab5title character varying(255),
    tab5content text,
    fb_page character varying(255),
    twitter character varying(255),
    template_number integer DEFAULT 1,
    slogan character varying(255),
    slogan_description character varying(255),
    properties hstore
);


--
-- Name: brandings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE brandings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: brandings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE brandings_id_seq OWNED BY brandings.id;


--
-- Name: capabilities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE capabilities (
    id integer NOT NULL,
    name character varying(255),
    key character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: capabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE capabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: capabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE capabilities_id_seq OWNED BY capabilities.id;


--
-- Name: cl_templates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cl_templates (
    id integer NOT NULL,
    tire_store_id integer DEFAULT 0,
    account_id integer DEFAULT 0,
    title character varying(255),
    body character varying(4096),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cl_email character varying(255),
    cl_password character varying(255),
    cl_posting_page character varying(255),
    cl_subarea character varying(255),
    cl_specific_location character varying(255),
    cl_login_page character varying(255),
    cl_logout_page character varying(255),
    cl_login_email_fieldname character varying(255),
    cl_login_password_fieldname character varying(255),
    cl_ad_name character varying(255),
    cl_ad_value character varying(255),
    cl_category_name character varying(255),
    cl_category_value character varying(255),
    cl_title_field character varying(255),
    cl_price_field character varying(255),
    cl_specific_location_field character varying(255),
    cl_actions text,
    title_new_listings character varying(255),
    body_new_listings character varying(4096)
);


--
-- Name: cl_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cl_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cl_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cl_templates_id_seq OWNED BY cl_templates.id;


--
-- Name: contracts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contracts (
    id integer NOT NULL,
    account_id integer,
    expiration_date date,
    contract_amount integer,
    max_monthly_listings integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    start_date date,
    plan_id integer,
    active boolean DEFAULT false,
    quantity integer DEFAULT 1,
    bill_cc boolean,
    billing_type integer,
    bill_date timestamp without time zone
);


--
-- Name: contracts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contracts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contracts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contracts_id_seq OWNED BY contracts.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    queue character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: devices; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE devices (
    id integer NOT NULL,
    user_id integer NOT NULL,
    token character varying(255) NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    platform character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id integer,
    tire_store_id integer,
    email character varying(255)
);


--
-- Name: devices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE devices_id_seq OWNED BY devices.id;


--
-- Name: distributor_imports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE distributor_imports (
    id integer NOT NULL,
    uuid character varying(255) NOT NULL,
    distributor_tier character varying(255) NOT NULL,
    distributor_id integer NOT NULL,
    warehouse_id integer NOT NULL,
    store_name character varying(255),
    store_address1 character varying(255),
    store_address2 character varying(255),
    store_city character varying(255),
    store_state character varying(255),
    store_zipcode character varying(255),
    store_phone character varying(255),
    store_contact_first_name character varying(255),
    store_contact_last_name character varying(255),
    store_contact_email character varying(255),
    latitude double precision,
    longitude double precision,
    clicked boolean,
    clicked_at timestamp without time zone,
    registered boolean,
    registered_at timestamp without time zone,
    other_information hstore,
    tire_store_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: distributor_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE distributor_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: distributor_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE distributor_imports_id_seq OWNED BY distributor_imports.id;


--
-- Name: distributors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE distributors (
    id integer NOT NULL,
    distributor_name character varying(255),
    address character varying(255),
    city character varying(255),
    state character varying(255),
    zipcode character varying(255),
    contact_name character varying(255),
    contact_email character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tire_manufacturers hstore
);


--
-- Name: distributors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE distributors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: distributors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE distributors_id_seq OWNED BY distributors.id;


--
-- Name: generic_tire_listings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE generic_tire_listings (
    id integer NOT NULL,
    remaining_tread_min integer,
    remaining_tread_max integer,
    treadlife_min integer,
    treadlife_max integer,
    tire_store_id integer,
    quantity integer,
    includes_mounting boolean,
    warranty_days integer,
    tire_sizes hstore,
    currency character varying(255),
    price integer,
    mounting_price integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: generic_tire_listings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE generic_tire_listings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: generic_tire_listings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE generic_tire_listings_id_seq OWNED BY generic_tire_listings.id;


--
-- Name: impressions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE impressions (
    id integer NOT NULL,
    impressionable_type character varying(255),
    impressionable_id integer,
    user_id integer,
    controller_name character varying(255),
    action_name character varying(255),
    view_name character varying(255),
    request_hash character varying(255),
    ip_address character varying(255),
    session_hash character varying(255),
    message text,
    referrer text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: impressions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE impressions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: impressions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE impressions_id_seq OWNED BY impressions.id;


--
-- Name: installation_costs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE installation_costs (
    id integer NOT NULL,
    account_id integer,
    tire_store_id integer,
    ea_install_price integer,
    min_wheel_diameter double precision,
    max_wheel_diameter double precision,
    other_properties hstore,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: installation_costs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE installation_costs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: installation_costs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE installation_costs_id_seq OWNED BY installation_costs.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notifications (
    id integer NOT NULL,
    user_id integer,
    account_id integer,
    admin_only boolean,
    super_user_only boolean,
    expiration_date timestamp without time zone,
    remaining_views integer,
    message character varying(255),
    title character varying(255),
    sticky boolean,
    visible_time integer,
    image character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notifications_id_seq OWNED BY notifications.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE orders (
    id integer NOT NULL,
    user_id integer,
    tire_listing_id integer,
    appointment_id integer,
    tire_quantity integer,
    tire_ea_price integer,
    tire_ea_install_price integer,
    th_user_fee integer,
    sales_tax_collected integer,
    th_processing_fee integer,
    transfer_id character varying(255),
    transfer_amount integer,
    other_properties hstore,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    buyer_email character varying(255) NOT NULL,
    buyer_name character varying(255) NOT NULL,
    buyer_address1 character varying(255) NOT NULL,
    buyer_address2 character varying(255),
    buyer_city character varying(255) NOT NULL,
    buyer_state character varying(255) NOT NULL,
    buyer_zip character varying(255) NOT NULL,
    stripe_properties hstore,
    status integer NOT NULL,
    inv_status integer DEFAULT 20 NOT NULL,
    th_sales_tax_collected integer DEFAULT 0 NOT NULL,
    buyer_phone character varying(255)
);


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE orders_id_seq OWNED BY orders.id;


--
-- Name: plan_capabilities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE plan_capabilities (
    id integer NOT NULL,
    plan_id integer,
    capability_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: plan_capabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plan_capabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plan_capabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plan_capabilities_id_seq OWNED BY plan_capabilities.id;


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE plans (
    id integer NOT NULL,
    name character varying(255),
    default_num_listings integer,
    stripe_plan character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plans_id_seq OWNED BY plans.id;


--
-- Name: promotions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE promotions (
    id integer NOT NULL,
    promotion_type character varying(255),
    tire_manufacturer_id integer,
    tire_model_infos hstore,
    account_id integer,
    tire_store_ids hstore,
    start_date date,
    end_date date,
    description text,
    promo_type integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    promo_attachment_file_name character varying(255),
    promo_attachment_content_type character varying(255),
    promo_attachment_file_size integer,
    promo_attachment_updated_at timestamp without time zone,
    promo_image_file_name character varying(255),
    promo_image_content_type character varying(255),
    promo_image_file_size integer,
    promo_image_updated_at timestamp without time zone,
    uuid character varying(255),
    promo_url character varying(255),
    promo_level character varying(255),
    promo_amount_min double precision,
    promo_amount_max double precision,
    tire_sizes hstore,
    promo_name character varying(255),
    new_or_used character varying(255),
    promotion_key character varying(255)
);


--
-- Name: promotions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE promotions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE promotions_id_seq OWNED BY promotions.id;


--
-- Name: push_configurations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE push_configurations (
    id integer NOT NULL,
    type character varying(255) NOT NULL,
    app character varying(255) NOT NULL,
    properties text,
    enabled boolean DEFAULT false NOT NULL,
    connections integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: push_configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE push_configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: push_configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE push_configurations_id_seq OWNED BY push_configurations.id;


--
-- Name: push_feedback; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE push_feedback (
    id integer NOT NULL,
    app character varying(255) NOT NULL,
    device character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    follow_up character varying(255) NOT NULL,
    failed_at timestamp without time zone NOT NULL,
    processed boolean DEFAULT false NOT NULL,
    processed_at timestamp without time zone,
    properties text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: push_feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE push_feedback_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: push_feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE push_feedback_id_seq OWNED BY push_feedback.id;


--
-- Name: push_message_details; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE push_message_details (
    id integer NOT NULL,
    device character varying(255) NOT NULL,
    properties text,
    guid character varying(255) NOT NULL,
    push_message_id integer NOT NULL,
    tire_store_id integer NOT NULL,
    has_been_read boolean DEFAULT false NOT NULL,
    last_read_date timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: push_message_details_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE push_message_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: push_message_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE push_message_details_id_seq OWNED BY push_message_details.id;


--
-- Name: push_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE push_messages (
    id integer NOT NULL,
    app character varying(255) NOT NULL,
    device character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    properties text,
    delivered boolean DEFAULT false NOT NULL,
    delivered_at timestamp without time zone,
    failed boolean DEFAULT false NOT NULL,
    failed_at timestamp without time zone,
    error_code integer,
    error_description character varying(255),
    deliver_after timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: push_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE push_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: push_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE push_messages_id_seq OWNED BY push_messages.id;


--
-- Name: redirect_rules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE redirect_rules (
    id integer NOT NULL,
    source character varying(255) NOT NULL,
    source_is_regex boolean DEFAULT false NOT NULL,
    source_is_case_sensitive boolean DEFAULT false NOT NULL,
    destination character varying(255) NOT NULL,
    active boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: redirect_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE redirect_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redirect_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE redirect_rules_id_seq OWNED BY redirect_rules.id;


--
-- Name: request_environment_rules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE request_environment_rules (
    id integer NOT NULL,
    redirect_rule_id integer NOT NULL,
    environment_key_name character varying(255) NOT NULL,
    environment_value character varying(255) NOT NULL,
    environment_value_is_regex boolean DEFAULT false NOT NULL,
    environment_value_is_case_sensitive boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: request_environment_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE request_environment_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_environment_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE request_environment_rules_id_seq OWNED BY request_environment_rules.id;


--
-- Name: reservations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reservations (
    id integer NOT NULL,
    user_id integer,
    tire_listing_id integer,
    buyer_email character varying(255),
    seller_email character varying(255),
    name character varying(255),
    address character varying(255),
    city character varying(255),
    state character varying(255),
    zip character varying(255),
    phone character varying(255),
    expiration_date timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    quantity integer,
    price integer,
    tire_manufacturer_id integer,
    tire_model_id integer,
    tire_size_id integer
);


--
-- Name: reservations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reservations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reservations_id_seq OWNED BY reservations.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: scrape_tire_stores; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE scrape_tire_stores (
    id integer NOT NULL,
    name character varying(255),
    store_id integer,
    additional_info character varying(255),
    address1 character varying(255),
    address2 character varying(255),
    city character varying(255),
    state character varying(255),
    zipcode character varying(255),
    phone character varying(255),
    scraper_id integer,
    latitude double precision,
    longitude double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    google_properties hstore
);


--
-- Name: scrape_tire_stores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE scrape_tire_stores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scrape_tire_stores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE scrape_tire_stores_id_seq OWNED BY scrape_tire_stores.id;


--
-- Name: services; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE services (
    id integer NOT NULL,
    service_name character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE services_id_seq OWNED BY services.id;


--
-- Name: simple_captcha_data; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE simple_captcha_data (
    id integer NOT NULL,
    key character varying(40),
    value character varying(6),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: simple_captcha_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE simple_captcha_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: simple_captcha_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE simple_captcha_data_id_seq OWNED BY simple_captcha_data.id;


--
-- Name: tire_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_categories (
    id integer NOT NULL,
    category_name character varying(255),
    category_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tire_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_categories_id_seq OWNED BY tire_categories.id;


--
-- Name: tire_listings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_listings (
    id integer NOT NULL,
    treadlife integer,
    price integer NOT NULL,
    description character varying(4096),
    teaser character varying(255),
    tire_store_id integer,
    tire_size_id integer,
    latitude double precision,
    longitude double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    source character varying(512),
    tire_manufacturer_id integer,
    includes_mounting boolean,
    warranty_days integer,
    quantity integer,
    orig_cost integer,
    crosspost_craigslist boolean,
    photo1_file_name character varying(255),
    photo1_content_type character varying(255),
    photo1_file_size integer,
    photo1_updated_at timestamp without time zone,
    photo2_file_name character varying(255),
    photo2_content_type character varying(255),
    photo2_file_size integer,
    photo2_updated_at timestamp without time zone,
    photo3_file_name character varying(255),
    photo3_content_type character varying(255),
    photo3_file_size integer,
    photo3_updated_at timestamp without time zone,
    photo4_file_name character varying(255),
    photo4_content_type character varying(255),
    photo4_file_size integer,
    photo4_updated_at timestamp without time zone,
    tire_model_id integer,
    remaining_tread double precision,
    original_tread double precision,
    currency character varying(255) DEFAULT 'USD'::character varying,
    is_new boolean DEFAULT false,
    start_date date,
    expiration_date date,
    stock_number character varying(255),
    sell_as_set_only boolean DEFAULT true,
    redirect_to character varying(255),
    is_generic boolean DEFAULT false,
    generic_tire_listing_id integer DEFAULT (-1),
    willing_to_ship integer DEFAULT 0,
    status integer DEFAULT 0 NOT NULL,
    price_source integer,
    warehouse_price_id integer,
    price_updated_at timestamp without time zone
);


--
-- Name: tire_listings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_listings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_listings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_listings_id_seq OWNED BY tire_listings.id;


--
-- Name: tire_manufacturers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_manufacturers (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tgp_brand_id integer DEFAULT 0
);


--
-- Name: tire_manufacturers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_manufacturers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_manufacturers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_manufacturers_id_seq OWNED BY tire_manufacturers.id;


--
-- Name: tire_model_infos; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_model_infos (
    id integer NOT NULL,
    tire_manufacturer_id integer,
    tire_model_name character varying(255),
    photo1_url character varying(255),
    photo2_url character varying(255),
    photo3_url character varying(255),
    photo4_url character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    stock_photo1_file_name character varying(255),
    stock_photo1_content_type character varying(255),
    stock_photo1_file_size integer,
    stock_photo1_updated_at timestamp without time zone,
    stock_photo2_file_name character varying(255),
    stock_photo2_content_type character varying(255),
    stock_photo2_file_size integer,
    stock_photo2_updated_at timestamp without time zone,
    stock_photo3_file_name character varying(255),
    stock_photo3_content_type character varying(255),
    stock_photo3_file_size integer,
    stock_photo3_updated_at timestamp without time zone,
    stock_photo4_file_name character varying(255),
    stock_photo4_content_type character varying(255),
    stock_photo4_file_size integer,
    stock_photo4_updated_at timestamp without time zone,
    description text,
    tgp_model_id integer DEFAULT 0,
    tgp_features hstore,
    tgp_benefits hstore,
    tgp_other_attributes hstore
);


--
-- Name: tire_model_infos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_model_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_model_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_model_infos_id_seq OWNED BY tire_model_infos.id;


--
-- Name: tire_model_pricings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_model_pricings (
    id integer NOT NULL,
    tire_model_id integer,
    source character varying(255),
    orig_source character varying(255),
    source_url character varying(255),
    price_type character varying(255),
    tire_ea_price double precision,
    other_properties hstore,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    zipcode integer,
    longitude numeric,
    latitude numeric
);


--
-- Name: tire_model_pricings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_model_pricings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_model_pricings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_model_pricings_id_seq OWNED BY tire_model_pricings.id;


--
-- Name: tire_models; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_models (
    id integer NOT NULL,
    tire_manufacturer_id integer,
    tire_size_id integer,
    load_index integer,
    speed_rating character varying(255),
    rim_width double precision,
    tread_depth double precision,
    utqg_temp character varying(255),
    utqg_treadwear integer,
    utqg_traction character varying(255),
    sidewall character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying(255),
    orig_cost integer,
    tire_category_id integer DEFAULT 0,
    product_code character varying(255) DEFAULT ''::character varying,
    construction character varying(255),
    weight double precision,
    warranty_miles integer,
    tire_code character varying(255),
    tire_model_info_id integer DEFAULT (-1),
    manu_part_num character varying(255) DEFAULT ''::character varying,
    skus hstore,
    ply character varying(255),
    diameter character varying(255),
    revs_per_mile character varying(255),
    min_rim_width double precision,
    max_rim_width double precision,
    single_max_load_pounds integer,
    dual_max_load_pounds integer,
    single_max_psi integer,
    dual_max_psi integer,
    section_width double precision,
    weight_pounds double precision,
    active boolean,
    embedded_speed character varying(255),
    load_description character varying(255),
    tgp_category_id integer,
    run_flat_id integer,
    tgp_tire_type_id integer,
    dual_load_index character varying(255),
    suffix character varying(255),
    tgp_model_id integer DEFAULT 0
);


--
-- Name: tire_models_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_models_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_models_id_seq OWNED BY tire_models.id;


--
-- Name: tire_searches; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_searches (
    id integer NOT NULL,
    auto_manufacturer_id integer,
    auto_model_id integer,
    auto_year_id integer,
    auto_options_id integer,
    tire_size_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    locationstr character varying(255),
    latitude double precision,
    longitude double precision,
    radius integer DEFAULT 20,
    quantity integer DEFAULT 0,
    saved_search_frequency character varying(255),
    saved_search_dow integer,
    send_text boolean DEFAULT false,
    text_phone character varying(255),
    new_or_used character varying(255) DEFAULT 'b'::character varying,
    tire_model_id integer,
    tire_manufacturer_id integer
);


--
-- Name: tire_searches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_searches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_searches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_searches_id_seq OWNED BY tire_searches.id;


--
-- Name: tire_sizes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_sizes (
    id integer NOT NULL,
    sizestr character varying(255),
    diameter integer,
    ratio integer,
    wheeldiameter numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tire_sizes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_sizes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_sizes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_sizes_id_seq OWNED BY tire_sizes.id;


--
-- Name: tire_store_markups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_store_markups (
    id integer NOT NULL,
    tire_store_id integer,
    warehouse_id integer,
    tire_manufacturer_id integer,
    tire_model_info_id integer,
    tire_size_id integer,
    tire_model_id integer,
    markup_type integer,
    markup_pct double precision,
    markup_dollars integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tire_category_id integer
);


--
-- Name: tire_store_markups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_store_markups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_store_markups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_store_markups_id_seq OWNED BY tire_store_markups.id;


--
-- Name: tire_store_warehouse_tiers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_store_warehouse_tiers (
    id integer NOT NULL,
    tire_store_id integer,
    warehouse_id integer,
    warehouse_tier_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tire_store_warehouse_tiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_store_warehouse_tiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_store_warehouse_tiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_store_warehouse_tiers_id_seq OWNED BY tire_store_warehouse_tiers.id;


--
-- Name: tire_store_warehouses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_store_warehouses (
    id integer NOT NULL,
    tire_store_id integer,
    distributor_id integer,
    warehouse_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tire_store_warehouses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_store_warehouses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_store_warehouses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_store_warehouses_id_seq OWNED BY tire_store_warehouses.id;


--
-- Name: tire_stores; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_stores (
    id integer NOT NULL,
    name character varying(255),
    address1 character varying(255),
    address2 character varying(255),
    city character varying(255),
    state character varying(255),
    zipcode character varying(255),
    phone character varying(255),
    account_id integer,
    latitude double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    longitude double precision,
    contact_email character varying(255),
    private_seller boolean DEFAULT false,
    hide_phone boolean DEFAULT false,
    send_text boolean DEFAULT false,
    text_phone character varying(255),
    domain character varying(255),
    colors hstore,
    authorized_promotion_tire_manufacturer_ids hstore,
    affiliate_id integer DEFAULT (-1) NOT NULL,
    affiliate_time date,
    affiliate_referrer character varying(255),
    willing_to_ship integer DEFAULT 0,
    brands_carried hstore,
    google_properties hstore,
    status integer DEFAULT 0 NOT NULL,
    financial_info hstore,
    other_properties hstore
);


--
-- Name: tire_stores_distributors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tire_stores_distributors (
    id integer NOT NULL,
    tire_store_id integer,
    distributor_id integer,
    tire_manufacturers hstore,
    frequency_days integer,
    next_run_time timestamp without time zone,
    last_run_time timestamp without time zone,
    records_created integer,
    records_updated integer,
    records_untouched integer,
    records_deleted integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    username character varying(255),
    password_digest character varying(255)
);


--
-- Name: tire_stores_distributors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_stores_distributors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_stores_distributors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_stores_distributors_id_seq OWNED BY tire_stores_distributors.id;


--
-- Name: tire_stores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tire_stores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tire_stores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tire_stores_id_seq OWNED BY tire_stores.id;


--
-- Name: tires; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tires (
    id integer NOT NULL,
    year integer,
    sidewall character varying(255),
    speedrating character varying(255),
    performancecategory character varying(255),
    tire_manufacturer_id integer,
    tire_size_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tires_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tires_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tires_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tires_id_seq OWNED BY tires.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    email character varying(255),
    password_digest character varying(255),
    phone character varying(255),
    status integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remember_token character varying(255),
    admin integer DEFAULT 0,
    account_id integer DEFAULT 0,
    tireseller boolean DEFAULT false,
    password_reset_token character varying(255),
    password_reset_sent_at timestamp without time zone,
    mobile_token character varying(255),
    tire_store_id integer,
    affiliate_id integer DEFAULT (-1) NOT NULL,
    affiliate_time date,
    affiliate_referrer character varying(255),
    other_properties hstore,
    address1 character varying(255),
    address2 character varying(255),
    city character varying(255),
    state character varying(255),
    zipcode character varying(255)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: warehouse_prices; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE warehouse_prices (
    id integer NOT NULL,
    warehouse_id integer,
    warehouse_tier_id integer,
    tire_model_id integer,
    base_price_warehouse_price_id integer,
    base_price integer,
    cost_pct_from_base double precision,
    wholesale_price integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: warehouse_prices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE warehouse_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE warehouse_prices_id_seq OWNED BY warehouse_prices.id;


--
-- Name: warehouse_tiers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE warehouse_tiers (
    id integer NOT NULL,
    warehouse_id integer,
    tier_name character varying(255),
    cost_pct_from_base double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: warehouse_tiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE warehouse_tiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_tiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE warehouse_tiers_id_seq OWNED BY warehouse_tiers.id;


--
-- Name: warehouses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE warehouses (
    id integer NOT NULL,
    distributor_id integer,
    name character varying(255),
    address1 character varying(255),
    address2 character varying(255),
    city character varying(255),
    state character varying(255),
    zipcode character varying(255),
    contact_name character varying(255),
    contact_email character varying(255),
    contact_phone character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: warehouses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE warehouses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE warehouses_id_seq OWNED BY warehouses.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts ALTER COLUMN id SET DEFAULT nextval('accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY affiliates ALTER COLUMN id SET DEFAULT nextval('affiliates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY appointments ALTER COLUMN id SET DEFAULT nextval('appointments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY asset_usages ALTER COLUMN id SET DEFAULT nextval('asset_usages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY assets ALTER COLUMN id SET DEFAULT nextval('assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY auto_manufacturers ALTER COLUMN id SET DEFAULT nextval('auto_manufacturers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY auto_models ALTER COLUMN id SET DEFAULT nextval('auto_models_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY auto_options ALTER COLUMN id SET DEFAULT nextval('auto_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY auto_years ALTER COLUMN id SET DEFAULT nextval('auto_years_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY brandings ALTER COLUMN id SET DEFAULT nextval('brandings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY capabilities ALTER COLUMN id SET DEFAULT nextval('capabilities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cl_templates ALTER COLUMN id SET DEFAULT nextval('cl_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contracts ALTER COLUMN id SET DEFAULT nextval('contracts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY devices ALTER COLUMN id SET DEFAULT nextval('devices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY distributor_imports ALTER COLUMN id SET DEFAULT nextval('distributor_imports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY distributors ALTER COLUMN id SET DEFAULT nextval('distributors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY generic_tire_listings ALTER COLUMN id SET DEFAULT nextval('generic_tire_listings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY impressions ALTER COLUMN id SET DEFAULT nextval('impressions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY installation_costs ALTER COLUMN id SET DEFAULT nextval('installation_costs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY orders ALTER COLUMN id SET DEFAULT nextval('orders_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY plan_capabilities ALTER COLUMN id SET DEFAULT nextval('plan_capabilities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY plans ALTER COLUMN id SET DEFAULT nextval('plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY promotions ALTER COLUMN id SET DEFAULT nextval('promotions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY push_configurations ALTER COLUMN id SET DEFAULT nextval('push_configurations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY push_feedback ALTER COLUMN id SET DEFAULT nextval('push_feedback_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY push_message_details ALTER COLUMN id SET DEFAULT nextval('push_message_details_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY push_messages ALTER COLUMN id SET DEFAULT nextval('push_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY redirect_rules ALTER COLUMN id SET DEFAULT nextval('redirect_rules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY request_environment_rules ALTER COLUMN id SET DEFAULT nextval('request_environment_rules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reservations ALTER COLUMN id SET DEFAULT nextval('reservations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY scrape_tire_stores ALTER COLUMN id SET DEFAULT nextval('scrape_tire_stores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY services ALTER COLUMN id SET DEFAULT nextval('services_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY simple_captcha_data ALTER COLUMN id SET DEFAULT nextval('simple_captcha_data_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_categories ALTER COLUMN id SET DEFAULT nextval('tire_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_listings ALTER COLUMN id SET DEFAULT nextval('tire_listings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_manufacturers ALTER COLUMN id SET DEFAULT nextval('tire_manufacturers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_model_infos ALTER COLUMN id SET DEFAULT nextval('tire_model_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_model_pricings ALTER COLUMN id SET DEFAULT nextval('tire_model_pricings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_models ALTER COLUMN id SET DEFAULT nextval('tire_models_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_searches ALTER COLUMN id SET DEFAULT nextval('tire_searches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_sizes ALTER COLUMN id SET DEFAULT nextval('tire_sizes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_store_markups ALTER COLUMN id SET DEFAULT nextval('tire_store_markups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_store_warehouse_tiers ALTER COLUMN id SET DEFAULT nextval('tire_store_warehouse_tiers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_store_warehouses ALTER COLUMN id SET DEFAULT nextval('tire_store_warehouses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_stores ALTER COLUMN id SET DEFAULT nextval('tire_stores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tire_stores_distributors ALTER COLUMN id SET DEFAULT nextval('tire_stores_distributors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tires ALTER COLUMN id SET DEFAULT nextval('tires_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouse_prices ALTER COLUMN id SET DEFAULT nextval('warehouse_prices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouse_tiers ALTER COLUMN id SET DEFAULT nextval('warehouse_tiers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouses ALTER COLUMN id SET DEFAULT nextval('warehouses_id_seq'::regclass);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: affiliates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY affiliates
    ADD CONSTRAINT affiliates_pkey PRIMARY KEY (id);


--
-- Name: appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- Name: asset_usages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY asset_usages
    ADD CONSTRAINT asset_usages_pkey PRIMARY KEY (id);


--
-- Name: assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: auto_manufacturers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY auto_manufacturers
    ADD CONSTRAINT auto_manufacturers_pkey PRIMARY KEY (id);


--
-- Name: auto_models_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY auto_models
    ADD CONSTRAINT auto_models_pkey PRIMARY KEY (id);


--
-- Name: auto_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY auto_options
    ADD CONSTRAINT auto_options_pkey PRIMARY KEY (id);


--
-- Name: auto_years_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY auto_years
    ADD CONSTRAINT auto_years_pkey PRIMARY KEY (id);


--
-- Name: brandings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY brandings
    ADD CONSTRAINT brandings_pkey PRIMARY KEY (id);


--
-- Name: capabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY capabilities
    ADD CONSTRAINT capabilities_pkey PRIMARY KEY (id);


--
-- Name: cl_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cl_templates
    ADD CONSTRAINT cl_templates_pkey PRIMARY KEY (id);


--
-- Name: contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: distributor_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY distributor_imports
    ADD CONSTRAINT distributor_imports_pkey PRIMARY KEY (id);


--
-- Name: distributors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY distributors
    ADD CONSTRAINT distributors_pkey PRIMARY KEY (id);


--
-- Name: generic_tire_listings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY generic_tire_listings
    ADD CONSTRAINT generic_tire_listings_pkey PRIMARY KEY (id);


--
-- Name: impressions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY impressions
    ADD CONSTRAINT impressions_pkey PRIMARY KEY (id);


--
-- Name: installation_costs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY installation_costs
    ADD CONSTRAINT installation_costs_pkey PRIMARY KEY (id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: plan_capabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY plan_capabilities
    ADD CONSTRAINT plan_capabilities_pkey PRIMARY KEY (id);


--
-- Name: plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: promotions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY promotions
    ADD CONSTRAINT promotions_pkey PRIMARY KEY (id);


--
-- Name: push_configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY push_configurations
    ADD CONSTRAINT push_configurations_pkey PRIMARY KEY (id);


--
-- Name: push_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY push_feedback
    ADD CONSTRAINT push_feedback_pkey PRIMARY KEY (id);


--
-- Name: push_message_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY push_message_details
    ADD CONSTRAINT push_message_details_pkey PRIMARY KEY (id);


--
-- Name: push_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY push_messages
    ADD CONSTRAINT push_messages_pkey PRIMARY KEY (id);


--
-- Name: redirect_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY redirect_rules
    ADD CONSTRAINT redirect_rules_pkey PRIMARY KEY (id);


--
-- Name: request_environment_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY request_environment_rules
    ADD CONSTRAINT request_environment_rules_pkey PRIMARY KEY (id);


--
-- Name: reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);


--
-- Name: scrape_tire_stores_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scrape_tire_stores
    ADD CONSTRAINT scrape_tire_stores_pkey PRIMARY KEY (id);


--
-- Name: services_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: simple_captcha_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY simple_captcha_data
    ADD CONSTRAINT simple_captcha_data_pkey PRIMARY KEY (id);


--
-- Name: tire_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_categories
    ADD CONSTRAINT tire_categories_pkey PRIMARY KEY (id);


--
-- Name: tire_listings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_listings
    ADD CONSTRAINT tire_listings_pkey PRIMARY KEY (id);


--
-- Name: tire_manufacturers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_manufacturers
    ADD CONSTRAINT tire_manufacturers_pkey PRIMARY KEY (id);


--
-- Name: tire_model_infos_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_model_infos
    ADD CONSTRAINT tire_model_infos_pkey PRIMARY KEY (id);


--
-- Name: tire_model_pricings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_model_pricings
    ADD CONSTRAINT tire_model_pricings_pkey PRIMARY KEY (id);


--
-- Name: tire_models_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_models
    ADD CONSTRAINT tire_models_pkey PRIMARY KEY (id);


--
-- Name: tire_searches_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_searches
    ADD CONSTRAINT tire_searches_pkey PRIMARY KEY (id);


--
-- Name: tire_sizes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_sizes
    ADD CONSTRAINT tire_sizes_pkey PRIMARY KEY (id);


--
-- Name: tire_store_markups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_store_markups
    ADD CONSTRAINT tire_store_markups_pkey PRIMARY KEY (id);


--
-- Name: tire_store_warehouse_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_store_warehouse_tiers
    ADD CONSTRAINT tire_store_warehouse_tiers_pkey PRIMARY KEY (id);


--
-- Name: tire_store_warehouses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_store_warehouses
    ADD CONSTRAINT tire_store_warehouses_pkey PRIMARY KEY (id);


--
-- Name: tire_stores_distributors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_stores_distributors
    ADD CONSTRAINT tire_stores_distributors_pkey PRIMARY KEY (id);


--
-- Name: tire_stores_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tire_stores
    ADD CONSTRAINT tire_stores_pkey PRIMARY KEY (id);


--
-- Name: tires_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tires
    ADD CONSTRAINT tires_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: warehouse_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY warehouse_prices
    ADD CONSTRAINT warehouse_prices_pkey PRIMARY KEY (id);


--
-- Name: warehouse_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY warehouse_tiers
    ADD CONSTRAINT warehouse_tiers_pkey PRIMARY KEY (id);


--
-- Name: warehouses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY warehouses
    ADD CONSTRAINT warehouses_pkey PRIMARY KEY (id);


--
-- Name: accounts_status_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX accounts_status_index ON accounts USING btree (status);


--
-- Name: brandings_properties; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX brandings_properties ON brandings USING gin (properties);


--
-- Name: controlleraction_ip_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX controlleraction_ip_index ON impressions USING btree (controller_name, action_name, ip_address);


--
-- Name: controlleraction_request_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX controlleraction_request_index ON impressions USING btree (controller_name, action_name, request_hash);


--
-- Name: controlleraction_session_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX controlleraction_session_index ON impressions USING btree (controller_name, action_name, session_hash);


--
-- Name: idx_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_key ON simple_captcha_data USING btree (key);


--
-- Name: impressionable_type_message_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX impressionable_type_message_index ON impressions USING btree (impressionable_type, message, impressionable_id);


--
-- Name: index_distributor_imports_on_uuid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_distributor_imports_on_uuid ON distributor_imports USING btree (uuid);


--
-- Name: index_impressions_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_impressions_on_user_id ON impressions USING btree (user_id);


--
-- Name: index_notifications_on_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_notifications_on_account_id ON notifications USING btree (account_id);


--
-- Name: index_notifications_on_expiration_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_notifications_on_expiration_date ON notifications USING btree (expiration_date);


--
-- Name: index_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_notifications_on_user_id ON notifications USING btree (user_id);


--
-- Name: index_orders_on_buyer_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_orders_on_buyer_email ON orders USING btree (buyer_email);


--
-- Name: index_orders_on_tire_listing_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_orders_on_tire_listing_id ON orders USING btree (tire_listing_id);


--
-- Name: index_push_feedback_on_processed; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_push_feedback_on_processed ON push_feedback USING btree (processed);


--
-- Name: index_push_message_details_on_guid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_push_message_details_on_guid ON push_message_details USING btree (guid);


--
-- Name: index_push_message_details_on_has_been_read_and_last_read_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_push_message_details_on_has_been_read_and_last_read_date ON push_message_details USING btree (has_been_read, last_read_date);


--
-- Name: index_push_message_details_on_push_message_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_push_message_details_on_push_message_id ON push_message_details USING btree (push_message_id);


--
-- Name: index_push_messages_on_delivered_and_failed_and_deliver_after; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_push_messages_on_delivered_and_failed_and_deliver_after ON push_messages USING btree (delivered, failed, deliver_after);


--
-- Name: index_redirect_rules_on_active; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_redirect_rules_on_active ON redirect_rules USING btree (active);


--
-- Name: index_redirect_rules_on_source; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_redirect_rules_on_source ON redirect_rules USING btree (source);


--
-- Name: index_redirect_rules_on_source_is_case_sensitive; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_redirect_rules_on_source_is_case_sensitive ON redirect_rules USING btree (source_is_case_sensitive);


--
-- Name: index_redirect_rules_on_source_is_regex; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_redirect_rules_on_source_is_regex ON redirect_rules USING btree (source_is_regex);


--
-- Name: index_request_environment_rules_on_redirect_rule_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_request_environment_rules_on_redirect_rule_id ON request_environment_rules USING btree (redirect_rule_id);


--
-- Name: index_tire_listings_on_tire_store_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tire_listings_on_tire_store_id ON tire_listings USING btree (tire_store_id);


--
-- Name: index_tire_listings_on_tire_store_id_and_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tire_listings_on_tire_store_id_and_updated_at ON tire_listings USING btree (tire_store_id, updated_at);


--
-- Name: index_tire_model_pricings_on_tire_model_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tire_model_pricings_on_tire_model_id ON tire_model_pricings USING btree (tire_model_id);


--
-- Name: index_tire_store_markups_on_tire_store_id_and_warehouse_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tire_store_markups_on_tire_store_id_and_warehouse_id ON tire_store_markups USING btree (tire_store_id, warehouse_id);


--
-- Name: index_tire_store_warehouses_on_tire_store_id_and_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_tire_store_warehouses_on_tire_store_id_and_distributor_id ON tire_store_warehouses USING btree (tire_store_id, distributor_id);


--
-- Name: index_tire_stores_distributors_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tire_stores_distributors_on_distributor_id ON tire_stores_distributors USING btree (distributor_id);


--
-- Name: index_tire_stores_distributors_on_tire_store_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tire_stores_distributors_on_tire_store_id ON tire_stores_distributors USING btree (tire_store_id);


--
-- Name: index_tire_stores_on_domain; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tire_stores_on_domain ON tire_stores USING btree (domain);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_remember_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_remember_token ON users USING btree (remember_token);


--
-- Name: index_warehouse_tiers_on_warehouse_id_and_tier_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_warehouse_tiers_on_warehouse_id_and_tier_name ON warehouse_tiers USING btree (warehouse_id, tier_name);


--
-- Name: index_warehouses_on_distributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_warehouses_on_distributor_id ON warehouses USING btree (distributor_id);


--
-- Name: poly_ip_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX poly_ip_index ON impressions USING btree (impressionable_type, impressionable_id, ip_address);


--
-- Name: poly_request_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX poly_request_index ON impressions USING btree (impressionable_type, impressionable_id, request_hash);


--
-- Name: poly_session_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX poly_session_index ON impressions USING btree (impressionable_type, impressionable_id, session_hash);


--
-- Name: promotions_tire_manufacturer_ids; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX promotions_tire_manufacturer_ids ON tire_stores USING gin (authorized_promotion_tire_manufacturer_ids);


--
-- Name: promotions_tire_model_infos; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX promotions_tire_model_infos ON promotions USING gin (tire_model_infos);


--
-- Name: promotions_tire_size_ids; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX promotions_tire_size_ids ON promotions USING gin (tire_sizes);


--
-- Name: promotions_tire_store_ids; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX promotions_tire_store_ids ON promotions USING gin (tire_store_ids);


--
-- Name: scrape_tire_stores_geocode; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX scrape_tire_stores_geocode ON scrape_tire_stores USING btree (latitude, longitude);


--
-- Name: scrape_tire_stores_scraper_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX scrape_tire_stores_scraper_id ON scrape_tire_stores USING btree (scraper_id);


--
-- Name: scrape_tire_stores_store_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX scrape_tire_stores_store_id ON scrape_tire_stores USING btree (scraper_id, store_id);


--
-- Name: store_warehouse_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX store_warehouse_index ON tire_store_warehouse_tiers USING btree (tire_store_id, warehouse_id);


--
-- Name: tire_listings_geocode; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tire_listings_geocode ON tire_listings USING btree (latitude, longitude);


--
-- Name: tire_listings_geocode_status; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tire_listings_geocode_status ON tire_listings USING btree (latitude, longitude, status);


--
-- Name: tire_listings_status_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tire_listings_status_index ON tire_listings USING btree (status);


--
-- Name: tire_listings_tire_store_id_status_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tire_listings_tire_store_id_status_index ON tire_listings USING btree (tire_store_id, status);


--
-- Name: tire_stores_colors; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tire_stores_colors ON tire_stores USING gin (colors);


--
-- Name: tire_stores_geocode; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tire_stores_geocode ON tire_stores USING btree (latitude, longitude);


--
-- Name: tire_stores_geocode_status; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tire_stores_geocode_status ON tire_stores USING btree (latitude, longitude, status);


--
-- Name: tire_stores_status_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tire_stores_status_index ON tire_stores USING btree (status);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20120625161305');

INSERT INTO schema_migrations (version) VALUES ('20120625161351');

INSERT INTO schema_migrations (version) VALUES ('20120625161414');

INSERT INTO schema_migrations (version) VALUES ('20120625161422');

INSERT INTO schema_migrations (version) VALUES ('20120625161427');

INSERT INTO schema_migrations (version) VALUES ('20120625161432');

INSERT INTO schema_migrations (version) VALUES ('20120625161442');

INSERT INTO schema_migrations (version) VALUES ('20120625161511');

INSERT INTO schema_migrations (version) VALUES ('20120625161537');

INSERT INTO schema_migrations (version) VALUES ('20120625161602');

INSERT INTO schema_migrations (version) VALUES ('20120625161628');

INSERT INTO schema_migrations (version) VALUES ('20120626010748');

INSERT INTO schema_migrations (version) VALUES ('20120626151930');

INSERT INTO schema_migrations (version) VALUES ('20120628180757');

INSERT INTO schema_migrations (version) VALUES ('20120629192037');

INSERT INTO schema_migrations (version) VALUES ('20120702175130');

INSERT INTO schema_migrations (version) VALUES ('20120703142748');

INSERT INTO schema_migrations (version) VALUES ('20120704162202');

INSERT INTO schema_migrations (version) VALUES ('20120712203532');

INSERT INTO schema_migrations (version) VALUES ('20120712203924');

INSERT INTO schema_migrations (version) VALUES ('20120712204241');

INSERT INTO schema_migrations (version) VALUES ('20120712211709');

INSERT INTO schema_migrations (version) VALUES ('20120716140046');

INSERT INTO schema_migrations (version) VALUES ('20120807124509');

INSERT INTO schema_migrations (version) VALUES ('20120810190623');

INSERT INTO schema_migrations (version) VALUES ('20120815142301');

INSERT INTO schema_migrations (version) VALUES ('20120815143715');

INSERT INTO schema_migrations (version) VALUES ('20120815151630');

INSERT INTO schema_migrations (version) VALUES ('20120816114326');

INSERT INTO schema_migrations (version) VALUES ('20120816124047');

INSERT INTO schema_migrations (version) VALUES ('20120820115841');

INSERT INTO schema_migrations (version) VALUES ('20120905134510');

INSERT INTO schema_migrations (version) VALUES ('20120906171527');

INSERT INTO schema_migrations (version) VALUES ('20120908152124');

INSERT INTO schema_migrations (version) VALUES ('20120908152410');

INSERT INTO schema_migrations (version) VALUES ('20120910121421');

INSERT INTO schema_migrations (version) VALUES ('20120925170433');

INSERT INTO schema_migrations (version) VALUES ('20121002164615');

INSERT INTO schema_migrations (version) VALUES ('20121018134212');

INSERT INTO schema_migrations (version) VALUES ('20121031130902');

INSERT INTO schema_migrations (version) VALUES ('20121106123121');

INSERT INTO schema_migrations (version) VALUES ('20121106132833');

INSERT INTO schema_migrations (version) VALUES ('20121106134534');

INSERT INTO schema_migrations (version) VALUES ('20121106141427');

INSERT INTO schema_migrations (version) VALUES ('20121106190221');

INSERT INTO schema_migrations (version) VALUES ('20121107143016');

INSERT INTO schema_migrations (version) VALUES ('20121129160855');

INSERT INTO schema_migrations (version) VALUES ('20121203162207');

INSERT INTO schema_migrations (version) VALUES ('20121210142158');

INSERT INTO schema_migrations (version) VALUES ('20121214153659');

INSERT INTO schema_migrations (version) VALUES ('20121216215712');

INSERT INTO schema_migrations (version) VALUES ('20121224122035');

INSERT INTO schema_migrations (version) VALUES ('20121226143807');

INSERT INTO schema_migrations (version) VALUES ('20130109193904');

INSERT INTO schema_migrations (version) VALUES ('20130109195001');

INSERT INTO schema_migrations (version) VALUES ('20130115221146');

INSERT INTO schema_migrations (version) VALUES ('20130116132849');

INSERT INTO schema_migrations (version) VALUES ('20130116132948');

INSERT INTO schema_migrations (version) VALUES ('20130116133011');

INSERT INTO schema_migrations (version) VALUES ('20130122182550');

INSERT INTO schema_migrations (version) VALUES ('20130123214908');

INSERT INTO schema_migrations (version) VALUES ('20130125165053');

INSERT INTO schema_migrations (version) VALUES ('20130129153601');

INSERT INTO schema_migrations (version) VALUES ('20130206141004');

INSERT INTO schema_migrations (version) VALUES ('20130214154037');

INSERT INTO schema_migrations (version) VALUES ('20130214171005');

INSERT INTO schema_migrations (version) VALUES ('20130221174420');

INSERT INTO schema_migrations (version) VALUES ('20130221182349');

INSERT INTO schema_migrations (version) VALUES ('20130222011013');

INSERT INTO schema_migrations (version) VALUES ('20130222164318');

INSERT INTO schema_migrations (version) VALUES ('20130222165418');

INSERT INTO schema_migrations (version) VALUES ('20130222165503');

INSERT INTO schema_migrations (version) VALUES ('20130225153519');

INSERT INTO schema_migrations (version) VALUES ('20130225153709');

INSERT INTO schema_migrations (version) VALUES ('20130225214255');

INSERT INTO schema_migrations (version) VALUES ('20130301183301');

INSERT INTO schema_migrations (version) VALUES ('20130303212148');

INSERT INTO schema_migrations (version) VALUES ('20130304161759');

INSERT INTO schema_migrations (version) VALUES ('20130318203608');

INSERT INTO schema_migrations (version) VALUES ('20130319182716');

INSERT INTO schema_migrations (version) VALUES ('20130319182744');

INSERT INTO schema_migrations (version) VALUES ('20130319182846');

INSERT INTO schema_migrations (version) VALUES ('20130319185706');

INSERT INTO schema_migrations (version) VALUES ('20130321160135');

INSERT INTO schema_migrations (version) VALUES ('20130321160401');

INSERT INTO schema_migrations (version) VALUES ('20130322130603');

INSERT INTO schema_migrations (version) VALUES ('20130324202030');

INSERT INTO schema_migrations (version) VALUES ('20130324203222');

INSERT INTO schema_migrations (version) VALUES ('20130325120918');

INSERT INTO schema_migrations (version) VALUES ('20130325132239');

INSERT INTO schema_migrations (version) VALUES ('20130325133944');

INSERT INTO schema_migrations (version) VALUES ('20130325152315');

INSERT INTO schema_migrations (version) VALUES ('20130325152457');

INSERT INTO schema_migrations (version) VALUES ('20130325152638');

INSERT INTO schema_migrations (version) VALUES ('20130325154451');

INSERT INTO schema_migrations (version) VALUES ('20130325154655');

INSERT INTO schema_migrations (version) VALUES ('20130326214542');

INSERT INTO schema_migrations (version) VALUES ('20130327152018');

INSERT INTO schema_migrations (version) VALUES ('20130419134426');

INSERT INTO schema_migrations (version) VALUES ('20130429191312');

INSERT INTO schema_migrations (version) VALUES ('20130503124250');

INSERT INTO schema_migrations (version) VALUES ('20130503124318');

INSERT INTO schema_migrations (version) VALUES ('20130506225539');

INSERT INTO schema_migrations (version) VALUES ('20130513111853');

INSERT INTO schema_migrations (version) VALUES ('20130521005212');

INSERT INTO schema_migrations (version) VALUES ('20130602222020');

INSERT INTO schema_migrations (version) VALUES ('20130602222807');

INSERT INTO schema_migrations (version) VALUES ('20130614135027');

INSERT INTO schema_migrations (version) VALUES ('20130614135028');

INSERT INTO schema_migrations (version) VALUES ('20130625174901');

INSERT INTO schema_migrations (version) VALUES ('20130625175106');

INSERT INTO schema_migrations (version) VALUES ('20130705161133');

INSERT INTO schema_migrations (version) VALUES ('20130718163228');

INSERT INTO schema_migrations (version) VALUES ('20130718163311');

INSERT INTO schema_migrations (version) VALUES ('20130718163330');

INSERT INTO schema_migrations (version) VALUES ('20130718163344');

INSERT INTO schema_migrations (version) VALUES ('20130718192057');

INSERT INTO schema_migrations (version) VALUES ('20130723114516');

INSERT INTO schema_migrations (version) VALUES ('20130723114537');

INSERT INTO schema_migrations (version) VALUES ('20130723142603');

INSERT INTO schema_migrations (version) VALUES ('20130723231146');

INSERT INTO schema_migrations (version) VALUES ('20130730202721');

INSERT INTO schema_migrations (version) VALUES ('20130731145536');

INSERT INTO schema_migrations (version) VALUES ('20130731175642');

INSERT INTO schema_migrations (version) VALUES ('20130801192021');

INSERT INTO schema_migrations (version) VALUES ('20131217130521');

INSERT INTO schema_migrations (version) VALUES ('20140110144854');

INSERT INTO schema_migrations (version) VALUES ('20140203171206');

INSERT INTO schema_migrations (version) VALUES ('20140203174541');

INSERT INTO schema_migrations (version) VALUES ('20140402133138');

INSERT INTO schema_migrations (version) VALUES ('20140402162515');

INSERT INTO schema_migrations (version) VALUES ('20140409141615');

INSERT INTO schema_migrations (version) VALUES ('20140409141850');

INSERT INTO schema_migrations (version) VALUES ('20140715133152');

INSERT INTO schema_migrations (version) VALUES ('20140715133224');

INSERT INTO schema_migrations (version) VALUES ('20140905202735');

INSERT INTO schema_migrations (version) VALUES ('20140908133149');

INSERT INTO schema_migrations (version) VALUES ('20140923210130');

INSERT INTO schema_migrations (version) VALUES ('20140924123022');

INSERT INTO schema_migrations (version) VALUES ('20140924183340');

INSERT INTO schema_migrations (version) VALUES ('20140924191400');

INSERT INTO schema_migrations (version) VALUES ('20140924200948');

INSERT INTO schema_migrations (version) VALUES ('20140925004622');

INSERT INTO schema_migrations (version) VALUES ('20141118133524');

INSERT INTO schema_migrations (version) VALUES ('20150107202818');

INSERT INTO schema_migrations (version) VALUES ('20150123183644');

INSERT INTO schema_migrations (version) VALUES ('20150127195753');

INSERT INTO schema_migrations (version) VALUES ('20150129184714');

INSERT INTO schema_migrations (version) VALUES ('20150129184858');

INSERT INTO schema_migrations (version) VALUES ('20150130193907');

INSERT INTO schema_migrations (version) VALUES ('20150204222509');

INSERT INTO schema_migrations (version) VALUES ('20150204225615');

INSERT INTO schema_migrations (version) VALUES ('20150204230019');

INSERT INTO schema_migrations (version) VALUES ('20150205135851');

INSERT INTO schema_migrations (version) VALUES ('20150521203917');

INSERT INTO schema_migrations (version) VALUES ('20150521203935');

INSERT INTO schema_migrations (version) VALUES ('20150521213121');

INSERT INTO schema_migrations (version) VALUES ('20150526191307');

INSERT INTO schema_migrations (version) VALUES ('20150622165748');

INSERT INTO schema_migrations (version) VALUES ('20150623183333');

INSERT INTO schema_migrations (version) VALUES ('20150804192116');

INSERT INTO schema_migrations (version) VALUES ('20150804192131');

INSERT INTO schema_migrations (version) VALUES ('20150911185626');

INSERT INTO schema_migrations (version) VALUES ('20150919001456');

INSERT INTO schema_migrations (version) VALUES ('20151005141141');

INSERT INTO schema_migrations (version) VALUES ('20151005141753');

INSERT INTO schema_migrations (version) VALUES ('20151005142125');

INSERT INTO schema_migrations (version) VALUES ('20151005142344');

INSERT INTO schema_migrations (version) VALUES ('20151005142632');

INSERT INTO schema_migrations (version) VALUES ('20151005175128');

INSERT INTO schema_migrations (version) VALUES ('20151006122839');

INSERT INTO schema_migrations (version) VALUES ('20151007003354');

INSERT INTO schema_migrations (version) VALUES ('20151014141052');

INSERT INTO schema_migrations (version) VALUES ('20151016134256');

INSERT INTO schema_migrations (version) VALUES ('20151105133419');