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

ad_proc -public ds_permission_p {} {
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
      ad_return_forbidden "Permission Denied" "<blockquote>
      <p>You don't have permission to $privilege [db_string name {select acs_object.name(:object_id) from dual}].</p>
      </blockquote>"
    }
    ad_script_abort
  }
}

ad_proc -public ds_enabled_p {} { 
    Returns true if developer-support facilities are enabled.
} {
    if { ![nsv_exists ds_properties enabled_p] || ![nsv_get ds_properties enabled_p] } {
	return 0
    }
    return 1
}

ad_proc -public ds_collection_enabled_p {} {
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

ad_proc -public ds_user_switching_enabled_p {} { 
    Returns whether user-switching is enabled.
} {
    return [expr {[nsv_exists ds_properties user_switching_enabled_p] &&
                  [nsv_get ds_properties user_switching_enabled_p]}]
}

ad_proc -public ds_database_enabled_p {} { 
    Returns true if developer-support database facilities are enabled. 
} {
    return [nsv_get ds_properties database_enabled_p]
}


ad_proc -public ds_lookup_administrator_p { user_id } { } {
    return 1
}

ad_proc -private ds_support_url {} {

    @return A link to the first instance of the developer-support information available in the site node, \
	    the empty_string if none are available.
} {
    return [apm_package_url_from_key "acs-developer-support"]
}

ad_proc ds_link {} { 
    Returns the "Developer Information" link in a right-aligned table, if enabled. 
} {

    if { ![ds_enabled_p] && ![ds_user_switching_enabled_p] } {
	return ""
    } 

    if { ![ds_permission_p] } {
        return ""
    }
    
    set out "<table align=\"right\" cellspacing=\"0\" cellpadding=\"0\">"
    if { [ds_enabled_p] && [ds_collection_enabled_p] } {
	global ad_conn
	
	set ds_url [ds_support_url]
	if {![empty_string_p $ds_url]} {
	    append out "<tr><td align=\"right\">
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
		append out "<tr><td align=\"right\">$counter database command[ad_decode $counter 1 " taking" "s totalling"] [format "%.f" [expr { $total / 1000 }]] ms</td></tr>"
	    }
	}
	
	if { [nsv_exists ds_request "$ad_conn(request).conn"] } {
	    array set conn [nsv_get ds_request "$ad_conn(request).conn"]
	    if { [info exists conn(startclicks)] } {
		append out "<tr><td align=\"right\">page served in
		[format "%.f" [expr { ([clock clicks] - $conn(startclicks)) / 1000 }]] ms</td></tr>\n"
	    }
	}
	
        if { [ad_parameter -package_id [ds_instance_id] ShowCommentsInlineP acs-developer-support 0] } {
            if { [nsv_exists ds_request "$ad_conn(request).comment"] } {
                append out "<tr><td><br />"
                foreach comment [nsv_get ds_request "$ad_conn(request).comment"] {
                    append out "<b>Comment:</b> $comment<br />\n"
                }
                append out "</td></tr>"
            }
        }
    }
    
    if { [ds_user_switching_enabled_p] } {
	append out "<tr><td align=\"right\">[ds_user_select_widget]</td>"
    }
    
    append out "</table>\n"
    return $out

}

ad_proc -private ds_collect_connection_info {} { 
    Collects information about the current connection. 
    Should be called only at the very beginning of the request processor handler. 
} {
    # JCD: check recursion_count to ensure adding headers only one time.
    if { [ds_enabled_p] && [ds_collection_enabled_p] && ![ad_conn recursion_count]} {
        ##This is expensive, but easy.  Otherwise we need to do it in every interpreter
        ds_replace_get_user_procs [ds_user_switching_enabled_p]

        ds_add start [ns_time]
        ds_add conn startclicks [ad_conn start_clicks]
        for { set i 0 } { $i < [ns_set size [ad_conn headers]] } { incr i } {
            ds_add headers [ns_set key [ad_conn headers] $i] [ns_set value [ad_conn headers] $i]
        }
        foreach param { method url query request peeraddr } {
            ds_add conn $param [ad_conn $param]
        }
    }
}    

ad_proc -private ds_collect_db_call { db command statement_name sql start_time errno error } {
    if { [ds_enabled_p] && [ds_collection_enabled_p] && [ds_database_enabled_p] } {
         set bound_sql $sql

         # It is very useful to be able to see the bind variable values displayed in the
         # ds output. For postgresql we have a way of doing this with the proc db_bind_var_substitution
         # but this proc does not work for Oracle
         if { [string equal [db_type] "postgresql"] } {
             upvar bind bind
             set errno [catch {
             if { [info exists bind] && [llength $bind] != 0 } {
                 if { [llength $bind] == 1 } {
                     set bind_vars [list]
                     set len [ns_set size $bind]
                     for {set i 0} {$i < $len} {incr i} {
                         lappend bind_vars [ns_set key $bind $i] \
                                 [ns_set value $bind $i]
                     }
                     set bound_sql [db_bind_var_substitution $sql $bind_vars]
                 } else {
                     set bound_sql [db_bind_var_substitution $sql $bind]
                 }
             } else {
                 set bound_sql [uplevel 4 [list db_bind_var_substitution $sql]]
             }
            } error]

            if { $errno } {
               ns_log Error "ds_collect_db_call: $error"
            }
         }

       ds_add db $db $command $statement_name $bound_sql $start_time [clock clicks] $errno $error
    }
}

