-- Create the default templates
declare
  v_item_id integer;
  v_revision_id integer;
begin

  select acs_object_id_seq.nextval into v_item_id from dual;

  v_item_id := content_template.new (
    name	=> 'default_template',
    parent_id 	=> -200,
    template_id	=> v_item_id
  );

  v_revision_id := content_revision.new (
    title	=> 'template',
    mime_type	=> 'text/html',
    item_id	=> v_item_id
  );

  update 
    cr_items
  set 
    live_revision = v_revision_id
  where 
    item_id = v_item_id;

  content_type.register_template (
    content_type	=> 'content_revision',
    template_id		=> v_item_id,
    use_context		=> 'public',
    is_default		=> 't'
  );

  content_type.register_template (
    content_type	=> 'image',
    template_id		=> v_item_id,
    use_context		=> 'public',
    is_default		=> 't'
  );

  content_type.register_template (
    content_type	=> 'content_template',
    template_id		=> v_item_id,
    use_context		=> 'public',
    is_default		=> 't'
  );
end;
/
show errors
