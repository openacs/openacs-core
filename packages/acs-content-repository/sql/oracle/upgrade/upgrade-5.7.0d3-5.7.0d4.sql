declare
 attr_id	acs_attributes.attribute_id%TYPE;
begin

 attr_id := content_type.create_attribute (
   content_type   => 'content_revision',
   attribute_name => 'item_id',
   datatype => 'integer',
   pretty_name => 'Item id',
   pretty_plural => 'Item ids'
 );

 attr_id := content_type.create_attribute (
   content_type   => 'content_revision',
   attribute_name => 'content',
   datatype => 'text',
   pretty_name => 'content',
   pretty_plural => 'content'
 );

end;
/
show errors
