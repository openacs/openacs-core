<?xml version="1.0"?>
<queryset>

  <fullquery name="note_select">      
    <querytext>
      select title, body
      from notes
      where note_id = :note_id
    </querytext>
  </fullquery>

  <fullquery name="object_update">      
    <querytext>
        update acs_objects
        set modifying_user = :modifying_user,
          modifying_ip = :modifying_ip
        where object_id = :note_id
    </querytext>
  </fullquery>

  <fullquery name="note_update">      
    <querytext>
        update notes
        set title = :title,
          body = :body
        where note_id = :note_id
    </querytext>
  </fullquery>
 
</queryset>
