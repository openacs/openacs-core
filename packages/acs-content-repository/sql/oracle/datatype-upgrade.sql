


update acs_attributes
  set datatype = 'keyword'
  where attribute_name = 'name'
  and object_type = 'content_item';

update acs_attributes
  set datatype = 'keyword'
  where attribute_name = 'locale'
  and object_type = 'content_item';

update acs_attributes
  set datatype = 'text'
  where attribute_name = 'title'
  and object_type = 'content_revision';

update acs_attributes
  set datatype = 'text'
  where attribute_name = 'description'
  and object_type = 'content_revision';

update acs_attributes
  set datatype = 'text'
  where attribute_name = 'mime_type'
  and object_type = 'content_revision';

update acs_attributes
  set datatype = 'integer'
  where attribute_name = 'width'
  and object_type = 'image';

update acs_attributes
  set datatype = 'integer'
  where attribute_name = 'height'
  and object_type = 'image';
