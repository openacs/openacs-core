# acs-api-browser/www/proc-browse.tcl
ad_page_contract {
    returns a list of all the procedures present 
    in server memory

    @author Todd Nightingale
    @creation-date 2000-7-14
    @cvs-id $Id$

} {
    { type "Public" }
    { sort_by "file"} 
} -properties {
    title:onevalue
    context:onevalue
    dimensional_slider:onevalue
    proc_list:multirow
}

set dimensional {
    {type "Type" "Public" {
	{All "All" ""}
	{Public "Public" ""}
	{Private "Private" ""}
	{Deprecated "Deprecated" ""}
}   }   
    {sort_by "Sorted By" "file" {
        {file "File" ""}
        {name "Name" ""}
}   }   
}

set title "$type Procedures"
set context [list "Browse Procedures"]
set dimensional_slider [ad_dimensional $dimensional]

set matches [list]
foreach proc [nsv_array names api_proc_doc] {
    array set doc_elements [nsv_get api_proc_doc $proc]

    if { $type eq "All"} {
	lappend matches [list $proc $doc_elements(script)] 
    } elseif {$type eq "Deprecated" && $doc_elements(deprecated_p)} {
	lappend matches [list $proc $doc_elements(script)] 
    } elseif {$type eq "Private" && $doc_elements(private_p) } {
	lappend matches [list $proc $doc_elements(script)] 
    } elseif {$type eq "Public" && $doc_elements(public_p) } {
	lappend matches [list $proc $doc_elements(script)] 
    } 
}

if {$sort_by eq "file"} {
    set matches [lsort -command ad_sort_by_second_string_proc $matches]    
} else {
    set matches [lsort -command ad_sort_by_first_string_proc $matches]
}

multirow create proc_list file proc url

foreach sublist $matches {
    set proc [lindex $sublist 0]
    set file [lindex $sublist 1]
    set url [api_proc_url $proc]
    multirow append proc_list $file $proc $url
}

