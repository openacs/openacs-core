ad_page_contract {
    @author Neophytos Demetriou <k2pts@cytanet.com.cy>
    @creation-date September 01, 2001
    @cvs-id $Id$
} {
    q:trim
    {t:trim ""}
    {offset:integer 0}
    {num:integer 0}
    {dfs:trim ""}
    {dts:trim ""}
    {search_package_id ""}
    {scope ""}
    {object_type "all"}
} -validate {
    keywords_p {
        if {![exists_and_not_null q]} {
            ad_complain "#search.lt_You_must_specify_some#"
        }
    }
}

set page_title "Search Results"

set package_id [ad_conn package_id]

set package_url [ad_conn package_url]
set package_url_with_extras $package_url

set context results
set context_base_url $package_url

# Do we want debugging information at the end of the page
set debug_p 0

set user_id [ad_conn user_id]
set driver [ad_parameter -package_id $package_id FtsEngineDriver]
if {[callback::impl_exists -impl $driver -callback search::driver_info]} {
    array set info [lindex [callback -impl $driver search::driver_info] 0]
#    array set info [list package_key intermedia-driver version 1 automatic_and_queries_p 1  stopwords_p 1]
} else {
    array set info [acs_sc_call FtsEngineDriver info [list] $driver]
}

if { [array get info] == "" } {
    ReturnHeaders
    ns_write "[_ search.lt_FtsEngineDriver_not_a]"
    ad_script_abort
}

if {[string equal "" [string trim $q]]} {
    set query {}
    set empty_p 1
    set url_advanced_search "advanced-search"
    ad_return_template
    # FIXME DAVEB I don't understand why I can't call ad_script_abort here instead of return....
    # if I call ad_script_abort the adp is never rendered
    return
} else { 
    set empty_p 0
}


if { $num <= 0} {
    set limit [ad_parameter -package_id $package_id LimitDefault]
} else {
    set limit $num
}


#
# Work out the date restriction 
#
set df ""
set dt ""

if { $dfs == "all" } {
    set dfs ""
}

array set symbol2interval [ad_parameter -package_id $package_id Symbol2Interval]
if { $dfs != "" } {
    set df [db_exec_plsql get_df "select now() + '$symbol2interval($dfs)'::interval"]
}
if { $dts != "" } {
    set dt [db_exec_plsql get_dt "select now() + '$symbol2interval($dts)'::interval"]
}

#set q [string tolower $q]
set urlencoded_query [ad_urlencode $q]

if { $offset < 0 } { set offset 0 }
set params [list $q $offset $limit $user_id $df]
if {$search_package_id eq "" && [ad_parameter -package_id $package_id SubsiteSearchP -default 1]
    && [subsite::main_site_id] != [ad_conn subsite_id]} {
    # We are in a subsite and SubsiteSearchP is true
    lappend params [concat [ad_conn subsite_id] [subsite::util::packages -node_id [ad_conn node_id]]]
} else { 
  lappend params $search_package_id
}

set t0 [clock clicks -milliseconds]

# TODO calculate subsite or dotlrn package_ids
if {![string equal "this" $scope]} {
    # don't send package_id if its not searching this package
    #set search_package_id ""
} else {
    set search_node_id [site_node::get_node_id_from_object_id -object_id $search_package_id]
    if {[string equal "dotlrn" [site_node::get_element -node_id $search_node_id -element package_key]]} {
	set search_package_id [site_node::get_children -node_id $search_node_id -element package_id]
    }
}

if {[callback::impl_exists -impl $driver -callback search::search]} {
    # DAVEB TODO Add subsite to the callback def?
    # FIXME do this in the intermedia driver!
#    set final_query_string [db_string final_query_select "select site_wide_search.im_convert(:q) from dual"]

    array set result [lindex [callback -impl $driver search::search -query $q -offset $offset -limit $limit -user_id $user_id -df $df -package_ids $search_package_id -object_type $object_type] 0]
} else {
    array set result [acs_sc_call FtsEngineDriver search $params $driver]
}
set tend [clock clicks -milliseconds]

