--
-- Fix some things that break on pg7.5
--

-- assignment to cascade_p failed in these 3 functions

create or replace function apm__unregister_package (varchar,boolean)
returns integer as '
declare
  package_key            alias for $1;  
  p_cascade_p            alias for $2;  -- default ''t''  
  v_cascade_p            boolean;
begin
   if cascade_p is null then 
	v_cascade_p := ''t'';
   else 
       v_cascade_p := p_cascade_p;
   end if;

   PERFORM apm_package_type__drop_type(
	package_key,
	v_cascade_p
   );

   return 0; 
end;' language 'plpgsql';

create or replace function apm__unregister_application (varchar,boolean)
returns integer as '
declare
  package_key            alias for $1;  
  p_cascade_p              alias for $2;  -- default ''f''  
  v_cascade_p            boolean;
begin
   if p_cascade_p is null then 
	v_cascade_p := ''f'';
   else 
       v_cascade_p := p_cascade_p;
   end if;

   PERFORM apm__unregister_package (
        package_key,
        v_cascade_p
   );

   return 0; 
end;' language 'plpgsql';

create or replace function apm__unregister_service (varchar,boolean)
returns integer as '
declare
  package_key           alias for $1;  
  p_cascade_p           alias for $2;  -- default ''f''  
  v_cascade_p           boolean;
begin
   if p_cascade_p is null then 
	v_cascade_p := ''f'';
   else 
	v_cascade_p := p_cascade_p;
   end if;

   PERFORM apm__unregister_package (
	package_key,
	v_cascade_p
   );

   return 0; 
end;' language 'plpgsql';


-- syntax error in old function 

create or replace function lob_get_data(integer) returns text as '
declare
        p_lob_id alias for $1;
        v_rec   record;
        v_data  text default '''';
begin
        for v_rec in select data, segment from lob_data where lob_id = p_lob_id order by segment 
        loop
            v_data := v_data || v_rec.data;
        end loop;

        return v_data;

end;' language 'plpgsql';


-- bit changed so "bit"($1) no longer existed.  use ::bit(32) which does.

create or replace function bitfromint4 (integer) returns bit varying as '
begin
    return $1::bit(32);
end;' language 'plpgsql' immutable strict;
