# $Id$
# File:        request-info.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Displays information about a page request.
# Inputs:      request

ad_page_contract {
} {
    request
    {rp_show_debug_p 0}
    {getrow_p:boolean "f"}
}

ds_require_permission [ad_conn package_id] "admin"

set page_title "Request Information"
set context [list $page_title]

set page_fragment_cache_p [ds_page_fragment_cache_enabled_p]

foreach name [nsv_array names ds_request] {
    ns_log Debug "DS: Checking request $request, $name."
    if { [regexp {^([0-9]+)\.([a-z]+)$} $name "" m_request key] && $m_request == $request } {
	set property($key) [nsv_get ds_request $name]
    }
}

if { [info exists property(start)] } {
    set expired_p 0
    append body "
<h3>Parameters</h3>

<blockquote>
<table cellspacing=0 cellpadding=0>
<tr><th align=left>Request Start Time:&nbsp;</th><td>[clock format [lindex $property(start) 0] -format "%Y-%m-%d %H:%M:%S"]\n"
} else {
    set expired_p 1
    append body "The information for this request is gone - either the server has been restarted, or
the request is more than [parameter::get -parameter DeveloperSupportLifetime -default 900] seconds old.
[ad_admin_footer]"
    return
}


if { [info exists property(conn)] } {
    array set conn $property(conn)

    foreach { key name } {
        end {Request Completion Time}
	endclicks {Request Duration}
        peeraddr IP
	method Method
	url URL
	query Query
        user_id {User ID}
        session_id {Session ID}
        browser_id {Browser ID}
        validated {Session Validation}
	error {Error}
    } {
	if { [info exists conn($key)] } {
	    switch $key {
		error {
		    set value "<pre>[ns_quotehtml $conn($key)]</pre>"
		}
		endclicks {
		    set value "[format "%.f" [expr { ($conn(endclicks) - $conn(startclicks)) }]] ms"
		}
		end {
		    set value [clock format $conn($key) -format "%Y-%m-%d %H:%M:%S"  ]
		}
		user_id {
		    if { [db_0or1row user_info "
                        select first_names, last_name, email
                        from users
                        where user_id = $conn(user_id)
		    "] } {
			set value "
<a href=\"/shared/community-member?user_id=$conn(user_id)\">$conn(user_id)</a>:
$first_names $last_name (<a href=\"mailto:$email\">mailto:$email</a>)
"
		    } else {
			set value $conn(user_id)
		    }
		}
		default {
		    set value [ns_quotehtml $conn($key)]
		}
	    }

	    append body "<tr valign=top><th align=left nowrap>$name:&nbsp;</th><td>[ad_decode $value "" "(empty)" $value]</td></tr>\n"
	}
    }
}

append body "</table></blockquote>"

if { [info exists property(rp)] } {
    append body "
<h3>Request Processor</h3>
<ul>
"
    foreach rp $property(rp) {
	set kind [lindex $rp 0]
	set info [lindex $rp 1]
	set startclicks [lindex $rp 2]
	set endclicks [lindex $rp 3]
	set action [lindex $rp 4]
	set error [lindex $rp 5]

	set duration "[format "%.1f" [expr { ($endclicks - $startclicks) }]] ms"

	if { [string equal $kind debug] && !$rp_show_debug_p } {
	    continue
	}

	if { [info exists conn(startclicks)] } {
	    append body "<li>[format "%+06.1f" [expr { ($startclicks - $conn(startclicks)) }]] ms: "
	} else {
	    append body "<li>"
	}

	switch $kind {
	    transformation {
                set proc [lindex $info 0]
                set from [lindex $info 1]
                set to [lindex $info 2]
#		unlist $info proc from to
		if { [empty_string_p $to] } {
		    set to "?"
		}
		append body "Applied transformation from <b>$from -> $to</b> - $duration\n"
	    }
	    filter {
		set kind [lindex $info 1]
		set method [lindex $info 2]
		set path [lindex $info 3]
		set proc [lindex $info 4]
		set args [lindex $info 5]

		append body "Applied $kind filter: <b>$proc</b> [ns_quotehtml $args] (for $method $path) - $duration\n"
		if { [string equal $action "error"] } {
		    append body "<ul><li>returned error: <pre>[ns_quotehtml $error]</pre></ul>\n"
		} elseif { ![empty_string_p $action] } {
		    append body "<ul><li>returned $action</ul>\n"
		}
	    }
	    registered_proc {
		set proc [lindex $info 2]
		set args [lindex $info 3]
		append body "Called registered procedure: <b>$proc</b> [ns_quotehtml $args] for ($method $path) - $duration\n"
		if { [string equal $action "error"] } {
		    append body "<ul><li>returned error: <pre>[ns_quotehtml $error]</pre></ul>\n"
		}
	    }
	    serve_file {
		set file [lindex $info 0]
		set handler [lindex $info 1]
		append body "Served file <b>$file</b> with <b>$handler</b> - $duration\n"
		if { [string equal $action "error"] } {
		    append body "<ul><li>returned error: <pre>[ns_quotehtml $error]</pre></ul>\n"
		}
	    }
            notice {
		append body "$info\n"
            }
	    debug {
		append body "<i>$info</i>\n"
	    }
	}
    }
    if { !$rp_show_debug_p } {
	append body "<p><a href=\"request-info?[export_ns_set_vars url]&rp_show_debug_p=1\">show RP debugging information</a>"
    }
    append body "</ul>\n"
}

if { [info exists property(comment)] } {
    append body "<h3>Comments</h3><ul>\n"
    foreach comment $property(comment) {
	append body "<li>$comment\n"
    }
    append body "</ul>\n"
}

if { [info exists property(headers)] } {
    append body "<h3>Headers</h3>
<blockquote><table cellspacing=0 cellpadding=0>\n"
    foreach { name value } $property(headers) {
	append body "<tr valign=top><th align=left>$name:&nbsp;</td><td>[ns_quotehtml $value]</td></tr>\n"
    }
    append body "</table></blockquote>\n"
}

if { [info exists property(oheaders)] } {
    append body "<h3>Output Headers</h3>
<blockquote><table cellspacing=0 cellpadding=0>\n"
    foreach { name value } $property(oheaders) {
	append body "<tr valign=top><th align=left>$name:&nbsp;</td><td>[ns_quotehtml $value]</td></tr>\n"
    }
    append body "</table></blockquote>\n"
}

multirow create dbreqs handle command sql duration_ms value

if { ![info exists property(db)] } {
    template::list::create \
        -name dbreqs \
        -elements { }
} else {

    foreach { handle command statement_name sql start end errno return } $property(db) {

	if { ![empty_string_p $handle] && [info exists pool($handle)] } {
	    set statement_pool $pool($handle)
	} else {
	    set statement_pool ""
	}
        
	if { $command == "gethandle" } {
	    # Remember which handle was acquired from which pool.
	    set statement_pool $sql
	    set value "gethandle (returned $return)"
	    set pool($return) $sql
	} elseif { $command == "releasehandle" } {
	    set value "releasehandle $handle"
	} else {
	    if { [empty_string_p $statement_name] } {
		set value ""
	    } else {
		set value "$statement_name: "
	    }
            
            # Remove extra whitespace before query
            set min_whitespace -1
            foreach line [split $sql \n] {
                set len [string length $line]
                set trimleft_len [string length [string trimleft $line]]
                if { $trimleft_len > 0 } {
                    set whitespace [expr $len - $trimleft_len]
                    if { $min_whitespace == -1 || $whitespace < $min_whitespace } {
                        set min_whitespace $whitespace
                    }
                }
            }
            
            if { $min_whitespace > 0 } {
                set new_sql {}
                foreach line [split $sql \n] {
                    append new_sql [string range $line $min_whitespace end] \n
                }
                set sql $new_sql
            }

	    append value "$command $statement_pool $handle<pre>[ns_quotehtml $sql]</pre>"
	}

        if { ![string equal $command "getrow"] || [template::util::is_true $getrow_p] } {
            multirow append dbreqs $handle $command $sql [expr { $end - $start }] $value
        }

    }

    multirow sort dbreqs -integer -decreasing duration_ms

    template::list::create \
        -name dbreqs \
        -sub_class narrow \
        -elements {
            duration_ms {
                label "Duration"
                html { align right }
                display_template {@dbreqs.duration_ms@ ms}
                aggregate sum
            }
            command {
                label "Command"
            }
            sql {
                label "SQL"
                aggregate_label "Total Duration (ms)"
                display_template {@dbreqs.value;noquote@}
            }
        } -filters {
            getrow_p {
                label "Getrow"
                values {
                    {"Include" t}
                    {"Exclude" f}
                }
                default_value t
            }
            request {
                hide_p t
            }
        }
            
}

# Profiling information
global ds_profile__total_ms ds_profile__iterations

template::list::create -name profiling -multirow profiling -elements {
	file_links {
	    label "Ops"
	    display_template {
		@profiling.file_links;noquote@
	    }
	}
	tag {
	    label "Template"
	}
	total_ms {
	    label "Total time"
	}
	size {
	    label "Size"
	}
}

multirow create profiling tag total_ms file_links size

if { [info exists property(prof)] } {
    foreach {tag time} $property(prof) {
        if {[file exists $tag]} {
            set file_links "<a href=\"send?fname=[ns_urlencode $tag]\" title=\"edit\">e</a>"
            append file_links " <a href=\"send?code=[ns_urlencode $tag]\" title=\"compiled code\">c</a>"
        } else {
            set file_links {}
        }

        if { $page_fragment_cache_p } {
            if { [string match *.adp $tag]} {
                append file_links " <a href=\"send?output=$request:[ns_urlencode $tag]\" title=\"output\">o</a>"
                if {[ns_cache get ds_page_bits "$request:$tag" dummy]} {
                    set size [string length $dummy]
                } else {
                    set size {?}
                }
            } else {
                append file_links " x"
                set size -
            }
        } else { 
            set size {}
        }

        set total_ms [lc_numeric $time]
        multirow append profiling $tag $total_ms $file_links $size
    }
}
