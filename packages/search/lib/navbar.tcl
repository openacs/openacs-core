set package_id [ad_conn package_id]

set limit [parameter::get -package_id $package_id -parameter LimitDefault]
set pages_per_group [parameter::get -package_id $package_id -parameter PagesPerGroup]

set current_result_page [expr {$low / $limit}]
set from_result_page [expr {($current_result_page / $pages_per_group) * $pages_per_group}]
set last_result_page [expr {($count + $limit - 1)/ $limit - 1}]
set to_result_page [expr {($last_result_page < $pages_per_group + $from_result_page - 1 ? $last_result_page : $pages_per_group + $from_result_page - 1)} ]
set current_page_group [expr { int($current_result_page / $pages_per_group) }]
set last_page_group [expr { int($last_result_page / $pages_per_group) }]
set first_page_in_group [expr { $current_page_group * $pages_per_group }]
set last_page_in_group [expr { ($current_page_group + 1) * $pages_per_group - 1 }]

security::csrf::new
if {[info exists ::__csrf_token]} {set __csrf_token $::__csrf_token}

if { $current_page_group >= 1 } {
    set offset [expr {($current_page_group - 1) * $pages_per_group * $limit}]
    set url_previous_group [export_vars -base search {q search_package_id offset num __csrf_token}]
} else {
    set url_previous_group ""
}

if { $current_page_group < $last_page_group } {
    set offset [expr {($current_page_group + 1) * $pages_per_group * $limit}]
    set url_next_group [export_vars -base search {q search_package_id offset num __csrf_token}]
} else {
    set url_next_group ""
}

if { $current_result_page > 0 } { 
    set offset [expr {($current_result_page - 1) * $limit}]
    set url_previous [export_vars -base search {q search_package_id offset num __csrf_token}]
} else {
    set url_previous ""
}

if { $current_result_page < $last_result_page } { 
    set offset [expr {$current_result_page * $limit + $limit}]
    set url_next [export_vars -base search {q search_package_id offset num __csrf_token}]
} else {
    set url_next ""
}

template::multirow create results_paginator item link current_p
for { set __i $from_result_page } { $__i <= $to_result_page} { incr __i } {
    set offset [expr {$__i * $limit}]
    set link [export_vars -base search {q search_package_id offset num __csrf_token}]
    template::multirow append results_paginator [expr {$__i + 1}] $link [expr {$__i == $current_result_page}]
}

ad_return_template [template::themed_template /packages/search/lib/navbar]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
