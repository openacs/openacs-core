<?xml version="1.0"?>
<queryset>

    <fullquery name="cr::keyword::item_assign.get_parent_id">
        <querytext>
            select parent_id
            from cr_keywords
            where keyword_id = :keyword
        </querytext>
    </fullquery>

</queryset>
