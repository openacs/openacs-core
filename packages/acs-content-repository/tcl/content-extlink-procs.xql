<?xml version="1.0"?>
<queryset>

   <fullquery name="content::extlink::name.get">      
      <querytext>
          select label
          from cr_extlinks
          where extlink_id = :item_id
      </querytext>
   </fullquery>

</queryset>
