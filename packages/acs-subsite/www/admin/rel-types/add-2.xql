<?xml version="1.0"?>
<queryset>

<fullquery name="update_rel_type_mapping">      
      <querytext>
      
    insert into group_type_allowed_rels
    (constraint_id, group_type, rel_type)
    values
    (:constraint_id, :object_type, :rel_type)

      </querytext>
</fullquery>

 
</queryset>
