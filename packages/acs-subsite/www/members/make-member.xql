<?xml version="1.0"?>

<queryset>

<fullquery name="get_rel_id">
      <querytext>

         select distinct rel_id
         from rel_segment_party_map
         where rel_type = 'admin_rel'
           and group_id = :group_id
           and party_id = :user_id
	
      </querytext>
</fullquery>
</queryset>
