ad_include_contract {
    Included from elements.
} {
    segment_id:integer,notnull
    group_id:integer,notnull
}

permission::require_permission -object_id $segment_id -privilege "read"

set write_p [permission::permission_p -object_id $segment_id -privilege "write"]

set package_url [ad_conn package_url]
set user_id [ad_conn user_id]

db_multirow elements elements_select {
    select acs_object.name(map.party_id) as name, map.rel_id,
           case when map.container_id = :group_id then 1 else 0 end as direct_p,
           acs_object.name(map.container_id) as container_name
      from rel_segment_party_map map
     where acs_permission.permission_p(map.party_id, :user_id, 'read')
       and map.segment_id = :segment_id
     order by name
}




# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
