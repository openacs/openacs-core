<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="template_demo_notes">      
    <querytext>

      select 
	n.template_demo_note_id, 
	n.title,
        n.color,
	to_char(o.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date,
	p.first_names || ' ' || p.last_name as creation_user_name
      from 
	template_demo_notes n, 
	acs_objects o,
	persons p
      where n.template_demo_note_id = o.object_id
	and o.creation_user = p.person_id
        and exists (select 1
                    from acs_object_party_privilege_map
                    where object_id = template_demo_note_id
                      and party_id = :user_id
                      and privilege = 'read')
        [template::list::orderby_clause -orderby -name notes]
    </querytext>
  </fullquery>
 
</queryset>
