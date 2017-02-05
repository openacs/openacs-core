ad_page_contract {
    @author Neophytos Demetriou <k2pts@cytanet.com.cy>
    @creation-date September 01, 2001
    @cvs-id $Id$
} {
    q:trim
    {t:trim ""}
    {offset:naturalnum,notnull 0}
    {num:range(0|200) 0}
    {dfs:word,trim,notnull ""}
    {dts:word,trim,notnull ""}
    {search_package_id:naturalnum ""}
    {scope ""}
    {object_type:token ""}
} -validate {
    keywords_p {
        if {![info exists q] || $q eq ""} {
            ad_complain "#search.lt_You_must_specify_some#"
        }
    }
    valid_dfs -requires dfs {
        if {![array exists symbol2interval]} {
            array set symbol2interval [parameter::get -package_id [ad_conn package_id] -parameter Symbol2Interval]
        }
        if {$dfs ni [array names symbol2interval]} {
            ad_complain "dfs: invalid interval"
        }
    }
    valid_dts -requires dts {
        if {![array exists symbol2interval]} {
            array set symbol2interval [parameter::get -package_id [ad_conn package_id] -parameter Symbol2Interval]
        }
        if {$dts ni [array names symbol2interval]} {
            ad_complain "dts: invalid interval"
        }
    }
    
    csrf { csrf::validate }
}

set page_title "Search Results"

set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set package_url_with_extras $package_url

set context Results
set context_base_url $package_url

# Do we want debugging information at the end of the page
set debug_p 0

set user_id [ad_conn user_id]
set driver [parameter::get -package_id $package_id -parameter FtsEngineDriver]
if {[callback::impl_exists -impl $driver -callback search::driver_info]} {
    array set info [lindex [callback -impl $driver search::driver_info] 0]
#    array set info [list package_key intermedia-driver version 1 automatic_and_queries_p 1  stopwords_p 1]
} else {
    array set info [acs_sc::invoke -contract FtsEngineDriver -operation info -call_args [list] -impl $driver]
}

if { [array get info] eq "" } {
    ns_return 200 text/html [_ search.lt_FtsEngineDriver_not_a]
    ad_script_abort
}

if { $num <= 0} {
    set limit [parameter::get -package_id $package_id -parameter LimitDefault]
} else {
    set limit $num
}


#
# Work out the date restriction 
#
set df ""
set dt ""

if { $dfs eq "all" } {
    set dfs ""
}

if { $dfs ne "" } {
    set df [db_exec_plsql get_df "select now() + '$symbol2interval($dfs)'::interval"]
}
if { $dts ne "" } {
    set dt [db_exec_plsql get_dt "select now() + '$symbol2interval($dts)'::interval"]
}

#set q [string tolower $q]
set urlencoded_query [ad_urlencode $q]

set params [list $q $offset $limit $user_id $df]
if {$search_package_id eq "" && [parameter::get -package_id $package_id -parameter SubsiteSearchP -default 1]
    && [subsite::main_site_id] != [ad_conn subsite_id]} {
    # We are in a subsite and SubsiteSearchP is true
    set subsite_packages [concat [ad_conn subsite_id] [subsite::util::packages -node_id [ad_conn node_id]]]
    lappend params $subsite_packages
    set search_package_id $subsite_packages
} elseif {$search_package_id ne ""} { 
  lappend params $search_package_id
}

set t0 [clock clicks -milliseconds]

# TODO calculate subsite or dotlrn package_ids
if {"this" ne $scope } {
    # don't send package_id if its not searching this package
  # set search_package_id "" ;# don't overwrite this, when you are restricting search to package_id
} else {
    set search_node_id [site_node::get_node_id_from_object_id -object_id $search_package_id]
    if {"dotlrn" eq [site_node::get_element -node_id $search_node_id -element package_key]} {
	set search_package_id [site_node::get_children -node_id $search_node_id -element package_id]
    }
}

