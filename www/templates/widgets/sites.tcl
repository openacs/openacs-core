# this is an ugly hack just to get the total # of sites.
# I must know that # to calculate the random offset...
# this probably costs too much when there are many sites. (olah)

etp::get_content_items -package_id 3894 -result_name sites
#etp::get_content_items -package_id 3173 -result_name sites
set total [template::multirow size sites]

set n_sites 5
set sites_limit [expr $n_sites + 1]

set groups [expr $total / $n_sites]
set offset [expr [ns_rand $groups] * $n_sites]

set orderby "upper(title)"

etp::get_page_attributes
etp::get_content_items

etp::get_content_items -package_id 3894 -result_name sites -orderby $orderby -limit "$sites_limit OFFSET $offset"
#etp::get_content_items -package_id 3173 -result_name sites -orderby $orderby -limit "$sites_limit OFFSET $offset"
