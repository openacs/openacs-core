update acs_attributes
set datatype = 'richtext'
where object_type = 'content_revision'
  and attribute_name = 'content';
