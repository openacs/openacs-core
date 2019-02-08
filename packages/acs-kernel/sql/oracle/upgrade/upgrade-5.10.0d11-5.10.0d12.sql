PROMPT starting utilities-create.sql....
--
-- Rebuild the utilities
--

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
	return boolean;
	
    function table_column_exists (
	t_name  in varchar2,
	c_name in varchar2)
	return boolean;
    
    function view_exists (
	name in varchar2)
	return boolean;
	
    function index_exists (
	name in varchar2)
	return boolean;

    function foreign_key_exists (
        table     IN varchar2,
	column    IN varchar2,
	reftable  IN varchar2,
	refcolumn IN varchar2)
    return boolean;

    function unique_exists (
        table     IN varchar2,
	column    IN varchar2,
	single_p  IN boolean default true)
    return boolean;

    function primary_key_exists (
        table     IN varchar2,
	column    IN varchar2,
	single_p  IN boolean default true)
    return boolean;

    function not_null_exists (
        table     IN varchar2,
	column    IN varchar2)
    return boolean;

    function get_default (
        table     IN varchar2,
	column    IN varchar2)
    return LONG;

    TYPE primary_keys IS TABLE OF varchar2;

    function get_primary_keys(table IN varchar2)
       return primary_keys
	 PIPELINED;

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
    return boolean
    as

      v_count integer;
      v_exists boolean;

    begin

      select decode(count(*),0,0,1) into v_count 
      from user_tables where table_name = upper(table_exists.name);

      if v_count = 1 then
        v_exists := true;
      else
        v_exists := false;
      end if;

      return v_exists;

    END table_exists;
    
    function table_column_exists (
        t_name  IN varchar2,
        c_name IN varchar2)
    return boolean
    as
      v_count integer;
      v_exists boolean;

    begin

      select decode(count(*),0,0,1) into v_count from user_tab_columns
      where table_name = upper(table_column_exists.t_name)
      and column_name = upper(table_column_exists.c_name);

      if v_count = 1 then
        v_exists := true;
      else
        v_exists := false;
      end if;

      return v_exists;
      
    END table_column_exists;
    
    function view_exists (
        name IN varchar2)
    return boolean
    as
      v_count integer;
      v_exists boolean;

    begin

      select decode(count(*),0,0,1) into v_count 
      from user_views where view_name = upper(view_exists.name);

      if v_count = 1 then
        v_exists := true;
      else
        v_exists := false;
      end if;

      return v_exists;

    END view_exists;
    
    function index_exists (
        name IN varchar2)
    return boolean
    as
      v_count integer;
      v_exists boolean;

    begin
      select decode(count(*),0,0,1) into v_count 
      from user_indexes where index_name = upper(index_exists.name);

      if v_count = 1 then
        v_exists := true;
      else
        v_exists := false;
      end if;

      return v_exists;
    END index_exists;

    function foreign_key_exists (
        table     IN varchar2,
	column    IN varchar2,
	reftable  IN varchar2,
	refcolumn IN varchar2)
    return boolean
    as
      v_count integer;
      v_exists boolean;

    begin
      select decode(count(*),0,0,1) into v_count
      from user_constraints cons
      left join user_cons_columns cols on cols.constraint_name = cons.constraint_name
      left join user_constraints cons_r on cons_r.constraint_name = cons.r_constraint_name
      left join user_cons_columns cols_r on cols_r.constraint_name = cons.r_constraint_name
      where cons.constraint_type = 'R'
        and cons.table_name = foreign_key_exists.table
	and cols.column_name = foreign_key_exists.column
  	and cons_r.table_name = foreign_key_exists.reftable
  	and cols_r.column_name = foreign_key_exists.refcolumn;

      if v_count = 1 then
        v_exists := true;
      else
        v_exists := false;
      end if;

      return v_exists;
    end foreign_key_exists;

    function unique_exists (
        table     IN varchar2,
	column    IN varchar2,
	single_p  IN boolean default true)
    return boolean
    as
      v_count integer;
      v_exists boolean;

    begin
      select decode(count(*),0,0,1) into v_count
       from all_constraints c
       join all_cons_columns cc on (c.owner = cc.owner
	                                 and c.constraint_name = cc.constraint_name)
       where c.constraint_type = 'U'
	 and c.table_name = unique_exists.table
	 and cc.column_name = unique_exists.column
	 and (not unique_exists.single_p or (
	    select count(*) from all_cons_columns
	     where constraint_name = c.constraint_name) = 1);
      if v_count = 1 then
        v_exists := true;
      else
        v_exists := false;
      end if;

      return v_exists;
    END unique_exists;

    function primary_key_exists (
        table     IN varchar2,
	column    IN varchar2,
	single_p  IN boolean default true)
    return boolean
    as
      v_count integer;
      v_exists boolean;

    begin
      select decode(count(*),0,0,1) into v_count
       from all_constraints c
       join all_cons_columns cc on (c.owner = cc.owner
	                                 and c.constraint_name = cc.constraint_name)
       where c.constraint_type = 'P'
	 and c.table_name = primary_key_exists.table
	 and cc.column_name = primary_key_exists.column
	 and (not primary_key_exists.single_p or (
	    select count(*) from all_cons_columns
	     where constraint_name = c.constraint_name
	       and owner = c.owner) = 1);

      if v_count = 1 then
        v_exists := true;
      else
        v_exists := false;
      end if;

      return v_exists;
    END primary_key_exists;

    function not_null_exists (
        table     IN varchar2,
	column    IN varchar2)
    return boolean
    as
      v_count integer;
      v_exists boolean;

    begin
      select decode(count(*),0,0,1) into v_count
        from all_tab_columns
	 where table_name = not_null_exists.table
	   and column_name = not_null_exists.column
           and nullable = 'N';

      if v_count = 1 then
        v_exists := true;
      else
        v_exists := false;
      end if;

      return v_exists;
    END not_null_exists;

    function get_default (
        table     in varchar2,
	column    in varchar2)
    return long
    as
      v_value long;

    begin
      select data_default into v_value
        from all_tab_columns
	 where table_name = get_default.table
	   and column_name = get_default.column;

      return v_value;
    end get_default;

    function get_primary_keys(
        table in varchar2)
    return primary_keys
    as
       v_rec primary_keys;

    begin
          select cols.column_name
	    bulk collect into v_rec
	  from all_constraints cons, all_cons_columns cols
	  where cols.table_name = get_primary_keys.table
	  and cons.constraint_type = 'P'
	  and cons.constraint_name = cols.constraint_name
	  and cons.owner = cols.owner
	  order by cols.table_name, cols.position;

        return v_rec;
    end get_primary_keys;

end util;
/
show errors