ad_proc -private ds_add { name args } { 
    Sets a developer-support property for the current request. 
    Should never be used except by elements of the request processor (e.g., security filters or abstract URLs). 
} {
    
    if { [ds_enabled_p] && [ds_collection_enabled_p] } { 
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
}

ad_proc -public ds_comment { value } { Adds a comment to the developer-support information for the current request. } {

     if { [ds_enabled_p] } {
         ds_add comment $value
     }
}

ad_proc -private ds_sweep_data {} {
    set now [ns_time]
    set lifetime [ad_parameter -package_id [ds_instance_id] DataLifetime acs-developer-support 900]

    # Find the last request before the DataLifetime cutoff

    set names [nsv_array names ds_request]
    set max_request 0
    foreach name $names {
	if { [regexp {^([0-9]+)\.start$} $name match request] 
             && $now - [lindex [nsv_get ds_request $name] 0] > $lifetime } {
            if {[expr {$request > $max_request}]} { 
                set max_request $request
            }
        }
    }

    # kill any request older than last request.

    set kill_count 0
    foreach name $names {
        if { [regexp {^([0-9]+)\.} $name "" request]
             && [expr {$request <= $max_request}] } {
	    incr kill_count
	    nsv_unset ds_request $name
	}
    }	
    
    ns_log "Notice" "Swept developer support information for [array size kill_requests] requests ($kill_count nsv elements)"
}

ad_proc -private ds_trace_filter { conn args why } { Adds developer-support information about the end of sessions.} {
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

ad_proc -public ds_user_select_widget {}  {
    set user_id [ad_get_user_id]
    set real_user_id [ds_get_real_user_id]

    set return_url [ad_conn url]
    if { ![empty_string_p [ad_conn query]] } {
	append return_url "?[ad_conn query]"
    }

    set you_are {}

    if { $user_id == 0 } {
	set selected " selected"
	set you_are "<small>You are currently <strong>not logged in</strong></small><br />"
	set you_are_really "<small>You are really <strong>not logged in</strong></small><br />"
    } else {
	set selected {}
    }
    set options "<option value=\"0\"$selected>--Logged out--</option>"

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
	    set you_are "<small>You are testing as <strong>$name ($email)</strong></small><br />"
	} else {
	    set selected {}
	}
        if { $real_user_id == $user_id_from_db } {
	    set you_are_really "<small>You are really <strong>$name ($email)</strong></small><br />"
	}
	append options "<option value=\"$user_id_from_db\"$selected>$name ($email)</option>"
    }

    set ds_url [ds_support_url]
    if {![empty_string_p $ds_url]} {
	return "<form action=\"${ds_url}/set-user\" method=\"get\">
	$you_are
	$you_are_really
	Change user: <select name=\"user_id\">
	$options
	</select>[export_form_vars return_url]<input type=submit value=\"Go\" /></form>"
    } else {
	ns_log Error "ACS-Developer-Support: Unable to offer link to Developer Support \
		because it is not mounted anywhere."
	return ""
    }
}

ad_proc -private ds_get_real_user_id {} { 
    Get the "real" user id.
} {
    if { [llength [info proc orig_ad_conn]] == 1 } {
        return [orig_ad_conn user_id]
    } else {
        return [ad_conn user_id]
    }
}

ad_proc -public ds_get_user_id {{original 0}} {
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

ad_proc -public ds_conn { args } {
    Developer support version of ad_conn. Overloads "ad_conn user_id",
    delegates to ad_conn in all other cases.
} {
    if { [lindex $args 0] == "user_id" || 
         ([lindex $args 0] == "-get" && [lindex $args 1] == "user_id") } {
        return [ds_get_user_id]
    } else {
        return [eval "orig_ad_conn [join $args]"]
    }
}

ad_proc -public ds_set_user_switching_enabled { enabled_p } {
    Enables/disables user-switching in a safe manner.

    @author Lars Pind (lars@pinds.com)
    @creation-date 31 August 2000
} {
    ns_log Warning "Developer-support user-switching [ad_decode $enabled_p 1 "enabled" "disabled"]"
    nsv_set ds_properties user_switching_enabled_p $enabled_p
}

ad_proc -public ds_set_database_enabled { enabled_p } {
    Enables/disables database statistics in a safe manner.

    @author Lars Pind (lars@pinds.com)
    @creation-date 31 August 2000
} {
    ns_log Warning "Developer-support database stats [ad_decode $enabled_p 1 "enabled" "disabled"]"
    nsv_set ds_properties database_enabled_p $enabled_p
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
            rename ad_conn orig_ad_conn
	    rename ad_get_user_id orig_ad_get_user_id
	    rename ad_verify_and_get_user_id orig_ad_verify_and_get_user_id
	    
            proc ad_conn { args } {
                eval "ds_conn [join $args]"
            }
	    proc ad_get_user_id {} {
                ds_get_user_id
	    }
	    proc ad_verify_and_get_user_id {} {
                ds_get_user_id
	    }
	}
    } else {
	if { [llength [info proc orig_ad_get_user_id]] == 1 } {
            rename ad_conn {}
            rename orig_ad_conn ad_conn

	    rename ad_get_user_id {}
	    rename orig_ad_get_user_id ad_get_user_id

	    rename ad_verify_and_get_user_id {}
	    rename orig_ad_verify_and_get_user_id ad_verify_and_get_user_id
	}
    }
}