if { $t == "Feeling Lucky" && $result(count) > 0} {
    set object_id [lindex $result(ids) 0]
    set object_type [acs_object_type $object_id]
    if {[callback::impl_exists -impl -callback search::url]} {
	set url [callback -impl $object_type search::url -object_id $object_id]
    } else {
	set url [acs_sc_call FtsContentProvider url [list $object_id] $object_type]
    }
    ad_returnredirect $url
    ad_script_abort
}

set elapsed [format "%.02f" [expr double(abs($tend - $t0)) / 1000.0]]
if { $offset >= $result(count) } { set offset [expr ($result(count) / $limit) * $limit] }
set low [expr $offset + 1]
set high [expr $offset + $limit]
if { $high > $result(count) } { set high $result(count) }
if { $info(automatic_and_queries_p) && ([lsearch -exact $q and] > 0) } {
    set and_queries_notice_p 1
} else {
    set and_queries_notice_p 0
}

set url_advanced_search ""
append url_advanced_search "advanced-search?q=${urlencoded_query}"
if { $num > 0 } { append url_advanced_search "&num=${num}" }


set query $q
set nquery [llength [split $q]]
set stopwords $result(stopwords)
set nstopwords [llength $result(stopwords)] 
set count $result(count)

template::multirow create searchresult title_summary txt_summary url_one object_id

for { set __i 0 } { $__i < [expr $high - $low +1] } { incr __i } {

    set object_id [lindex $result(ids) $__i]
    set object_type [acs_object_type $object_id]
    if {[callback::impl_exists -impl $object_type -callback search::datasource]} {
	array set datasource [lindex [callback -impl $object_type search::datasource -object_id $object_id] 0]
	set url_one [lindex [callback -impl $object_type search::url -object_id $object_id] 0]
    } else {
	ns_log notice "SEARCH search/www/search.tcl callback::datasource::${object_type} not found"
	array set datasource [acs_sc_call FtsContentProvider datasource [list $object_id] $object_type]
	set url_one [acs_sc_call FtsContentProvider url [list $object_id] $object_type]
    }
    search::content_get txt $datasource(content) $datasource(mime) $datasource(storage_type) $object_id
    if {[callback::impl_exists -impl $driver -callback search::summary]} {
	set title_summary [lindex [callback -impl $driver search::summary -query $q -text $datasource(title)] 0]
	set txt_summary [lindex [callback -impl $driver search::summary -query $q -text $txt] 0]
    } else {
	set title_summary [acs_sc_call FtsEngineDriver summary [list $q $datasource(title)] $driver]
	set txt_summary [acs_sc_call FtsEngineDriver summary [list $q $txt] $driver]
    }
    template::multirow append searchresult $title_summary $txt_summary $url_one
}


set from_result_page 1
set current_result_page [expr ($low / $limit) + 1]
set to_result_page [expr ceil(double($result(count)) / double($limit))]

set url_previous ""
set url_next ""
append url_previous "search?q=${urlencoded_query}&search_package_id=$search_package_id"
append url_next "search?q=${urlencoded_query}&search_package_id=$search_package_id"
if { [expr $current_result_page - 1] > $from_result_page } { 
    append url_previous "&offset=[expr ($current_result_page - 2) * $limit]"
}
if { $current_result_page < $to_result_page } { 
    append url_next "&offset=[expr $current_result_page * $limit]"
}
if { $num > 0 } {
    append url_previous "&num=$num"
    append url_next "&num=$num"
}
set ol_start [expr $offset + 1]

template::multirow create results_paginator item link
for { set __i $from_result_page } { $__i <= $to_result_page} { incr __i } {
    set link "search?q=${urlencoded_query}&search_package_id=$search_package_id"
    if { $__i > 1 } { append link "&offset=[expr ($__i - 1) * $limit]" }
    if { $num > 0 } { append link "&num=$num" }

    template::multirow append results_paginator $__i $link
}

set search_the_web [ad_parameter -package_id $package_id SearchTheWeb]
if [llength $search_the_web] {
    set stw ""
    foreach {url site} $search_the_web {
	append stw "<a href=\"[format $url $urlencoded_query]\">$site</a> "
    }
}

# header stuffs
if {![template::multirow exists link]} {
    template::multirow create link rel type href title lang media
}
template::multirow append link \
    stylesheet \
    "text/css" \
    "/resources/search/search.css" \
    "" \
    "" \
    "all"
