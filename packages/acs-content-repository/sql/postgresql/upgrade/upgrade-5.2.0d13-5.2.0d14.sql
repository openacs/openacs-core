-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2005-03-20
-- @arch-tag: 8694a7de-393a-4d70-a3ce-36019afdf05c
-- @cvs-id $Id$
--

-- add define function args calls for content_keyword
-- add content_keyword__del to coincide with oracle

select define_function_args ('content_keyword__get_heading','keyword_id');
select define_function_args ('content_keyword__get_description','keyword_id');
select define_function_args ('content_keyword__set_heading','keyword_id,heading');
select define_function_args ('content_keyword__set_description','keyword_id,description');
select define_function_args ('content_keyword__is_leaf','keyword_id');
select define_function_args ('content_keyword__del','keyword_id');
select define_function_args ('content_keyword__item_assign','item_id,keyword_id,context_id;null,creation_user;null,creation_ip;null');
select define_function_args ('content_keyword__item_unassign','item_id,keyword_id');
select define_function_args ('content_keyword__is_assigned','item_id,keyword_id,recurse;none');
select define_function_args ('content_keyword__get_path','keyword_id');

create or replace function content_keyword__del (integer)
returns integer as '
declare
  delete__keyword_id             alias for $1;  
  v_rec                          record; 
begin

  for v_rec in select item_id from cr_item_keyword_map 
    where keyword_id = delete__keyword_id LOOP
    PERFORM content_keyword__item_unassign(v_rec.item_id, delete__keyword_id);
  end LOOP;

  PERFORM acs_object__delete(delete__keyword_id);

  return 0; 
end;' language 'plpgsql';

create or replace function content_keyword__delete (integer)
returns integer as '
declare
  delete__keyword_id             alias for $1;  
  v_rec                          record; 
begin
  perform content_keyword__del(delete__keyword_id);
  return 0; 
end;' language 'plpgsql';
