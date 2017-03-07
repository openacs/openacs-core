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

end util;
/
show errors
