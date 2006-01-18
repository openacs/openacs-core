-- update image package to allow null package_id
-- hbrock@harpcolumn.com 2006-1-19

create or replace package image
as
  --/**
  -- Creates a new image
  -- Binary file stored in file-system
  --*/
  function new (
    name		in cr_items.name%TYPE,
    parent_id		in cr_items.parent_id%TYPE default null,
    item_id		in acs_objects.object_id%TYPE default null,
    revision_id		in acs_objects.object_id%TYPE default null,
    content_type	in acs_object_types.object_type%TYPE default 'image',
    creation_date	in acs_objects.creation_date%TYPE default sysdate, 
    creation_user	in acs_objects.creation_user%TYPE default null, 
    creation_ip		in acs_objects.creation_ip%TYPE default null, 
    locale		in cr_items.locale%TYPE default null,
    context_id		in acs_objects.context_id%TYPE default null,
    title		in cr_revisions.title%TYPE default null,
    description		in cr_revisions.description%TYPE default null,
    mime_type		in cr_revisions.mime_type%TYPE default null,
    nls_language	in cr_revisions.nls_language%TYPE default null,
    relation_tag	in cr_child_rels.relation_tag%TYPE default null,
    is_live		in char default 'f',
    publish_date	in cr_revisions.publish_date%TYPE default sysdate,
    data		in cr_revisions.content%TYPE default null,
    filename		in cr_revisions.filename%TYPE default null,
    height		in images.height%TYPE default null,
    width		in images.width%TYPE default null,
    file_size		in cr_revisions.content_length%TYPE default null,
    storage_type        in cr_items.storage_type%TYPE default 'file',
    package_id          in acs_objects.package_id%TYPE default null
  ) return cr_items.item_id%TYPE;

  function new_revision (
    item_id		in acs_objects.object_id%TYPE default null,
    revision_id		in acs_objects.object_id%TYPE default null,
    creation_date	in acs_objects.creation_date%TYPE default sysdate, 
    creation_user	in acs_objects.creation_user%TYPE default null, 
    creation_ip		in acs_objects.creation_ip%TYPE default null, 
    title		in cr_revisions.title%TYPE default null,
    description		in cr_revisions.description%TYPE default null,
    mime_type		in cr_revisions.mime_type%TYPE default null,
    nls_language	in cr_revisions.nls_language%TYPE default null,
    is_live		in char default 'f',
    publish_date	in cr_revisions.publish_date%TYPE default sysdate,
    data                in cr_revisions.content%TYPE default null,
    filename		in cr_revisions.filename%TYPE default null,
    height		in images.height%TYPE default null,
    width		in images.width%TYPE default null,
    file_size		in cr_revisions.content_length%TYPE default null,
    package_id          in acs_objects.package_id%TYPE default null
  ) return cr_revisions.revision_id%TYPE;

  --/**
  -- Deletes a single revision of image
  -- Schedules binary file for deletion.
  -- File delete sweep checks to see if no other images are using binary prior to deleting
  --*/
  procedure delete_revision (
    revision_id		in cr_revisions.revision_id%TYPE
  );

  --/**
  -- Deletes a image and all revisions
  -- Schedules binary files for deletion.
  -- 
  -- Be careful, cannot be undone (easily)
  --*/
  procedure del (
    item_id		in cr_items.item_id%TYPE
  );

end image;
/
show errors;

