<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="user_info">      
      <querytext>
      select first_names, 
             last_name, 
             username, 
             email,
             nvl(screen_name,'&lt; none set up &gt;') as screen_name,
             creation_date, 
             creation_ip, 
             to_char(last_visit, 'YYYY-MM-DD HH24:MI:SS') as last_visit_ansi, 
             member_state,
             email_verified_p, 
             url
      from   cc_users
      where  user_id = :user_id
      </querytext>
</fullquery>

<fullquery name="get_item_id">      
      <querytext>
      select live_revision as revision_id, nvl(title,'view this portrait') portrait_title
from acs_rels a, cr_items c, cr_revisions cr 
where a.object_id_two = c.item_id
and c.live_revision = cr.revision_id
and a.object_id_one = :user_id
and a.rel_type = 'user_portrait_rel'
      </querytext>
</fullquery>

 
<fullquery name="user_contributions">      
      <querytext>
      select at.pretty_name, at.pretty_plural, a.creation_date, acs_object.name(a.object_id) object_name
from acs_objects a, acs_object_types at
where a.object_type = at.object_type
and a.creation_user = :user_id
order by pretty_name, creation_date desc, object_name
      </querytext>
</fullquery>

 
</queryset>
