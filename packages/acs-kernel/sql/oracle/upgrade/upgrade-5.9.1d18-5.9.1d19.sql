
-- new utilities added, rebuild utilities package

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
    begin
      return exists (select 1 from user_tables where table_name = t_name);
    END table_exists;
    
    function table_column_exists (
        t_name  IN varchar2,
        c_name IN varchar2)
    return boolean
    as
    begin
      return exists (select 1 from user_tab_columns where c.table_name = t_name and c.column_name = c_name);
    END table_column_exists;
    
    function view_exists (
        name IN varchar2)
    return boolean
    as
    begin
      return exists (select 1 from user_views where view_name = name);
    END view_exists;
    
    function index_exists (
        name IN varchar2)
    return boolean
    as
    begin
      return exists (select 1 from user_indexes where index_name = name);
    END index_exists;

    function foreign_key_exists (
        table     IN varchar2,
	column    IN varchar2,
	reftable  IN varchar2,
	refcolumn IN varchar2)
    return boolean
    as
    begin
      return exists (
      SELECT 1 FROM USER_CONSTRAINTS CONS
      LEFT JOIN USER_CONS_COLUMNS COLS ON COLS.CONSTRAINT_NAME = CONS.CONSTRAINT_NAME
      LEFT JOIN USER_CONSTRAINTS CONS_R ON CONS_R.CONSTRAINT_NAME = CONS.R_CONSTRAINT_NAME
      LEFT JOIN USER_CONS_COLUMNS COLS_R ON COLS_R.CONSTRAINT_NAME = CONS.R_CONSTRAINT_NAME
      WHERE CONS.CONSTRAINT_TYPE = 'R'
        AND CONS.TABLE_NAME = table
	AND COLS.COLUMN_NAME = column
  	AND CONS_R.TABLE_NAME = reftable
  	AND COLS_R.COLUMN_NAME = refcolumn);
    END foreign_key_exists;

    function unique_exists (
        table     IN varchar2,
	column    IN varchar2,
	single_p  IN boolean default true)
    return boolean
    as
    begin
      return exists (
      SELECT 1
       FROM all_constraints c
       JOIN all_cons_columns cc ON (c.owner = cc.owner
	                                 AND c.constraint_name = cc.constraint_name)
       WHERE c.constraint_type = 'U'
	 AND c.table_name = table
	 AND cc.column_name = column
	 and (not single_p or (
	    select count(*) from all_cons_columns
	     where constraint_name = c.constraint_name) = 1));
    END unique_exists;

    function primary_key_exists (
        table     IN varchar2,
	column    IN varchar2,
	single_p  IN boolean default true)
    return boolean
    as
    begin
      return exists (
      SELECT 1
       FROM all_constraints c
       JOIN all_cons_columns cc ON (c.owner = cc.owner
	                                 AND c.constraint_name = cc.constraint_name)
       WHERE c.constraint_type = 'P'
	 AND c.table_name = table
	 AND cc.column_name = column
	 and (not single_p or (
	    select count(*) from all_cons_columns
	     where constraint_name = c.constraint_name
	       and owner = c.owner) = 1));
    END primary_key_exists;

    function not_null_exists (
        table     IN varchar2,
	column    IN varchar2)
    return boolean
    as
    begin
      return (
      SELECT nullable = 'N'
        FROM ALL_TAB_COLUMNS
	 WHERE table_name = table
	   AND column_name = column);
    END not_null_exists;

    function get_default (
        table     IN varchar2,
	column    IN varchar2)
    return LONG
    as
    begin
      return (
      SELECT DATA_DEFAULT
        FROM ALL_TAB_COLUMNS
	 WHERE table_name = table
	   AND column_name = column);
    END get_default;    

end util;
/
show errors
