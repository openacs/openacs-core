PROMPT starting utilities-create.sql....
--
-- PL/SQL utility routines for accessing schema information
--
-- @author Jon Salz (jsalz@mit.edu), Antonio Pisano, Gustaf Neumann
--

create or replace TYPE t_util_primary_keys IS TABLE OF varchar2(100);
/
show errors


create or replace package util
as
    function multiple_nextval(
        v_sequence_name in varchar2,
        v_count in integer)
        return varchar2;

    function logical_negation (
        true_or_false IN varchar2)
        return varchar2;

    function table_exists (
        name in varchar2)
        return char;

    function table_column_exists (
        table_name  in varchar2,
        column in varchar2)
        return char;

    function view_exists (
        name in varchar2)
        return char;

    function index_exists (
        name in varchar2)
        return char;

    function foreign_key_exists (
        table_name IN varchar2,
        column    IN varchar2,
        reftable  IN varchar2,
        refcolumn IN varchar2)
    return char;

    function unique_exists (
        table_name IN varchar2,
        column    IN varchar2,
        single_p  IN boolean default true)
    return char;

    function primary_key_exists (
        table_name IN varchar2,
        column    IN varchar2,
        single_p  IN boolean default true)
    return char;

    function not_null_exists (
        table_name IN varchar2,
        column    IN varchar2)
    return char;

    function get_default (
        table_name IN varchar2,
        column    IN varchar2)
    return LONG;

    function get_primary_keys (
        table_name IN varchar2)
       return t_util_primary_keys;

end util;
/
show errors

create or replace package body util
as
    -- Retrieves v_count (not necessarily consecutive) nextval values from the
    -- sequence named v_sequence_name.
    function multiple_nextval(
        v_sequence_name in varchar2,
        v_count in integer
    )
    return varchar2
    is
        a_sequence_values varchar2(4000);
    begin
        execute immediate '
            declare
                a_nextval integer;
            begin
                for counter in 1..:v_count loop
                    select ' || v_sequence_name || '.nextval into a_nextval from dual;
                    :a_sequence_values := :a_sequence_values || '','' || a_nextval;
                end loop;
            end;
        ' using in v_count, in out a_sequence_values;
        return substr(a_sequence_values, 2);
    end;

    function logical_negation (
        true_or_false IN varchar2)
    return varchar2
    as
    begin
      IF true_or_false is null THEN
        return null;
      ELSIF true_or_false = 'f' THEN
        return 't';
      ELSE
        return 'f';
      END IF;
    END logical_negation;

    function table_exists (
        name IN varchar2)
    return char
    as
      v_exists char;

    begin

      select decode(count(*),0,'f','t') into v_exists
      from user_tables where table_name = upper(table_exists.name);

      return v_exists;

    END table_exists;

    function table_column_exists (
        table_name IN varchar2,
        column IN varchar2)
    return char
    as
      v_exists char;

    begin

      select decode(count(*),0,'f','t') into v_exists
      from user_tab_columns
      where table_name = upper(table_column_exists.table_name)
      and column_name = upper(table_column_exists.column);

      return v_exists;

    END table_column_exists;

    function view_exists (
        name IN varchar2)
    return char
    as
      v_exists char;

    begin

      select decode(count(*),0,'f','t') into v_exists
      from user_views where view_name = upper(view_exists.name);

      return v_exists;

    END view_exists;

    function index_exists (
        name IN varchar2)
    return char
    as
      v_exists char;

    begin
      select decode(count(*),0,'f','t') into v_exists
      from user_indexes where index_name = upper(index_exists.name);

      return v_exists;
    END index_exists;

    function foreign_key_exists (
        table_name IN varchar2,
        column    IN varchar2,
        reftable  IN varchar2,
        refcolumn IN varchar2)
    return char
    as
      v_exists char;

    begin
      select decode(count(*),0,'f','t') into v_exists
      from user_constraints cons
      left join user_cons_columns cols on cols.constraint_name = cons.constraint_name
      left join user_constraints cons_r on cons_r.constraint_name = cons.r_constraint_name
      left join user_cons_columns cols_r on cols_r.constraint_name = cons.r_constraint_name
      where cons.constraint_type = 'R'
        and cons.table_name = upper(foreign_key_exists.table_name)
        and cols.column_name = upper(foreign_key_exists.column)
        and cons_r.table_name = upper(foreign_key_exists.reftable)
        and cols_r.column_name = upper(foreign_key_exists.refcolumn);

      return v_exists;
    end foreign_key_exists;

    function unique_exists (
        table_name IN varchar2,
        column    IN varchar2,
        single_p  IN boolean default true)
    return char
    as
      v_exists char;
      v_single integer;

    begin
      v_single := case when unique_exists.single_p then 1 else 0 end;

      select decode(count(*),0,'f','t') into v_exists
       from all_constraints c
       join all_cons_columns cc on (c.owner = cc.owner
                                         and c.constraint_name = cc.constraint_name)
       where c.constraint_type = 'U'
         and c.table_name = upper(unique_exists.table_name)
         and cc.column_name = upper(unique_exists.column)
         and ((v_single = 0) or (
            select count(*) from all_cons_columns
             where constraint_name = c.constraint_name) = 1);

      return v_exists;
    END unique_exists;

    function primary_key_exists (
        table_name IN varchar2,
        column    IN varchar2,
        single_p  IN boolean default true)
    return char
    as
      v_exists char;
      v_single integer;

    begin
      v_single := case when primary_key_exists.single_p then 1 else 0 end;

      select decode(count(*),0,'f','t') into v_exists
       from all_constraints c
       join all_cons_columns cc on (c.owner = cc.owner
                                    and c.constraint_name = cc.constraint_name)
       where c.constraint_type = 'P'
         and c.table_name = upper(primary_key_exists.table_name)
         and cc.column_name = upper(primary_key_exists.column)
         and ((v_single = 0) or (
            select count(*) from all_cons_columns
             where constraint_name = c.constraint_name
               and owner = c.owner) = 1);

      return v_exists;
    END primary_key_exists;

    function not_null_exists (
        table_name IN varchar2,
        column    IN varchar2)
    return char
    as
      v_exists char;

    begin
      select decode(count(*),0,'f','t') into v_exists
        from all_tab_columns
         where table_name = upper(not_null_exists.table_name)
           and column_name = upper(not_null_exists.column)
           and nullable = 'N';

      return v_exists;
    END not_null_exists;

    function get_default (
        table_name in varchar2,
        column    in varchar2)
    return long
    as
      v_value long;

    begin
      select data_default into v_value
        from all_tab_columns
         where table_name = upper(get_default.table_name)
           and column_name = upper(get_default.column);

      return v_value;

      exception when no_data_found then
         return null;
    end get_default;

    function get_primary_keys(
        table_name in varchar2)
    return t_util_primary_keys
    as
       v_ret t_util_primary_keys;

    begin
          select cols.column_name
          bulk collect into v_ret
          from all_constraints cons, all_cons_columns cols
          where cols.table_name = upper(get_primary_keys.table_name)
          and cons.constraint_type = 'P'
          and cons.constraint_name = cols.constraint_name
          and cons.owner = cols.owner
          order by cols.table_name, cols.position;

        return v_ret;
    end get_primary_keys;

end util;
/
show errors
