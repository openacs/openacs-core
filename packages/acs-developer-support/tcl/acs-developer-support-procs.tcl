# $Id$
# File:        developer-support-procs.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Date:        22 Apr 2000
# Description: Provides routines used to aggregate request/response information for debugging.

ad_proc -private ds_instance_id {} {

    @return The instance of a running acs developer support.

} {
    return [util_memoize [list db_string acs_kernel_id_get {
	select package_id from apm_packages
	where package_key = 'acs-developer-support'
	and rownum=1
    } -default 0]]
}

ad_proc ds_permission_p {} {
    Do we have permission to view developer support stuff.
} {
    return [ad_permission_p -user_id [ds_get_real_user_id] [ds_instance_id] "admin"]
}

ad_proc -public ds_require_permission {
  object_id
  privilege
} {
  set user_id [ds_get_real_user_id]
  if {![ad_permission_p -user_id $user_id $object_id $privilege]} {
    if {$user_id == 0} {
      ad_maybe_redirect_for_registration
    } else {
      ns_log Notice "$user_id doesn't have $privilege on object $object_id"
      ns_write "[ad_header "Security Violation"]
      <h2>Security Violation</h2>
      <hr>
      <blockquote>
      You don't have permission to $privilege [db_string name {select acs_object.name(:object_id) from dual}].
      <p>
      This incident has been logged.
      </blockquote>
      [ad_footer]"
    }
    ad_script_abort
  }
}

ad_proc ds_enabled_p {} { 
    Returns true if developer-support facilities are enabled.
} {
    if { ![nsv_exists ds_properties enabled_p] || ![nsv_get ds_properties enabled_p] } {
	return 0
    }
    return 1
}

ad_proc ds_collection_enabled_p {} {
    Returns whether we're collecting information about this request
} {
    global ad_conn
    if { ![info exists ad_conn(request)] } {
	return 0
    }
    foreach pattern [nsv_get ds_properties enabled_ips] {
	if { [string match $pattern [ad_conn peeraddr]] } {
	    return 1
	}
    }
    return 0
}

ad_proc ds_user_switching_enabled_p {} { 
    Returns whether user-switching is enabled.
} {
    return [nsv_get ds_properties user_switching_enabled_p]
}

ad_proc ds_database_enabled_p {} { 
    Returns true if developer-support database facilities are enabled. 
} {
    return [nsv_get ds_properties database_enabled_p]
}


proc_doc ds_lookup_administrator_p { user_id } { } {
    return 1
}

ad_proc -private ds_support_url {} {

    @return A link to the first instance of the developer-support information available in the site node, \
	    the empty_string if none are available.
} {
    return [util_memoize [list db_string ds_support_url {
	select site_node.url(node_id) 
	from site_nodes s, apm_packages p
	where p.package_id = s.object_id
	and p.package_key ='acs-developer-support'
	and rownum = 1
    } -default ""]]
}

proc_doc ds_link {} { Returns the "Developer Information" link in a right-aligned table, if enabled. } {

    if { ![ds_enabled_p] && ![ds_user_switching_enabled_p] } {
	return ""
    } 

    if { ![ds_permission_p] } {
        return ""
    }
    
    set out "<table align=right cellspacing=0 cellpadding=0>"
    if { [ds_enabled_p] && [ds_collection_enabled_p] } {
	global ad_conn
	
	set ds_url [ds_support_url]
	if {![empty_string_p $ds_url]} {
	    append out "<tr><td align=right>
	    <a href=\"${ds_url}request-info?request=$ad_conn(request)\">Developer Information</a>
	</td></tr>
	"
	} else {
	    ns_log Error "ACS-Developer-Support: Unable to offer link to Developer Support \
		    because it is not mounted anywhere."
	}
	
	if { [nsv_exists ds_request "$ad_conn(request).db"] } {
	    set total 0
	    set counter 0
	    foreach { handle command statement_name sql start end errno error } [nsv_get ds_request "$ad_conn(request).db"] {
		incr total [expr { $end - $start }]
		if { [lsearch { dml exec 1row 0or1row select } [lindex $command 0]] >= 0 } {
		    incr counter
		}
	    }
	    if { $counter > 0 } {
		append out "<tr><td align=right>$counter database command[ad_decode $counter 1 " taking" "s totalling"] [format "%.f" [expr { $total / 1000 }]] ms</td></tr>"
	    }
	}
	
	if { [nsv_exists ds_request "$ad_conn(request).conn"] } {
	    array set conn [nsv_get ds_request "$ad_conn(request).conn"]
	    if { [info exists conn(startclicks)] } {
		append out "<tr><td align=right>page served in
		[format "%.f" [expr { ([clock clicks] - $conn(startclicks)) / 1000 }]] ms</td></tr>\n"
	    }
	}
	
        if { [ad_parameter ShowCommentsInlineP "developer-support" 0] } {
            if { [nsv_exists ds_request "$ad_conn(request).comment"] } {
                append out "<tr><td><br>"
                foreach comment [nsv_get ds_request "$ad_conn(request).comment"] {
                    append out "<b>Comment:</b> $comment<br>\n"
                }
                append out "</td></tr>"
            }
        }
    }
    
    if { [ds_user_switching_enabled_p] } {
	append out "<tr><td align=right>[ds_user_select_widget]</td>"
    }
    
    append out "</table>\n"
    return $out

}

