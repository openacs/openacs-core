<?xml version="1.0"?>
<queryset>

<fullquery name="exists_p">      
      <querytext>
      select count(*) from group_type_rels where group_type = :group_type and rel_type = :rel_type
      </querytext>
</fullquery>

 
</queryset>
