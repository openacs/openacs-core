<?xml version="1.0"?>
<queryset>

<fullquery name="get_item_id">
        <querytext>

        select object_id_two as item_id
        from acs_rels
        where object_id_one = :user_id
        and rel_type = 'user_portrait_rel'

        </querytext>
</fullquery>

<fullquery name="upload_image_info">
        <querytext>

                insert into images
                (image_id, width, height)
                values
                (:revision_id, :original_width, :original_height)

        </querytext>
</fullquery>

<fullquery name="get_revision_id">
        <querytext>

        select live_revision as revision_id
        from cr_items
        where item_id = :item_id

        </querytext>
</fullquery>

<fullquery name="update_image_info">
        <querytext>

	update images
	set width = :original_width, height = :original_height
	where image_id = :revision_id

        </querytext>
</fullquery>

</queryset>
