set n_jobs  4
set jobs_limit [expr $n_jobs + 1]


etp::get_page_attributes
etp::get_content_items

etp::get_content_items -package_id 3889 -result_name jobs -limit $jobs_limit
#etp::get_content_items -package_id 3197 -result_name jobs -limit $jobs_limit
