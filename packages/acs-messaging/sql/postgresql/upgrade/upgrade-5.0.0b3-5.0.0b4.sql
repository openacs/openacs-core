-- call image__delete instead.

create or replace function acs_message__delete_image (integer)
returns integer as '
declare
    p_image_id  alias for $1;
begin
    perform image__delete(p_image_id);

    return 1;
end;' language 'plpgsql';
