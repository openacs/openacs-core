# /pvt/home.tcl

ad_page_contract {
    user's workspace page
    @cvs-id $Id$
} -properties {
    system_name:onevalue
    context:onevalue
    full_name:onevalue
    email:onevalue
    url:onevalue
    screen_name:onevalue
    bio:onevalue
    portrait_state:onevalue
    portrait_publish_date:onevalue
    portrait_title:onevalue
    export_user_id:onevalue
    ad_url:onevalue
    member_link:onevalue
}

ad_maybe_redirect_for_registration

set user_id [ad_conn user_id]

acs_user::get -array user -include_bio

set page_title [ad_pvt_home_name]

set context [list $page_title]

set ad_url [ad_url]

set community_member_url [acs_community_member_url -user_id $user_id]

set system_name [ad_system_name]

# LARS:
# This form doesn't include screen_name, because we currently don't use that anywhere

ad_form -name user_info -cancel_url [ad_conn url] -mode display -form {
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
        {html {size 80}}
    }
    {bio:text(textarea),optional
        {label "About yourself"}
        {html {rows 8 cols 60}}
    }
} -on_request {
    foreach var { first_names last_name email screen_name url bio } {
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
    ad_returnredirect [ad_conn url]
    ad_script_abort
}

# TODO: Validate email: [util_email_valid_p $email]
# TODO: Validate email unique

# LARS HACK: Make the URL and email elements real links
if { ![form is_valid user_info] } {
    element set_properties user_info email -display_value "<a href=\"mailto:[element get_value user_info email]\">[element get_value user_info email]</a>"
    element set_properties user_info url -display_value "<a href=\"[element get_value user_info url]\">[element get_value user_info url]</a>"
}

# The template needs to know if this is a request
set form_request_p [expr [form is_request user_info] && [empty_string_p [form get_action user_info]]]

if [ad_parameter SolicitPortraitP "user-info" 0] {
    # we have portraits for some users 
    if ![db_0or1row get_portrait_info "
    select cr.publish_date, nvl(cr.title,'your portrait') as portrait_title
    from cr_revisions cr, cr_items ci, acs_rels a
    where cr.revision_id = ci.live_revision
    and  ci.item_id = a.object_id_two
    and a.object_id_one = :user_id
    and a.rel_type = 'user_portrait_rel'
    "] {
	set portrait_state "upload"
    } else {
	set portrait_state "show"
	set portrait_publish_date [util_AnsiDatetoPrettyDate $publish_date]
    }
} else {
    set portrait_state "none"
}



ad_return_template