if {[callback::impl_exists -impl $driver -callback search::search]} {
    # DAVEB TODO Add subsite to the callback def?
    # FIXME do this in the intermedia driver!
    #    set final_query_string [db_string final_query_select "select site_wide_search.im_convert(:q) from dual"]

    array set result [lindex [callback -impl $driver search::search -query $q -offset $offset -limit $limit \
				  -user_id $user_id -df $df \
				  -extra_args [list package_ids $search_package_id object_type $object_type]] 0]
} else {
    array set result [acs_sc::invoke -contract FtsEngineDriver -operation search \
			  -call_args $params -impl $driver]
}
set tend [clock clicks -milliseconds]

if { $t eq [_ search.Feeling_Lucky] && $result(count) > 0} {
    set object_id [lindex $result(ids) 0]
    set object_type [acs_object_type $object_id]
    if {[callback::impl_exists -impl $object_type -callback search::url]} {
	set url [callback -impl $object_type search::url -object_id $object_id]
    } else {
	set url [acs_sc::invoke -contract FtsContentProvider -operation url \
		     -call_args [list $object_id] -impl $object_type]
    }
    ad_returnredirect $url
    ad_script_abort
}

set elapsed [format "%.02f" [expr {double(abs($tend - $t0)) / 1000.0}]]
#
# $count is the number of results to be displayed, while
# $result(count) is the total number of results (without taking
# permissions into account)
#
set count [llength $result(ids)]
if { $offset >= $result(count) } { set offset [expr {($result(count) / $limit) * $limit}] }
set low  [expr {$offset + 1}]
set high [expr {$offset + $limit}]
if { $high > $result(count) } { set high $result(count) }

if { $info(automatic_and_queries_p) && "and" in $q } {
    set and_queries_notice_p 1
} else {
    set and_queries_notice_p 0
}

set url_advanced_search ""
append url_advanced_search "advanced-search?q=$urlencoded_query"
if {[info exists ::__csrf_token]} {append url_advanced_search "&__csrf_token=$::__csrf_token"}
if { $num > 0 } { append url_advanced_search "&num=$num" }

set query $q
set nquery [llength [split $q]]
set stopwords $result(stopwords)
set nstopwords [llength $result(stopwords)] 

template::multirow create searchresult title_summary txt_summary url_one object_id

foreach object_id $result(ids) {
    if {[catch {
        set object_type [acs_object_type $object_id]
        if {[callback::impl_exists -impl $object_type -callback search::datasource]} {
            array set datasource [lindex [callback -impl $object_type search::datasource -object_id $object_id] 0]
            set url_one [lindex [callback -impl $object_type search::url -object_id $object_id] 0]
        } else {
            #ns_log warning "SEARCH search/www/search.tcl callback::datasource::$object_type not found"
            array set datasource [acs_sc::invoke -contract FtsContentProvider -operation datasource \
				      -call_args [list $object_id] -impl $object_type]
            set url_one [acs_sc::invoke -contract FtsContentProvider -operation url \
			     -call_args [list $object_id] -impl $object_type]
        }
        search::content_get txt $datasource(content) $datasource(mime) $datasource(storage_type) $object_id
        if {[callback::impl_exists -impl $driver -callback search::summary]} {
            set title_summary [lindex [callback -impl $driver search::summary -query $q -text $datasource(title)] 0]
            set txt_summary [lindex [callback -impl $driver search::summary -query $q -text $txt] 0]
        } else {
            set title_summary [acs_sc::invoke -contract FtsEngineDriver -operation summary \
				   -call_args [list $q $datasource(title)] -impl $driver]
            set txt_summary [acs_sc::invoke -contract FtsEngineDriver -operation summary \
				 -call_args [list $q $txt] -impl $driver]
        }
    } errmsg]} {
        ns_log error "search.tcl object_id $object_id object_type $object_type error $errmsg"
    } else {
        template::multirow append searchresult $title_summary $txt_summary $url_one
    }
}

set search_the_web [parameter::get -package_id $package_id -parameter SearchTheWeb]
if {$search_the_web ne ""} {
    set stw ""
    foreach {url site} $search_the_web {
	append stw "<a href=\"[format $url $urlencoded_query]\">$site</a> "
    }
}

# header stuffs
template::head::add_css \
    -href "/resources/search/search.css" \
    -media "all"

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
