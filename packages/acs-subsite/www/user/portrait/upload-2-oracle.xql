<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_item">
        <querytext>

        begin
          :1 := content_item.new(
                 name => :name,
                 creation_ip => :creation_ip);
        end;

        </querytext>
</fullquery>

<fullquery name="create_rel">
        <querytext>

        begin
          :1 := acs_rel.new (
                 rel_type => 'user_portrait_rel',
                 object_id_one => :user_id,
                 object_id_two => :item_id);
        end;

        </querytext>
</fullquery>

<fullquery name="create_revision">
        <querytext>

        begin
          :1 := content_revision.new(
             title => :title,
             description => :portrait_comment,
             text => 'not_important',
             mime_type => :guessed_file_type,
             item_id => :item_id,
             creation_user => :user_id,
             creation_ip => :creation_ip
          );

          update cr_items
          set live_revision = :1
          where item_id = :item_id;
        end;

        </querytext>
</fullquery>

<fullquery name="update_photo">
        <querytext>

        update cr_revisions
        set content = empty_blob()
        where revision_id = :revision_id
        returning content into :1

        </querytext>
</fullquery>

<fullquery name="update_photo_info">
        <querytext>

	update cr_revisions
	set description = :portrait_comment,
	    publish_date = sysdate,
	    mime_type = :guessed_file_type,
	    title = :title
	where revision_id = :revision_id
 
        </querytext>
</fullquery>

</queryset>
