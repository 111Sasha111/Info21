-- Процедура: удалить все таблицы в текущей базе
CREATE OR REPLACE PROCEDURE DropAllTables()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
    ) LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END;
$$;

-- Процедура: вывести список всех скалярных SQL-функций и их параметров
CREATE OR REPLACE PROCEDURE ShowScalarFunctions()
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM
        p.proname AS function_name,
        pg_get_function_identity_arguments(p.oid) AS parameters
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'  -- только функции (не процедуры)
      AND p.prorettype != 'record'::regtype  -- исключаем табличные
    ORDER BY p.proname;
END;
$$;

-- Процедура: удалить все DML-триггеры
CREATE OR REPLACE PROCEDURE DropAllTriggers()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tgname, tgrelid::regclass AS table_name
        FROM pg_trigger
        WHERE tgrelid IN (
            SELECT oid FROM pg_class WHERE relnamespace = (
                SELECT oid FROM pg_namespace WHERE nspname = 'public'
            )
        )
        AND NOT tgisinternal
    ) LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || quote_ident(r.tgname) ||
                ' ON ' || r.table_name;
    END LOOP;
END;
$$;

-- Процедура: найти объекты с описанием, содержащим заданную строку
CREATE OR REPLACE PROCEDURE FindObjectsWithComment(search_str TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM obj_description(oid) AS description, relname AS name, 'table' AS type
    FROM pg_class
    WHERE relkind = 'r' AND obj_description(oid) ILIKE '%' || search_str || '%'

    UNION ALL

    SELECT obj_description(p.oid), p.proname, 'function'
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND obj_description(p.oid) ILIKE '%' || search_str || '%';
END;
$$;
