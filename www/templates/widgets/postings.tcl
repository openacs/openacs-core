ad_page_contract {
    @author Ola Hansson ola@polyxena.net
    @creation-date 2002-08-06
} {
} -properties {
    title:onevalue
    forum_limit:onevalue
    forum_posts:multirow
}

set n_posts 10
set forum_limit [expr $n_posts + 1]
set max_post_age_days 7
if {![info exists boxclass]} {set boxclass box}

db_multirow forum_posts messages_select "
select * from (
  select fm.message_id,
         fm.forum_id,
         ff.name as forum_name,
         fm.subject,
         fm.last_child_post
  from forums_messages fm
       , forums_forums ff
  where fm.forum_id = ff.forum_id
  and fm.parent_id is null
  and last_child_post > ( now() - '7 days' :: interval )
  and ff.package_id = 3061
  and ff.forum_id <> 46408
  and ff.enabled_p='t'
  and fm.state='approved'
  order by last_child_post desc
  limit $forum_limit) as messages
order by messages.forum_name,messages.last_child_post desc
" {
    # insert spaces into words that are longer than 20 characters. otherwise
    # the layout would barf (box becomes too wide because of non-breaking text).
    regsub -all {(\S{15}?)} $subject {\1 } subject
    set subject [ad_quotehtml $subject]
} 



