--
-- /packages/acs-kernel/sql/utilities-create.sql
--
-- Useful PL/SQL utility routines.
--
-- @author Jon Salz (jsalz@mit.edu)
-- @creation-date 12 Aug 2000
-- @cvs-id utilities-create.sql,v 1.3 2000/11/02 17:55:51 yon Exp
--

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
END;' language 'plpgsql' immutable strict;


