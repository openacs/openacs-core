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

    function computehash_raw(
	v_value IN varchar2 )
	return raw;

    function computehash(
	v_value IN varchar2)
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

    -- This is for Password Hashing.
    -- Make sure to run: 'loadjava -user username/password Security.class'
    -- before running this.
    -- Make sure you have javasyspriv and javauserpriv granted for the user.

    function computehash_raw( v_value IN varchar2 )
    return raw
    as language java
    name 'Security.computeSHA(java.lang.String) returns java.lang.byte[]';

    -- The hashing function can be changed to MD5 by using computeMD5.

    function computehash (v_value IN varchar2)
    return varchar2
    as
	v_hashed	char(40);
    begin
	select RAWTOHEX(computehash_raw(v_value)) into v_hashed from dual;
	return v_hashed;
    end computehash;

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
