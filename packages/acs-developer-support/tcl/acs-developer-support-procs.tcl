ad_library {

    Provides routines used to aggregate request/response information for debugging.

    @author Jon Salz <jsalz@mit.edu>
    @creation-date 22 Apr 2000
}

 ad_proc -private ds_instance_id {} {

     @return The instance of a running acs developer support.

 } {
     return [util_memoize [list db_string acs_kernel_id_get {} -default 0]]
 }

 ad_proc -public ds_permission_p {} {
     Do we have permission to view developer support stuff.
 } {
     set party_id [ds_ad_conn user_id]
     if {$party_id == 0 || $party_id eq ""} {
         # set up a fake id in order to make user_switching mode work
         # with
         # non logged users, if not it will enter into a infinite loop
         # with
         # ad_conn in any new unknown request (roc)
         set party_id "-99"
     }
     return [permission::permission_p -party_id $party_id -object_id [ds_instance_id] -privilege "admin"]
 }

 ad_proc -public ds_require_permission {
   object_id
   privilege
 } {
     Requires the user identified by ds_add_conn user_id to have the given privilege on
     the given object.
 } {
     set user_id [ds_ad_conn user_id]
     if {![permission::permission_p -party_id $user_id -object_id $object_id -privilege $privilege]} {
     if {$user_id == 0} {
       auth::require_login
     } else {
       ns_log Warning "$user_id doesn't have $privilege on object $object_id"
       ad_return_forbidden "Permission Denied" "<blockquote>
       <p>You don't have permission to $privilege [db_string name {}].</p>
       </blockquote>"
     }
     ad_script_abort
   }
 }

 ad_proc -public ds_enabled_p {} { 
     Returns true if developer-support facilities are enabled.
 } {
     #
     # On busy sites, frequent calls to [ds_enabled_p] leads to huge
     # number of mutex locks for the nsv ds_properties. Therefore,
     # cache its results in a per-thead variable.
     #
     if {[info exists ::ds_enabled_p]} {
         return $::ds_enabled_p
     }
     if { ![nsv_exists ds_properties enabled_p] || ![nsv_get ds_properties enabled_p] } {
         set ::ds_enabled_p 0
     } else {
         set ::ds_enabled_p 1
     }
     return $::ds_enabled_p
 }

 ad_proc -public ds_collection_enabled_p {} {
     Returns whether we're collecting information about this request
 } {
     if { [info exists ::ad_conn(ds_collection_enabled_p)] } {
         return $::ad_conn(ds_collection_enabled_p)
     }
     if { ![info exists ::ad_conn(request)] } {
         return 0
     }
     foreach pattern [nsv_get ds_properties enabled_ips] {
         if { [string match $pattern [ad_conn peeraddr]] } {
             set ::ad_conn(ds_collection_enabled_p) 1
             return 1
         }
     }
     set ::ad_conn(ds_collection_enabled_p) 0
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

 ad_proc -public ds_profiling_enabled_p {} { 
     Returns true if developer-support template profiling facilities are enabled. 
 } {
     return [nsv_get ds_properties profiling_enabled_p]
 }

 ad_proc -public ds_page_fragment_cache_enabled_p {} { o
     Are we populating the page fragment cache?
 } {
     return [nsv_get ds_properties page_fragment_cache_p]
 }

 ad_proc -public ds_adp_reveal_enabled_p {} { 
    Returns true if developer-support adp revealing facilities are enabled. 
 } {
     return [nsv_get ds_properties adp_reveal_enabled_p]
 }

 ad_proc -public ds_adp_box_class {} {
    Return developer support adp box class on/off
} {
     if { [ds_adp_reveal_enabled_p] } {
         return developer-support-adp-box-on
     } else {
         return developer-support-adp-box-off
     }
 }

 ad_proc -public ds_adp_file_class {} {
    Return developer support adp file on/off
} {
     if { [ds_adp_reveal_enabled_p] } {
         return developer-support-adp-file-on
     } else {
         return developer-support-adp-file-off
     }
 }

 ad_proc -public ds_adp_output_class {} {
    Return developer support adp output on/off
} {
     if { [ds_adp_reveal_enabled_p] } {
         return developer-support-adp-output-on
     } else {
         return developer-support-adp-output-off
     }
 }

 ad_proc -public ds_adp_start_box {
     {-stub \$__adp_stub} 
 } {
    Appends adp start box if the show toggle is true
 } {
     template::adp_append_code "if { \[info exists ::ds_show_p\] } {"
     template::adp_append_code "    set __apidoc_path \[string range $stub \[string length \$::acs::rootdir\] end\].adp"
     template::adp_append_code "    set __stub_path \[join \[split $stub /\] \" / \"\]"
     template::adp_append_code "    append __adp_output \"<div class=\\\"\[::ds_adp_box_class\]\\\"><span class=\\\"\[::ds_adp_file_class\]\\\"><a href=\\\"/api-doc/content-page-view?source_p=1&amp;path=\$__apidoc_path\\\" style=\\\"text-decoration: None;\\\">\$__stub_path</a></span><div class=\\\"\[::ds_adp_output_class\]\\\">\""
     template::adp_append_code "}"
 }


 ad_proc -public ds_adp_end_box {
     {-stub \$__adp_stub} 
 } {
    Appends adp end box if the show toggle is true
 } {
     template::adp_append_code "if { \[info exists ::ds_show_p\] } {"
     template::adp_append_code "    append __adp_output \"</div></div><!-- END\n$stub (lvl \[info level\])-->\""
     template::adp_append_code "}"
 }

 ad_proc -public ds_lookup_administrator_p { user_id } { } {
     return 1
 }

 ad_proc -private ds_support_url {} {

     @return A link to the first instance of the developer-support information available in the site node, \
             the empty_string if none are available.
 } {
     return [apm_package_url_from_key acs-developer-support]
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

     set out "<div class='developer-support'>"
     if { [ds_enabled_p] && [ds_collection_enabled_p] } {

         set ds_url [ds_support_url]
         if {$ds_url ne ""} {
             append out [subst {
		 <a href="$ds_url">Developer Support Home</a> -
		 <a href="${ds_url}request-info?request=$::ad_conn(request)">Request Information</a><br>
	     }]
         } else {
             ns_log Error "ACS-Developer-Support: Unable to offer link to Developer Support \
                     because it is not mounted anywhere."
         }

         if { [nsv_exists ds_request $::ad_conn(request).db] } {
             set total 0
             set counter 0
             foreach { handle command statement_name sql start end errno error } [nsv_get ds_request $::ad_conn(request).db] {
                 set total [expr { $total + ($end - $start) }]
                 if { [lindex $command 0] in { dml exec 1row 0or1row select } } {
                     incr counter
                 }
             }
             if { $counter > 0 } {
                 append out "$counter database command[ad_decode $counter 1 " taking" "s totalling"] [format {%.f} $total] ms<br>"
             }
         }

         if { [nsv_exists ds_request $::ad_conn(request).conn] } {
             array set conn [nsv_get ds_request $::ad_conn(request).conn]
             if { [info exists conn(startclicks)] } {
                 set time [format "%.f" [expr { ([clock clicks -microseconds] - $conn(startclicks))/1000.0 }]]
                 append out "Page served in $time ms<br>\n"
             }
         }

         if { [parameter::get -package_id [ds_instance_id] -parameter ShowCommentsInlineP -default 0] } {
	     set href [export_vars -base ${ds_url}comments-toggle { { return_url [ad_return_url] } }]
             append out [subst {
		 Comments: <b>On</b> | <a href="[ns_quotehtml $href]">Off</a><br>
	     }]
             if { [nsv_exists ds_request $::ad_conn(request).comment] } {
                 foreach comment [nsv_get ds_request $::ad_conn(request).comment] {
                     append out "<b>Comment:</b> $comment<br>\n"
                 }
             }
         } else {
	     set href [export_vars -base ${ds_url}comments-toggle { { return_url [ad_return_url] } }]
             append out [subst {
		 Comments: <a href="[ns_quotehtml $href]">On</a> | <b>Off</b><br>
	     }]
         }
     }

     if { [ds_user_switching_enabled_p] } {
         append out [ds_user_select_widget] "<br>"
     }

     return $out

 }

 ad_proc ds_show_p {} { 
     Should we show developer-support on the current connection.
 } {
     if { [ds_enabled_p] && [ds_permission_p] } {
         return 1
     }
     return 0
 }

 ad_proc -public ds_get_page_serve_time_ms {} {
     Returns the number of miliseconds passed since this request thread was started.

     Returns the empty string if this information is not available.
 } {
     set result {}
     if { [ds_enabled_p] && [ds_collection_enabled_p] } {
         if { [nsv_exists ds_request $::ad_conn(request).conn] } {
             array set conn [nsv_get ds_request $::ad_conn(request).conn]
             if { [info exists conn(startclicks)] } {
                 set result [format "%.f" [expr { ([clock clicks -microseconds] - $conn(startclicks))/1000.0 }]]
             }
         }
     }
     return $result
 }

 ad_proc -public ds_get_db_command_info {} {
     Get a Tcl list with { num_commands total_ms } for the database commands for the request.

     @return list containing num_commands and total_ms, or empty string if the information is not available.
 } { 
     set result {}
     if { [ds_enabled_p] && [ds_collection_enabled_p] } {
         if { [nsv_exists ds_request $::ad_conn(request).db] } {
             set total 0
             set counter 0
             foreach { handle command statement_name sql start end errno error } [nsv_get ds_request $::ad_conn(request).db] {
                 set total [expr { $total + ($end - $start) }]
                 if { [lindex $command 0] in { dml exec 1row 0or1row select } } {
                     incr counter
                 }
             }
             set result [list $counter $total]
         }
     }
     return $result
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

         # JCD: don't bind if there was an error since this can potentially mess up the traceback 
         # making bugs much harder to track down 
         if { ($errno == 0 || $errno == 2) && [db_type] eq "postgresql" } {
             upvar bind bind
             set _errno [catch {
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
                     set bound_sql [uplevel 3 [list db_bind_var_substitution $sql]]
                 }
             } _error]
             if { $_errno } {
                 ns_log Warning "ds_collect_db_call: $_error\nStatement: $statement_name\nSQL: $sql"
                 set bound_sql $sql
             }
         }

         ds_add db $db $command $statement_name $bound_sql $start_time [expr {[clock clicks -microseconds]/1000.0}] $errno $error
     }
 }

 ad_proc -private ds_add { name args } { 
     Sets a developer-support property for the current request. 
 } {
     if { [ds_enabled_p] && [ds_collection_enabled_p] } {
         if { [catch { nsv_exists ds_request . }] } {
             ns_log "Warning" "ds_request NSVs not initialized"
             return
         }

         if { ![info exists ::ad_conn(request)] } {
             set ::ad_conn(request) [nsv_incr rp_properties request_count]
         }
         nsv_lappend ds_request $::ad_conn(request).$name {*}$args
     }
 }

 ad_proc -public ds_comment { value } { Adds a comment to the developer-support information for the current request. } {

      if { [ds_enabled_p] } {
          ds_add comment $value
      }
 }

 ad_proc -private ds_sweep_data {} {
     set now [ns_time]
     set lifetime [parameter::get -package_id [ds_instance_id] -parameter DataLifetime -default 900]

     # Find the last request before the DataLifetime cutoff

     set names [nsv_array names ds_request]
     set max_request 0
     foreach name $names {
         if { [regexp {^([0-9]+)\.start$} $name match request] 
              && $now - [lindex [nsv_get ds_request $name] 0] > $lifetime } {
             if {$request > $max_request} { 
                 set max_request $request
             }
         }
     }

     # kill any request older than last request.

     set kill_count 0
     foreach name $names {
         if { [regexp {^([0-9]+)\.} $name "" request]
              && $request <= $max_request
          } {
             incr kill_count
             nsv_unset ds_request $name
         }
     }	

     ns_log "Debug" "Swept developer support information for [array size kill_requests] requests ($kill_count nsv elements)"
 }

 ad_proc -private ds_trace_filter { conn args why } { Adds developer-support information about the end of sessions.} {
     if { [ds_enabled_p] && [ds_collection_enabled_p] } {
         ds_add conn end [ns_time] endclicks [clock clicks -microseconds]

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

 ad_proc -public ds_user_select_widget {} {
     Build a select widget for all users in the system, for quick user switching.  Very
     expensive (returns a big file) for OpenACS instances with a large number of users,
     so perhaps best used on test instances.
 } {
     set user_id [ad_conn user_id]
     set real_user_id [ds_get_real_user_id]

     set return_url [ad_conn url]
     set query [ad_conn query]
     if { $query ne "" } {
         append return_url "?$query"
     }

     set you_are {}

     if { $user_id == 0 } {
         set selected " selected"
         set you_are "<small>You are currently <strong>not logged in</strong></small><br>"
         set you_are_really "<small>You are really <strong>not logged in</strong></small><br>"
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
         order by name
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
         append options "<option value=\"$user_id_from_db\"$selected>$name ($email)</option>"
     }

     set ds_url [ds_support_url]
     if {$ds_url ne ""} {
         return [subst {
	     <form action="${ds_url}set-user" method="get">
	     $you_are
	     $you_are_really
	     Change user: <select name="user_id">
	     $options
	     </select>[export_vars -form {return_url}]
	     <input type="submit" value="Go"></form>
	 }]
     } else {
         ns_log Error "ACS-Developer-Support: Unable to offer link to Developer Support \
                 because it is not mounted anywhere."
         return ""
     }
 }

 ad_proc -private ds_get_real_user_id {} { 
     Get the "real" user id.
 } {
     return [ds_ad_conn user_id]
 }

 ad_proc -private ds_ad_conn { args } { 
     Get the "real" user id.
 } {
     if {[info commands orig_ad_conn] ne ""} {
       return [orig_ad_conn {*}$args]
     } else {
       return [ad_conn {*}$args]
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
    foreach elm { user_id untrusted_user_id } {
        if { [lindex $args 0] eq $elm || 
             ([lindex $args 0] eq "-get" && [lindex $args 1] eq $elm) } {
            return [ds_get_user_id]
        }
    }
    return [orig_ad_conn {*}$args]
}

ad_proc -public ds_set_user_switching_enabled { enabled_p } {
    Enables/disables user-switching in a safe manner.

    @author Lars Pind (lars@pinds.com)
    @creation-date 31 August 2000
} {
    ns_log Notice "Developer-support user-switching [ad_decode $enabled_p 1 enabled disabled]"
    nsv_set ds_properties user_switching_enabled_p $enabled_p
}

ad_proc -public ds_set_profiling_enabled { enabled_p } {
    Enables/disables profiling statistics in a safe manner.

    @author Lars Pind (lars@pinds.com)
    @creation-date 31 August 2000
} {
    ns_log Notice "Developer-support profiling stats [ad_decode $enabled_p 1 "enabled" "disabled"]"
    nsv_set ds_properties profiling_enabled_p $enabled_p
}

ad_proc -public ds_set_database_enabled { enabled_p } {
    Enables/disables database statistics in a safe manner.

    @author Lars Pind (lars@pinds.com)
    @creation-date 31 August 2000
} {
    ns_log Notice "Developer-support database stats [ad_decode $enabled_p 1 "enabled" "disabled"]"
    nsv_set ds_properties database_enabled_p $enabled_p
}

ad_proc -public ds_set_adp_reveal_enabled { enabled_p } {
    Enables/disables database statistics in a safe manner.

    @author Lars Pind (lars@pinds.com)
    @creation-date 31 August 2000
} {
    ns_log Notice "Developer-support adp reveal stats [ad_decode $enabled_p 1 "enabled" "disabled"]"
    nsv_set ds_properties adp_reveal_enabled_p $enabled_p
}

ad_proc -private ds_replace_get_user_procs { enabled_p } {
    Replace the ad_get_user procs with our own versions
} {
    if { $enabled_p } {
	if { [info commands orig_ad_conn] eq ""} {
            #ds_comment "Enabling user-switching"
            # let the user stay who he is now (but ignore any error trying to do so)
	    catch {
		ad_set_client_property developer-support user_id [ad_conn user_id]
	    }
            rename ad_conn orig_ad_conn
            proc ad_conn { args } {
	        ds_conn {*}$args
            }
	}
    } else {
        #ds_comment "Disabling user-switching"
	if { [info commands orig_ad_conn] ne ""} {
            rename ad_conn {}
            rename orig_ad_conn ad_conn
	}
    }
}

ad_proc -private ds_watch_packages {} {
    Watch Tcl libraries and xql files for packages listed
    in the PackageWatchList parameter on server startup.

    @author Peter Marklund
} {
    set package_watch_string [parameter::get_from_package_key \
                                  -package_key acs-developer-support \
                                  -parameter PackageWatchList]

    foreach package_key [split $package_watch_string] {
        if { [apm_package_enabled_p $package_key] } {
            ns_log Notice "Developer-support - watching all files for package $package_key"
            apm_watch_all_files $package_key        
        } else {
            ns_log Notice "developer support - not watching file for package $package_key as package is not enabled"
        }
    }
}

ad_proc -public ds_comments_p {} {
    Should we show comments inline on the page?
} {
    return [parameter::get -package_id [ds_instance_id] -parameter ShowCommentsInlineP -default 0]
}

ad_proc -public ds_get_comments {} {
    Get comments for the current request
} {
    set comments [list]
    if { [nsv_exists ds_request $::ad_conn(request).comment] } {
        set comments [nsv_get ds_request $::ad_conn(request).comment]
    }
    return $comments
}

ad_proc -public ds_profile { command {tag {}} } {
    Helper proc for performance profiling of templates. 

    This will record the total time spent within an invocation of a template (computed as
    time between the 'ds_profile start' and 'ds_profile stop' invocations inserted by the
    template engine).

    @param command Must be "start" or "stop".
    @param tag In practice, the path to the template being profiled.
    
    <ul>
      <li><b>start</b> marks the beginning of a block.
      <li><b>stop</b> marks the end of a block. Start and stops must match.
    </ul>
    
} {
    if {![ds_enabled_p]} { 
        error "DS not enabled"
    }
    switch $command {
        start {
            if { $tag eq "" } {
                error "Tag parameter is required"
            }
            set ::ds_profile__start_clock($tag) [clock clicks -microseconds]
        }
        stop {
            if { [info exists ::ds_profile__start_clock($tag)] 
                 && $::ds_profile__start_clock($tag) ne "" } {
                ds_add prof $tag \
                    [expr {[clock clicks -microseconds] - $::ds_profile__start_clock($tag)}]
                unset ::ds_profile__start_clock($tag)
            } else {
                ns_log Warning "ds_profile stop called without a corresponding call to ds_profile start, with tag $tag"
            }
        }
        default {
            error "Invalid command. Valid commands are 'start', 'stop', and 'log'."
        }
    }
}

ad_proc -public ds_init { } {

    Perform setup for the developer support for a single request.  We
    save the state in global variables to avoid highly redundant
    computations (up to 50 times per page on openacs.org)

} {
    #ns_log notice "ds_init called [::ds_enabled_p]"

    if {[::ds_enabled_p] } {
	#
	# Save current setup for developer support in global
	# variables, which are deleted automatically after every
	# request.
	#
	if {[::ds_collection_enabled_p] } {set ::ds_collection_enabled_p 1}
	if {[::ds_profiling_enabled_p] } {set ::ds_profiling_enabled_p 1}
	if {[::ds_show_p]} {set ::ds_show_p 1}
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
