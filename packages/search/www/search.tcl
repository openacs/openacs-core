ad_page_contract {
    @author Neophytos Demetriou <k2pts@cytanet.com.cy>
    @creation-date September 01, 2001
    @cvs-id $Id$
} {
    q:notnull,trim
    {offset 0}
} -errors {
    q:notnull {You must specify some keywords.}
}

ns_startcontent -type "text/html"
set this_dir [file dirname [ad_conn file]]
set template_top_file "$this_dir/search-results-top"
set template_one_file "$this_dir/search-results-one"
set template_bottom_file "$this_dir/search-results-bottom"


set package_id [ad_conn package_id]
set driver [ad_parameter -package_id $package_id FtsEngineDriver]
array set info [acs_sc_call FtsEngineDriver info [list] $driver]
set limit [ad_parameter -package_id $package_id LimitDefault]

set title "Search Results"
set context_bar [ad_context_bar {Search Results}]

set q [string tolower $q]
if { $offset < 0 } { set offset 0 }
set t0 [clock clicks -milliseconds]
array set result [acs_sc_call FtsEngineDriver search [list $q $offset $limit] $driver]
set tend [clock clicks -milliseconds]
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

set template_top [template::adp_parse $template_top_file [list \
	title $title \
	context_bar $context_bar \
	query $q \
	nquery [llength $q] \
	and_queries_notice_p $and_queries_notice_p \
	stopwords $result(stopwords) \
	nstopwords [llength $result(stopwords)] \
	low $low \
	high $high \
	count $result(count) \
	elapsed $elapsed]]

ns_write $template_top

    for { set __i [expr 0] } { $__i < [expr $high - $low +1] } { incr __i } {

	set object_id [lindex $result(ids) $__i]
	set object_type [db_exec_plsql get_object_type "select acs_object_util__get_object_type($object_id)"]
	array set datasource [acs_sc_call FtsContentProvider datasource [list $object_id] $object_type]

	set txt [search_content_filter $datasource(content) $datasource(mime) $datasource(storage)]
	set title_summary [acs_sc_call FtsEngineDriver summary [list $q $datasource(title)] $driver]
	set txt_summary [acs_sc_call FtsEngineDriver summary [list $q $txt] $driver]
	set url [acs_sc_call FtsContentProvider url [list $object_id] $object_type]


	set template_one [template::adp_parse $template_one_file [list \
		title_summary $title_summary \
		txt_summary $txt_summary \
		url $url]]

	ns_write $template_one

    }

    set urlencoded_query [ad_urlencode $q]
    set from_result_page 1
    set current_result_page [expr ($low / $limit) + 1]
    set to_result_page [expr ($result(count) / $limit) + 1]

    set items [list]
    set links [list]
    set values [list]
    for { set __i $from_result_page } { $__i <= $to_result_page} { incr __i } {
	lappend items $__i
	if { $__i == 1 } {
	    lappend links "search?q=${urlencoded_query}"
	} else {
	    lappend links "search?q=${urlencoded_query}&offset=[expr ($__i - 1) * $limit]"
	}
	lappend values $__i
    }

    set search_the_web [ad_parameter -package_id $package_id SearchTheWeb]
    if [llength $search_the_web] {
	set stw ""
	foreach {url site} $search_the_web {
	    append stw "<a href=[format $url $urlencoded_query]>$site</a> "
	}
    }

set template_bottom [template::adp_parse $template_bottom_file [list \
	query $q \
	count $result(count) \
	urlencoded_query $urlencoded_query \
	from_result_page $from_result_page \
	current_result_page $current_result_page \
	to_result_page $to_result_page \
	offset_previous [expr $offset - $limit] \
	choice_bar [search_choice_bar $items $links $values $current_result_page] \
	offset_next [expr $offset + $limit] \
	stw $stw\
	  ]]

ns_write $template_bottom






