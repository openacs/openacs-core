--
-- /packages/acs-kernel/sql/utilities-create.sql
--
-- Useful PL/SQL utility routines.
--
-- @author Jon Salz (jsalz@mit.edu)
-- @creation-date 12 Aug 2000
-- @cvs-id utilities-create.sql,v 1.3 2000/11/02 17:55:51 yon Exp
--

-- create or replace package util
-- as
--     function multiple_nextval(
-- 	v_sequence_name in varchar2,
-- 	v_count in integer)
--         return varchar2;
-- 
--     function computehash_raw(
-- 	v_value IN varchar2 )
-- 	return raw;
-- 
--     function computehash(
-- 	v_value IN varchar2)
-- 	return varchar2;
-- 
--     function logical_negation (
--         true_or_false IN varchar2)
-- 	return varchar2;
-- end util;

-- show errors

-- create or replace package body util
-- function multiple_nextval
create function util__multiple_nextval (varchar,integer)
returns varchar as '
declare
  v_sequence_name        alias for $1;  
  v_count                alias for $2;  
  a_sequence_values      text default ''''; 
  v_rec                  record;
begin
    for counter in 1..v_count loop
        for v_rec in EXECUTE ''select '' || quote_ident(v_sequence_name) ''.nextval as a_seq_val''
        LOOP
           a_sequence_values := a_sequence_values || '''','''' || v_rec.a_seq_val;
          exit;
        end loop;
    end loop;

    return substr(a_sequence_values, 2);
 
end;' language 'plpgsql';

    -- This is for Password Hashing.
    -- Make sure to run: 'loadjava -user username/password Security.class'
    -- before running this.
    -- Make sure you have javasyspriv and javauserpriv granted for the user.

--    function computehash_raw( v_value IN varchar2 )
--    return raw
--    as language java
--    name 'Security.computeSHA(java.lang.String) returns java.lang.byte[]';

create function RAWTOHEX(text) returns text as '
declare
        arg     alias for $1;
begin
        raise exception ''not implemented yet: depends on java code in acs classic'';
        return '''';
end;' language 'plpgsql';


create function util__computehash_raw(text) returns text as '
declare
        arg     alias for $1;
begin
        raise exception ''not implemented yet: depends on java code in acs classic'';
        return '''';
end;' language 'plpgsql';


    -- The hashing function can be changed to MD5 by using computeMD5.

create function util__computehash (varchar) returns varchar as '
declare 
        v_value alias for $1;
	v_hashed      char(40);
begin
	select RAWTOHEX(util__computehash_raw(v_value)) into v_hashed;

	return v_hashed;
end;' language 'plpgsql';


create function util__logical_negation (boolean) returns boolean as '
declare
        true_or_false alias for $1;
begin
      IF true_or_false is null THEN
        return null;
      ELSE IF true_or_false = ''f'' THEN
        return ''t'';   
      ELSE 
        return ''f'';   
      END IF; END IF;
END;' language 'plpgsql';


