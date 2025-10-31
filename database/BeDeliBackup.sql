--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3
-- Dumped by pg_dump version 15.3

-- Started on 2025-10-31 15:58:31

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 16495)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 4327 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 231 (class 1259 OID 17583)
-- Name: driverlocations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.driverlocations (
    id integer NOT NULL,
    driver_id integer NOT NULL,
    location public.geography(Point,4326) NOT NULL,
    recorded_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.driverlocations OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 17582)
-- Name: driverlocations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.driverlocations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.driverlocations_id_seq OWNER TO postgres;

--
-- TOC entry 4328 (class 0 OID 0)
-- Dependencies: 230
-- Name: driverlocations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.driverlocations_id_seq OWNED BY public.driverlocations.id;


--
-- TOC entry 220 (class 1259 OID 16422)
-- Name: driverstock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.driverstock (
    id integer NOT NULL,
    driver_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL
);


ALTER TABLE public.driverstock OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16421)
-- Name: driverstock_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.driverstock_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.driverstock_id_seq OWNER TO postgres;

--
-- TOC entry 4329 (class 0 OID 0)
-- Dependencies: 219
-- Name: driverstock_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.driverstock_id_seq OWNED BY public.driverstock.id;


--
-- TOC entry 224 (class 1259 OID 16476)
-- Name: orderitems; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orderitems (
    id integer NOT NULL,
    order_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL
);


ALTER TABLE public.orderitems OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16475)
-- Name: orderitems_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orderitems_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.orderitems_id_seq OWNER TO postgres;

--
-- TOC entry 4330 (class 0 OID 0)
-- Dependencies: 223
-- Name: orderitems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orderitems_id_seq OWNED BY public.orderitems.id;


--
-- TOC entry 222 (class 1259 OID 16455)
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    driver_id integer,
    status character varying(50) NOT NULL,
    delivery_address text NOT NULL,
    delivery_lat numeric(10,7),
    delivery_lng numeric(10,7),
    total_price numeric(10,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT orders_status_check CHECK (((status)::text = ANY ((ARRAY['Pendente'::character varying, 'Aceito'::character varying, 'Em Rota'::character varying, 'Entregue'::character varying, 'Cancelado'::character varying])::text[])))
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16454)
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.orders_id_seq OWNER TO postgres;

--
-- TOC entry 4331 (class 0 OID 0)
-- Dependencies: 221
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- TOC entry 218 (class 1259 OID 16413)
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    price numeric(10,2) NOT NULL
);


ALTER TABLE public.products OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16412)
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.products_id_seq OWNER TO postgres;

--
-- TOC entry 4332 (class 0 OID 0)
-- Dependencies: 217
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- TOC entry 216 (class 1259 OID 16400)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password_hash text NOT NULL,
    role character varying(50) NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['cliente'::character varying, 'entregador'::character varying, 'loja'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16399)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 4333 (class 0 OID 0)
-- Dependencies: 215
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 4129 (class 2604 OID 17586)
-- Name: driverlocations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driverlocations ALTER COLUMN id SET DEFAULT nextval('public.driverlocations_id_seq'::regclass);


--
-- TOC entry 4125 (class 2604 OID 16425)
-- Name: driverstock id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driverstock ALTER COLUMN id SET DEFAULT nextval('public.driverstock_id_seq'::regclass);


--
-- TOC entry 4128 (class 2604 OID 16479)
-- Name: orderitems id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orderitems ALTER COLUMN id SET DEFAULT nextval('public.orderitems_id_seq'::regclass);


--
-- TOC entry 4126 (class 2604 OID 16458)
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- TOC entry 4124 (class 2604 OID 16416)
-- Name: products id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- TOC entry 4122 (class 2604 OID 16403)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 4321 (class 0 OID 17583)
-- Dependencies: 231
-- Data for Name: driverlocations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.driverlocations (id, driver_id, location, recorded_at) FROM stdin;
1	2	0101000020E61000000C022B87165147C03EE8D9ACFA8C37C0	2025-10-31 15:50:37.261806-03
\.


--
-- TOC entry 4315 (class 0 OID 16422)
-- Dependencies: 220
-- Data for Name: driverstock; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.driverstock (id, driver_id, product_id, quantity) FROM stdin;
1	2	1	9
2	2	2	4
\.


--
-- TOC entry 4319 (class 0 OID 16476)
-- Dependencies: 224
-- Data for Name: orderitems; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orderitems (id, order_id, product_id, quantity, unit_price) FROM stdin;
1	1	1	1	110.00
2	1	2	1	15.00
\.


--
-- TOC entry 4317 (class 0 OID 16455)
-- Dependencies: 222
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orders (id, customer_id, driver_id, status, delivery_address, delivery_lat, delivery_lng, total_price, created_at) FROM stdin;
1	3	2	Entregue	Rua das Flores, 123	-23.5505200	-46.6333090	125.00	2025-10-31 15:50:37.261806-03
\.