proc_doc ds_collect_connection_info {} { Collects information about the current connection. Should be called only at the very beginning of the request processor handler. } {
    if { [ds_enabled_p] && [ds_collection_enabled_p] } {
        ##This is expensive, but easy.  Otherwise we need to do it in every interpreter
        ds_replace_get_user_procs [ds_user_switching_enabled_p]

	ds_add start [ns_time]
	ds_add conn startclicks [clock clicks]
	for { set i 0 } { $i < [ns_set size [ad_conn headers]] } { incr i } {
	    ds_add headers [ns_set key [ad_conn headers] $i] [ns_set value [ad_conn headers] $i]
	}
	foreach param { method url query request peeraddr } {
	    ds_add conn $param [ad_conn $param]
	}
    }
}    

proc_doc ds_collect_db_call { db command statement_name sql start_time errno error } {
    if { [ds_enabled_p] && [ds_collection_enabled_p] && [ds_database_enabled_p] } {
	ds_add db $db $command $statement_name $sql $start_time [clock clicks] $errno $error
    }
}

proc_doc ds_add { name args } { Sets a developer-support property for the current request. Should never be used except by elements of the request processor (e.g., security filters or abstract URLs). } {
    if { [catch { nsv_exists ds_request . }] } {
	ns_log "Warning" "ds_request NSVs not initialized"
	return
    }

    global ad_conn
    if { ![info exists ad_conn(request)] } {
	set ad_conn(request) [nsv_incr rp_properties request_count]
    }
    eval [concat [list nsv_lappend ds_request "$ad_conn(request).$name"] $args]
}

proc_doc ds_comment { value } { Adds a comment to the developer-support information for the current request. } {
    ds_add comment $value
}

proc ds_sweep_data {} {
    set now [ns_time]
    set lifetime [ad_parameter DataLifetime "developer-support" 900]

    # kill_requests is an array of request numbers to kill
    array set kill_requests [list]

    set names [nsv_array names ds_request]
    foreach name $names {
	if { [regexp {^([0-9]+)\.start$} $name "" request] && \
		$now - [nsv_get ds_request $name] > $lifetime } {
	    set kill_requests($request) 1
	}
    }
    set kill_count 0
    foreach name $names {
	if { [regexp {^([0-9]+)\.} $name "" request] && \
		[info exists kill_requests($request)] } {
	    incr kill_count
	    nsv_unset ds_request $name
	}
    }	

    ns_log "Notice" "Swept developer support information for [array size kill_requests] requests ($kill_count nsv elements)"
}

proc_doc ds_trace_filter { conn args why } { Adds developer-support information about the end of sessions.} {
    if { [ds_enabled_p] && [ds_collection_enabled_p] } {
	ds_add conn end [ns_time] endclicks [clock clicks]

	for { set i 0 } { $i < [ns_set size [ad_conn outputheaders]] } { incr i } {
	    ds_add oheaders [ns_set key [ad_conn outputheaders] $i] [ns_set value [ad_conn outputheaders] $i]
	}

	foreach param { browser_id validated session_id user_id } {
	    global ad_sec_$param
	    if { [info exists ad_sec_$param] } {
		ds_add conn $param [set "ad_sec_$param"]
	    }
	}
    }

    return "filter_ok"
}

