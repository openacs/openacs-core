<?xml version="1.0"?>
<queryset>

<fullquery name="new.parent_rel_type">      
      <querytext>
      
	    select table_name as references_table,
	           id_column as references_column
	      from acs_object_types
	     where object_type=:supertype
	
      </querytext>
</fullquery>

<fullquery name="rel_types::new.update_type">
<querytext>
update acs_object_types set dynamic_p='t' where object_type = :rel_type
</querytext>
</fullquery>

<fullquery name="rel_types::add_permissible.insert_rel_type">
<querytext>
insert into group_type_rels
(group_rel_type_id, group_type, rel_type)
values
(acs_object_id_seq.nextval, :group_type, :rel_type)
</querytext>
</fullquery>
 
</queryset>
