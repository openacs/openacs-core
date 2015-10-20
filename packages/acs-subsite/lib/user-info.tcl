#
# Expects: 
#  user_id:naturalnum,optional
#  return_url:optional
#  edit_p:optional
#  message:optional
#  show_groups_p:optional

auth::require_login -account_status closed

if { (![info exists user_id] || $user_id eq "") } {
    set user_id [ad_conn untrusted_user_id]
} elseif { $user_id != [auth::get_user_id -account_status closed] } {
    permission::require_permission -object_id $user_id -privilege admin
}

if { (![info exists return_url] || $return_url eq "") } {
    set return_url [ad_conn url]
}

if { (![info exists show_groups_p] || $show_groups_p eq "") } {
    set show_groups_p 0
}

set action_url "[subsite::get_element -element url]user/basic-info-update"

acs_user::get -user_id $user_id -array user -include_bio

set authority_name [auth::authority::get_element -authority_id $user(authority_id) -element pretty_name]

set form_elms { authority_id username first_names last_name email screen_name url bio }
foreach elm $form_elms {
    set elm_mode($elm) {}
}
set read_only_elements [auth::sync::get_sync_elements -authority_id $user(authority_id)]
set read_only_notice_p [expr {[llength $read_only_elements] > 0}]
if { ![acs_user::site_wide_admin_p] } {
    lappend read_only_elements authority_id username
}
foreach elm $read_only_elements {
    set elm_mode($elm) {display}
}

set edit_mode_p [expr {[form::get_action user_info] ne ""}]

set form_mode display
if { [info exists edit_p] && $edit_p eq "1" } {
    set form_mode edit
}

ad_form -name user_info -cancel_url $return_url -action $action_url -mode $form_mode -form {
    {user_id:integer(hidden),optional}
    {return_url:text(hidden),optional}
    {message:text(hidden),optional}
}

# Fill the form elements list
set elms_list [list]

if { [llength [auth::authority::get_authority_options]] > 1 } {
    lappend elms_list {
        authority_id:text(select)
        {mode $elm_mode(authority_id)}
        {label "[_ acs-subsite.Authority]"}
        {options {[auth::authority::get_authority_options]}}
    }
} else {
    lappend read_only_elements authority_id
}

if { $user(authority_id) != [auth::authority::local]
     || ![auth::UseEmailForLoginP]
     || ([acs_user::site_wide_admin_p] && [llength [auth::authority::get_authority_options]] > 1)
 } {
    lappend elms_list {
        username:text(text)
        {label "[_ acs-subsite.Username]"}
        {mode $elm_mode(username)}
    }
} else {
    lappend read_only_elements username
}

# TODO: Use get_registration_form_elements, or auto-generate the form somehow? Deferred.

lappend elms_list {
    first_names:text
    {label "[_ acs-subsite.First_names]"}
    {html {size 50}}
    {mode $elm_mode(first_names)}
} {
    last_name:text
    {label "[_ acs-subsite.Last_name]"}
    {html {size 50}}
    {mode $elm_mode(last_name)}
} {
    email:text
    {label "[_ acs-subsite.Email]"}
    {html {size 50}}
    {mode $elm_mode(email)}
}

if { [acs_user::ScreenName] ne "none" } {
    lappend elms_list [list screen_name:text[ad_decode [acs_user::ScreenName] "solicit" ",optional" ""] \
                           {label "[_ acs-subsite.Screen_name]"} \
                           {html {size 50}} \
                           {mode $elm_mode(screen_name)} \
                          ]
}

lappend elms_list {
    url:text,optional
    {label "[_ acs-subsite.Home_page]"}
    {html {size 50}}
    {mode $elm_mode(url)}
} {
    bio:text(textarea),optional
    {label "[_ acs-subsite.Biography]"}
    {html {rows 8 cols 60}}
    {mode $elm_mode(bio)}
    {display_value {[ad_text_to_html -- $user(bio)]}}
}

set locale_options [list]
db_foreach get_locales {} {
    if { [lang::message::message_exists_p $locale acs-lang.this-language] } {
        set label "[lang::message::lookup $locale  acs-lang.this-language]"
    }
    lappend locale_options [list ${label} $locale]
}

if { [llength $locale_options] > 1 } {
    lappend elms_list {
        site_wide_locale:text(select_locales),optional
        {label "[_ acs-lang.Your_Preferred_Locale]"}
        {options $locale_options}
    }
}

lappend elms_list [list \
                       timezone:text(select),optional \
                       {label "[_ acs-lang.Your_timezone]"} \
                       [list options [db_list_of_lists get_timezones {}]]]

# Setting focus on the first editable element of the form
set first_element {}
foreach elm $form_elms {
    if { $elm_mode($elm) eq "" && ( [lsearch $read_only_elements $elm] eq -1) } {
        set first_element $elm
        break
    }
}
set focus "user_info.$first_element"

# 
ad_form -extend -name user_info -form $elms_list -on_request {
    foreach var { authority_id first_names last_name email username screen_name url bio } {
        set $var $user($var)
    }

    set site_wide_locale [ad_conn locale]

    set timezone [lang::user::timezone]
    if { $timezone eq "" } {
        set timezone [lang::system::timezone]
    }

} -on_submit {

    # Makes the email an image or text according to the level of privacy
    catch {email_image::edit_email_image -user_id $user_id -new_email $email} errmsg

    set user_info(authority_id) $user(authority_id)
    set user_info(username) $user(username)
    foreach elm $form_elms {
        if { $elm_mode($elm) eq "" && [info exists $elm] } {
            set user_info($elm) [string trim [set $elm]]
        }
    }

    array set result [auth::update_local_account \
                          -authority_id $user(authority_id) \
                          -username $user(username) \
                          -array user_info]


    # Handle authentication problems
    switch $result(update_status) {
        ok {
            # Updating locale/tz data
            if { [info exists site_wide_locale] } {
                lang::user::set_locale $site_wide_locale
            }
            lang::user::set_timezone $timezone
        }
        default {
            # Adding the error to the first element, but only if there are no element messages
            if { [llength $result(element_messages)] == 0 } {
                form set_error user_info $first_element $result(update_message)
            }
                
            # Element messages
            foreach { elm_name elm_error } $result(element_messages) {
                form set_error user_info $elm_name $elm_error
            }
            break
        }
    }
 
} -after_submit {
    if {[ad_conn account_status] eq "closed"} {
        auth::verify_account_status
    }
    
    ad_returnredirect $return_url
    ad_script_abort
}

# LARS HACK: Make the URL and email elements real links
if { ![form is_valid user_info] } {
    element set_properties user_info email -display_value "<a href=\"mailto:[element get_value user_info email]\">[element get_value user_info email]</a>"
    if {![string match -nocase "http://*" [element get_value user_info url]]} {
	element set_properties user_info url -display_value \
		"<a href=\"http://[element get_value user_info url]\">[element get_value user_info url]</a>"
    } else {
	element set_properties user_info url -display_value \
		"<a href=\"[element get_value user_info url]\">[element get_value user_info url]</a>"
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
