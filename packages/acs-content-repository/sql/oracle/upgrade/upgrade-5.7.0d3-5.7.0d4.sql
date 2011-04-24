declare
 attr_id	acs_attributes.attribute_id%TYPE;
 exists_p integer;
begin

  select count(*) into exists_p
  from acs_attributes
  where object_type = 'content_revision'
    and attribute_name = 'item_id';

  if exists_p = 0 then
    attr_id := content_type.create_attribute (
      content_type   => 'content_revision',
      attribute_name => 'item_id',
      datatype => 'integer',
      pretty_name => 'Item id',
      pretty_plural => 'Item ids'
    );
  end if;

  select count(*) into exists_p
  from acs_attributes
  where object_type = 'content_revision'
    and attribute_name = 'content';

  if exists_p = 0 then
    attr_id := content_type.create_attribute (
      content_type   => 'content_revision',
      attribute_name => 'content',
      datatype => 'text',
      pretty_name => 'content',
      pretty_plural => 'content'
    );
  end if;

end;
/
show errors
