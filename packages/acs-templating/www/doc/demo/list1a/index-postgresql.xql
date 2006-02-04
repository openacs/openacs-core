<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="template_demo_notes">      
    <querytext>

      select 
	n.template_demo_note_id, 
	n.title
      from template_demo_notes n, acs_objects o
      where n.template_demo_note_id = o.object_id
        and exists (select 1
                    from acs_object_party_privilege_map
                    where object_id = template_demo_note_id
                      and party_id = :user_id
                      and privilege = 'read')

    </querytext>
  </fullquery>
 
</queryset>
