set show_p [ds_show_p]

# TODO: Go through request-processor to see what other information should be exposed to developer-support

# TODO: Always show comments inline by default?

if { $show_p } {

    set ds_url [ds_support_url]

    set comments_p [ds_comments_p]

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
            set you_are "<small>You are currently <strong>not logged in</strong></small><br />"
            set you_are_really "<small>You are really <strong>not logged in</strong></small><br />"
        } else {
            set selected {}
        }

        # Default values
        set fake_user_name {Unregistered Visitor}
        set real_user_name {Unregistered Visitor}
        set fake_user_email {}
        set real_user_email {}

        db_multirow -unclobber -extend { selected_p } users select_users { 
            select u.user_id, 
                   pe.first_names || ' ' || pe.last_name as name,
                   pa.email 
            from   users u, 
                   persons pe,
                   parties pa
            where  pa.party_id = u.user_id
            and    pe.person_id = u.user_id
            order  by lower(pe.first_names), lower(pe.last_name)
        } {
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
        
        set set_user_url "${ds_url}/set-user"
        set export_vars [export_vars -form { { return_url [ad_return_url] } }]

        set unfake_url [export_vars -base $set_user_url { { user_id $real_user_id } { return_url [ad_return_url] } }]
    }

}
