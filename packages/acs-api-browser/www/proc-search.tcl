# acs-api-browser/www/proc-search.tcl

ad_page_contract {
    Searches for procedures with containing query_string
    if lucky redirects to best match
    Weight the different hits with the propper weights

    Shows a list of returned procs with links to proc-view

    Note: api documentation information taken from nsv array

    @author Todd Nightingale (tnight@arsdigita.com)
    @creation-date Jul 14, 2000
    @cvs-id $Id$
} {
    {name_weight:optional 0}
    {doc_weight:optional 0}
    {param_weight:optional 0}
    {source_weight:optional 0}
    {search_type:optional 0}
    {show_deprecated_p 0}
    {show_private_p 0}
    query_string
} -properties {
    title:onevalue
    context:onevalue
    name_weight:onevalue
    doc_weight:onevalue
    param_weight:onevalue
    source_weight:onevalue
    query_string:onevalue
    results:multirow
}

##########################################################
##  Begin Page

set quick_view [string equal $search_type "Only best match"]

#########################
## Optimizes quick search
if {$quick_view && [nsv_exists api_proc_doc $query_string]} {
    ad_returnredirect [api_proc_url $query_string]
    ad_script_abort
}

###########################
# No weighting use default:
if { ($name_weight == 0) && ($doc_weight == 0) && ($param_weight == 0) && ($source_weight ==0) } {
    set name_weight 1
}

# Exact name search
if {$name_weight eq "exact"} {
    set name_weight 5
    set exact_match_p 1
} else {
    set exact_match_p 0
}

set counter 0
set matches [list]
set deprecated_matches [list]
set private_matches [list]

# place a [list proc_name score positionals] into matches for every proc
foreach proc [nsv_array names api_proc_doc] { 

    set score 0
    array set doc_elements [nsv_get api_proc_doc $proc]

    ###############
    ## Name Search:
    ###############
    if {$name_weight} {
        # JCD: this was a little perverse since exact matches were
        # actually worth less than matches in the name (if there were
        # 2 or more, which happens with namespaces) so I doubled the
        # value of an exact match.

        ##Exact match:
        if {[string tolower $query_string] eq [string tolower $proc]} {
            incr score [expr {$name_weight * 2}]
        } elseif { ! $exact_match_p } {
            incr score [expr {$name_weight * [::apidoc::ad_keywords_score $query_string $proc]}] 
        }
    }
   
    ################
    ## Param Search:
    ################
    if {$param_weight} {
        incr score [expr {$param_weight * [::apidoc::ad_keywords_score $query_string "$doc_elements(positionals) $doc_elements(switches)"]}]
    }
    

    ##############
    ## Doc Search:
    ##############
    if {$doc_weight} {
        
        set doc_string [lindex $doc_elements(main) 0]
        if {[info exists doc_elements(param)]} {
            foreach parameter $doc_elements(param) {
                append doc_string " $parameter"
            }
        }
        if {[info exists doc_elements(return)]} {
            append doc_string " $doc_elements(return)"
        }
        incr score [expr {$doc_weight * [::apidoc::ad_keywords_score $query_string $doc_string]}]
        
    }
    
    #################
    ## Source Search:
    #################
    if {$source_weight} {
        if {![catch {set source [info body $proc]}]} {
            incr score [expr {$source_weight * [::apidoc::ad_keywords_score $query_string $source]}] 
        }    
    }

    #####
    ## Place Needed info in matches
    if {$score} {
        if {$doc_elements(varargs_p)} { 
            set args "$doc_elements(positionals) \[&nbsp;args...&nbsp;\]"
        } else { 
            set args $doc_elements(positionals)
        }   
        if { $doc_elements(deprecated_p) } {
            lappend deprecated_matches [list $proc $score $args]
        } else {
            if { $doc_elements(public_p) } { 
                lappend matches [list $proc $score $args]
            } else {
                lappend private_matches [list $proc $score $args]
            }
        }
    }
}

set matches [lsort -command ::apidoc::ad_sort_by_score_proc $matches]

if {$quick_view && $matches ne "" || [llength $matches] == 1 } {
    ad_returnredirect [api_proc_url [lindex $matches 0 0]]
    ad_script_abort
}

set title "Procedure Search for: \"$query_string\""
set context [list "Search: $query_string"]

multirow create results score proc args url

foreach output $matches {
    incr counter
    lassign $output proc score args
    set url [api_proc_url $proc]
    multirow append results $score $proc $args $url
}

multirow create deprecated_results score proc args url

foreach output $deprecated_matches {
    incr counter
    lassign $output proc score args
    set url [api_proc_url $proc]
    multirow append deprecated_results $score $proc $args $url
}

set show_deprecated_url [export_vars -base [ad_conn url] -override { { show_deprecated_p 1 } } { name_weight doc_weight param_weight source_weight search_type query_string show_private_p }]

set hide_deprecated_url [export_vars -base [ad_conn url] -override { { show_deprecated_p 0 } } { name_weight doc_weight param_weight source_weight search_type query_string show_private_p }]


multirow create private_results score proc args url

foreach output $private_matches {
    incr counter
    lassign $output proc score args
    set url [api_proc_url $proc]
    multirow append private_results $score $proc $args $url
}

set show_private_url [export_vars -base [ad_conn url] -override { { show_private_p 1 } } { name_weight doc_weight param_weight source_weight search_type query_string show_deprecated_p }]

set hide_private_url [export_vars -base [ad_conn url] -override { { show_private_p 0 } } { name_weight doc_weight param_weight source_weight search_type query_string show_deprecated_p }]
