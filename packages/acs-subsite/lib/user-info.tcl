#
# Expects: 
#  user_id:optional
# return_url:optional
#

ad_maybe_redirect_for_registration

if { ![exists_and_not_null user_id] } {
    set user_id [ad_conn user_id]
} else {
    permission::require_permission -object_id $user_id -privilege admin
}

if { ![exists_and_not_null return_url] } {
    set return_url [ad_conn url]
}

set action_url "[subsite::get_element -element url]user/basic-info-update"

acs_user::get -array user -include_bio

ad_form -name user_info -cancel_url $return_url -action $action_url -mode display -form {
    {return_url:text(hidden),optional {value $return_url}}
}

if { ![auth::UseEmailForLoginP] } {
    ad_form -extend -name user_info -form {
        {username:text(inform)
            {label "Username"}
        }
    }
}

ad_form -extend -name user_info -form {
    {first_names:text
        {label "First names"}
        {html {size 50}}
    }
    {last_name:text
        {label "Last Name"}
        {html {size 50}}
    }
    {email:text
        {label "Email"}
        {html {size 50}}
    }
    {screen_name:text,optional
        {label "Screen name"}
        {html {size 50}}
    }
    {url:text,optional
        {label "Home Page"}
        {html {size 50}}
    }
    {bio:text(textarea),optional
        {label "About yourself"}
        {html {rows 8 cols 60}}
    }
} -on_request {
    foreach var { first_names last_name email username screen_name url bio } {
        set $var $user($var)
    }
} -on_submit {
    db_transaction {
        person::update \
            -person_id $user_id \
            -first_names $first_names \
            -last_name $last_name
        
        party::update \
            -party_id $user_id \
            -email $email \
            -url $url

        acs_user::update \
            -user_id $user_id \
            -screen_name $screen_name

        person::update_bio \
            -person_id $user_id \
            -bio $bio
    }
} -after_submit {
    ad_returnredirect $return_url
    ad_script_abort
}

# TODO: Validate email: [util_email_valid_p $email]
# TODO: Validate email unique

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
