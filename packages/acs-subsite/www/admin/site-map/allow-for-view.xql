<?xml version="1.0"?>

<queryset>

    <fullquery name="delete_nodes">
        <querytext>
	    delete from site_nodes_selection
        </querytext>
    </fullquery>


    <fullquery name="insert_nodes">
        <querytext>
	insert into site_nodes_selection (node_id,view_p) values (:checkbox,'t')
        </querytext>
    </fullquery>


</queryset>