ad_proc ds_user_select_widget {}  {
    set user_id [ad_get_user_id]
    set real_user_id [ds_get_real_user_id]

    set return_url [ad_conn url]
    if { ![empty_string_p [ad_conn query]] } {
	append return_url "?[ad_conn query]"
    }

    set you_are {}

    if { $user_id == 0 } {
	set selected " selected"
	set you_are "<small>You are currently <strong>not logged in</strong></small><br>"
	set you_are_really "<small>You are really <strong>not logged in</strong></small><br>"
    } else {
	set selected {}
    }
    set options "<option value=0$selected>--Logged out--</option>"

    db_foreach users { 
	select u.user_id as user_id_from_db, 
	       acs_object.name(user_id) as name, 
	       p.email 
	from   users u, 
	       parties p 
	where  u.user_id = p.party_id 
    } {
	if { $user_id == $user_id_from_db } {
	    set selected " selected"
	    set you_are "<small>You are testing as <strong>$name ($email)</strong></small><br>"
	} else {
	    set selected {}
	}
        if { $real_user_id == $user_id_from_db } {
	    set you_are_really "<small>You are really <strong>$name ($email)</strong></small><br>"
	}
	append options "<option value=$user_id_from_db$selected>$name ($email)</option>"
    }

    set ds_url [ds_support_url]
    if {![empty_string_p $ds_url]} {
	return "<form action=${ds_url}/set-user method=get>
	$you_are
	$you_are_really
	Change user: <select name=user_id>
	$options
	</select>[export_form_vars return_url]<input type=submit value=\"Go\"></form>"
    } else {
	ns_log Error "ACS-Developer-Support: Unable to offer link to Developer Support \
		because it is not mounted anywhere."
	return ""
    }
}

ad_proc -private ds_get_real_user_id {} { 
    Get the "real" user id.
} {
    if { [llength [info proc orig_ad_get_user_id]] == 1 } {
        return [orig_ad_get_user_id]
    } else {
        return [ad_get_user_id]
    }
}

ad_proc ds_get_user_id {{original 0}} {
    Developer support version of ad_get_user_id, used for debugging sites.
} {
    set orig_user_id [ds_get_real_user_id]
    if {($original == 0) && ([ds_user_switching_enabled_p]) && [ds_permission_p]} {
        set ds_user_id [ad_get_client_property -default $orig_user_id developer-support user_id]
        return $ds_user_id
    } else {
        return $orig_user_id
    }
}

ad_proc ds_set_user_switching_enabled { enabled_p } {
    Enables/disables user-switching in a safe manner.

    @author Lars Pind (lars@pinds.com)
    @creation-date 31 August 2000
} {
    ns_log Warning "Developer-support user-switching [ad_decode $enabled_p 1 "enabled" "disabled"]"
    nsv_set ds_properties user_switching_enabled_p $enabled_p
}

ad_proc -private ds_replace_get_user_procs { enabled_p } {
    Replace the ad_get_user procs with our own versions
} {
    if { $enabled_p } {
	if { [llength [info proc orig_ad_get_user_id]] == 0 } {

	    # let the user stay who he is now (but ignore any error trying to do so)
	    catch {
		ad_set_client_property developer-support user_id [ad_get_user_id]
	    }
	    rename ad_get_user_id orig_ad_get_user_id
	    rename ad_verify_and_get_user_id orig_ad_verify_and_get_user_id
	    
	    proc ad_get_user_id {} {
                ds_get_user_id
	    }
	    proc ad_verify_and_get_user_id {} {
                ds_get_user_id
	    }
	}
    } else {
	if { [llength [info proc orig_ad_get_user_id]] == 1 } {
	    rename ad_get_user_id {}
	    rename orig_ad_get_user_id ad_get_user_id

	    rename ad_verify_and_get_user_id {}
	    rename orig_ad_verify_and_get_user_id ad_verify_and_get_user_id
	}
    }
}
