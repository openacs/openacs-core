
# /www/templates/homepage-news.tcl

ad_page_contract {
    @author Pat Colgan (pat@museatech.net)
    @creation-date 2001-09-01

    This page is for the OpenACS homepage.  In addition to 
    the Edit This Page functions, it has code for pulling
    out featured articles and profiles, news, and bboard
    posts.  

} {
} -properties {
    pa:onerow
    news_items:multirow
    feature_items:multirow
    forum_posts:multirow
    n_news_items:onevalue
    n_feature_items:onevalue
    n_forum_posts:onevalue
}

## config for the three call-out boxes
set n_news_items 5
set n_feature_items 3
set n_forum_posts 10
set max_post_age_days 14


set news_limit [expr $n_news_items + 1]
set forum_limit [expr $n_forum_posts + 1]

etp::get_page_attributes

#set user_id [ad_conn user_id]

set view_clause [db_map view_clause_live]

db_multirow news_items news_items_select "
select item_id,
       publish_title,
       pretty_publish_date
from   news_items_approved
where  package_id = 43787
       and publish_date < current_timestamp
       and (archive_date is null or archive_date > current_timestamp)
order  by publish_date desc, item_id desc
"


# This query gets all messages less than max_post_age_days old
# from forums the user has permission to access.
# Added sent_date_no_time so the order sorts properly within
# one day

#db_multirow forum_posts messages_select "
#    select message_id, title, sent_date,
#	       to_char(sent_date,'MM/DD/YY') as sent_date_no_time,
#               to_char(sent_date,'HH24:MM') as sent_time,
#               f.short_name as forum_name, f.forum_id,
#               case when num_replies = 2 then 
#                    '1 reply'
#               else 
#                    num_replies - 1 || ' ' || 'replies' 
#               end
#                 as replies_pretty,
#                  
#               case when length(content) > 100 then
#                  substring(content, 0, 100) || '...'
#               else
#                  content
#               end
#               as content
#          from bboard_messages_all b, bboard_forums f
#          where acs_permission__permission_p(b.forum_id,:user_id,'bboard_read_forum') = 't'
#	    and sent_date > now() - $max_post_age_days
#            and reply_to is null
#            and b.forum_id = f.forum_id
#            and f.bboard_id = 2369
#	order by sent_date desc
#         limit $forum_limit

#"

# This is the "forums" version (olah)
db_multirow forum_posts messages_select "

select fm.message_id,
       fm.forum_id,
       forums_forum__name(fm.forum_id) as forum_name,
       fm.subject as title

from (select message_id,
             forum_id,
             subject,
             parent_id
      from forums_messages_approved
      order by posting_date desc
      limit $forum_limit) fm, forums_forums ff

where fm.forum_id = ff.forum_id
and fm.parent_id is null
--and ff.package_id = 3061 
and ff.package_id = 3928 
order by forum_name
"

#Warning!  lazy hardcode of package id!

# this presents only non-expired news items
#set where "sysdate() between to_date(attributes.release_date, 'YYYY-MM-DD') 
#  and to_date(attributes.archive_date, 'YYYY-MM-DD')"
#set orderby "to_date(attributes.release_date, 'YYYY-MM-DD') desc"

# this limits the query to the desired number of items...
# ... plus one, so that we can use maxrows and rowcount
# in the adp to present a "more..." link if appropriate
# (maxrows without limiting the query could be performance killer)

set feature_limit [expr $n_feature_items + 1]

# speaking of performance, when this is live these 
# calls (including multirow above) should be cached.
# prob. a short cache for the forums.


#etp::get_content_items -where $where -orderby $orderby \
	               -limit $news_limit \
                       -package_id ???? -result_name news_items \
                       release_date archive_date 


#etp::get_content_items -package_id 4053 -limit $feature_limit \
                       -result_name feature_items
etp::get_content_items -package_id 16464 -limit $feature_limit \
                       -result_name feature_items