create or replace package body image
as
  function new (
    name		in cr_items.name%TYPE,
    parent_id		in cr_items.parent_id%TYPE default null,
    item_id		in acs_objects.object_id%TYPE default null,
    revision_id		in acs_objects.object_id%TYPE default null,
    content_type	in acs_object_types.object_type%TYPE default 'image',
    creation_date	in acs_objects.creation_date%TYPE default sysdate, 
    creation_user	in acs_objects.creation_user%TYPE default null, 
    creation_ip		in acs_objects.creation_ip%TYPE default null, 
    locale		in cr_items.locale%TYPE default null,
    context_id		in acs_objects.context_id%TYPE default null,
    title		in cr_revisions.title%TYPE default null,
    description		in cr_revisions.description%TYPE default null,
    mime_type		in cr_revisions.mime_type%TYPE default null,
    nls_language	in cr_revisions.nls_language%TYPE default null,
    relation_tag	in cr_child_rels.relation_tag%TYPE default null,
    is_live		in char default 'f',
    publish_date	in cr_revisions.publish_date%TYPE default sysdate,
    data                in cr_revisions.content%TYPE default null,
    filename		in cr_revisions.filename%TYPE default null,
    height		in images.height%TYPE default null,
    width		in images.width%TYPE default null,
    file_size		in cr_revisions.content_length%TYPE default null,
    storage_type        in cr_items.storage_type%TYPE default 'file',
    package_id          in acs_objects.package_id%TYPE default null
  ) return cr_items.item_id%TYPE
  is
    v_item_id	      cr_items.item_id%TYPE;
    v_revision_id     cr_revisions.revision_id%TYPE;
    v_package_id      acs_objects.package_id%TYPE;
  begin
    
    if package_id is null then
      v_package_id := acs_object.package_id(new.parent_id);
    else
      v_package_id := package_id;
    end if;

    v_item_id := content_item.new (
      name           => name,
      item_id	     => item_id,
      parent_id	     => parent_id,
      package_id     => v_package_id,
      relation_tag   => relation_tag,
      content_type   => content_type,
      creation_date  => creation_date,
      creation_user  => creation_user,
      creation_ip    => creation_ip,
      locale	     => locale,
      context_id     => context_id,
      storage_type   => storage_type
    );

    v_revision_id := content_revision.new (
      title         => title,
      description   => description,
      item_id	    => v_item_id,
      revision_id   => revision_id,
      package_id    => v_package_id,
      publish_date  => publish_date,
      mime_type	    => mime_type,
      nls_language  => nls_language,
      data          => data,
      filename      => filename,
      creation_date => sysdate,
      creation_user => creation_user,
      creation_ip   => creation_ip
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, height, width);

    -- update revision with image file info
    update cr_revisions
    set content_length = file_size
    where revision_id = v_revision_id;

    -- is_live => 't' not used as part of content_item.new
    -- because content_item.new does not let developer specify revision_id,
    -- revision_id is determined in advance 

    if is_live = 't' then
       content_item.set_live_revision (
         revision_id => v_revision_id
       );
    end if;

    return v_item_id;
  end new;

  function new_revision (
    item_id		in acs_objects.object_id%TYPE default null,
    revision_id		in acs_objects.object_id%TYPE default null,
    creation_date	in acs_objects.creation_date%TYPE default sysdate, 
    creation_user	in acs_objects.creation_user%TYPE default null, 
    creation_ip		in acs_objects.creation_ip%TYPE default null, 
    title		in cr_revisions.title%TYPE default null,
    description		in cr_revisions.description%TYPE default null,
    mime_type		in cr_revisions.mime_type%TYPE default null,
    nls_language	in cr_revisions.nls_language%TYPE default null,
    is_live		in char default 'f',
    publish_date	in cr_revisions.publish_date%TYPE default sysdate,
    data                in cr_revisions.content%TYPE default null,
    filename		in cr_revisions.filename%TYPE default null,
    height		in images.height%TYPE default null,
    width		in images.width%TYPE default null,
    file_size		in cr_revisions.content_length%TYPE default null,
    package_id          in acs_objects.package_id%TYPE default null
  ) return cr_revisions.revision_id%TYPE
  is
    v_revision_id     cr_revisions.revision_id%TYPE;
    v_package_id      acs_objects.package_id%TYPE;

  begin
    if package_id is null then
      v_package_id := acs_object.package_id(new_revision.item_id);
    else
      v_package_id := package_id;
    end if;

    v_revision_id := content_revision.new (
      title => title,
      description   => description,
      item_id	    => item_id,
      revision_id   => revision_id,
      package_id    => v_package_id,
      publish_date  => publish_date,
      mime_type	    => mime_type,
      nls_language  => nls_language,
      data          => data,
      filename      => filename,
      creation_date => creation_date,
      creation_user => creation_user,
      creation_ip   => creation_ip
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, height, width);

    -- update revision with image file info
    update cr_revisions
    set content_length = file_size
    where revision_id = v_revision_id;

    -- is_live => 't' not used as part of content_item.new
    -- because content_item.new does not let developer specify revision_id,
    -- revision_id is determined in advance 

    if is_live = 't' then
       content_item.set_live_revision (
         revision_id => v_revision_id
       );
    end if;

    return v_revision_id;
  end new_revision;

  procedure delete_revision (
    revision_id		in cr_revisions.revision_id%TYPE
  )
  is
	v_content	cr_files_to_delete.path%TYPE default null;
  begin
    content_revision.del (
      revision_id => revision_id
    );
  end delete_revision;
  
  procedure del (
    item_id		in cr_items.item_id%TYPE
  )
  is 

    cursor image_revision_cur is
      select
        revision_id
      from
        cr_revisions
      where
        item_id = image.del.item_id
      order by revision_id asc;

      -- order by used in cursur so latest revision will be deleted last
      -- save resetting latest revision multiple times during delete process

  begin
    for v_revision_val in image_revision_cur loop
      image.delete_revision (
        revision_id => v_revision_val.revision_id
      );
    end loop;

    content_item.del (
      item_id => item_id
    );
  end del;
    
end image;
/
show errors;
