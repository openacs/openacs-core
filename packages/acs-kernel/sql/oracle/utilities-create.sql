--
-- /packages/acs-kernel/sql/utilities-create.sql
--
-- Useful PL/SQL utility routines.
--
-- @author Jon Salz (jsalz@mit.edu)
-- @creation-date 12 Aug 2000
-- @cvs-id $Id$
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

end util;
/
show errors
