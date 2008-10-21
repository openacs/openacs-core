set show_p [ds_show_p]

# TODO: Go through request-processor to see what other information should be exposed to developer-support

# TODO: Always show comments inline by default?
set request [ad_conn request]

if { $show_p } {

    set page_fragment_cache_p [ds_page_fragment_cache_enabled_p]

    set ds_url [ds_support_url]

    #set comments_p [ds_comments_p]
    # LARS: Always have comments turned on
    set comments_p 1

    multirow create comments text
    if { $comments_p } {
        foreach comment [ds_get_comments] {
            multirow append comments $comment
        }
    }

    set user_switching_p [ds_user_switching_enabled_p]
    if { $user_switching_p } {

        set fake_user_id [ad_get_user_id]
        set real_user_id [ds_get_real_user_id]

        if { $fake_user_id == 0 } {
            set selected " selected"
            set you_are "<small>You are currently <strong>not logged in</strong></small><br>"
            set you_are_really "<small>You are really <strong>not logged in</strong></small><br>"
        } else {
            set selected {}
        }

        # Default values
        set fake_user_name {Unregistered Visitor}
        set real_user_name {Unregistered Visitor}
        set fake_user_email {}
        set real_user_email {}

        set set_user_url "${ds_url}set-user"
        set export_vars [export_vars -form { { return_url [ad_return_url] } }]

        set unfake_url [export_vars -base $set_user_url { { user_id $real_user_id } { return_url [ad_return_url] } }]

        #Decide what to do based on how many users there are.
        set n_users [util_memoize {db_string select_n_users "select count(user_id) from users" -default "unknown"} 300]

        if { $n_users > 100 } {
            set search_p 1
            set size_restriction "and u.user_id in (:real_user_id, :fake_user_id)"
            #Remap the set_user_url to the users search page
            set target $set_user_url
            set set_user_url /acs-admin/users/search
        } else {
            set search_p 0
            set size_restriction ""
        }

        db_multirow -unclobber -extend { selected_p } users select_users "
            select u.user_id, 
                   pe.first_names || ' ' || pe.last_name as name,
                   pa.email 
            from   users u, 
                   persons pe,
                   parties pa
            where  pa.party_id = u.user_id
            and    pe.person_id = u.user_id
            $size_restriction
            order  by lower(pe.first_names), lower(pe.last_name)
        " {
            if { $fake_user_id == $user_id } {
                set selected_p 1
                set fake_user_name $name
                set fake_user_email $email
            } else {
                set selected_p 0
            }
            if { $real_user_id == $user_id } {
                set real_user_name $name
                set real_user_email $email
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
	    label "Tag"
	}
	num_iterations {
	    label "Iterations"
	}
	total_ms {
	    label "Total time"
	}
	ms_per_iteration {
	    label "Avg. time per iteration"
	}
	size {
	    label "Size"
	}
    }

    multirow create profiling tag num_iterations total_ms ms_per_iteration file_links size

    if {[ns_cache get ds_page_bits "$request:error" errors]} {
        set errcount [llength $errors]
    } else {
        set errcount 0
    }
    if { [info exists ds_profile__total_ms] } {
        foreach tag [lsort [array names ds_profile__iterations]] {
            if {[file exists $tag]} {
                set file_links "<a href=\"${ds_url}send?fname=[ns_urlencode $tag]\" title=\"edit\">e</a>"
                append file_links " <a href=\"${ds_url}send?code=[ns_urlencode $tag]\" title=\"compiled code\">c</a>"
            } else {
                set file_links {}
            }

            if { $page_fragment_cache_p } {
                if { [string match *.adp $tag]} {
                    append file_links " <a href=\"${ds_url}send?output=$request:[ns_urlencode $tag]\" title=\"output\">o</a>"
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

            if {[info exists ds_profile__total_ms($tag)]} {
                set total_ms [lc_numeric [set ds_profile__total_ms($tag)]]
                if {[info exists ds_profile__iterations($tag)]
                    && $ds_profile__iterations($tag) > 0} {
                        set ms_per_iteration [lc_numeric [expr {1.0*$ds_profile__total_ms($tag)/$ds_profile__iterations($tag)}]]
                } else {
                    set ms_per_iteration -
                }
            } else {
                set total_ms -
                set ms_per_iteration -
            }
            multirow append profiling $tag [set ds_profile__iterations($tag)] $total_ms $ms_per_iteration $file_links $size
        }
    }
}
