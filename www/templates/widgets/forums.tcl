
set user_id [ad_conn user_id]

db_multirow forums forums_select {
    select forum_id, name as short_name, posting_policy, charter
      from forums_forums f
      where
      acs_permission__permission_p(forum_id,:user_id,'forum_read') = 't'
      and enabled_p = 't'
      and package_id = 3061
    order by upper(name)
} {

    regsub -all {/} $short_name { / } short_name
}
