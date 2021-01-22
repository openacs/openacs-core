<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="template_demo_notes_paginate">      
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
      and   p.person_id = o.creation_user
      and   acs_permission__permission_p(n.template_demo_note_id, :user_id, 'read')
      
      [template::list::filter_where_clauses -and -name notes]
      [template::list::orderby_clause -orderby -name notes]
      
    </querytext>
  </fullquery>
 
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
      and   p.person_id = o.creation_user
      and   acs_permission__permission_p(n.template_demo_note_id, :user_id, 'read')

      [template::list::page_where_clause -and -name notes -key template_demo_note_id]
      
    </querytext>
  </fullquery>
 
</queryset>
