<?xml version="1.0"?>
<queryset>

    <fullquery name="cr::keyword::get_keyword_id.select_keyword_id">
        <querytext>
            select keyword_id 
            from   cr_keywords
            where  parent_id = :parent_id
            and    heading = :heading
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::item_unassign_children.item_unassign_children">
        <querytext>
            delete from cr_item_keyword_map
            where item_id = :item_id
            and   keyword_id in (select p.keyword_id
                                   from   cr_keywords p
                                   where  p.parent_id = :parent_id)
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::item_assign.get_parent_id">
        <querytext>
            select parent_id
            from cr_keywords
            where keyword_id = :keyword
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::item_get_assigned.get_keywords">
        <querytext>
            select keyword_id from cr_item_keyword_map
            where item_id = :item_id
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::item_get_assigned.get_child_keywords">
        <querytext>
            select km.keyword_id
            from cr_item_keyword_map km,
                 cr_keywords kw
            where km.item_id = :item_id
            and   kw.parent_id = :parent_id
            and   kw.keyword_id = km.keyword_id
        </querytext>
    </fullquery>
    
    <fullquery name="cr::keyword::get_options_flat.select_keyword_options">
        <querytext>
            select heading,
                   keyword_id
            from   cr_keywords
            where  [ad_decode $parent_id "" "parent_id is null" "parent_id = :parent_id"]
            order  by lower(heading)
        </querytext>
    </fullquery>


</queryset>
