<?xml version="1.0"?>

<queryset>

    <fullquery name="existing_urls">
        <querytext>
            select name
            from   site_nodes
            where  parent_id = :node_id
        </querytext>
    </fullquery>

</queryset>
