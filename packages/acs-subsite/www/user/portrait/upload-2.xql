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


<fullquery name="update_object_title">
        <querytext>

	    update acs_objects
	    set title = :title
	    where object_id = :revision_id

        </querytext>
</fullquery>

</queryset>
