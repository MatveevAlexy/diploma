--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.23
-- Dumped by pg_dump version 14.1

-- Started on 2023-05-11 23:19:30

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
-- TOC entry 212 (class 1255 OID 16761)
-- Name: approve(integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.approve(journal_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	table_n name;
	for_id integer;
	cols name[];
	vals jsonb;
BEGIN
	SELECT name_of_table FROM journal WHERE id = journal_id INTO table_n;
	CASE
		WHEN operation = 2 FROM journal WHERE id = journal_id THEN
		EXECUTE 'DELETE FROM ' || table_n || ' WHERE id = ' || foreign_id FROM journal WHERE id = journal_id;
		WHEN operation = 1 FROM journal WHERE id = journal_id THEN
		SELECT foreign_id FROM journal WHERE id = journal_id INTO for_id;
		SELECT col_set FROM journal WHERE id = journal_id INTO cols;
		SELECT new_val_set FROM journal WHERE id = journal_id INTO vals;
		PERFORM approve_for(journal_id, table_n, for_id, cols, vals);
		ELSE SELECT journal_id INTO journal_id;
	END CASE;
	
	UPDATE journal SET state = 1 WHERE id = journal_id;
	UPDATE journal SET moder = current_user WHERE id = journal_id;
END;
$$;


ALTER FUNCTION public.approve(journal_id integer) OWNER TO adm;

--
-- TOC entry 214 (class 1255 OID 18258)
-- Name: approve(integer, integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.approve(journal_id integer, modname integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	table_n name;
	for_id integer;
	cols name[];
	vals jsonb;
BEGIN
	SELECT name_of_table FROM journal WHERE id = journal_id INTO table_n;
	CASE
		WHEN operation = 2 FROM journal WHERE id = journal_id THEN
			EXECUTE 'DELETE FROM ' || table_n || ' WHERE id = ' || foreign_id FROM journal WHERE id = journal_id;
			UPDATE journal SET state = 1 WHERE id = journal_id;
			UPDATE journal SET moder = modname WHERE id = journal_id;
		WHEN operation = 1 FROM journal WHERE id = journal_id THEN
			SELECT foreign_id FROM journal WHERE id = journal_id INTO for_id;
			SELECT col_set FROM journal WHERE id = journal_id INTO cols;
			SELECT new_val_set FROM journal WHERE id = journal_id INTO vals;
			PERFORM approve_for(journal_id, table_n, for_id, cols, vals);
			UPDATE journal SET state = 1 WHERE id = journal_id;
			UPDATE journal SET moder = modname WHERE id = journal_id;
		ELSE
			UPDATE journal SET state = 1 WHERE id = journal_id;
			UPDATE journal SET moder = modname WHERE id = journal_id;
	END CASE;
	
END;
$$;


ALTER FUNCTION public.approve(journal_id integer, modname integer) OWNER TO adm;

--
-- TOC entry 239 (class 1255 OID 16760)
-- Name: approve_for(integer, name, integer, name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.approve_for(journal_id integer, table_n name, for_id integer, cols name[], new_vals jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE 
	i integer;
BEGIN
    FOR i IN 1..array_length(cols, 1) LOOP
		EXECUTE ('UPDATE ' || table_n || ' SET ' || cols[i] || ' = ''' || (new_vals->(i-1)) || ''' WHERE id = ' || for_id);
    END LOOP;
END;
$$;


ALTER FUNCTION public.approve_for(journal_id integer, table_n name, for_id integer, cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 236 (class 1255 OID 16762)
-- Name: decline(integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.decline(journal_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE journal SET state = 2 WHERE id = journal_id;
	UPDATE journal SET moder = current_user WHERE id = journal_id;
END;
$$;


ALTER FUNCTION public.decline(journal_id integer) OWNER TO adm;

--
-- TOC entry 223 (class 1255 OID 18259)
-- Name: decline(integer, integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.decline(journal_id integer, modname integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE journal SET state = 2 WHERE id = journal_id;
	UPDATE journal SET moder = modname WHERE id = journal_id;
END;
$$;


ALTER FUNCTION public.decline(journal_id integer, modname integer) OWNER TO adm;

--
-- TOC entry 233 (class 1255 OID 16764)
-- Name: exp_del(integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.exp_del(upd_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	old_vals jsonb;
	cols name[];
BEGIN
	SELECT array_agg(column_name::TEXT) FROM information_schema.columns WHERE table_name = 'exp' INTO cols;
	SELECT array_remove(cols, 'created_at') INTO cols;
	SELECT array_remove(cols, 'updated_at') INTO cols;
	SELECT exp_del_for(upd_id, cols) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, operation, state, col_set, old_val_set)
	VALUES ('exp', upd_id, 2, 0, cols, old_vals);
END;
$$;


ALTER FUNCTION public.exp_del(upd_id integer) OWNER TO adm;

--
-- TOC entry 229 (class 1255 OID 18213)
-- Name: exp_del(integer, integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.exp_del(upd_id integer, username integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	old_vals jsonb;
	cols name[];
BEGIN
	SELECT array_agg(column_name::TEXT) FROM information_schema.columns WHERE table_name = 'exp' INTO cols;
	SELECT array_remove(cols, 'created_at') INTO cols;
	SELECT array_remove(cols, 'updated_at') INTO cols;
	SELECT exp_del_for(upd_id, cols) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, old_val_set)
	VALUES ('exp', upd_id, username, 2, 0, cols, old_vals);
END;
$$;


ALTER FUNCTION public.exp_del(upd_id integer, username integer) OWNER TO adm;

--
-- TOC entry 219 (class 1255 OID 18200)
-- Name: exp_del(integer, name); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.exp_del(upd_id integer, username name) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	old_vals jsonb;
	cols name[];
BEGIN
	SELECT array_agg(column_name::TEXT) FROM information_schema.columns WHERE table_name = 'exp' INTO cols;
	SELECT array_remove(cols, 'created_at') INTO cols;
	SELECT array_remove(cols, 'updated_at') INTO cols;
	SELECT exp_del_for(upd_id, cols) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, old_val_set)
	VALUES ('exp', upd_id, username, 2, 0, cols, old_vals);
END;
$$;


ALTER FUNCTION public.exp_del(upd_id integer, username name) OWNER TO adm;

--
-- TOC entry 240 (class 1255 OID 16763)
-- Name: exp_del_for(integer, name[]); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.exp_del_for(upd_id integer, cols name[]) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE 
	i integer;
	old_vals jsonb;
	tmp jsonb;
BEGIN
    FOR i IN 1..array_length(cols, 1) LOOP
		EXECUTE ('SELECT ' || cols[i] || ' FROM exp WHERE id = ' || upd_id) INTO tmp;
		CASE 
			WHEN old_vals IS NULL THEN SELECT jsonb_build_array(tmp) INTO old_vals;
			ELSE SELECT old_vals || jsonb_build_array(tmp) INTO old_vals;
		END CASE;
    END LOOP;
	RETURN old_vals;
END;
$$;


ALTER FUNCTION public.exp_del_for(upd_id integer, cols name[]) OWNER TO adm;

--
-- TOC entry 238 (class 1255 OID 16766)
-- Name: exp_new(name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.exp_new(cols name[], new_vals jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE new_id integer;
BEGIN
    INSERT INTO exp DEFAULT VALUES RETURNING id INTO new_id;

	PERFORM exp_new_for(new_id, cols, new_vals);

	INSERT INTO journal (name_of_table, foreign_id, operation, state, col_set, new_val_set)
	VALUES ('exp', new_id, 0, 0, cols, new_vals);
END;
$$;


ALTER FUNCTION public.exp_new(cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 231 (class 1255 OID 18254)
-- Name: exp_new(name[], jsonb, integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.exp_new(cols name[], new_vals jsonb, username integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE new_id integer;
BEGIN
    INSERT INTO exp DEFAULT VALUES RETURNING id INTO new_id;

	PERFORM exp_new_for(new_id, cols, new_vals);

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, new_val_set)
	VALUES ('exp', new_id, username, 0, 0, cols, new_vals);
	
	RETURN new_id;
END;
$$;


ALTER FUNCTION public.exp_new(cols name[], new_vals jsonb, username integer) OWNER TO adm;

--
-- TOC entry 217 (class 1255 OID 18198)
-- Name: exp_new(name[], jsonb, name); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.exp_new(cols name[], new_vals jsonb, username name) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE new_id integer;
BEGIN
    INSERT INTO exp DEFAULT VALUES RETURNING id INTO new_id;

	PERFORM exp_new_for(new_id, cols, new_vals);

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, new_val_set)
	VALUES ('exp', new_id, username, 0, 0, cols, new_vals);
END;
$$;


ALTER FUNCTION public.exp_new(cols name[], new_vals jsonb, username name) OWNER TO adm;

--
-- TOC entry 234 (class 1255 OID 16765)
-- Name: exp_new_for(integer, name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.exp_new_for(new_id integer, cols name[], new_vals jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE 
	i integer;
	elem json;
BEGIN
SELECT id INTO new_id FROM exp ORDER BY id DESC LIMIT 1;
    FOR i IN 1..array_length(cols, 1) LOOP
		SELECT new_vals->(i-1) INTO elem;
        EXECUTE ('UPDATE exp SET ' || cols[i] || ' = ''' || elem || ''' WHERE id = ' || new_id);
    END LOOP;
END;
$$;


ALTER FUNCTION public.exp_new_for(new_id integer, cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 211 (class 1255 OID 16768)
-- Name: exp_upd(integer, name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.exp_upd(upd_id integer, cols name[], new_vals jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE old_vals jsonb;
BEGIN
	SELECT exp_upd_for(upd_id, cols, new_vals) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, operation, state, col_set, new_val_set, old_val_set)
	VALUES ('exp', upd_id, 1, 0, cols, new_vals, old_vals);
END;
$$;


ALTER FUNCTION public.exp_upd(upd_id integer, cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 228 (class 1255 OID 18211)
-- Name: exp_upd(integer, name[], jsonb, integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.exp_upd(upd_id integer, cols name[], new_vals jsonb, username integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE old_vals jsonb;
BEGIN
	SELECT exp_upd_for(upd_id, cols, new_vals) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, new_val_set, old_val_set)
	VALUES ('exp', upd_id, username, 1, 0, cols, new_vals, old_vals);
END;
$$;


ALTER FUNCTION public.exp_upd(upd_id integer, cols name[], new_vals jsonb, username integer) OWNER TO adm;

--
-- TOC entry 218 (class 1255 OID 18199)
-- Name: exp_upd(integer, name[], jsonb, name); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.exp_upd(upd_id integer, cols name[], new_vals jsonb, username name) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE old_vals jsonb;
BEGIN
	SELECT exp_upd_for(upd_id, cols, new_vals) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, new_val_set, old_val_set)
	VALUES ('exp', upd_id, username, 1, 0, cols, new_vals, old_vals);
END;
$$;


ALTER FUNCTION public.exp_upd(upd_id integer, cols name[], new_vals jsonb, username name) OWNER TO adm;

--
-- TOC entry 210 (class 1255 OID 16767)
-- Name: exp_upd_for(integer, name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.exp_upd_for(upd_id integer, cols name[], new_vals jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE 
	i integer;
	old_vals jsonb;
	tmp jsonb;
BEGIN
    FOR i IN 1..array_length(cols, 1) LOOP
		EXECUTE ('SELECT ' || cols[i] || ' FROM exp WHERE id = ' || upd_id) INTO tmp;
		CASE 
			WHEN old_vals IS NULL THEN SELECT jsonb_build_array(tmp) INTO old_vals;
			ELSE SELECT old_vals || jsonb_build_array(tmp) INTO old_vals;
		END CASE;
        --EXECUTE ('UPDATE exp SET ' || cols[i] || ' = ''' || new_vals[i - 1] || ''' WHERE id = ' || upd_id);
    END LOOP;
	RETURN old_vals;
END;
$$;


ALTER FUNCTION public.exp_upd_for(upd_id integer, cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 235 (class 1255 OID 16770)
-- Name: launch_del(integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.launch_del(upd_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	old_vals jsonb;
	cols name[];
BEGIN
	SELECT array_agg(column_name::TEXT) FROM information_schema.columns WHERE table_name = 'launch' INTO cols;
	SELECT array_remove(cols, 'created_at') INTO cols;
	SELECT array_remove(cols, 'updated_at') INTO cols;
	SELECT launch_del_for(upd_id, cols) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, operation, state, col_set, old_val_set)
	VALUES ('launch', upd_id, 2, 0, cols, old_vals);
END;
$$;


ALTER FUNCTION public.launch_del(upd_id integer) OWNER TO adm;

--
-- TOC entry 227 (class 1255 OID 18210)
-- Name: launch_del(integer, integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.launch_del(upd_id integer, username integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	old_vals jsonb;
	cols name[];
BEGIN
	SELECT array_agg(column_name::TEXT) FROM information_schema.columns WHERE table_name = 'launch' INTO cols;
	SELECT array_remove(cols, 'created_at') INTO cols;
	SELECT array_remove(cols, 'updated_at') INTO cols;
	SELECT launch_del_for(upd_id, cols) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, old_val_set)
	VALUES ('launch', upd_id, username, 2, 0, cols, old_vals);
END;
$$;


ALTER FUNCTION public.launch_del(upd_id integer, username integer) OWNER TO adm;

--
-- TOC entry 222 (class 1255 OID 18204)
-- Name: launch_del(integer, name); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.launch_del(upd_id integer, username name) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	old_vals jsonb;
	cols name[];
BEGIN
	SELECT array_agg(column_name::TEXT) FROM information_schema.columns WHERE table_name = 'launch' INTO cols;
	SELECT array_remove(cols, 'created_at') INTO cols;
	SELECT array_remove(cols, 'updated_at') INTO cols;
	SELECT launch_del_for(upd_id, cols) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, old_val_set)
	VALUES ('launch', upd_id, username, 2, 0, cols, old_vals);
END;
$$;


ALTER FUNCTION public.launch_del(upd_id integer, username name) OWNER TO adm;

--
-- TOC entry 237 (class 1255 OID 16769)
-- Name: launch_del_for(integer, name[]); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.launch_del_for(upd_id integer, cols name[]) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE 
	i integer;
	old_vals jsonb;
	tmp jsonb;
BEGIN
    FOR i IN 1..array_length(cols, 1) LOOP
		EXECUTE ('SELECT ' || cols[i] || ' FROM launch WHERE id = ' || upd_id) INTO tmp;
		CASE 
			WHEN old_vals IS NULL THEN SELECT jsonb_build_array(tmp) INTO old_vals;
			ELSE SELECT old_vals || jsonb_build_array(tmp) INTO old_vals;
		END CASE;
    END LOOP;
	RETURN old_vals;
END;
$$;


ALTER FUNCTION public.launch_del_for(upd_id integer, cols name[]) OWNER TO adm;

--
-- TOC entry 209 (class 1255 OID 16772)
-- Name: launch_new(name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.launch_new(cols name[], new_vals jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE new_id integer;
BEGIN
    INSERT INTO launch DEFAULT VALUES RETURNING id INTO new_id;

	PERFORM launch_new_for(new_id, cols, new_vals);

	INSERT INTO journal (name_of_table, foreign_id, operation, state, col_set, new_val_set)
	VALUES ('launch', new_id, 0, 0, cols, new_vals);
END;
$$;


ALTER FUNCTION public.launch_new(cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 232 (class 1255 OID 18255)
-- Name: launch_new(name[], jsonb, integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.launch_new(cols name[], new_vals jsonb, username integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE new_id integer;
BEGIN
    INSERT INTO launch DEFAULT VALUES RETURNING id INTO new_id;

	PERFORM launch_new_for(new_id, cols, new_vals);

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, new_val_set)
	VALUES ('launch', new_id, username, 0, 0, cols, new_vals);
	RETURN new_id;
END;
$$;


ALTER FUNCTION public.launch_new(cols name[], new_vals jsonb, username integer) OWNER TO adm;

--
-- TOC entry 220 (class 1255 OID 18202)
-- Name: launch_new(name[], jsonb, name); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.launch_new(cols name[], new_vals jsonb, username name) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE new_id integer;
BEGIN
    INSERT INTO launch DEFAULT VALUES RETURNING id INTO new_id;

	PERFORM launch_new_for(new_id, cols, new_vals);

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, new_val_set)
	VALUES ('launch', new_id, username, 0, 0, cols, new_vals);
END;
$$;


ALTER FUNCTION public.launch_new(cols name[], new_vals jsonb, username name) OWNER TO adm;

--
-- TOC entry 241 (class 1255 OID 16771)
-- Name: launch_new_for(integer, name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.launch_new_for(new_id integer, cols name[], new_vals jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE i integer;
BEGIN
SELECT id INTO new_id FROM launch ORDER BY id DESC LIMIT 1;
    FOR i IN 1..array_length(cols, 1) LOOP
        EXECUTE ('UPDATE launch SET ' || cols[i] || ' = ''' || (new_vals -> (i - 1)) || ''' WHERE id = ' || new_id);
    END LOOP;
END;
$$;


ALTER FUNCTION public.launch_new_for(new_id integer, cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 247 (class 1255 OID 16774)
-- Name: launch_upd(integer, name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.launch_upd(upd_id integer, cols name[], new_vals jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE old_vals jsonb;
BEGIN
	SELECT launch_upd_for(upd_id, cols, new_vals) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, operation, state, col_set, new_val_set, old_val_set)
	VALUES ('launch', upd_id, 1, 0, cols, new_vals, old_vals);
END;
$$;


ALTER FUNCTION public.launch_upd(upd_id integer, cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 226 (class 1255 OID 18208)
-- Name: launch_upd(integer, name[], jsonb, integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.launch_upd(upd_id integer, cols name[], new_vals jsonb, username integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE old_vals jsonb;
BEGIN
	SELECT launch_upd_for(upd_id, cols, new_vals) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, new_val_set, old_val_set)
	VALUES ('launch', upd_id, username, 1, 0, cols, new_vals, old_vals);
END;
$$;


ALTER FUNCTION public.launch_upd(upd_id integer, cols name[], new_vals jsonb, username integer) OWNER TO adm;

--
-- TOC entry 221 (class 1255 OID 18203)
-- Name: launch_upd(integer, name[], jsonb, name); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.launch_upd(upd_id integer, cols name[], new_vals jsonb, username name) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE old_vals jsonb;
BEGIN
	SELECT launch_upd_for(upd_id, cols, new_vals) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, new_val_set, old_val_set)
	VALUES ('launch', upd_id, username, 1, 0, cols, new_vals, old_vals);
END;
$$;


ALTER FUNCTION public.launch_upd(upd_id integer, cols name[], new_vals jsonb, username name) OWNER TO adm;

--
-- TOC entry 246 (class 1255 OID 16773)
-- Name: launch_upd_for(integer, name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.launch_upd_for(upd_id integer, cols name[], new_vals jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE 
	i integer;
	old_vals jsonb;
	tmp jsonb;
BEGIN
    FOR i IN 1..array_length(cols, 1) LOOP
		EXECUTE ('SELECT ' || cols[i] || ' FROM launch WHERE id = ' || upd_id) INTO tmp;
		CASE 
			WHEN old_vals IS NULL THEN SELECT jsonb_build_array(tmp) INTO old_vals;
			ELSE SELECT old_vals || jsonb_build_array(tmp) INTO old_vals;
		END CASE;
        --EXECUTE ('UPDATE launch SET ' || cols[i] || ' = ''' || new_vals[i - 1] || ''' WHERE id = ' || upd_id);
    END LOOP;
	RETURN old_vals;
END;
$$;


ALTER FUNCTION public.launch_upd_for(upd_id integer, cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 242 (class 1255 OID 16776)
-- Name: type_exp_del(integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.type_exp_del(upd_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	old_vals jsonb;
	cols name[];
BEGIN
	SELECT array_agg(column_name::TEXT) FROM information_schema.columns WHERE table_name = 'type_exp' INTO cols;
	SELECT array_remove(cols, 'created_at') INTO cols;
	SELECT array_remove(cols, 'updated_at') INTO cols;
	SELECT type_exp_del_for(upd_id, cols) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, operation, state, col_set, old_val_set)
	VALUES ('type_exp', upd_id, 2, 0, cols, old_vals);
END;
$$;


ALTER FUNCTION public.type_exp_del(upd_id integer) OWNER TO adm;

--
-- TOC entry 225 (class 1255 OID 18207)
-- Name: type_exp_del(integer, integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.type_exp_del(upd_id integer, username integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	old_vals jsonb;
	cols name[];
BEGIN
	SELECT array_agg(column_name::TEXT) FROM information_schema.columns WHERE table_name = 'type_exp' INTO cols;
	SELECT array_remove(cols, 'created_at') INTO cols;
	SELECT array_remove(cols, 'updated_at') INTO cols;
	SELECT type_exp_del_for(upd_id, cols) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, old_val_set)
	VALUES ('type_exp', upd_id, username, 2, 0, cols, old_vals);
END;
$$;


ALTER FUNCTION public.type_exp_del(upd_id integer, username integer) OWNER TO adm;

--
-- TOC entry 216 (class 1255 OID 18197)
-- Name: type_exp_del(integer, name); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.type_exp_del(upd_id integer, username name) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	old_vals jsonb;
	cols name[];
BEGIN
	SELECT array_agg(column_name::TEXT) FROM information_schema.columns WHERE table_name = 'type_exp' INTO cols;
	SELECT array_remove(cols, 'created_at') INTO cols;
	SELECT array_remove(cols, 'updated_at') INTO cols;
	SELECT type_exp_del_for(upd_id, cols) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, old_val_set)
	VALUES ('type_exp', upd_id, username, 2, 0, cols, old_vals);
END;
$$;


ALTER FUNCTION public.type_exp_del(upd_id integer, username name) OWNER TO adm;

--
-- TOC entry 245 (class 1255 OID 16775)
-- Name: type_exp_del_for(integer, name[]); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.type_exp_del_for(upd_id integer, cols name[]) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE 
	i integer;
	old_vals jsonb;
	tmp jsonb;
BEGIN
    FOR i IN 1..array_length(cols, 1) LOOP
		EXECUTE ('SELECT ' || cols[i] || ' FROM type_exp WHERE id = ' || upd_id) INTO tmp;
		CASE 
			WHEN old_vals IS NULL THEN SELECT jsonb_build_array(tmp) INTO old_vals;
			ELSE SELECT old_vals || jsonb_build_array(tmp) INTO old_vals;
		END CASE;
    END LOOP;
	RETURN old_vals;
END;
$$;


ALTER FUNCTION public.type_exp_del_for(upd_id integer, cols name[]) OWNER TO adm;

--
-- TOC entry 244 (class 1255 OID 16778)
-- Name: type_exp_new(name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.type_exp_new(cols name[], new_vals jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE new_id integer;
BEGIN
    INSERT INTO type_exp DEFAULT VALUES RETURNING id INTO new_id;

	PERFORM type_exp_new_for(new_id, cols, new_vals);

	INSERT INTO journal (name_of_table, foreign_id, operation, state, col_set, new_val_set)
	VALUES ('type_exp', new_id, 0, 0, cols, new_vals);
END;
$$;


ALTER FUNCTION public.type_exp_new(cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 230 (class 1255 OID 18260)
-- Name: type_exp_new(name[], jsonb, integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.type_exp_new(cols name[], new_vals jsonb, username integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE new_id integer;
BEGIN
    INSERT INTO type_exp DEFAULT VALUES RETURNING id INTO new_id;

	PERFORM type_exp_new_for(new_id, cols, new_vals);

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, new_val_set)
	VALUES ('type_exp', new_id, username, 0, 0, cols, new_vals);
	
	RETURN new_id;
END;
$$;


ALTER FUNCTION public.type_exp_new(cols name[], new_vals jsonb, username integer) OWNER TO adm;

--
-- TOC entry 213 (class 1255 OID 18194)
-- Name: type_exp_new(name[], jsonb, name); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.type_exp_new(cols name[], new_vals jsonb, username name) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE new_id integer;
BEGIN
    INSERT INTO type_exp DEFAULT VALUES RETURNING id INTO new_id;

	PERFORM type_exp_new_for(new_id, cols, new_vals);

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, new_val_set)
	VALUES ('type_exp', new_id, username, 0, 0, cols, new_vals);
END;
$$;


ALTER FUNCTION public.type_exp_new(cols name[], new_vals jsonb, username name) OWNER TO adm;

--
-- TOC entry 248 (class 1255 OID 16777)
-- Name: type_exp_new_for(integer, name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.type_exp_new_for(new_id integer, cols name[], new_vals jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE i integer;
BEGIN
SELECT id INTO new_id FROM type_exp ORDER BY id DESC LIMIT 1;
    FOR i IN 1..array_length(cols, 1) LOOP
        EXECUTE ('UPDATE type_exp SET ' || cols[i] || ' = ''' || (new_vals -> (i - 1)) || ''' WHERE id = ' || new_id);
    END LOOP;
END;
$$;


ALTER FUNCTION public.type_exp_new_for(new_id integer, cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 243 (class 1255 OID 16780)
-- Name: type_exp_upd(integer, name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.type_exp_upd(upd_id integer, cols name[], new_vals jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE old_vals jsonb;
BEGIN
	SELECT type_exp_upd_for(upd_id, cols, new_vals) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, operation, state, col_set, new_val_set, old_val_set)
	VALUES ('type_exp', upd_id, 1, 0, cols, new_vals, old_vals);
END;
$$;


ALTER FUNCTION public.type_exp_upd(upd_id integer, cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 224 (class 1255 OID 18206)
-- Name: type_exp_upd(integer, name[], jsonb, integer); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.type_exp_upd(upd_id integer, cols name[], new_vals jsonb, username integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE old_vals jsonb;
BEGIN
	SELECT type_exp_upd_for(upd_id, cols, new_vals) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, new_val_set, old_val_set)
	VALUES ('type_exp', upd_id, username, 1, 0, cols, new_vals, old_vals);
END;
$$;


ALTER FUNCTION public.type_exp_upd(upd_id integer, cols name[], new_vals jsonb, username integer) OWNER TO adm;

--
-- TOC entry 215 (class 1255 OID 18195)
-- Name: type_exp_upd(integer, name[], jsonb, name); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.type_exp_upd(upd_id integer, cols name[], new_vals jsonb, username name) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE old_vals jsonb;
BEGIN
	SELECT type_exp_upd_for(upd_id, cols, new_vals) INTO old_vals;

	INSERT INTO journal (name_of_table, foreign_id, "user", operation, state, col_set, new_val_set, old_val_set)
	VALUES ('type_exp', upd_id, username, 1, 0, cols, new_vals, old_vals);
END;
$$;


ALTER FUNCTION public.type_exp_upd(upd_id integer, cols name[], new_vals jsonb, username name) OWNER TO adm;

--
-- TOC entry 249 (class 1255 OID 16779)
-- Name: type_exp_upd_for(integer, name[], jsonb); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.type_exp_upd_for(upd_id integer, cols name[], new_vals jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE 
	i integer;
	old_vals jsonb;
	tmp jsonb;
BEGIN
    FOR i IN 1..array_length(cols, 1) LOOP
		EXECUTE ('SELECT ' || cols[i] || ' FROM type_exp WHERE id = ' || upd_id) INTO tmp;
		CASE 
			WHEN old_vals IS NULL THEN SELECT jsonb_build_array(tmp) INTO old_vals;
			ELSE SELECT old_vals || jsonb_build_array(tmp) INTO old_vals;
		END CASE;
        --EXECUTE ('UPDATE type_exp SET ' || cols[i] || ' = ''' || new_vals[i - 1] || ''' WHERE id = ' || upd_id);
    END LOOP;
	RETURN old_vals;
END;
$$;


ALTER FUNCTION public.type_exp_upd_for(upd_id integer, cols name[], new_vals jsonb) OWNER TO adm;

--
-- TOC entry 196 (class 1255 OID 16665)
-- Name: upd_timestamp(); Type: FUNCTION; Schema: public; Owner: adm
--

CREATE FUNCTION public.upd_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.upd_timestamp() OWNER TO adm;

SET default_tablespace = '';

--
-- TOC entry 186 (class 1259 OID 16668)
-- Name: exp; Type: TABLE; Schema: public; Owner: adm
--

CREATE TABLE public.exp (
    id integer NOT NULL,
    type_exp_id integer,
    sc_id integer,
    ccond jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    path_to_exp jsonb,
    exp_name character varying(500),
    exp_goal character varying(1000)
);


ALTER TABLE public.exp OWNER TO adm;

--
-- TOC entry 185 (class 1259 OID 16666)
-- Name: exp_id_seq; Type: SEQUENCE; Schema: public; Owner: adm
--

CREATE SEQUENCE public.exp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exp_id_seq OWNER TO adm;

--
-- TOC entry 2895 (class 0 OID 0)
-- Dependencies: 185
-- Name: exp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adm
--

ALTER SEQUENCE public.exp_id_seq OWNED BY public.exp.id;


--
-- TOC entry 191 (class 1259 OID 16728)
-- Name: journal; Type: TABLE; Schema: public; Owner: adm
--

CREATE TABLE public.journal (
    id integer NOT NULL,
    name_of_table name,
    foreign_id integer,
    operation integer,
    state integer,
    old_val_set jsonb,
    new_val_set jsonb,
    col_set name[],
    change_time timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    "user" integer,
    moder integer
);


ALTER TABLE public.journal OWNER TO adm;

--
-- TOC entry 192 (class 1259 OID 16739)
-- Name: journal_id_seq; Type: SEQUENCE; Schema: public; Owner: adm
--

CREATE SEQUENCE public.journal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.journal_id_seq OWNER TO adm;

--
-- TOC entry 2898 (class 0 OID 0)
-- Dependencies: 192
-- Name: journal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adm
--

ALTER SEQUENCE public.journal_id_seq OWNED BY public.journal.id;


--
-- TOC entry 188 (class 1259 OID 16681)
-- Name: launch; Type: TABLE; Schema: public; Owner: adm
--

CREATE TABLE public.launch (
    id integer NOT NULL,
    vcond jsonb,
    result jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    exp_id integer
);


ALTER TABLE public.launch OWNER TO adm;

--
-- TOC entry 187 (class 1259 OID 16679)
-- Name: launch_id_seq; Type: SEQUENCE; Schema: public; Owner: adm
--

CREATE SEQUENCE public.launch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.launch_id_seq OWNER TO adm;

--
-- TOC entry 2901 (class 0 OID 0)
-- Dependencies: 187
-- Name: launch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adm
--

ALTER SEQUENCE public.launch_id_seq OWNED BY public.launch.id;


--
-- TOC entry 195 (class 1259 OID 18229)
-- Name: scomp; Type: TABLE; Schema: public; Owner: adm
--

CREATE TABLE public.scomp (
    id integer NOT NULL,
    sc_nm_ru character varying(100),
    sc_nm_en character varying(100)
);


ALTER TABLE public.scomp OWNER TO adm;

--
-- TOC entry 190 (class 1259 OID 16694)
-- Name: type_exp; Type: TABLE; Schema: public; Owner: adm
--

CREATE TABLE public.type_exp (
    id integer NOT NULL,
    name character varying(500),
    goal character varying(500),
    ccond jsonb,
    vcond jsonb,
    result jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    path_to_type jsonb
);


ALTER TABLE public.type_exp OWNER TO adm;

--
-- TOC entry 189 (class 1259 OID 16692)
-- Name: type_exp_id_seq; Type: SEQUENCE; Schema: public; Owner: adm
--

CREATE SEQUENCE public.type_exp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.type_exp_id_seq OWNER TO adm;

--
-- TOC entry 2905 (class 0 OID 0)
-- Dependencies: 189
-- Name: type_exp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adm
--

ALTER SEQUENCE public.type_exp_id_seq OWNED BY public.type_exp.id;


--
-- TOC entry 193 (class 1259 OID 18178)
-- Name: users; Type: TABLE; Schema: public; Owner: adm
--

CREATE TABLE public.users (
    id integer NOT NULL,
    "user" name,
    pswd name,
    is_moder integer DEFAULT 0
);


ALTER TABLE public.users OWNER TO adm;

--
-- TOC entry 194 (class 1259 OID 18183)
-- Name: users_seq; Type: SEQUENCE; Schema: public; Owner: adm
--

CREATE SEQUENCE public.users_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_seq OWNER TO adm;

--
-- TOC entry 2908 (class 0 OID 0)
-- Dependencies: 194
-- Name: users_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adm
--

ALTER SEQUENCE public.users_seq OWNED BY public.users.id;


--
-- TOC entry 2704 (class 2604 OID 16671)
-- Name: exp id; Type: DEFAULT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.exp ALTER COLUMN id SET DEFAULT nextval('public.exp_id_seq'::regclass);


--
-- TOC entry 2715 (class 2604 OID 16741)
-- Name: journal id; Type: DEFAULT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.journal ALTER COLUMN id SET DEFAULT nextval('public.journal_id_seq'::regclass);


--
-- TOC entry 2707 (class 2604 OID 16684)
-- Name: launch id; Type: DEFAULT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.launch ALTER COLUMN id SET DEFAULT nextval('public.launch_id_seq'::regclass);


--
-- TOC entry 2710 (class 2604 OID 16697)
-- Name: type_exp id; Type: DEFAULT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.type_exp ALTER COLUMN id SET DEFAULT nextval('public.type_exp_id_seq'::regclass);


--
-- TOC entry 2717 (class 2604 OID 18186)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_seq'::regclass);


--
-- TOC entry 2857 (class 0 OID 16668)
-- Dependencies: 186
-- Data for Name: exp; Type: TABLE DATA; Schema: public; Owner: adm
--

COPY public.exp (id, type_exp_id, sc_id, ccond, created_at, updated_at, path_to_exp, exp_name, exp_goal) FROM stdin;
4	9	29	\N	2022-08-29 17:01:28.487341+03	2023-03-13 19:49:30.662621+03	[{"ref": "Решение систем линейных уравнений", "name": "Решение систем линейных уравнений", "type": "?"}, {"ref": "Прямые методы решения СЛАУ", "name": "Прямые методы решения СЛАУ", "type": "?"}, {"ref": "Linpack benchmark", "name": "Linpack benchmark", "type": "A"}, {"ref": "Linpack, HPL", "name": "Linpack, HPL", "type": "I"}]	"Производительность реализаций алгоритмов по решению СЛАУ для плотных матриц на суперкомпьютере Ломоносов"	\N
5	9	91	\N	2022-08-29 17:01:28.487341+03	2023-03-13 19:49:30.662621+03	[{"ref": "Решение систем линейных уравнений", "name": "Решение систем линейных уравнений", "type": "?"}, {"ref": "Прямые методы решения СЛАУ", "name": "Прямые методы решения СЛАУ", "type": "?"}, {"ref": "Linpack benchmark", "name": "Linpack benchmark", "type": "A"}, {"ref": "Linpack, HPL", "name": "Linpack, HPL", "type": "I"}]	\N	\N
2	7	29	\N	2022-05-03 23:34:43.34944+03	2023-03-13 19:49:30.662621+03	[{"ref": "Треугольные разложения", "name": "Треугольные разложения", "type": "?"}, {"ref": "Метод Холецкого (нахождение симметричного треугольного разложения)", "name": "Метод Холецкого", "type": "M"}, {"ref": "Разложение Холецкого (метод квадратного корня)", "name": "Разложение Холецкого", "type": "A"}]	\N	\N
15	14	29	["NVIDIA GPU V100"]	2022-11-22 00:00:00.073892+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Поиск в ширину (BFS)", "name": "Поиск в ширину (BFS)", "type": "A"}, {"ref": "BFS, VGL", "name": "BFS, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма BFS от типов\nграфов, их размера на узле Volta-1 суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма BFS на узле Volta-1 суперкомпьютера Ломоносов-2"
16	14	29	["NVIDIA GPU P100"]	2022-11-23 19:57:25.002414+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Поиск в ширину (BFS)", "name": "Поиск в ширину (BFS)", "type": "A"}, {"ref": "BFS, VGL", "name": "BFS, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма BFS от типов\nграфов, их размера на узле Pascal суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма BFS на узле Pascal суперкомпьютера Ломоносов-2"
17	14	29	["Intel Xeon 6126"]	2022-11-23 19:57:25.002414+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Поиск в ширину (BFS)", "name": "Поиск в ширину (BFS)", "type": "A"}, {"ref": "BFS, VGL", "name": "BFS, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма BFS от типов\nграфов, их размера на узле Pascal суперкомпьютера Ломоносов-2(без использования GPU)"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма BFS на узле Pascal суперкомпьютера Ломоносов-2(без использования GPU)"
18	14	29	["Intel Xeon 6240"]	2022-11-23 19:57:25.002414+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Поиск в ширину (BFS)", "name": "Поиск в ширину (BFS)", "type": "A"}, {"ref": "BFS, VGL", "name": "BFS, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма BFS от типов\nграфов, их размера на узле Volta-2 суперкомпьютера Ломоносов-2(без использования GPU)"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма BFS на узле Volta-2 суперкомпьютера Ломоносов-2(без использования GPU)"
10	12	29	[4096, 32768]	2022-08-29 17:01:28.487341+03	2023-03-13 19:49:30.662621+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Поиск в ширину (BFS)", "name": "Поиск в ширину (BFS)", "type": "A"}, {"ref": "BFS, MPI, Graph500", "name": "BFS, MPI, Graph500", "type": "I"}]	\N	\N
11	12	91	[158976, 7630848]	2022-08-29 17:01:28.487341+03	2023-03-13 19:49:30.662621+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Поиск в ширину (BFS)", "name": "Поиск в ширину (BFS)", "type": "A"}, {"ref": "BFS, MPI, Graph500", "name": "BFS, MPI, Graph500", "type": "I"}]	\N	\N
19	14	29	["NEC SX-Aurora TSUBASA"]	2022-11-23 19:57:25.002414+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Поиск в ширину (BFS)", "name": "Поиск в ширину (BFS)", "type": "A"}, {"ref": "BFS, VGL", "name": "BFS, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма BFS от типов\nграфов, их размера на узле NEC суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма BFS на узле NEC суперкомпьютера Ломоносов-2"
20	15	29	["NVIDIA GPU V100"]	2022-11-28 21:36:56.271493+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Алгоритм Дейкстры", "name": "Алгоритм Дейкстры", "type": "A"}, {"ref": "Dijkstra, VGL, push", "name": "Dijkstra, VGL, push", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма Дейкстры, push от типов\nграфов, их размера на узле Volta-1 суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма Дейкстры, push на узле Volta-1 суперкомпьютера Ломоносов-2"
21	15	29	["NVIDIA GPU P100"]	2022-11-28 21:36:56.271493+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Алгоритм Дейкстры", "name": "Алгоритм Дейкстры", "type": "A"}, {"ref": "Dijkstra, VGL, push", "name": "Dijkstra, VGL, push", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма Дейкстры, push от типов\nграфов, их размера на узле Pascal суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма Дейкстры, push на узле Pascal суперкомпьютера Ломоносов-2"
22	15	29	["Intel Xeon 6126"]	2022-11-28 21:36:56.271493+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Алгоритм Дейкстры", "name": "Алгоритм Дейкстры", "type": "A"}, {"ref": "Dijkstra, VGL, push", "name": "Dijkstra, VGL, push", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма Дейкстры, push от типов\nграфов, их размера на узле Pascal суперкомпьютера Ломоносов-2(без использования GPU)"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма Дейкстры, push на узле Pascal суперкомпьютера Ломоносов-2(без использования GPU)"
23	15	29	["Intel Xeon 6240"]	2022-11-28 21:36:56.271493+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Алгоритм Дейкстры", "name": "Алгоритм Дейкстры", "type": "A"}, {"ref": "Dijkstra, VGL, push", "name": "Dijkstra, VGL, push", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма Дейкстры, push от типов\nграфов, их размера на узле Volta-2 суперкомпьютера Ломоносов-2(без использования GPU)"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма Дейкстры, push на узле Volta-2 суперкомпьютера Ломоносов-2(без использования GPU)"
24	15	29	["NEC SX-Aurora TSUBASA"]	2022-11-28 21:36:56.271493+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Алгоритм Дейкстры", "name": "Алгоритм Дейкстры", "type": "A"}, {"ref": "Dijkstra, VGL, push", "name": "Dijkstra, VGL, push", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма Дейкстры, push от типов\nграфов, их размера на узле NEC суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма Дейкстры, push на узле NEC суперкомпьютера Ломоносов-2"
25	15	29	["NVIDIA GPU V100"]	2022-11-28 21:36:56.271493+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Алгоритм Дейкстры", "name": "Алгоритм Дейкстры", "type": "A"}, {"ref": "Dijkstra, VGL, pull", "name": "Dijkstra, VGL, pull", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма Дейкстры, pull от типов\nграфов, их размера на узле Volta-1 суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма Дейкстры, pull на узле Volta-1 суперкомпьютера Ломоносов-2"
26	15	29	["NVIDIA GPU P100"]	2022-11-28 21:36:56.271493+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Алгоритм Дейкстры", "name": "Алгоритм Дейкстры", "type": "A"}, {"ref": "Dijkstra, VGL, pull", "name": "Dijkstra, VGL, pull", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма Дейкстры, pull от типов\nграфов, их размера на узле Pascal суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма Дейкстры, pull на узле Pascal суперкомпьютера Ломоносов-2"
27	15	29	["Intel Xeon 6126"]	2022-11-28 21:36:56.271493+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Алгоритм Дейкстры", "name": "Алгоритм Дейкстры", "type": "A"}, {"ref": "Dijkstra, VGL, pull", "name": "Dijkstra, VGL, pull", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма Дейкстры, pull от типов\nграфов, их размера на узле Pascal суперкомпьютера Ломоносов-2(без использования GPU)"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма Дейкстры, pull на узле Pascal суперкомпьютера Ломоносов-2(без использования GPU)"
28	15	29	["Intel Xeon 6240"]	2022-11-28 21:36:56.271493+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Алгоритм Дейкстры", "name": "Алгоритм Дейкстры", "type": "A"}, {"ref": "Dijkstra, VGL, pull", "name": "Dijkstra, VGL, pull", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма Дейкстры, pull от типов\nграфов, их размера на узле Volta-2 суперкомпьютера Ломоносов-2(без использования GPU)"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма Дейкстры, pull на узле Volta-2 суперкомпьютера Ломоносов-2(без использования GPU)"
29	15	29	["NEC SX-Aurora TSUBASA"]	2022-11-28 21:36:56.271493+03	2023-02-26 20:09:36.43762+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Алгоритм Дейкстры", "name": "Алгоритм Дейкстры", "type": "A"}, {"ref": "Dijkstra, VGL, pull", "name": "Dijkstra, VGL, pull", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма Дейкстры, pull от типов\nграфов, их размера на узле NEC суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма Дейкстры, pull на узле NEC суперкомпьютера Ломоносов-2"
30	16	29	["NVIDIA GPU V100"]	2022-11-28 22:18:56.240308+03	2023-02-26 20:09:36.43762+03	[{"ref": "Прикладные задачи из разных областей", "name": "Прикладные задачи из разных областей", "type": "?"}, {"ref": "Ранжирование Интернет-страниц", "name": "Ранжирование Интернет-страниц", "type": "P"}, {"ref": "PageRank", "name": "PageRank", "type": "A"}, {"ref": "PageRank, VGL", "name": "PageRank, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма PageRank от типов\nграфов, их размера на узле Volta-1 суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма PageRank на узле Volta-1 суперкомпьютера Ломоносов-2"
31	16	29	["NVIDIA GPU P100"]	2022-11-28 22:18:56.240308+03	2023-02-26 20:09:36.43762+03	[{"ref": "Прикладные задачи из разных областей", "name": "Прикладные задачи из разных областей", "type": "?"}, {"ref": "Ранжирование Интернет-страниц", "name": "Ранжирование Интернет-страниц", "type": "P"}, {"ref": "PageRank", "name": "PageRank", "type": "A"}, {"ref": "PageRank, VGL", "name": "PageRank, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма PageRank от типов\nграфов, их размера на узле Pascal суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма PageRank на узле Pascal суперкомпьютера Ломоносов-2"
32	16	29	["Intel Xeon 6126"]	2022-11-28 22:18:56.240308+03	2023-02-26 20:09:36.43762+03	[{"ref": "Прикладные задачи из разных областей", "name": "Прикладные задачи из разных областей", "type": "?"}, {"ref": "Ранжирование Интернет-страниц", "name": "Ранжирование Интернет-страниц", "type": "P"}, {"ref": "PageRank", "name": "PageRank", "type": "A"}, {"ref": "PageRank, VGL", "name": "PageRank, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма PageRank от типов\nграфов, их размера на узле Pascal суперкомпьютера Ломоносов-2(без использования GPU)"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма PageRank на узле Pascal суперкомпьютера Ломоносов-2(без использования GPU)"
33	16	29	["Intel Xeon 6240"]	2022-11-28 22:18:56.240308+03	2023-02-26 20:09:36.43762+03	[{"ref": "Прикладные задачи из разных областей", "name": "Прикладные задачи из разных областей", "type": "?"}, {"ref": "Ранжирование Интернет-страниц", "name": "Ранжирование Интернет-страниц", "type": "P"}, {"ref": "PageRank", "name": "PageRank", "type": "A"}, {"ref": "PageRank, VGL", "name": "PageRank, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма PageRank от типов\nграфов, их размера на узле Volta-2 суперкомпьютера Ломоносов-2(без использования GPU)"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма PageRank на узле Volta-2 суперкомпьютера Ломоносов-2(без использования GPU)"
34	16	29	["NEC SX-Aurora TSUBASA"]	2022-11-28 22:18:56.240308+03	2023-02-26 20:09:36.43762+03	[{"ref": "Прикладные задачи из разных областей", "name": "Прикладные задачи из разных областей", "type": "?"}, {"ref": "Ранжирование Интернет-страниц", "name": "Ранжирование Интернет-страниц", "type": "P"}, {"ref": "PageRank", "name": "PageRank", "type": "A"}, {"ref": "PageRank, VGL", "name": "PageRank, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма PageRank от типов\nграфов, их размера на узле NEC суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма PageRank на узле NEC суперкомпьютера Ломоносов-2"
35	17	29	["NVIDIA GPU V100"]	2022-11-28 22:18:56.240308+03	2023-02-26 20:09:36.43762+03	[{"ref": "Прикладные задачи из разных областей", "name": "Прикладные задачи из разных областей", "type": "?"}, {"ref": "Ранжирование Интернет-страниц", "name": "Ранжирование Интернет-страниц", "type": "P"}, {"ref": "HITS (Hyperlink Induced Topic Search)", "name": "HITS", "type": "A"}, {"ref": "HITS, VGL", "name": "HITS, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма HITS от типов\nграфов, их размера на узле Volta-1 суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма HITS на узле Volta-1 суперкомпьютера Ломоносов-2"
36	17	29	["NVIDIA GPU P100"]	2022-11-28 22:18:56.240308+03	2023-02-26 20:09:36.43762+03	[{"ref": "Прикладные задачи из разных областей", "name": "Прикладные задачи из разных областей", "type": "?"}, {"ref": "Ранжирование Интернет-страниц", "name": "Ранжирование Интернет-страниц", "type": "P"}, {"ref": "HITS (Hyperlink Induced Topic Search)", "name": "HITS", "type": "A"}, {"ref": "HITS, VGL", "name": "HITS, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма HITS от типов\nграфов, их размера на узле Pascal суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма HITS на узле Pascal суперкомпьютера Ломоносов-2"
37	17	29	["Intel Xeon 6126"]	2022-11-28 22:18:56.240308+03	2023-02-26 20:09:36.43762+03	[{"ref": "Прикладные задачи из разных областей", "name": "Прикладные задачи из разных областей", "type": "?"}, {"ref": "Ранжирование Интернет-страниц", "name": "Ранжирование Интернет-страниц", "type": "P"}, {"ref": "HITS (Hyperlink Induced Topic Search)", "name": "HITS", "type": "A"}, {"ref": "HITS, VGL", "name": "HITS, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма HITS от типов\nграфов, их размера на узле Pascal суперкомпьютера Ломоносов-2(без использования GPU)"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма HITS на узле Pascal суперкомпьютера Ломоносов-2(без использования GPU)"
38	17	29	["Intel Xeon 6240"]	2022-11-28 22:18:56.240308+03	2023-02-26 20:09:36.43762+03	[{"ref": "Прикладные задачи из разных областей", "name": "Прикладные задачи из разных областей", "type": "?"}, {"ref": "Ранжирование Интернет-страниц", "name": "Ранжирование Интернет-страниц", "type": "P"}, {"ref": "HITS (Hyperlink Induced Topic Search)", "name": "HITS", "type": "A"}, {"ref": "HITS, VGL", "name": "HITS, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма HITS от типов\nграфов, их размера на узле Volta-2 суперкомпьютера Ломоносов-2(без использования GPU)"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма HITS на узле Volta-2 суперкомпьютера Ломоносов-2(без использования GPU)"
39	17	29	["NEC SX-Aurora TSUBASA"]	2022-11-28 22:18:56.240308+03	2023-02-26 20:09:36.43762+03	[{"ref": "Прикладные задачи из разных областей", "name": "Прикладные задачи из разных областей", "type": "?"}, {"ref": "Ранжирование Интернет-страниц", "name": "Ранжирование Интернет-страниц", "type": "P"}, {"ref": "HITS (Hyperlink Induced Topic Search)", "name": "HITS", "type": "A"}, {"ref": "HITS, VGL", "name": "HITS, VGL", "type": "I"}]	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма HITS от типов\nграфов, их размера на узле NEC суперкомпьютера Ломоносов-2"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма HITS на узле NEC суперкомпьютера Ломоносов-2"
6	10	29	[64384]	2022-08-29 17:01:28.487341+03	2023-03-13 19:49:30.662621+03	[{"ref": "Исследование и моделирование компьютеров", "name": "Исследование и моделирование компьютеров", "type": "?"}, {"ref": "Тесты производительности компьютеров", "name": "Тесты производительности компьютеров", "type": "?"}, {"ref": "Linpack benchmark", "name": "Linpack benchmark", "type": "A"}, {"ref": "Linpack, HPL", "name": "Linpack, HPL", "type": "I"}]	"Производительность тестов linpack на суперкомпьютере Ломоносов в полной комплектации"	\N
7	10	91	[7630848]	2022-08-29 17:01:28.487341+03	2023-03-13 19:49:30.662621+03	[{"ref": "Исследование и моделирование компьютеров", "name": "Исследование и моделирование компьютеров", "type": "?"}, {"ref": "Тесты производительности компьютеров", "name": "Тесты производительности компьютеров", "type": "?"}, {"ref": "Linpack benchmark", "name": "Linpack benchmark", "type": "A"}, {"ref": "Linpack, HPL", "name": "Linpack, HPL", "type": "I"}]	\N	\N
8	11	29	\N	2022-08-29 17:01:28.487341+03	2023-03-13 19:49:30.662621+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Поиск в ширину (BFS)", "name": "Поиск в ширину (BFS)", "type": "A"}, {"ref": "BFS, MPI, Graph500", "name": "BFS, MPI, Graph500", "type": "I"}]	\N	\N
9	11	91	\N	2022-08-29 17:01:28.487341+03	2023-03-13 19:49:30.662621+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Поиск в ширину (BFS)", "name": "Поиск в ширину (BFS)", "type": "A"}, {"ref": "BFS, MPI, Graph500", "name": "BFS, MPI, Graph500", "type": "I"}]	\N	\N
\.


--
-- TOC entry 2862 (class 0 OID 16728)
-- Dependencies: 191
-- Data for Name: journal; Type: TABLE DATA; Schema: public; Owner: adm
--

COPY public.journal (id, name_of_table, foreign_id, operation, state, old_val_set, new_val_set, col_set, change_time, updated_at, "user", moder) FROM stdin;
55	launch	42	1	2	[[661.639, 0.01267852711]]	[["661", "0.01"]]	{result}	2023-04-18 19:43:45.455116+03	2023-04-18 19:52:32.506749+03	2	1
3	launch	10	1	2	[[442.01]]	[[11]]	{result}	2022-09-12 18:52:32.58567+03	2023-03-11 19:03:23.325026+03	1	1
56	launch	42	0	1	\N	[42, 15, ["syn_rmat_18_32", 262144, 8388608], [661.639, 0.01267852711]]	{id,exp_id,vcond,result}	2023-04-18 19:51:13.391275+03	2023-04-18 19:51:34.44039+03	1	1
58	launch	42	1	0	[[661.639, 0.01267852711]]	[["661", "0.01"]]	{result}	2023-04-19 05:11:38.516942+03	2023-04-19 05:11:38.516942+03	2	\N
6	exp	14	0	0	\N	[7, 1]	{type_exp_id,sc_id}	2022-09-12 19:06:20.166435+03	2023-03-11 19:03:23.325026+03	1	\N
7	exp	13	0	0	\N	["Тест", ["TEPS", "GNEPS"]]	{name,result}	2022-09-12 19:07:39.733652+03	2023-03-11 19:03:23.325026+03	1	\N
38	launch	10	2	0	[10, [1073741824, 32768, 2592, 2944], [442.01], 7]	\N	{id,vcond,result,exp_id}	2023-03-11 15:46:41.89081+03	2023-03-11 19:03:23.325026+03	1	\N
\.


--
-- TOC entry 2859 (class 0 OID 16681)
-- Dependencies: 188
-- Data for Name: launch; Type: TABLE DATA; Schema: public; Owner: adm
--

COPY public.launch (id, vcond, result, created_at, updated_at, exp_id) FROM stdin;
2	[4, 1024]	[2.5]	2022-05-03 23:37:00.65034+03	2022-05-03 23:37:00.65034+03	2
4	[16384, 1048576, 1024, 128, 128]	[1.2]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	4
5	[1024, 1000000, 320, 128, 128]	[0.8]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	4
6	[1048576, 7280640, 2048, 1024, 1024]	[200]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	5
7	[262144, 1000000, 800, 512, 512]	[132.8]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	5
8	[33554432, 4096, 503, 128]	[2.48]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	6
9	[1000000, 1600, 128, 503]	[1.56]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	6
10	[1073741824, 32768, 2592, 2944]	[442.01]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	7
11	[1000000, 8000, 2944, 2592]	[203.1]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	7
12	[2048, 16384, 30, 128, 128]	[60.1]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	8
13	[1024, 8192, 30, 64, 128]	[31]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	8
14	[4096, 196608, 37, 384, 512]	[3076]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	9
15	[2000, 96000, 32, 320, 300]	[1765]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	9
16	[37, 256, 128]	[103.079]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	10
17	[30, 128, 256]	[98]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	10
18	[41, 2592, 2944]	[102955]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	11
19	[35, 2592, 2944]	[100676]	2022-08-29 17:13:46.725499+03	2022-08-29 17:13:46.725499+03	11
65	["syn_ru_18_32", 262144, 8388608]	[889.647, 0.00942914212]	2022-11-24 19:10:44.373336+03	2022-11-24 19:10:44.373336+03	17
66	["syn_ru_18_32", 262144, 8388608]	[855.237, 0.009808518574]	2022-11-24 19:10:44.373336+03	2022-11-24 19:10:44.373336+03	18
67	["syn_ru_18_32", 262144, 8388608]	[11399.4, 0.0007358815376]	2022-11-24 19:10:44.373336+03	2022-11-24 19:10:44.373336+03	19
68	["syn_rmat_22_32", 4194304, 134217728]	[3501.84, 0.03832777283]	2022-11-24 19:13:36.537585+03	2022-11-24 19:13:36.537585+03	16
69	["syn_rmat_22_32", 4194304, 134217728]	[1365.33, 0.09830424]	2022-11-24 19:13:36.537585+03	2022-11-24 19:13:36.537585+03	17
70	["syn_rmat_22_32", 4194304, 134217728]	[1274.71, 0.1052927552]	2022-11-24 19:13:36.537585+03	2022-11-24 19:13:36.537585+03	18
71	["syn_rmat_22_32", 4194304, 134217728]	[14842.3, 0.009042919763]	2022-11-24 19:13:36.537585+03	2022-11-24 19:13:36.537585+03	19
42	["syn_rmat_18_32", 262144, 8388608]	[661.639, 0.01267852711]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
43	["syn_ru_18_32", 262144, 8388608]	[1008.19, 0.008320463405]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
44	["syn_ru_22_32", 4194304, 134217728]	[4455.08, 0.03012689514]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
45	["syn_rmat_24_32", 16777216, 536870912]	[5950.43, 0.090223885]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
46	["syn_ru_24_32", 16777216, 536870912]	[4058.03, 0.1322984088]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
47	["syn_ru_25_32", 33554432, 1073741824]	[4143.96, 0.2591100841]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
48	["web_stanford", 282000, 2300000]	[82.0458, 0.02803312296]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
49	["soc_youtube_friendships", 1130000, 3000000]	[351.987, 0.008523042044]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
50	["road_texas", 1380000, 1900000]	[237.116, 0.008012955684]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
51	["soc_livejournal_links", 5200000, 49000000]	[2828.75, 0.01732213875]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
52	["road_western_usa", 6200000, 15000000]	[3.16674, 4.736732413]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
53	["web_zhishi", 7830000, 66000000]	[441.613, 0.1494521221]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
54	["rating_amazon_ratings", 3400000, 5800000]	[162.541, 0.03568330452]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
55	["road_central_usa", 14000000, 34000000]	[4.82319, 7.049276516]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
56	["web_uk_domain_2002", 18500000, 262000000]	[6195.59, 0.04228814366]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
57	["soc_twitter_www", 41600000, 1500000000]	[2048.87, 0.7321108709]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
58	["road_full_usa", 24000000, 57700000]	[4.21903, 13.67612935]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
59	["web_web_trackers", 40400000, 140000000]	[891.154, 0.1570996708]	2022-11-23 22:28:42.582241+03	2022-11-23 22:28:42.582241+03	15
60	["syn_rmat_18_32", 262144, 8388608]	[715.369, 0.01172626714]	2022-11-24 19:08:06.699101+03	2022-11-24 19:08:06.699101+03	16
61	["syn_rmat_18_32", 262144, 8388608]	[1584.26, 0.00529496926]	2022-11-24 19:08:06.699101+03	2022-11-24 19:08:06.699101+03	17
62	["syn_rmat_18_32", 262144, 8388608]	[1537.91, 0.005454550656]	2022-11-24 19:08:06.699101+03	2022-11-24 19:08:06.699101+03	18
63	["syn_rmat_18_32", 262144, 8388608]	[7452.61, 0.001125593316]	2022-11-24 19:08:06.699101+03	2022-11-24 19:08:06.699101+03	19
64	["syn_ru_18_32", 262144, 8388608]	[1130.14, 0.007422627285]	2022-11-24 19:10:44.373336+03	2022-11-24 19:10:44.373336+03	16
72	["syn_ru_22_32", 4194304, 134217728]	[3553.47, 0.03777089099]	2022-11-24 19:16:06.089336+03	2022-11-24 19:16:06.089336+03	16
73	["syn_ru_22_32", 4194304, 134217728]	[668.206, 0.2008627998]	2022-11-24 19:16:06.089336+03	2022-11-24 19:16:06.089336+03	17
74	["syn_ru_22_32", 4194304, 134217728]	[660.386, 0.2032413286]	2022-11-24 19:16:06.089336+03	2022-11-24 19:16:06.089336+03	18
75	["syn_ru_22_32", 4194304, 134217728]	[12617.6, 0.01063734213]	2022-11-24 19:16:06.089336+03	2022-11-24 19:16:06.089336+03	19
76	["syn_rmat_24_32", 16777216, 536870912]	[4689.21, 0.114490695]	2022-11-24 19:18:41.764722+03	2022-11-24 19:18:41.764722+03	16
77	["syn_rmat_24_32", 16777216, 536870912]	[1440.96, 0.3725786365]	2022-11-24 19:18:41.764722+03	2022-11-24 19:18:41.764722+03	17
78	["syn_rmat_24_32", 16777216, 536870912]	[1392.37, 0.3855806373]	2022-11-24 19:18:41.764722+03	2022-11-24 19:18:41.764722+03	18
79	["syn_rmat_24_32", 16777216, 536870912]	[13716.6, 0.03914023242]	2022-11-24 19:18:41.764722+03	2022-11-24 19:18:41.764722+03	19
80	["syn_ru_24_32", 16777216, 536870912]	[3285.99, 0.1633817851]	2022-11-24 19:21:54.403739+03	2022-11-24 19:21:54.403739+03	16
81	["syn_ru_24_32", 16777216, 536870912]	[250.407, 2.143993227]	2022-11-24 19:21:54.403739+03	2022-11-24 19:21:54.403739+03	17
82	["syn_ru_24_32", 16777216, 536870912]	[220.194, 2.438172303]	2022-11-24 19:21:54.403739+03	2022-11-24 19:21:54.403739+03	18
83	["syn_ru_24_32", 16777216, 536870912]	[6679.09, 0.08038084709]	2022-11-24 19:21:54.403739+03	2022-11-24 19:21:54.403739+03	19
84	["syn_rmat_25_32", 33554432, 1073741824]	[322.014, 3.334456961]	2022-11-24 19:32:39.773245+03	2022-11-24 19:32:39.773245+03	16
85	["syn_rmat_25_32", 33554432, 1073741824]	[1826.89, 0.5877430081]	2022-11-24 19:32:39.773245+03	2022-11-24 19:32:39.773245+03	17
86	["syn_rmat_25_32", 33554432, 1073741824]	[4838.07, 0.2219359836]	2022-11-24 19:32:39.773245+03	2022-11-24 19:32:39.773245+03	18
87	["syn_ru_25_32", 33554432, 1073741824]	[330.658, 3.247288207]	2022-11-24 19:37:14.385945+03	2022-11-24 19:37:14.385945+03	16
88	["syn_ru_25_32", 33554432, 1073741824]	[257.995, 4.161870672]	2022-11-24 19:37:14.385945+03	2022-11-24 19:37:14.385945+03	17
89	["syn_ru_25_32", 33554432, 1073741824]	[212.704, 5.048056567]	2022-11-24 19:37:14.385945+03	2022-11-24 19:37:14.385945+03	18
90	["web_stanford", 282000, 2300000]	[86.9398, 0.02645508731]	2022-11-24 19:37:14.385945+03	2022-11-24 19:37:14.385945+03	16
91	["web_stanford", 282000, 2300000]	[969.095, 0.00237334833]	2022-11-24 19:37:14.385945+03	2022-11-24 19:37:14.385945+03	18
92	["web_stanford", 282000, 2300000]	[1201.27, 0.001914640339]	2022-11-24 19:37:14.385945+03	2022-11-24 19:37:14.385945+03	19
93	["soc_youtube_friendships", 1130000, 3000000]	[492.069, 0.00609670595]	2022-11-24 19:40:21.853002+03	2022-11-24 19:40:21.853002+03	16
94	["soc_youtube_friendships", 1130000, 3000000]	[1519.79, 0.001973956928]	2022-11-24 19:40:21.853002+03	2022-11-24 19:40:21.853002+03	17
95	["soc_youtube_friendships", 1130000, 3000000]	[1032.75, 0.00290486565]	2022-11-24 19:40:21.853002+03	2022-11-24 19:40:21.853002+03	18
96	["soc_youtube_friendships", 1130000, 3000000]	[9309.1, 0.0003222653103]	2022-11-24 19:40:21.853002+03	2022-11-24 19:40:21.853002+03	19
97	["road_texas", 1380000, 1900000]	[243.462, 0.00780409263]	2022-11-24 19:43:22.58596+03	2022-11-24 19:43:22.58596+03	16
98	["road_texas", 1380000, 1900000]	[697.433, 0.002724276024]	2022-11-24 19:43:22.58596+03	2022-11-24 19:43:22.58596+03	17
99	["road_texas", 1380000, 1900000]	[415.762, 0.004569922215]	2022-11-24 19:43:22.58596+03	2022-11-24 19:43:22.58596+03	18
100	["road_texas", 1380000, 1900000]	[3637.41, 0.0005223496939]	2022-11-24 19:43:22.58596+03	2022-11-24 19:43:22.58596+03	19
101	["soc_livejournal_links", 5200000, 49000000]	[3118.87, 0.01571081834]	2022-11-24 19:47:33.791614+03	2022-11-24 19:47:33.791614+03	16
102	["soc_livejournal_links", 5200000, 49000000]	[5482.98, 0.008936746076]	2022-11-24 19:47:33.791614+03	2022-11-24 19:47:33.791614+03	17
103	["soc_livejournal_links", 5200000, 49000000]	[4147.3, 0.01181491573]	2022-11-24 19:47:33.791614+03	2022-11-24 19:47:33.791614+03	18
104	["soc_livejournal_links", 5200000, 49000000]	[42366.8, 0.00115656599]	2022-11-24 19:47:33.791614+03	2022-11-24 19:47:33.791614+03	19
105	["road_western_usa", 6200000, 15000000]	[3.55584, 4.218412527]	2022-11-24 19:49:24.006164+03	2022-11-24 19:49:24.006164+03	16
106	["road_western_usa", 6200000, 15000000]	[2.38057, 6.301011943]	2022-11-24 19:49:24.006164+03	2022-11-24 19:49:24.006164+03	17
107	["road_western_usa", 6200000, 15000000]	[2.22523, 6.740876224]	2022-11-24 19:49:24.006164+03	2022-11-24 19:49:24.006164+03	18
108	["road_western_usa", 6200000, 15000000]	[15.4961, 0.9679854931]	2022-11-24 19:49:24.006164+03	2022-11-24 19:49:24.006164+03	19
109	["web_zhishi", 7830000, 66000000]	[987.127, 0.06686069776]	2022-11-24 19:51:57.184179+03	2022-11-24 19:51:57.184179+03	16
110	["web_zhishi", 7830000, 66000000]	[1156.8, 0.05705394191]	2022-11-24 19:51:57.184179+03	2022-11-24 19:51:57.184179+03	17
111	["web_zhishi", 7830000, 66000000]	[1005.76, 0.06562201718]	2022-11-24 19:51:57.184179+03	2022-11-24 19:51:57.184179+03	18
112	["web_zhishi", 7830000, 66000000]	[3187.81, 0.0207038688]	2022-11-24 19:51:57.184179+03	2022-11-24 19:51:57.184179+03	19
113	["rating_amazon_ratings", 3400000, 5800000]	[176.962, 0.03277539811]	2022-11-24 21:43:18.616332+03	2022-11-24 21:43:18.616332+03	16
114	["rating_amazon_ratings", 3400000, 5800000]	[233.775, 0.02481018073]	2022-11-24 21:43:18.616332+03	2022-11-24 21:43:18.616332+03	17
115	["rating_amazon_ratings", 3400000, 5800000]	[217.955, 0.02661099768]	2022-11-24 21:43:18.616332+03	2022-11-24 21:43:18.616332+03	18
116	["rating_amazon_ratings", 3400000, 5800000]	[1575.27, 0.003681908498]	2022-11-24 21:43:18.616332+03	2022-11-24 21:43:18.616332+03	19
117	["road_central_usa", 14000000, 34000000]	[4.77575, 7.119300633]	2022-11-24 21:47:55.433581+03	2022-11-24 21:47:55.433581+03	16
118	["road_central_usa", 14000000, 34000000]	[1.63022, 20.85608077]	2022-11-24 21:47:55.433581+03	2022-11-24 21:47:55.433581+03	17
119	["road_central_usa", 14000000, 34000000]	[1.65667, 20.52309754]	2022-11-24 21:47:55.433581+03	2022-11-24 21:47:55.433581+03	18
120	["road_central_usa", 14000000, 34000000]	[13.9873, 2.43077649]	2022-11-24 21:47:55.433581+03	2022-11-24 21:47:55.433581+03	19
121	["web_uk_domain_2002", 18500000, 262000000]	[5030.9, 0.05207815699]	2022-11-24 21:49:57.093179+03	2022-11-24 21:49:57.093179+03	16
122	["web_uk_domain_2002", 18500000, 262000000]	[1664.91, 0.1573658636]	2022-11-24 21:49:57.093179+03	2022-11-24 21:49:57.093179+03	17
123	["web_uk_domain_2002", 18500000, 262000000]	[2699.9, 0.09704063113]	2022-11-24 21:49:57.093179+03	2022-11-24 21:49:57.093179+03	18
124	["web_uk_domain_2002", 18500000, 262000000]	[55785.4, 0.004696569353]	2022-11-24 21:49:57.093179+03	2022-11-24 21:49:57.093179+03	19
125	["soc_twitter_www", 41600000, 1500000000]	[331.689, 4.522308548]	2022-11-24 21:51:09.53727+03	2022-11-24 21:51:09.53727+03	16
126	["soc_twitter_www", 41600000, 1500000000]	[607.877, 2.467604466]	2022-11-24 21:51:09.53727+03	2022-11-24 21:51:09.53727+03	17
127	["soc_twitter_www", 41600000, 1500000000]	[3584.18, 0.418505767]	2022-11-24 21:51:09.53727+03	2022-11-24 21:51:09.53727+03	18
128	["road_full_usa", 24000000, 57700000]	[4.10626, 14.05171616]	2022-11-24 21:54:20.507743+03	2022-11-24 21:54:20.507743+03	16
129	["road_full_usa", 24000000, 57700000]	[1.23059, 46.88807808]	2022-11-24 21:54:20.507743+03	2022-11-24 21:54:20.507743+03	17
130	["road_full_usa", 24000000, 57700000]	[1.22714, 47.01989993]	2022-11-24 21:54:20.507743+03	2022-11-24 21:54:20.507743+03	18
131	["road_full_usa", 24000000, 57700000]	[9.99814, 5.77107342]	2022-11-24 21:54:20.507743+03	2022-11-24 21:54:20.507743+03	19
132	["web_web_trackers", 40400000, 140000000]	[778.258, 0.1798889314]	2022-11-24 21:54:20.507743+03	2022-11-24 21:54:20.507743+03	16
133	["web_web_trackers", 40400000, 140000000]	[318.325, 0.4398020891]	2022-11-24 21:54:20.507743+03	2022-11-24 21:54:20.507743+03	17
134	["web_web_trackers", 40400000, 140000000]	[321.373, 0.4356308713]	2022-11-24 21:54:20.507743+03	2022-11-24 21:54:20.507743+03	18
135	["web_web_trackers", 40400000, 140000000]	[9632.98, 0.01453340503]	2022-11-24 21:54:20.507743+03	2022-11-24 21:54:20.507743+03	19
136	["syn_rmat_18_32", 262144, 8388608]	[1056.07, 0.007943231036]	2022-11-30 19:09:35.665693+03	2022-11-30 19:09:35.665693+03	20
137	["syn_rmat_18_32", 262144, 8388608]	[1063.09, 0.007890778768]	2022-11-30 19:09:35.665693+03	2022-11-30 19:09:35.665693+03	21
138	["syn_rmat_18_32", 262144, 8388608]	[159.21, 0.0526889517]	2022-11-30 19:09:35.665693+03	2022-11-30 19:09:35.665693+03	22
139	["syn_rmat_18_32", 262144, 8388608]	[158.643, 0.05287726531]	2022-11-30 19:09:35.665693+03	2022-11-30 19:09:35.665693+03	23
140	["syn_rmat_18_32", 262144, 8388608]	[1058.49, 0.007925070619]	2022-11-30 19:09:35.665693+03	2022-11-30 19:09:35.665693+03	24
141	["syn_ru_18_32", 262144, 8388608]	[881.61, 0.009515100782]	2022-11-30 19:12:42.616743+03	2022-11-30 19:12:42.616743+03	20
142	["syn_ru_18_32", 262144, 8388608]	[712.281, 0.01177710482]	2022-11-30 19:12:42.616743+03	2022-11-30 19:12:42.616743+03	21
143	["syn_ru_18_32", 262144, 8388608]	[61.2192, 0.1370257697]	2022-11-30 19:12:42.616743+03	2022-11-30 19:12:42.616743+03	22
144	["syn_ru_18_32", 262144, 8388608]	[60.0562, 0.1396793004]	2022-11-30 19:12:42.616743+03	2022-11-30 19:12:42.616743+03	23
145	["syn_ru_18_32", 262144, 8388608]	[1148.14, 0.007306258819]	2022-11-30 19:12:42.616743+03	2022-11-30 19:12:42.616743+03	24
146	["syn_rmat_22_32", 4194304, 134217728]	[845.867, 0.158674742]	2022-11-30 19:19:17.468059+03	2022-11-30 19:19:17.468059+03	20
147	["syn_rmat_22_32", 4194304, 134217728]	[473.512, 0.2834515873]	2022-11-30 19:19:17.468059+03	2022-11-30 19:19:17.468059+03	21
148	["syn_rmat_22_32", 4194304, 134217728]	[95.2604, 1.408956166]	2022-11-30 19:19:17.468059+03	2022-11-30 19:19:17.468059+03	22
149	["syn_rmat_22_32", 4194304, 134217728]	[86.7705, 1.546812891]	2022-11-30 19:19:17.468059+03	2022-11-30 19:19:17.468059+03	23
150	["syn_rmat_22_32", 4194304, 134217728]	[1441.04, 0.09313948815]	2022-11-30 19:19:17.468059+03	2022-11-30 19:19:17.468059+03	24
151	["syn_ru_22_32", 4194304, 134217728]	[450.875, 0.2976827901]	2022-11-30 19:21:56.416603+03	2022-11-30 19:21:56.416603+03	20
152	["syn_ru_22_32", 4194304, 134217728]	[276.834, 0.4848310829]	2022-11-30 19:21:56.416603+03	2022-11-30 19:21:56.416603+03	21
153	["syn_ru_22_32", 4194304, 134217728]	[41.3414, 3.246569492]	2022-11-30 19:21:56.416603+03	2022-11-30 19:21:56.416603+03	22
154	["syn_ru_22_32", 4194304, 134217728]	[40.4569, 3.317548502]	2022-11-30 19:21:56.416603+03	2022-11-30 19:21:56.416603+03	23
155	["syn_ru_22_32", 4194304, 134217728]	[847.994, 0.1582767425]	2022-11-30 19:21:56.416603+03	2022-11-30 19:21:56.416603+03	24
156	["syn_rmat_24_32", 16777216, 536870912]	[685.803, 0.7828354673]	2022-11-30 19:24:17.384595+03	2022-11-30 19:24:17.384595+03	20
157	["syn_rmat_24_32", 16777216, 536870912]	[194.582, 2.759098539]	2022-11-30 19:24:17.384595+03	2022-11-30 19:24:17.384595+03	21
158	["syn_rmat_24_32", 16777216, 536870912]	[93.3895, 5.74872884]	2022-11-30 19:24:17.384595+03	2022-11-30 19:24:17.384595+03	22
159	["syn_rmat_24_32", 16777216, 536870912]	[87.6739, 6.123497552]	2022-11-30 19:24:17.384595+03	2022-11-30 19:24:17.384595+03	23
160	["syn_rmat_24_32", 16777216, 536870912]	[1184.12, 0.4533923183]	2022-11-30 19:24:17.384595+03	2022-11-30 19:24:17.384595+03	24
161	["syn_ru_24_32", 16777216, 536870912]	[237.981, 2.255940231]	2022-11-30 19:27:31.215588+03	2022-11-30 19:27:31.215588+03	20
162	["syn_ru_24_32", 16777216, 536870912]	[120.272, 4.463806306]	2022-11-30 19:27:31.215588+03	2022-11-30 19:27:31.215588+03	21
163	["syn_ru_24_32", 16777216, 536870912]	[13.4668, 39.86625717]	2022-11-30 19:27:31.215588+03	2022-11-30 19:27:31.215588+03	22
164	["syn_ru_24_32", 16777216, 536870912]	[11.2189, 47.85414898]	2022-11-30 19:27:31.215588+03	2022-11-30 19:27:31.215588+03	23
165	["syn_ru_24_32", 16777216, 536870912]	[365.79, 1.46770254]	2022-11-30 19:27:31.215588+03	2022-11-30 19:27:31.215588+03	24
166	["syn_rmat_25_32", 33554432, 1073741824]	[557.953, 1.924430595]	2022-11-30 19:30:40.447307+03	2022-11-30 19:30:40.447307+03	20
167	["syn_rmat_25_32", 33554432, 1073741824]	[232.142, 4.625366474]	2022-11-30 19:30:40.447307+03	2022-11-30 19:30:40.447307+03	21
168	["syn_rmat_25_32", 33554432, 1073741824]	[125.253, 8.572583683]	2022-11-30 19:30:40.447307+03	2022-11-30 19:30:40.447307+03	22
169	["syn_rmat_25_32", 33554432, 1073741824]	[212.045, 5.063745073]	2022-11-30 19:30:40.447307+03	2022-11-30 19:30:40.447307+03	23
170	["syn_ru_25_32", 33554432, 1073741824]	[174.51, 6.152895674]	2022-11-30 19:30:40.447307+03	2022-11-30 19:30:40.447307+03	20
171	["syn_ru_25_32", 33554432, 1073741824]	[113.535, 9.45736402]	2022-11-30 19:30:40.447307+03	2022-11-30 19:30:40.447307+03	21
172	["syn_ru_25_32", 33554432, 1073741824]	[11.2597, 95.36149489]	2022-11-30 19:30:40.447307+03	2022-11-30 19:30:40.447307+03	22
173	["syn_ru_25_32", 33554432, 1073741824]	[10.0088, 107.2797762]	2022-11-30 19:30:40.447307+03	2022-11-30 19:30:40.447307+03	23
174	["web_stanford", 282000, 2300000]	[866.927, 0.002653049219]	2022-11-30 19:46:43.279368+03	2022-11-30 19:46:43.279368+03	20
175	["web_stanford", 282000, 2300000]	[451.869, 0.005089970766]	2022-11-30 19:46:43.279368+03	2022-11-30 19:46:43.279368+03	21
176	["web_stanford", 282000, 2300000]	[127.254, 0.01807408804]	2022-11-30 19:46:43.279368+03	2022-11-30 19:46:43.279368+03	22
177	["web_stanford", 282000, 2300000]	[127.307, 0.0180665635]	2022-11-30 19:46:43.279368+03	2022-11-30 19:46:43.279368+03	23
178	["web_stanford", 282000, 2300000]	[356.784, 0.006446477421]	2022-11-30 19:46:43.279368+03	2022-11-30 19:46:43.279368+03	24
179	["soc_youtube_friendships", 1130000, 3000000]	[1929.21, 0.001555040664]	2022-11-30 19:48:31.700658+03	2022-11-30 19:48:31.700658+03	20
180	["soc_youtube_friendships", 1130000, 3000000]	[1191.12, 0.002518637921]	2022-11-30 19:48:31.700658+03	2022-11-30 19:48:31.700658+03	21
181	["soc_youtube_friendships", 1130000, 3000000]	[182.66, 0.01642395708]	2022-11-30 19:48:31.700658+03	2022-11-30 19:48:31.700658+03	22
182	["soc_youtube_friendships", 1130000, 3000000]	[300.77, 0.009974399042]	2022-11-30 19:48:31.700658+03	2022-11-30 19:48:31.700658+03	23
183	["soc_youtube_friendships", 1130000, 3000000]	[3057.93, 0.0009810558123]	2022-11-30 19:48:31.700658+03	2022-11-30 19:48:31.700658+03	24
184	["road_texas", 1380000, 1900000]	[961.623, 0.001975826285]	2022-11-30 20:13:23.282032+03	2022-11-30 20:13:23.282032+03	20
185	["road_texas", 1380000, 1900000]	[712.384, 0.002667100889]	2022-11-30 20:13:23.282032+03	2022-11-30 20:13:23.282032+03	21
186	["road_texas", 1380000, 1900000]	[258.65, 0.007345834139]	2022-11-30 20:13:23.282032+03	2022-11-30 20:13:23.282032+03	22
187	["road_texas", 1380000, 1900000]	[276.467, 0.006872429621]	2022-11-30 20:13:23.282032+03	2022-11-30 20:13:23.282032+03	23
188	["road_texas", 1380000, 1900000]	[2715.63, 0.0006996534874]	2022-11-30 20:13:23.282032+03	2022-11-30 20:13:23.282032+03	24
189	["soc_livejournal_links", 5200000, 49000000]	[3167.5, 0.01546961326]	2022-11-30 20:15:12.121071+03	2022-11-30 20:15:12.121071+03	20
190	["soc_livejournal_links", 5200000, 49000000]	[2274.06, 0.02154736463]	2022-11-30 20:15:12.121071+03	2022-11-30 20:15:12.121071+03	21
191	["soc_livejournal_links", 5200000, 49000000]	[188.276, 0.2602562196]	2022-11-30 20:15:12.121071+03	2022-11-30 20:15:12.121071+03	22
192	["soc_livejournal_links", 5200000, 49000000]	[143.497, 0.3414705534]	2022-11-30 20:15:12.121071+03	2022-11-30 20:15:12.121071+03	23
193	["soc_livejournal_links", 5200000, 49000000]	[4613.2, 0.01062169427]	2022-11-30 20:15:12.121071+03	2022-11-30 20:15:12.121071+03	24
194	["road_western_usa", 6200000, 15000000]	[12.3362, 1.215933594]	2022-11-30 20:16:58.07934+03	2022-11-30 20:16:58.07934+03	20
195	["road_western_usa", 6200000, 15000000]	[7.96098, 1.884190137]	2022-11-30 20:16:58.07934+03	2022-11-30 20:16:58.07934+03	21
196	["road_western_usa", 6200000, 15000000]	[0.433524, 34.60016054]	2022-11-30 20:16:58.07934+03	2022-11-30 20:16:58.07934+03	22
197	["road_western_usa", 6200000, 15000000]	[0.414755, 36.16592928]	2022-11-30 20:16:58.07934+03	2022-11-30 20:16:58.07934+03	23
198	["road_western_usa", 6200000, 15000000]	[6.20466, 2.417537786]	2022-11-30 20:16:58.07934+03	2022-11-30 20:16:58.07934+03	24
199	["web_zhishi", 7830000, 66000000]	[464.07, 0.1422199237]	2022-11-30 20:30:55.743529+03	2022-11-30 20:30:55.743529+03	20
200	["web_zhishi", 7830000, 66000000]	[279.181, 0.2364057726]	2022-11-30 20:30:55.743529+03	2022-11-30 20:30:55.743529+03	21
201	["web_zhishi", 7830000, 66000000]	[63.8469, 1.033722859]	2022-11-30 20:30:55.743529+03	2022-11-30 20:30:55.743529+03	22
202	["web_zhishi", 7830000, 66000000]	[19.6485, 3.359035041]	2022-11-30 20:30:55.743529+03	2022-11-30 20:30:55.743529+03	23
203	["web_zhishi", 7830000, 66000000]	[560.352, 0.1177831078]	2022-11-30 20:30:55.743529+03	2022-11-30 20:30:55.743529+03	24
204	["rating_amazon_ratings", 3400000, 5800000]	[534.368, 0.01085394335]	2022-11-30 20:30:55.743529+03	2022-11-30 20:30:55.743529+03	20
205	["rating_amazon_ratings", 3400000, 5800000]	[444.688, 0.01304285252]	2022-11-30 20:30:55.743529+03	2022-11-30 20:30:55.743529+03	21
206	["rating_amazon_ratings", 3400000, 5800000]	[47.6169, 0.1218054934]	2022-11-30 20:30:55.743529+03	2022-11-30 20:30:55.743529+03	22
207	["rating_amazon_ratings", 3400000, 5800000]	[41.9349, 0.138309618]	2022-11-30 20:30:55.743529+03	2022-11-30 20:30:55.743529+03	23
208	["rating_amazon_ratings", 3400000, 5800000]	[796.199, 0.007284611008]	2022-11-30 20:30:55.743529+03	2022-11-30 20:30:55.743529+03	24
209	["road_central_usa", 14000000, 34000000]	[10.7165, 3.172677647]	2022-11-30 20:32:42.376072+03	2022-11-30 20:32:42.376072+03	20
210	["road_central_usa", 14000000, 34000000]	[6.40476, 5.308551765]	2022-11-30 20:32:42.376072+03	2022-11-30 20:32:42.376072+03	21
211	["road_central_usa", 14000000, 34000000]	[0.340671, 99.80303577]	2022-11-30 20:32:42.376072+03	2022-11-30 20:32:42.376072+03	22
212	["road_central_usa", 14000000, 34000000]	[0.330247, 102.9532441]	2022-11-30 20:32:42.376072+03	2022-11-30 20:32:42.376072+03	23
213	["road_central_usa", 14000000, 34000000]	[5.22058, 6.51268633]	2022-11-30 20:32:42.376072+03	2022-11-30 20:32:42.376072+03	24
214	["web_uk_domain_2002", 18500000, 262000000]	[2796.3, 0.09369524014]	2022-11-30 20:34:15.808114+03	2022-11-30 20:34:15.808114+03	20
215	["web_uk_domain_2002", 18500000, 262000000]	[2606.36, 0.1005233352]	2022-11-30 20:34:15.808114+03	2022-11-30 20:34:15.808114+03	21
216	["web_uk_domain_2002", 18500000, 262000000]	[113.851, 2.301253393]	2022-11-30 20:34:15.808114+03	2022-11-30 20:34:15.808114+03	22
217	["web_uk_domain_2002", 18500000, 262000000]	[183.031, 1.431451503]	2022-11-30 20:34:15.808114+03	2022-11-30 20:34:15.808114+03	23
218	["web_uk_domain_2002", 18500000, 262000000]	[3167.96, 0.08270306443]	2022-11-30 20:34:15.808114+03	2022-11-30 20:34:15.808114+03	24
219	["soc_twitter_www", 41600000, 1500000000]	[270.177, 5.551915966]	2022-11-30 20:35:43.94486+03	2022-11-30 20:35:43.94486+03	20
220	["soc_twitter_www", 41600000, 1500000000]	[111.051, 13.50730745]	2022-11-30 20:35:43.94486+03	2022-11-30 20:35:43.94486+03	21
221	["soc_twitter_www", 41600000, 1500000000]	[24.0758, 62.30322565]	2022-11-30 20:35:43.94486+03	2022-11-30 20:35:43.94486+03	22
222	["soc_twitter_www", 41600000, 1500000000]	[50.9567, 29.43675709]	2022-11-30 20:35:43.94486+03	2022-11-30 20:35:43.94486+03	23
223	["road_full_usa", 24000000, 57700000]	[6.57993, 8.769090249]	2022-11-30 20:49:44.396498+03	2022-11-30 20:49:44.396498+03	20
224	["road_full_usa", 24000000, 57700000]	[4.7389, 12.17582139]	2022-11-30 20:49:44.396498+03	2022-11-30 20:49:44.396498+03	21
225	["road_full_usa", 24000000, 57700000]	[0.22178, 260.1677338]	2022-11-30 20:49:44.396498+03	2022-11-30 20:49:44.396498+03	22
226	["road_full_usa", 24000000, 57700000]	[0.211417, 272.9203423]	2022-11-30 20:49:44.396498+03	2022-11-30 20:49:44.396498+03	23
227	["road_full_usa", 24000000, 57700000]	[3.60526, 16.00439358]	2022-11-30 20:49:44.396498+03	2022-11-30 20:49:44.396498+03	24
228	["web_web_trackers", 40400000, 140000000]	[615.486, 0.2274625255]	2022-11-30 20:49:44.396498+03	2022-11-30 20:49:44.396498+03	20
229	["web_web_trackers", 40400000, 140000000]	[427.135, 0.3277652265]	2022-11-30 20:49:44.396498+03	2022-11-30 20:49:44.396498+03	21
230	["web_web_trackers", 40400000, 140000000]	[28.4235, 4.925501785]	2022-11-30 20:49:44.396498+03	2022-11-30 20:49:44.396498+03	22
231	["web_web_trackers", 40400000, 140000000]	[26.6447, 5.254328253]	2022-11-30 20:49:44.396498+03	2022-11-30 20:49:44.396498+03	23
232	["web_web_trackers", 40400000, 140000000]	[873.783, 0.1602228471]	2022-11-30 20:49:44.396498+03	2022-11-30 20:49:44.396498+03	24
233	["syn_rmat_18_32", 262144, 8388608]	[2441.64, 0.003435644894]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	25
234	["syn_rmat_18_32", 262144, 8388608]	[1381.01, 0.006074255798]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	26
235	["syn_rmat_18_32", 262144, 8388608]	[266.793, 0.03144238417]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	27
236	["syn_rmat_18_32", 262144, 8388608]	[266.384, 0.0314906601]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	28
237	["syn_rmat_18_32", 262144, 8388608]	[1104.09, 0.007597757429]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	29
238	["syn_ru_18_32", 262144, 8388608]	[404.267, 0.02075016759]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	25
239	["syn_ru_18_32", 262144, 8388608]	[367.68, 0.02281496954]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	26
240	["syn_ru_18_32", 262144, 8388608]	[52.138, 0.1608924009]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	27
241	["syn_ru_18_32", 262144, 8388608]	[47.0394, 0.1783315263]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	28
242	["syn_ru_18_32", 262144, 8388608]	[1825.03, 0.004596421977]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	29
243	["syn_rmat_22_32", 4194304, 134217728]	[222.059, 0.6044237252]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	25
244	["syn_rmat_22_32", 4194304, 134217728]	[945.772, 0.1419134083]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	26
245	["syn_rmat_22_32", 4194304, 134217728]	[200.936, 0.6679625751]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	27
246	["syn_rmat_22_32", 4194304, 134217728]	[576.14, 0.2329602666]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	28
247	["syn_rmat_22_32", 4194304, 134217728]	[3774.2, 0.03556190133]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	29
248	["syn_ru_22_32", 4194304, 134217728]	[243.287, 0.5516847509]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	25
249	["syn_ru_22_32", 4194304, 134217728]	[154.402, 0.8692745431]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	26
250	["syn_ru_22_32", 4194304, 134217728]	[31.2235, 4.298612519]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	27
251	["syn_ru_22_32", 4194304, 134217728]	[26.486, 5.067497093]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	28
252	["syn_ru_22_32", 4194304, 134217728]	[1157.1, 0.1159949252]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	29
253	["syn_rmat_24_32", 16777216, 536870912]	[7043.74, 0.07621958107]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	25
254	["syn_rmat_24_32", 16777216, 536870912]	[1329.11, 0.4039326406]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	26
255	["syn_rmat_24_32", 16777216, 536870912]	[438.548, 1.224201027]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	27
256	["syn_rmat_24_32", 16777216, 536870912]	[656.412, 0.8178871075]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	28
257	["syn_rmat_24_32", 16777216, 536870912]	[7811.28, 0.06873020965]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	29
258	["syn_ru_24_32", 16777216, 536870912]	[135.072, 3.974701729]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	25
259	["syn_ru_24_32", 16777216, 536870912]	[102.369, 5.244467681]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	26
260	["syn_ru_24_32", 16777216, 536870912]	[10.4431, 51.40915169]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	27
261	["syn_ru_24_32", 16777216, 536870912]	[9.06907, 59.1980117]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	28
262	["syn_ru_24_32", 16777216, 536870912]	[404.978, 1.325679202]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	29
263	["syn_rmat_25_32", 33554432, 1073741824]	[397.505, 2.701203316]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	25
264	["syn_rmat_25_32", 33554432, 1073741824]	[247.728, 4.334357941]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	26
265	["syn_rmat_25_32", 33554432, 1073741824]	[546.506, 1.964739315]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	27
266	["syn_rmat_25_32", 33554432, 1073741824]	[839.791, 1.2785822]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	28
267	["syn_ru_25_32", 33554432, 1073741824]	[124.591, 8.618133124]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	25
268	["syn_ru_25_32", 33554432, 1073741824]	[75.5062, 14.22057823]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	26
269	["syn_ru_25_32", 33554432, 1073741824]	[8.64188, 124.2486385]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	27
270	["syn_ru_25_32", 33554432, 1073741824]	[7.80484, 137.5738419]	2022-12-01 22:34:41.979869+03	2022-12-01 22:34:41.979869+03	28
271	["web_stanford", 282000, 2300000]	[602.697, 0.003816179606]	2022-12-02 22:41:40.347284+03	2022-12-02 22:41:40.347284+03	25
272	["web_stanford", 282000, 2300000]	[351.028, 0.006552183871]	2022-12-02 22:41:40.347284+03	2022-12-02 22:41:40.347284+03	26
273	["web_stanford", 282000, 2300000]	[40.9023, 0.05623155666]	2022-12-02 22:41:40.347284+03	2022-12-02 22:41:40.347284+03	27
274	["web_stanford", 282000, 2300000]	[87.2836, 0.02635088379]	2022-12-02 22:41:40.347284+03	2022-12-02 22:41:40.347284+03	28
275	["web_stanford", 282000, 2300000]	[369.26, 0.006228673563]	2022-12-02 22:41:40.347284+03	2022-12-02 22:41:40.347284+03	29
276	["soc_youtube_friendships", 1130000, 3000000]	[2261.04, 0.001326823055]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	25
277	["soc_youtube_friendships", 1130000, 3000000]	[2114.47, 0.001418795254]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	26
278	["soc_youtube_friendships", 1130000, 3000000]	[638.632, 0.004697540994]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	27
279	["soc_youtube_friendships", 1130000, 3000000]	[414.999, 0.007228933082]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	28
280	["soc_youtube_friendships", 1130000, 3000000]	[8422.19, 0.0003562018905]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	29
281	["road_texas", 1380000, 1900000]	[916.231, 0.002073712852]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	25
282	["road_texas", 1380000, 1900000]	[925.926, 0.002051999836]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	26
283	["road_texas", 1380000, 1900000]	[276.671, 0.006867362318]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	28
284	["road_texas", 1380000, 1900000]	[2409.61, 0.0007885093438]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	29
285	["soc_livejournal_links", 5200000, 49000000]	[7427.8, 0.006596838903]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	25
286	["soc_livejournal_links", 5200000, 49000000]	[3899.19, 0.01256671257]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	26
287	["soc_livejournal_links", 5200000, 49000000]	[427.733, 0.1145574459]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	27
288	["soc_livejournal_links", 5200000, 49000000]	[452.879, 0.1081966706]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	28
289	["soc_livejournal_links", 5200000, 49000000]	[11367.5, 0.004310534418]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	29
290	["road_western_usa", 6200000, 15000000]	[12.5679, 1.193516817]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	25
291	["road_western_usa", 6200000, 15000000]	[8.86087, 1.692836031]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	26
292	["road_western_usa", 6200000, 15000000]	[0.245794, 61.02671343]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	27
293	["road_western_usa", 6200000, 15000000]	[0.241588, 62.08917661]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	28
294	["road_western_usa", 6200000, 15000000]	[3.3147, 4.525296407]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	29
295	["web_zhishi", 7830000, 66000000]	[5692.28, 0.011594651]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	25
296	["web_zhishi", 7830000, 66000000]	[2899.78, 0.02276034734]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	26
297	["web_zhishi", 7830000, 66000000]	[311.836, 0.2116497133]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	27
298	["web_zhishi", 7830000, 66000000]	[235.212, 0.2805979287]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	28
299	["web_zhishi", 7830000, 66000000]	[5490.88, 0.01201993123]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	29
300	["rating_amazon_ratings", 3400000, 5800000]	[316.125, 0.0183471728]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	25
301	["rating_amazon_ratings", 3400000, 5800000]	[208.565, 0.02780907631]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	26
302	["rating_amazon_ratings", 3400000, 5800000]	[37.0389, 0.1565921234]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	27
303	["rating_amazon_ratings", 3400000, 5800000]	[34.9502, 0.1659504094]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	28
304	["rating_amazon_ratings", 3400000, 5800000]	[761.434, 0.007617206481]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	29
305	["road_central_usa", 14000000, 34000000]	[11.125, 3.056179775]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	25
306	["road_central_usa", 14000000, 34000000]	[6.76256, 5.027681825]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	26
307	["road_central_usa", 14000000, 34000000]	[0.18956, 179.3627348]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	27
308	["road_central_usa", 14000000, 34000000]	[0.179073, 189.8667024]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	28
309	["road_central_usa", 14000000, 34000000]	[2.65782, 12.79243892]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	29
310	["web_uk_domain_2002", 18500000, 262000000]	[4350.03, 0.06022946968]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	25
311	["web_uk_domain_2002", 18500000, 262000000]	[2468.76, 0.1061261524]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	26
312	["web_uk_domain_2002", 18500000, 262000000]	[210.216, 1.246337101]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	27
313	["web_uk_domain_2002", 18500000, 262000000]	[303.123, 0.8643355997]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	28
314	["web_uk_domain_2002", 18500000, 262000000]	[4503.35, 0.05817891125]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	29
315	["soc_twitter_www", 41600000, 1500000000]	[1097.52, 1.366717691]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	25
316	["soc_twitter_www", 41600000, 1500000000]	[121.664, 12.32903735]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	26
317	["soc_twitter_www", 41600000, 1500000000]	[17.5363, 85.53685783]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	27
318	["soc_twitter_www", 41600000, 1500000000]	[90.5027, 16.57409116]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	28
319	["road_full_usa", 24000000, 57700000]	[7.71029, 7.483505808]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	25
320	["road_full_usa", 24000000, 57700000]	[5.07409, 11.37149716]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	26
321	["road_full_usa", 24000000, 57700000]	[2.02184, 28.5383611]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	29
322	["web_web_trackers", 40400000, 140000000]	[205.256, 0.6820750672]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	25
323	["web_web_trackers", 40400000, 140000000]	[154.232, 0.9077234296]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	26
324	["web_web_trackers", 40400000, 140000000]	[13.7971, 10.14705989]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	27
325	["web_web_trackers", 40400000, 140000000]	[13.6598, 10.24905196]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	28
326	["web_web_trackers", 40400000, 140000000]	[327.187, 0.4278898611]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	29
327	["syn_rmat_18_32", 262144, 8388608]	[5420.85, 0.001547470969]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	30
328	["syn_rmat_18_32", 262144, 8388608]	[4843.07, 0.001732084814]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	31
329	["syn_rmat_18_32", 262144, 8388608]	[1350.28, 0.006212495186]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	32
330	["syn_rmat_18_32", 262144, 8388608]	[1183.49, 0.007088026092]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	33
331	["syn_rmat_18_32", 262144, 8388608]	[6435.75, 0.001303439071]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	34
332	["syn_ru_18_32", 262144, 8388608]	[5123.68, 0.001637223246]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	30
333	["syn_ru_18_32", 262144, 8388608]	[4873.68, 0.001721206152]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	31
334	["syn_ru_18_32", 262144, 8388608]	[1096.32, 0.007651605371]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	32
335	["syn_ru_18_32", 262144, 8388608]	[1044.01, 0.008034988171]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	33
336	["syn_ru_18_32", 262144, 8388608]	[13186.3, 0.0006361608639]	2022-12-02 23:36:00.702559+03	2022-12-02 23:36:00.702559+03	34
337	["syn_rmat_22_32", 4194304, 134217728]	[6105.72, 0.02198229332]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	30
338	["syn_rmat_22_32", 4194304, 134217728]	[4337.47, 0.03094378244]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	31
339	["syn_rmat_22_32", 4194304, 134217728]	[1093.85, 0.1227021328]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	32
340	["syn_rmat_22_32", 4194304, 134217728]	[1056.33, 0.1270604148]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	33
341	["syn_rmat_22_32", 4194304, 134217728]	[7890.26, 0.01701055833]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	34
342	["syn_ru_22_32", 4194304, 134217728]	[3885.3, 0.03454501017]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	30
343	["syn_ru_22_32", 4194304, 134217728]	[2793.68, 0.04804334355]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	31
344	["syn_ru_22_32", 4194304, 134217728]	[383.475, 0.3500038542]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	32
345	["syn_ru_22_32", 4194304, 134217728]	[388.002, 0.3459201963]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	33
346	["syn_ru_22_32", 4194304, 134217728]	[5610.48, 0.02392268184]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	34
347	["syn_rmat_24_32", 16777216, 536870912]	[10335.9, 0.05194234774]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	30
348	["syn_rmat_24_32", 16777216, 536870912]	[7975.27, 0.06731695755]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	31
349	["syn_rmat_24_32", 16777216, 536870912]	[1167.37, 0.4598978147]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	32
350	["syn_rmat_24_32", 16777216, 536870912]	[1124.88, 0.4772694972]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	33
351	["syn_rmat_24_32", 16777216, 536870912]	[13759.3, 0.03901876636]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	34
352	["syn_ru_24_32", 16777216, 536870912]	[2830.61, 0.1896661539]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	30
353	["syn_ru_24_32", 16777216, 536870912]	[2200.18, 0.2440122681]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	31
354	["syn_ru_24_32", 16777216, 536870912]	[227.819, 2.356567767]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	32
355	["syn_ru_24_32", 16777216, 536870912]	[197.969, 2.711893842]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	33
356	["syn_ru_24_32", 16777216, 536870912]	[4013.45, 0.1337679333]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	34
357	["syn_rmat_25_32", 33554432, 1073741824]	[20663.8, 0.05196245724]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	30
358	["syn_rmat_25_32", 33554432, 1073741824]	[1596.85, 0.672412452]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	32
359	["syn_rmat_25_32", 33554432, 1073741824]	[1537.49, 0.6983732083]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	33
360	["syn_ru_25_32", 33554432, 1073741824]	[2765.09, 0.3883207505]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	30
361	["syn_ru_25_32", 33554432, 1073741824]	[1341.7, 0.8002845822]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	31
362	["syn_ru_25_32", 33554432, 1073741824]	[219.009, 4.902729221]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	32
363	["syn_ru_25_32", 33554432, 1073741824]	[188.815, 5.686740058]	2022-12-03 16:29:29.859795+03	2022-12-03 16:29:29.859795+03	33
364	["web_stanford", 282000, 2300000]	[1637.97, 0.001404177122]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	30
365	["web_stanford", 282000, 2300000]	[1714.33, 0.001341632008]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	31
366	["web_stanford", 282000, 2300000]	[1450.19, 0.001585999076]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	32
367	["web_stanford", 282000, 2300000]	[1602.27, 0.001435463436]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	33
368	["web_stanford", 282000, 2300000]	[172.677, 0.0133196662]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	34
369	["soc_youtube_friendships", 1130000, 3000000]	[2130.2, 0.001408318468]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	30
370	["soc_youtube_friendships", 1130000, 3000000]	[2109.47, 0.001422158172]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	31
371	["soc_youtube_friendships", 1130000, 3000000]	[730.245, 0.004108210258]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	32
372	["soc_youtube_friendships", 1130000, 3000000]	[740.028, 0.004053900663]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	33
373	["soc_youtube_friendships", 1130000, 3000000]	[263.305, 0.01139363096]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	34
374	["road_texas", 1380000, 1900000]	[1505.71, 0.001261863174]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	30
375	["road_texas", 1380000, 1900000]	[1473.17, 0.00128973574]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	31
376	["road_texas", 1380000, 1900000]	[449.478, 0.004227125688]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	32
377	["road_texas", 1380000, 1900000]	[443.567, 0.004283456614]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	33
378	["road_texas", 1380000, 1900000]	[4213.66, 0.000450914407]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	34
379	["soc_livejournal_links", 5200000, 49000000]	[7226.5, 0.006780599184]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	30
380	["soc_livejournal_links", 5200000, 49000000]	[4699.31, 0.0104270627]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	31
381	["soc_livejournal_links", 5200000, 49000000]	[519.444, 0.09433163151]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	32
382	["soc_livejournal_links", 5200000, 49000000]	[509.521, 0.09616875458]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	33
383	["soc_livejournal_links", 5200000, 49000000]	[11683.7, 0.00419387694]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	34
384	["road_western_usa", 6200000, 15000000]	[5831.1, 0.002572413438]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	30
385	["road_western_usa", 6200000, 15000000]	[4973.25, 0.003016136329]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	31
386	["road_western_usa", 6200000, 15000000]	[482.473, 0.03108982264]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	32
387	["road_western_usa", 6200000, 15000000]	[467.581, 0.03208000325]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	33
388	["web_zhishi", 7830000, 66000000]	[5090.08, 0.01296639738]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	30
389	["web_zhishi", 7830000, 66000000]	[3421.53, 0.01928961605]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	31
390	["web_zhishi", 7830000, 66000000]	[669.743, 0.09854526288]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	32
391	["web_zhishi", 7830000, 66000000]	[640.814, 0.1029940045]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	33
392	["web_zhishi", 7830000, 66000000]	[16735.8, 0.003943641774]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	34
393	["rating_amazon_ratings", 3400000, 5800000]	[2714.68, 0.002136531746]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	30
394	["rating_amazon_ratings", 3400000, 5800000]	[2166.38, 0.002677277301]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	31
395	["rating_amazon_ratings", 3400000, 5800000]	[596.953, 0.009716007793]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	32
396	["rating_amazon_ratings", 3400000, 5800000]	[588.776, 0.009850945011]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	33
397	["rating_amazon_ratings", 3400000, 5800000]	[7343.88, 0.0007897732534]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	34
398	["road_central_usa", 14000000, 34000000]	[7426.43, 0.004578242843]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	30
399	["road_central_usa", 14000000, 34000000]	[5842.89, 0.005819038181]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	31
400	["road_central_usa", 14000000, 34000000]	[511.559, 0.06646349688]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	32
401	["road_central_usa", 14000000, 34000000]	[495.644, 0.06859762249]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	33
402	["web_uk_domain_2002", 18500000, 262000000]	[13287.6, 0.01971763148]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	30
403	["web_uk_domain_2002", 18500000, 262000000]	[9451.19, 0.02772137688]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	31
404	["web_uk_domain_2002", 18500000, 262000000]	[882.734, 0.2968051531]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	32
405	["web_uk_domain_2002", 18500000, 262000000]	[803.734, 0.3259784954]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	33
406	["web_uk_domain_2002", 18500000, 262000000]	[10030.2, 0.02612111424]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	34
407	["soc_twitter_www", 41600000, 1500000000]	[4639.3, 0.3233246395]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	30
408	["soc_twitter_www", 41600000, 1500000000]	[1818.39, 0.8249055483]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	31
409	["soc_twitter_www", 41600000, 1500000000]	[444.5, 3.374578178]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	32
410	["soc_twitter_www", 41600000, 1500000000]	[402.455, 3.727124772]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	33
411	["road_full_usa", 24000000, 57700000]	[8298.94, 0.006952695163]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	30
412	["road_full_usa", 24000000, 57700000]	[6272.43, 0.009198986677]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	31
413	["road_full_usa", 24000000, 57700000]	[507.026, 0.1138008702]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	32
414	["road_full_usa", 24000000, 57700000]	[490.767, 0.1175710673]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	33
415	["road_full_usa", 24000000, 57700000]	[6861.53, 0.008409203195]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	34
416	["web_web_trackers", 40400000, 140000000]	[2302.6, 0.06080083384]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	30
417	["web_web_trackers", 40400000, 140000000]	[2315.57, 0.06046027544]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	31
418	["web_web_trackers", 40400000, 140000000]	[604.473, 0.2316067053]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	32
419	["web_web_trackers", 40400000, 140000000]	[558.769, 0.2505507643]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	33
420	["web_web_trackers", 40400000, 140000000]	[8991.28, 0.01557064178]	2022-12-03 18:59:56.356361+03	2022-12-03 18:59:56.356361+03	34
421	["syn_rmat_18_32", 262144, 8388608]	[4129.87, 0.002031203888]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	35
422	["syn_rmat_18_32", 262144, 8388608]	[3580.56, 0.002342820118]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	36
423	["syn_rmat_18_32", 262144, 8388608]	[850.929, 0.009858176182]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	37
424	["syn_rmat_18_32", 262144, 8388608]	[868.898, 0.00965430695]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	38
425	["syn_rmat_18_32", 262144, 8388608]	[6107.41, 0.001373513159]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	39
426	["syn_ru_18_32", 262144, 8388608]	[4065.91, 0.002063156341]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	35
427	["syn_ru_18_32", 262144, 8388608]	[3603.71, 0.002327769993]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	36
428	["syn_ru_18_32", 262144, 8388608]	[743.331, 0.01128515829]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	37
429	["syn_ru_18_32", 262144, 8388608]	[711.976, 0.01178214996]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	38
430	["syn_ru_18_32", 262144, 8388608]	[14238.6, 0.0005891455621]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	39
431	["syn_rmat_22_32", 4194304, 134217728]	[5234.07, 0.02564308999]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	35
432	["syn_rmat_22_32", 4194304, 134217728]	[3586.93, 0.03741855236]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	36
433	["syn_rmat_22_32", 4194304, 134217728]	[604.915, 0.2218786573]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	37
434	["syn_rmat_22_32", 4194304, 134217728]	[580.982, 0.2310187372]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	38
435	["syn_rmat_22_32", 4194304, 134217728]	[12481.7, 0.01075316087]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	39
436	["syn_ru_22_32", 4194304, 134217728]	[3395.45, 0.03952870106]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	35
437	["syn_ru_22_32", 4194304, 134217728]	[2471.49, 0.0543064014]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	36
438	["syn_ru_22_32", 4194304, 134217728]	[279.519, 0.4801738987]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	37
439	["syn_ru_22_32", 4194304, 134217728]	[261.881, 0.5125141877]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	38
440	["syn_ru_22_32", 4194304, 134217728]	[6637.55, 0.02022097431]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	39
441	["syn_rmat_24_32", 16777216, 536870912]	[6953.34, 0.07721050776]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	35
442	["syn_rmat_24_32", 16777216, 536870912]	[4648.56, 0.1154918753]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	36
443	["syn_rmat_24_32", 16777216, 536870912]	[570.771, 0.9406064989]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	37
444	["syn_rmat_24_32", 16777216, 536870912]	[558.021, 0.9620980429]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	38
445	["syn_rmat_24_32", 16777216, 536870912]	[11929.1, 0.04500514808]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	39
446	["syn_ru_24_32", 16777216, 536870912]	[2555.02, 0.2101239568]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	35
447	["syn_ru_24_32", 16777216, 536870912]	[2016.53, 0.2662350235]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	36
448	["syn_ru_24_32", 16777216, 536870912]	[193.097, 2.780317208]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	37
449	["syn_ru_24_32", 16777216, 536870912]	[163.076, 3.292151586]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	38
450	["syn_ru_24_32", 16777216, 536870912]	[3815.39, 0.1407119356]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	39
451	["syn_rmat_25_32", 33554432, 1073741824]	[11522.4, 0.09318734153]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	35
452	["syn_rmat_25_32", 33554432, 1073741824]	[1421.35, 0.755438016]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	36
453	["syn_rmat_25_32", 33554432, 1073741824]	[643.248, 1.669250155]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	37
454	["syn_rmat_25_32", 33554432, 1073741824]	[626.218, 1.714645417]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	38
455	["syn_ru_25_32", 33554432, 1073741824]	[2471.51, 0.4344476955]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	35
456	["syn_ru_25_32", 33554432, 1073741824]	[916.856, 1.171112829]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	36
457	["syn_ru_25_32", 33554432, 1073741824]	[187.101, 5.738835303]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	37
458	["syn_ru_25_32", 33554432, 1073741824]	[155.224, 6.917369891]	2022-12-03 19:59:32.386488+03	2022-12-03 19:59:32.386488+03	38
459	["web_stanford", 282000, 2300000]	[1382.4, 0.001663773148]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	35
460	["web_stanford", 282000, 2300000]	[1397.06, 0.001646314403]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	36
461	["web_stanford", 282000, 2300000]	[627.888, 0.003663073669]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	37
462	["web_stanford", 282000, 2300000]	[635.259, 0.003620570507]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	38
463	["web_stanford", 282000, 2300000]	[4275.33, 0.0005379701684]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	39
464	["soc_youtube_friendships", 1130000, 3000000]	[1152.97, 0.002601975767]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	35
465	["soc_youtube_friendships", 1130000, 3000000]	[957.26, 0.003133944801]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	36
466	["soc_youtube_friendships", 1130000, 3000000]	[223.002, 0.01345279415]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	37
467	["soc_youtube_friendships", 1130000, 3000000]	[224.151, 0.013383835]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	38
468	["soc_youtube_friendships", 1130000, 3000000]	[2692.98, 0.001114007531]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	39
469	["road_texas", 1380000, 1900000]	[1360.66, 0.001396381168]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	35
470	["road_texas", 1380000, 1900000]	[1329.86, 0.00142872182]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	36
471	["road_texas", 1380000, 1900000]	[130.79, 0.01452710452]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	37
472	["road_texas", 1380000, 1900000]	[131.68, 0.01442891859]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	38
473	["road_texas", 1380000, 1900000]	[1847.26, 0.001028550394]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	39
474	["soc_livejournal_links", 5200000, 49000000]	[4011.15, 0.01221594804]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	35
475	["soc_livejournal_links", 5200000, 49000000]	[2866.17, 0.01709598523]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	36
476	["soc_livejournal_links", 5200000, 49000000]	[286.949, 0.1707620518]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	37
477	["soc_livejournal_links", 5200000, 49000000]	[272.679, 0.1796984733]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	38
478	["soc_livejournal_links", 5200000, 49000000]	[6677.44, 0.007338141563]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	39
479	["road_western_usa", 6200000, 15000000]	[4528.56, 0.003312311198]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	35
480	["road_western_usa", 6200000, 15000000]	[3600.96, 0.004165555852]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	36
481	["road_western_usa", 6200000, 15000000]	[147.02, 0.1020269351]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	37
482	["road_western_usa", 6200000, 15000000]	[150.442, 0.09970619907]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	38
483	["road_western_usa", 6200000, 15000000]	[2484.6, 0.006037189085]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	39
484	["web_zhishi", 7830000, 66000000]	[4115.94, 0.01603521917]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	35
485	["web_zhishi", 7830000, 66000000]	[2744.83, 0.02404520499]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	36
486	["web_zhishi", 7830000, 66000000]	[256.805, 0.2570043418]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	37
487	["web_zhishi", 7830000, 66000000]	[238.792, 0.2763911689]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	38
488	["web_zhishi", 7830000, 66000000]	[5448.65, 0.01211309223]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	39
489	["rating_amazon_ratings", 3400000, 5800000]	[1563.05, 0.003710693836]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	35
490	["rating_amazon_ratings", 3400000, 5800000]	[1168.59, 0.004963246305]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	36
491	["rating_amazon_ratings", 3400000, 5800000]	[174.571, 0.03322430415]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	37
492	["rating_amazon_ratings", 3400000, 5800000]	[166.58, 0.03481810541]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	38
493	["rating_amazon_ratings", 3400000, 5800000]	[2906.57, 0.001995479207]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	39
494	["road_central_usa", 14000000, 34000000]	[5476.76, 0.006208050015]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	35
495	["road_central_usa", 14000000, 34000000]	[4114.16, 0.008264141404]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	36
496	["road_central_usa", 14000000, 34000000]	[146.94, 0.2313869607]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	37
497	["road_central_usa", 14000000, 34000000]	[146.425, 0.2322007854]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	38
498	["road_central_usa", 14000000, 34000000]	[2434.33, 0.01396688206]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	39
499	["web_uk_domain_2002", 18500000, 262000000]	[8772.34, 0.02986660344]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	35
500	["web_uk_domain_2002", 18500000, 262000000]	[5708.68, 0.04589502302]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	36
501	["web_uk_domain_2002", 18500000, 262000000]	[405.807, 0.6456271085]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	37
502	["web_uk_domain_2002", 18500000, 262000000]	[375.19, 0.6983128548]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	38
503	["web_uk_domain_2002", 18500000, 262000000]	[8691.84, 0.03014321479]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	39
504	["soc_twitter_www", 41600000, 1500000000]	[2820.52, 0.5318168281]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	35
505	["soc_twitter_www", 41600000, 1500000000]	[1152.44, 1.3015862]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	36
506	["soc_twitter_www", 41600000, 1500000000]	[319.957, 4.688129967]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	37
507	["soc_twitter_www", 41600000, 1500000000]	[284.368, 5.274855117]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	38
508	["road_full_usa", 24000000, 57700000]	[5935.28, 0.009721529566]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	35
509	["road_full_usa", 24000000, 57700000]	[4322.03, 0.01335020812]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	36
510	["road_full_usa", 24000000, 57700000]	[144.473, 0.3993825836]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	37
511	["road_full_usa", 24000000, 57700000]	[145.119, 0.3976047244]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	38
512	["road_full_usa", 24000000, 57700000]	[2364.95, 0.02439797882]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	39
513	["web_web_trackers", 40400000, 140000000]	[374.729, 0.373603324]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	35
514	["web_web_trackers", 40400000, 140000000]	[287.291, 0.4873107755]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	36
515	["web_web_trackers", 40400000, 140000000]	[165.272, 0.847088436]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	37
516	["web_web_trackers", 40400000, 140000000]	[150.505, 0.9302016544]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	38
517	["web_web_trackers", 40400000, 140000000]	[2635.97, 0.05311137835]	2022-12-03 21:52:44.366469+03	2022-12-03 21:52:44.366469+03	39
\.


--
-- TOC entry 2866 (class 0 OID 18229)
-- Dependencies: 195
-- Data for Name: scomp; Type: TABLE DATA; Schema: public; Owner: adm
--

COPY public.scomp (id, sc_nm_ru, sc_nm_en) FROM stdin;
29	Ломоносов-2	Lomonosov-2
91	Fugaku	Fugaku
108	Frontera	Frontera
\.


--
-- TOC entry 2861 (class 0 OID 16694)
-- Dependencies: 190
-- Data for Name: type_exp; Type: TABLE DATA; Schema: public; Owner: adm
--

COPY public.type_exp (id, name, goal, ccond, vcond, result, created_at, updated_at, path_to_type) FROM stdin;
10	"Производительность тестов linpack"	"Сравнение производительности решения СЛАУ для плотных матриц для различных суперкомпьютеров"	["n_cores", "units"]	["mtx_size", "units", "block_size", "units", "P", "units", "Q", "units"]	["performance", "PFlop/s"]	2022-08-29 16:51:46.540243+03	2023-02-26 20:43:18.261698+03	[{"ref": "Исследование и моделирование компьютеров", "name": "Исследование и моделирование компьютеров", "type": "?"}, {"ref": "Тесты производительности компьютеров", "name": "Тесты производительности компьютеров", "type": "?"}, {"ref": "Linpack benchmark", "name": "Linpack benchmark", "type": "A"}]
11	"Скорость обработки рёбер графа при обходе в ширину"	"Изучение зависимости скорости обработки от размера графа, параметров процессорной решётки, числа узлов и ядер"	\N	["n_nodes", "units", "n_cores", "units", "scale", "units", "P", "units", "Q", "units"]	["TEPS", "GTEPS"]	2022-08-29 16:55:41.115611+03	2023-02-26 20:43:18.261698+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Поиск в ширину (BFS)", "name": "Поиск в ширину (BFS)", "type": "A"}]
12	"Скорость обработки рёбер графа при прохождении тестов graph500"	"Сравнение скорости обработки рёбер графа для различных суперкомпьютеров"	["n_nodes", "units", "n_cores", "units"]	["scale", "units", "P", "units", "Q", "units"]	["TEPS", "GTEPS"]	2022-08-29 16:55:41.115611+03	2023-02-26 20:43:18.261698+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Поиск в ширину (BFS)", "name": "Поиск в ширину (BFS)", "type": "A"}]
14	"Исследование зависимостей времени счета и\nчисла обработанных рёбер алгоритма BFS от типов\nграфов, их размера и архитектуры\nвычислительного узла"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма BFS"	["computing node", "name"]	["graph_name", "name", "n_verticies", "units", "n_edges", "units"]	["TEPS", "MTEPS", "time", "s"]	2022-11-21 23:50:38.326745+03	2023-02-26 20:43:18.261698+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Поиск в ширину (BFS)", "name": "Поиск в ширину (BFS)", "type": "A"}]
7	Эффективность алгоритмов, реализующих треугольное разложение матриц\n	Изучение зависимостей эффективности реализаций алгоритмов по треугольному разложению матриц от количества процессоров на суперкомпьютерах массивно-параллельной архитектуры и от размера матриц. Реализации построены на различных вариантах технологии MPI. Исходные матрицы содержат числа типа double (64 бит) \n	\N	["n_proc", "units", "mtx_size", "units"]	["efficiency", "%"]	2022-05-03 23:29:55.171209+03	2023-03-09 17:42:51.726732+03	[{"ref": "Треугольные разложения", "name": "Треугольные разложения", "type": "?"}, {"ref": "Метод Холецкого (нахождение симметричного треугольного разложения)", "name": "Метод Холецкого", "type": "M"}, {"ref": "Разложение Холецкого (метод квадратного корня)", "name": "Разложение Холецкого", "type": "A"}]
9	"Производительность алгоритмов, реализующих решение СЛАУ для плотных матриц"	"Изучение зависимости производительности решения СЛАУ от размера матрицы, размера блока и конфигурации процессорной решётки"	\N	["n_cores", "units", "mtx_size", "units", "block_size", "units", "P", "units", "Q", "units"]	["performance", "PFlop/s"]	2022-08-29 16:34:09.354474+03	2023-03-09 17:42:51.726732+03	[{"ref": "Решение систем линейных уравнений", "name": "Решение систем линейных уравнений", "type": "?"}, {"ref": "Прямые методы решения СЛАУ", "name": "Прямые методы решения СЛАУ", "type": "?"}, {"ref": "Linpack benchmark", "name": "Linpack benchmark", "type": "A"}]
15	"Производительность алгоритма Дейкстры поиска кратчайшего пути от одной вершины"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма Дейкстры"	["computing node", "name"]	["graph_name", "name", "n_verticies", "units", "n_edges", "units"]	["TEPS", "MTEPS", "time", "s"]	2022-11-28 21:07:02.521775+03	2023-03-09 17:42:51.726732+03	[{"ref": "Обход графа", "name": "Обход графа", "type": "?"}, {"ref": "Поиск кратчайшего пути от одной вершины (SSSP)", "name": "Поиск кратчайшего пути от одной вершины", "type": "P"}, {"ref": "Алгоритм Дейкстры", "name": "Алгоритм Дейкстры", "type": "A"}]
16	"Производительность алгортма PageRank ранжирования Интернет-страниц"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма ранжирования Пейджа"	["computing node", "name"]	["graph_name", "name", "n_verticies", "units", "n_edges", "units"]	["TEPS", "MTEPS", "time", "s"]	2022-11-28 21:13:43.068973+03	2023-03-09 17:42:51.726732+03	[{"ref": "Прикладные задачи из разных областей", "name": "Прикладные задачи из разных областей", "type": "?"}, {"ref": "Ранжирование Интернет-страниц", "name": "Ранжирование Интернет-страниц", "type": "P"}, {"ref": "PageRank", "name": "PageRank", "type": "A"}]
17	"Производительность алгортма HITS ранжирования Интернет-страниц"	"Для различных синтетических и реальных графов, отличающихся количеством вершин и рёбер, получить время счёта и число\nобработанных рёбер в секунду алгоритма HITS"	["computing node", "name"]	["graph_name", "name", "n_verticies", "units", "n_edges", "units"]	["TEPS", "MTEPS", "time", "s"]	2022-11-28 21:15:13.480529+03	2023-03-09 17:42:51.726732+03	[{"ref": "Прикладные задачи из разных областей", "name": "Прикладные задачи из разных областей", "type": "?"}, {"ref": "Ранжирование Интернет-страниц", "name": "Ранжирование Интернет-страниц", "type": "P"}, {"ref": "HITS (Hyperlink Induced Topic Search)", "name": "HITS", "type": "A"}]
\.


--
-- TOC entry 2864 (class 0 OID 18178)
-- Dependencies: 193
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: adm
--

COPY public.users (id, "user", pswd, is_moder) FROM stdin;
1	adm	matveev2001a@gmail.com	1
2	new_user	password	0
\.


--
-- TOC entry 2909 (class 0 OID 0)
-- Dependencies: 185
-- Name: exp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adm
--

SELECT pg_catalog.setval('public.exp_id_seq', 58, true);


--
-- TOC entry 2910 (class 0 OID 0)
-- Dependencies: 192
-- Name: journal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adm
--

SELECT pg_catalog.setval('public.journal_id_seq', 105, true);


--
-- TOC entry 2911 (class 0 OID 0)
-- Dependencies: 187
-- Name: launch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adm
--

SELECT pg_catalog.setval('public.launch_id_seq', 523, true);


--
-- TOC entry 2912 (class 0 OID 0)
-- Dependencies: 189
-- Name: type_exp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adm
--

SELECT pg_catalog.setval('public.type_exp_id_seq', 73, true);


--
-- TOC entry 2913 (class 0 OID 0)
-- Dependencies: 194
-- Name: users_seq; Type: SEQUENCE SET; Schema: public; Owner: adm
--

SELECT pg_catalog.setval('public.users_seq', 2, true);


--
-- TOC entry 2719 (class 2606 OID 16678)
-- Name: exp pk_exp_id; Type: CONSTRAINT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.exp
    ADD CONSTRAINT pk_exp_id PRIMARY KEY (id);


--
-- TOC entry 2725 (class 2606 OID 16738)
-- Name: journal pk_journal_id; Type: CONSTRAINT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.journal
    ADD CONSTRAINT pk_journal_id PRIMARY KEY (id);


--
-- TOC entry 2721 (class 2606 OID 16691)
-- Name: launch pk_launch_id; Type: CONSTRAINT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.launch
    ADD CONSTRAINT pk_launch_id PRIMARY KEY (id);


--
-- TOC entry 2723 (class 2606 OID 16704)
-- Name: type_exp pk_type_id; Type: CONSTRAINT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.type_exp
    ADD CONSTRAINT pk_type_id PRIMARY KEY (id);


--
-- TOC entry 2729 (class 2606 OID 18233)
-- Name: scomp scomp_pkey; Type: CONSTRAINT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.scomp
    ADD CONSTRAINT scomp_pkey PRIMARY KEY (id);


--
-- TOC entry 2727 (class 2606 OID 18182)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 2735 (class 2620 OID 16705)
-- Name: exp exp_update; Type: TRIGGER; Schema: public; Owner: adm
--

CREATE TRIGGER exp_update BEFORE UPDATE ON public.exp FOR EACH ROW EXECUTE PROCEDURE public.upd_timestamp();


--
-- TOC entry 2738 (class 2620 OID 16742)
-- Name: journal journal_update; Type: TRIGGER; Schema: public; Owner: adm
--

CREATE TRIGGER journal_update BEFORE UPDATE ON public.journal FOR EACH ROW EXECUTE PROCEDURE public.upd_timestamp();


--
-- TOC entry 2736 (class 2620 OID 16706)
-- Name: launch launch_update; Type: TRIGGER; Schema: public; Owner: adm
--

CREATE TRIGGER launch_update BEFORE UPDATE ON public.launch FOR EACH ROW EXECUTE PROCEDURE public.upd_timestamp();


--
-- TOC entry 2737 (class 2620 OID 16707)
-- Name: type_exp type_exp_update; Type: TRIGGER; Schema: public; Owner: adm
--

CREATE TRIGGER type_exp_update BEFORE UPDATE ON public.type_exp FOR EACH ROW EXECUTE PROCEDURE public.upd_timestamp();


--
-- TOC entry 2730 (class 2606 OID 16708)
-- Name: exp exp_type; Type: FK CONSTRAINT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.exp
    ADD CONSTRAINT exp_type FOREIGN KEY (type_exp_id) REFERENCES public.type_exp(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2732 (class 2606 OID 16713)
-- Name: launch experiment; Type: FK CONSTRAINT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.launch
    ADD CONSTRAINT experiment FOREIGN KEY (exp_id) REFERENCES public.exp(id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 2734 (class 2606 OID 18224)
-- Name: journal fk_journal_moder; Type: FK CONSTRAINT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.journal
    ADD CONSTRAINT fk_journal_moder FOREIGN KEY (moder) REFERENCES public.users(id) NOT VALID;


--
-- TOC entry 2733 (class 2606 OID 18219)
-- Name: journal fk_journal_user; Type: FK CONSTRAINT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.journal
    ADD CONSTRAINT fk_journal_user FOREIGN KEY ("user") REFERENCES public.users(id) NOT VALID;


--
-- TOC entry 2731 (class 2606 OID 18234)
-- Name: exp fk_sc; Type: FK CONSTRAINT; Schema: public; Owner: adm
--

ALTER TABLE ONLY public.exp
    ADD CONSTRAINT fk_sc FOREIGN KEY (sc_id) REFERENCES public.scomp(id) NOT VALID;


--
-- TOC entry 2872 (class 0 OID 0)
-- Dependencies: 212
-- Name: FUNCTION approve(journal_id integer); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.approve(journal_id integer) TO mrv;


--
-- TOC entry 2873 (class 0 OID 0)
-- Dependencies: 239
-- Name: FUNCTION approve_for(journal_id integer, table_n name, for_id integer, cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.approve_for(journal_id integer, table_n name, for_id integer, cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2874 (class 0 OID 0)
-- Dependencies: 236
-- Name: FUNCTION decline(journal_id integer); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.decline(journal_id integer) TO mrv;


--
-- TOC entry 2875 (class 0 OID 0)
-- Dependencies: 233
-- Name: FUNCTION exp_del(upd_id integer); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.exp_del(upd_id integer) TO mrv;


--
-- TOC entry 2876 (class 0 OID 0)
-- Dependencies: 240
-- Name: FUNCTION exp_del_for(upd_id integer, cols name[]); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.exp_del_for(upd_id integer, cols name[]) TO mrv;


--
-- TOC entry 2877 (class 0 OID 0)
-- Dependencies: 238
-- Name: FUNCTION exp_new(cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.exp_new(cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2878 (class 0 OID 0)
-- Dependencies: 234
-- Name: FUNCTION exp_new_for(new_id integer, cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.exp_new_for(new_id integer, cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2879 (class 0 OID 0)
-- Dependencies: 211
-- Name: FUNCTION exp_upd(upd_id integer, cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.exp_upd(upd_id integer, cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2880 (class 0 OID 0)
-- Dependencies: 210
-- Name: FUNCTION exp_upd_for(upd_id integer, cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.exp_upd_for(upd_id integer, cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2881 (class 0 OID 0)
-- Dependencies: 235
-- Name: FUNCTION launch_del(upd_id integer); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.launch_del(upd_id integer) TO mrv;


--
-- TOC entry 2882 (class 0 OID 0)
-- Dependencies: 237
-- Name: FUNCTION launch_del_for(upd_id integer, cols name[]); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.launch_del_for(upd_id integer, cols name[]) TO mrv;


--
-- TOC entry 2883 (class 0 OID 0)
-- Dependencies: 209
-- Name: FUNCTION launch_new(cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.launch_new(cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2884 (class 0 OID 0)
-- Dependencies: 241
-- Name: FUNCTION launch_new_for(new_id integer, cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.launch_new_for(new_id integer, cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2885 (class 0 OID 0)
-- Dependencies: 247
-- Name: FUNCTION launch_upd(upd_id integer, cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.launch_upd(upd_id integer, cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2886 (class 0 OID 0)
-- Dependencies: 246
-- Name: FUNCTION launch_upd_for(upd_id integer, cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.launch_upd_for(upd_id integer, cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2887 (class 0 OID 0)
-- Dependencies: 242
-- Name: FUNCTION type_exp_del(upd_id integer); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.type_exp_del(upd_id integer) TO mrv;


--
-- TOC entry 2888 (class 0 OID 0)
-- Dependencies: 245
-- Name: FUNCTION type_exp_del_for(upd_id integer, cols name[]); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.type_exp_del_for(upd_id integer, cols name[]) TO mrv;


--
-- TOC entry 2889 (class 0 OID 0)
-- Dependencies: 244
-- Name: FUNCTION type_exp_new(cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.type_exp_new(cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2890 (class 0 OID 0)
-- Dependencies: 248
-- Name: FUNCTION type_exp_new_for(new_id integer, cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.type_exp_new_for(new_id integer, cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2891 (class 0 OID 0)
-- Dependencies: 243
-- Name: FUNCTION type_exp_upd(upd_id integer, cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.type_exp_upd(upd_id integer, cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2892 (class 0 OID 0)
-- Dependencies: 249
-- Name: FUNCTION type_exp_upd_for(upd_id integer, cols name[], new_vals jsonb); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.type_exp_upd_for(upd_id integer, cols name[], new_vals jsonb) TO mrv;


--
-- TOC entry 2893 (class 0 OID 0)
-- Dependencies: 196
-- Name: FUNCTION upd_timestamp(); Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON FUNCTION public.upd_timestamp() TO mrv;


--
-- TOC entry 2894 (class 0 OID 0)
-- Dependencies: 186
-- Name: TABLE exp; Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON TABLE public.exp TO mrv;
GRANT SELECT ON TABLE public.exp TO anton;


--
-- TOC entry 2896 (class 0 OID 0)
-- Dependencies: 185
-- Name: SEQUENCE exp_id_seq; Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON SEQUENCE public.exp_id_seq TO mrv;


--
-- TOC entry 2897 (class 0 OID 0)
-- Dependencies: 191
-- Name: TABLE journal; Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON TABLE public.journal TO mrv;
GRANT SELECT ON TABLE public.journal TO anton;


--
-- TOC entry 2899 (class 0 OID 0)
-- Dependencies: 192
-- Name: SEQUENCE journal_id_seq; Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON SEQUENCE public.journal_id_seq TO mrv;


--
-- TOC entry 2900 (class 0 OID 0)
-- Dependencies: 188
-- Name: TABLE launch; Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON TABLE public.launch TO mrv;
GRANT SELECT ON TABLE public.launch TO anton;


--
-- TOC entry 2902 (class 0 OID 0)
-- Dependencies: 187
-- Name: SEQUENCE launch_id_seq; Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON SEQUENCE public.launch_id_seq TO mrv;


--
-- TOC entry 2903 (class 0 OID 0)
-- Dependencies: 195
-- Name: TABLE scomp; Type: ACL; Schema: public; Owner: adm
--

GRANT SELECT ON TABLE public.scomp TO anton;


--
-- TOC entry 2904 (class 0 OID 0)
-- Dependencies: 190
-- Name: TABLE type_exp; Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON TABLE public.type_exp TO mrv;
GRANT SELECT ON TABLE public.type_exp TO anton;


--
-- TOC entry 2906 (class 0 OID 0)
-- Dependencies: 189
-- Name: SEQUENCE type_exp_id_seq; Type: ACL; Schema: public; Owner: adm
--

GRANT ALL ON SEQUENCE public.type_exp_id_seq TO mrv;


--
-- TOC entry 2907 (class 0 OID 0)
-- Dependencies: 193
-- Name: TABLE users; Type: ACL; Schema: public; Owner: adm
--

GRANT SELECT ON TABLE public.users TO anton;


--
-- TOC entry 1727 (class 826 OID 17014)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: -; Owner: adm
--

ALTER DEFAULT PRIVILEGES FOR ROLE adm GRANT SELECT ON TABLES  TO anton;


-- Completed on 2023-05-11 23:19:33

--
-- PostgreSQL database dump complete
--

