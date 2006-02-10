<?xml version="1.0"?>
<queryset>

  <fullquery name="template_demo_note_select">      
    <querytext>
      select title, body, color
      from template_demo_notes
      where template_demo_note_id = :template_demo_note_id
    </querytext>
  </fullquery>

  <fullquery name="object_update">      
    <querytext>
        update acs_objects
        set modifying_user = :modifying_user,
          modifying_ip = :modifying_ip
        where object_id = :template_demo_note_id
    </querytext>
  </fullquery>

  <fullquery name="template_demo_note_update">      
    <querytext>
        update template_demo_notes
        set title = :title,
          body = :body
          color = :color
        where template_demo_note_id = :template_demo_note_id
    </querytext>
  </fullquery>
 
</queryset>
