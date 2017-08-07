# TODO: Go through request-processor to see what other information should be exposed to developer-support

# TODO: Always show comments inline by default?
set request [ad_conn request]

if { [ds_show_p] } {

    set show_p 0

    if {[ns_cache get ds_page_bits "$request:error" errors]} {
        set errcount [llength $errors]
        set show_p 1
    } else {
        set errcount 0
    }

    set page_fragment_cache_p [ds_page_fragment_cache_enabled_p]

    set ds_url [ds_support_url]

    #set comments_p [ds_comments_p]
    # LARS: Always have comments turned on
    set comments_p 1

    multirow create comments text
    if { $comments_p } {
        foreach comment [ds_get_comments] {
            multirow append comments $comment
            set show_p 1
        }
    }

    set user_switching_p [ds_user_switching_enabled_p]
    if { $user_switching_p } {

        set show_p 1
        set fake_user_id [ad_conn user_id]
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
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
