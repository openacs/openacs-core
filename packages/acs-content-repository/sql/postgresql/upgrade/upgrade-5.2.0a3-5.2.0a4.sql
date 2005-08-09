-- procedure for content symlink delete
select define_function_args('content_symlink__delete','symlink_id');
create or replace function content_symlink__delete (integer)
returns integer as '
declare
  delete__symlink_id             alias for $1;  
begin

  PERFORM content_symlink__del(delete__symlink_id);

  return 0; 
end;' language 'plpgsql';


select define_function_args('content_symlink__del','symlink_id');
create or replace function content_symlink__del (integer)
returns integer as '
declare
  del__symlink_id             alias for $1;  
begin

  delete from cr_symlinks
    where symlink_id = del__symlink_id;

  PERFORM content_item__delete(del__symlink_id);

  return 0; 
end;' language 'plpgsql';
