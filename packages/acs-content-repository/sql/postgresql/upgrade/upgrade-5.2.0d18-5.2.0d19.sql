-- 
-- 
-- 
-- @author Victor Guerra (guerra@galileo.edu)
-- @creation-date 2006-07-13
-- @arch-tag: 5d9217e6-cdc0-4fa3-81c7-2f51eb04780e
-- @cvs-id $Id$
--

-- this script was originally created by daveb -- upgrade-5.2.0d15-5.2.0a1.sql

-- patch#548 bug#1937

select define_function_args('content_revision__copy_attributes','content_type,revision_id,copy_id');
create or replace function content_revision__copy_attributes (varchar,integer,integer)
returns integer as '
declare
  copy_attributes__content_type           alias for $1;  
  copy_attributes__revision_id            alias for $2;  
  copy_attributes__copy_id                alias for $3;  
  v_table_name                            acs_object_types.table_name%TYPE;
  v_id_column                             acs_object_types.id_column%TYPE;
  cols                                    varchar default ''''; 
  attr_rec                                record;
begin

  if copy_attributes__content_type is null or copy_attributes__revision_id is null or copy_attributes__copy_id is null then 
     raise exception ''content_revision__copy_attributes called with null % % %'',copy_attributes__content_type,copy_attributes__revision_id, copy_attributes__copy_id;
  end if;

  select table_name, id_column into v_table_name, v_id_column
  from acs_object_types where object_type = copy_attributes__content_type;

  for attr_rec in select
                    attribute_name
                  from
                    acs_attributes
                  where
                    object_type = copy_attributes__content_type 
  LOOP
    cols := cols || '', '' || attr_rec.attribute_name;
  end loop;

    execute ''insert into '' || v_table_name || ''('' || v_id_column || cols || '')'' || '' select '' || copy_attributes__copy_id || 
          '' as '' || v_id_column || cols || '' from '' || 
          v_table_name || '' where '' || v_id_column || '' = '' || 
          copy_attributes__revision_id;

  return 0; 

end;' language 'plpgsql';

-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2005-06-05
-- @arch-tag: 16725764-0b5d-4e98-a75d-dc77bf3141de
-- @cvs-id $Id$
--

-- patch#548 bug#1937

select define_function_args('content_revision__copy_attributes','content_type,revision_id,copy_id');
create or replace function content_revision__copy_attributes (varchar,integer,integer)
returns integer as '
declare
  copy_attributes__content_type           alias for $1;  
  copy_attributes__revision_id            alias for $2;  
  copy_attributes__copy_id                alias for $3;  
  v_table_name                            acs_object_types.table_name%TYPE;
  v_id_column                             acs_object_types.id_column%TYPE;
  cols                                    varchar default ''''; 
  attr_rec                                record;
begin

  if copy_attributes__content_type is null or copy_attributes__revision_id is null or copy_attributes__copy_id is null then 
     raise exception ''content_revision__copy_attributes called with null % % %'',copy_attributes__content_type,copy_attributes__revision_id, copy_attributes__copy_id;
  end if;

  select table_name, id_column into v_table_name, v_id_column
  from acs_object_types where object_type = copy_attributes__content_type;

  for attr_rec in select
                    attribute_name
                  from
                    acs_attributes
                  where
                    object_type = copy_attributes__content_type 
  LOOP
    cols := cols || '', '' || attr_rec.attribute_name;
  end loop;

    execute ''insert into '' || v_table_name || ''('' || v_id_column || cols || '')'' || '' select '' || copy_attributes__copy_id || 
          '' as '' || v_id_column || cols || '' from '' || 
          v_table_name || '' where '' || v_id_column || '' = '' || 
          copy_attributes__revision_id;

  return 0; 

end;' language 'plpgsql';

