# included from elements.
ad_require_permission $segment_id "read"

set write_p [ad_permission_p $segment_id "write"]

set package_url [ad_conn package_url]
set user_id [ad_conn user_id]

db_multirow elements elements_select {
    select acs_object.name(map.party_id) as name, map.rel_id, 
           decode(map.container_id, :group_id, 1, 0) as direct_p,
           acs_object.name(map.container_id) as container_name
      from rel_segment_party_map map
     where acs_permission.permission_p(map.party_id, :user_id, 'read') = 't'
       and map.segment_id = :segment_id
     order by lower(name)
}



