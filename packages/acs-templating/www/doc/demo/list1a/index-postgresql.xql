<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="template_demo_notes">      
    <querytext>

      select 
	n.template_demo_note_id, 
	n.title
      from  template_demo_notes n, acs_objects o
      where n.template_demo_note_id = o.object_id
      and   acs_permission__permission_p(template_demo_note_id, :user_id, 'read')
    </querytext>
  </fullquery>
 
</queryset>
