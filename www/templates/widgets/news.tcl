ad_page_contract {
    @author Ola Hansson ola@polyxena.net
    @creation-date 2002-08-06
} {
} -properties {
    title:onevalue
    n_news_items:onevalue
    news_items:multirow
}

set n_news_items 6
set news_limit [expr $n_news_items + 1]

set max_post_age_days 60

db_multirow news_items news_items_select "
select item_id,
       publish_title,
       pretty_publish_date
from   news_items_approved
--where  package_id = 43787
--where  package_id = 3147
where publish_date < current_timestamp
       and (archive_date is null or archive_date > current_timestamp)
order  by publish_date desc, item_id desc
limit $news_limit
" {
    regsub -all {/} $publish_title { / } publish_title
}

#etp::get_page_attributes
#etp::get_content_items -where $where -orderby $orderby \
	               -limit $news_limit \
                       -package_id ???? -result_name news_items \
                       release_date archive_date
