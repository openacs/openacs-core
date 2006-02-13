<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="notes">      
    <querytext>
      select note_id, title, body,
             decode(acs_permission.permission_p(note_id,
                                                :user_id,
                                                'write'),
                    't', 1,
                    'f', 0) as write_p,
             decode(acs_permission.permission_p(note_id,
                                                :user_id,
                                                'admin'),
                    't', 1,
                    'f', 0) as admin_p,
             decode(acs_permission.permission_p(note_id,
                                                :user_id,
                                                'delete'),
                    't', 1,
                    'f', 0) as delete_p
      from notes n, acs_objects o
      where n.note_id = o.object_id
        and o.context_id = :package_id
        and exists (select 1
                    from acs_object_party_privilege_map
                    where object_id = note_id
                      and party_id = :user_id
                      and privilege = 'read')
      order by creation_date
    </querytext>
  </fullquery>
 
</queryset>
