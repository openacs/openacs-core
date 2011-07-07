--
-- /packages/acs-kernel/sql/utilities-create.sql
--
-- Useful PL/SQL utility routines.
--
-- @author Jon Salz (jsalz@mit.edu)
-- @creation-date 12 Aug 2000
-- @cvs-id $Id$
--



-- added
select define_function_args('util__multiple_nextval','v_sequence_name,v_count');

--
-- procedure util__multiple_nextval/2
--
CREATE OR REPLACE FUNCTION util__multiple_nextval(
   v_sequence_name varchar,
   v_count integer
) RETURNS varchar AS $$
DECLARE
  a_sequence_values      text default ''; 
  v_rec                  record;
BEGIN
    for counter in 1..v_count loop
        for v_rec in EXECUTE 'select ' || quote_ident(v_sequence_name) || '.nextval as a_seq_val'
        LOOP
           a_sequence_values := a_sequence_values || '','' || v_rec.a_seq_val;
          exit;
        end loop;
    end loop;

    return substr(a_sequence_values, 2);
 
END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('util__logical_negation','true_or_false');

--
-- procedure util__logical_negation/1
--
CREATE OR REPLACE FUNCTION util__logical_negation(
   true_or_false boolean
) RETURNS boolean AS $$
DECLARE
BEGIN
      IF true_or_false is null THEN
        return null;
      ELSE IF true_or_false = 'f' THEN
        return 't';   
      ELSE 
        return 'f';   
      END IF; END IF;
END;
$$ LANGUAGE plpgsql immutable strict;


