ad_page_contract {
    Recover forgotten password.

    @author Simon Carstensen
    @creation-date 2003-08-29
    @cvs-id $Id$
} {
    {authority_id:naturalnum ""}
    {username ""}
    {email ""}
} -validate {
    valid_email -requires email {
        if {![regexp {^[\w.@+/=$%!*~-]+$} $email]} {
            ad_complain "invalid email address"
        }
    }
}

set page_title [_ acs-subsite.Reset_Password]
set context [list $page_title]

# display error if the subsite doesn't allow recovery of passwords
set subsite_id [subsite::get_element -element object_id]

set email_forgotten_password_p [parameter::get \
                                    -parameter EmailForgottenPasswordP \
                                    -package_id $subsite_id \
                                    -default 1]

if {[string is false $email_forgotten_password_p]} {
    ad_return_forbidden Forbidden "Emailing passwords is not allowed"
    ad_script_abort
}


# Display form to collect username and authority
set authority_options [auth::authority::get_authority_options]

if { (![info exists authority_id] || $authority_id eq "") } {
    set authority_id [lindex $authority_options 0 1]
}

ad_form -name recover -edit_buttons [list [list [_ acs-kernel.common_continue] ok]] -form { {dummy:text(hidden),optional} }
    


set username_widget text
if { [parameter::get -parameter UsePasswordWidgetForUsername -package_id [ad_acs_kernel_id]] } {
    set username_widget password
}

set focus {}
if { [auth::UseEmailForLoginP] } {
    ad_form -extend -name recover -form [list [list email:text($username_widget) [list label "Email"]]]
    set user_id_widget_name email
    set focus "email"
} else {
    if { [llength $authority_options] > 1 } {
        ad_form -extend -name recover -form {
            {authority_id:integer(select) 
                {label {[_ acs-kernel.authentication_authority]}} 
                {options $authority_options}
            }
        }
    }
    
    ad_form -extend -name recover -form [list [list username:text($username_widget) [list label "Username"]]] -validate {
        {username
            { [acs_user::get_by_username -authority_id $authority_id -username $username] ne "" }
            { Could not find username at authority }
        }
    }

    set user_id_widget_name username
    set focus "username"
}
set focus "recover.$focus"





set submission_p 0

ad_form -extend -name recover -on_request {}

# We handle form submission here, because otherwise we can't handle both the case where we use the form
# and the case where we don't in one go
if { [form is_valid recover] || (![form is_submission recover] && (([info exists username] && $username ne "") || ([info exists email] && $email ne ""))) } {
    array set recover_info [auth::password::recover_password \
                                -authority_id $authority_id \
                                -username $username \
                                -email $email]

    set login_url [ad_get_login_url -authority_id $authority_id -username $username]
}

set system_owner [ad_system_owner]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
