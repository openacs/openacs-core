set n_hosting  4
set hosting_limit [expr $n_hosting + 1]


etp::get_page_attributes
etp::get_content_items

etp::get_content_items -package_id 44095 -result_name hosting -limit $hosting_limit
