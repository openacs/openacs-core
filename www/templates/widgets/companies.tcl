# practically an unlimited no. of companies should be displayed
set n_companies  1000
set companies_limit  [expr $n_companies + 1]


etp::get_page_attributes
etp::get_content_items

etp::get_content_items -package_id 3906 -result_name companies -limit $companies_limit -orderby "lower(title)"
#etp::get_content_items -package_id 3188 -result_name companies -limit $companies_limit