--
-- TOC entry 4313 (class 0 OID 16413)
-- Dependencies: 218
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (id, name, description, price) FROM stdin;
1	Botijão de Gás P13	Botijão de 13kg padrão de cozinha	110.00
2	Galão de Água 20L	Água mineral 20 litros	15.00
\.


--
-- TOC entry 4121 (class 0 OID 16817)
-- Dependencies: 226
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- TOC entry 4311 (class 0 OID 16400)
-- Dependencies: 216
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, password_hash, role, created_at) FROM stdin;
1	Admin Loja	loja@email.com	hash_provisorio_loja	loja	2025-10-31 15:42:54.383336-03
2	João Entregador	joao@email.com	hash_provisorio_entregador	entregador	2025-10-31 15:42:54.383336-03
3	Maria Cliente	maria@email.com	hash_provisorio_cliente	cliente	2025-10-31 15:42:54.383336-03
\.


--
-- TOC entry 4334 (class 0 OID 0)
-- Dependencies: 230
-- Name: driverlocations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.driverlocations_id_seq', 1, true);


--
-- TOC entry 4335 (class 0 OID 0)
-- Dependencies: 219
-- Name: driverstock_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.driverstock_id_seq', 2, true);


--
-- TOC entry 4336 (class 0 OID 0)
-- Dependencies: 223
-- Name: orderitems_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orderitems_id_seq', 2, true);


--
-- TOC entry 4337 (class 0 OID 0)
-- Dependencies: 221
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orders_id_seq', 1, true);


--
-- TOC entry 4338 (class 0 OID 0)
-- Dependencies: 217
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.products_id_seq', 2, true);


--
-- TOC entry 4339 (class 0 OID 0)
-- Dependencies: 215
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 3, true);


--
-- TOC entry 4153 (class 2606 OID 17591)
-- Name: driverlocations driverlocations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driverlocations
    ADD CONSTRAINT driverlocations_pkey PRIMARY KEY (id);


--
-- TOC entry 4141 (class 2606 OID 16427)
-- Name: driverstock driverstock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driverstock
    ADD CONSTRAINT driverstock_pkey PRIMARY KEY (id);


--
-- TOC entry 4149 (class 2606 OID 16481)
-- Name: orderitems orderitems_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orderitems
    ADD CONSTRAINT orderitems_pkey PRIMARY KEY (id);


--
-- TOC entry 4146 (class 2606 OID 16464)
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- TOC entry 4139 (class 2606 OID 16420)
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- TOC entry 4135 (class 2606 OID 16411)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 4137 (class 2606 OID 16409)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4154 (class 1259 OID 17598)
-- Name: idx_driver_locations_driver_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_driver_locations_driver_id ON public.driverlocations USING btree (driver_id);


--
-- TOC entry 4155 (class 1259 OID 17597)
-- Name: idx_driver_locations_gist; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_driver_locations_gist ON public.driverlocations USING gist (location);


--
-- TOC entry 4142 (class 1259 OID 16438)
-- Name: idx_driver_stock_driver_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_driver_stock_driver_id ON public.driverstock USING btree (driver_id);


--
-- TOC entry 4147 (class 1259 OID 16494)
-- Name: idx_order_items_order_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_items_order_id ON public.orderitems USING btree (order_id);


--
-- TOC entry 4143 (class 1259 OID 16492)
-- Name: idx_orders_customer_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_customer_id ON public.orders USING btree (customer_id);


--
-- TOC entry 4144 (class 1259 OID 16493)
-- Name: idx_orders_driver_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_driver_id ON public.orders USING btree (driver_id);


--
-- TOC entry 4158 (class 2606 OID 16465)
-- Name: orders fk_customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES public.users(id);


--
-- TOC entry 4156 (class 2606 OID 16428)
-- Name: driverstock fk_driver; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driverstock
    ADD CONSTRAINT fk_driver FOREIGN KEY (driver_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4159 (class 2606 OID 16470)
-- Name: orders fk_driver; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_driver FOREIGN KEY (driver_id) REFERENCES public.users(id);


--
-- TOC entry 4162 (class 2606 OID 17592)
-- Name: driverlocations fk_driver; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driverlocations
    ADD CONSTRAINT fk_driver FOREIGN KEY (driver_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4160 (class 2606 OID 16482)
-- Name: orderitems fk_order; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orderitems
    ADD CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- TOC entry 4157 (class 2606 OID 16433)
-- Name: driverstock fk_product; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driverstock
    ADD CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- TOC entry 4161 (class 2606 OID 16487)
-- Name: orderitems fk_product; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orderitems
    ADD CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES public.products(id);


-- Completed on 2025-10-31 15:58:31

--
-- PostgreSQL database dump complete
--

