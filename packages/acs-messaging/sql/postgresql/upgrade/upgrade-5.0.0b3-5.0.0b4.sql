-- call image__delete instead.



-- added
select define_function_args('acs_message__delete_image','image_id');

--
-- procedure acs_message__delete_image/1
--
CREATE OR REPLACE FUNCTION acs_message__delete_image(
   p_image_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    perform image__delete(p_image_id);

    return 1;
END;
$$ LANGUAGE plpgsql;
