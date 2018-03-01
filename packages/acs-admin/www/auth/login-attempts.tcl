ad_page_contract {
    Administration page for failed login attempts

    @author Günter Ernst (guenter.ernst@wu.ac.at)
    @creation-date 2018-02-19
    @cvs-id $Id:
}

set page_title "Login Attempts"
set context [list [list "." "Authentication"] $page_title]


set max_failed_login_attempts [parameter::get_from_package_key \
                                  -parameter "MaxConsecutiveFailedLoginAttempts" \
                                  -package_key "acs-authentication" \
                                  -default 0]

set auth_package_id [apm_package_id_from_key "acs-authentication"]
set parameter_url [export_vars -base /shared/parameters { { package_id $auth_package_id } { return_url [ad_return_url] } }]

::template::multirow create login_attempts attempt_key attempts locked_until flush_url

foreach { attempt_key seconds attempts } [::auth::login_attempts::get_all] {
    ::template::multirow append login_attempts $attempt_key $attempts [clock_to_ansi $seconds] [export_vars -base "login-attempts-reset" {attempt_key}]
}


list::create \
    -name "login_attempts" \
    -multirow "login_attempts" \
    -actions [list "Flush all" "[export_vars -base "login-attempts-reset" {{attempt_key all}}]" "Clear all login attempts" \
                   "Configure" "[export_vars -base "/shared/parameters" {{package_id $auth_package_id} {return_url [ad_return_url]}}]" "Configure"] \
    -bulk_actions {"Flush selected attempts" "login-attempts-reset" "Flush selected attempts"} \
    -bulk_action_method "post" \
    -pass_properties {max_failed_login_attempts} \
    -key attempt_key \
    -elements {
        attempt_key {
            label "Attempt key"
        }
        attempts {
            label "Attempts"
            display_template {
                <if @login_attempts.attempts@ gt @max_failed_login_attempts@>
                    <span style="color:red;font-weight:bold;">@login_attempts.attempts;literal@</span>
                </if><else>@login_attempts.attempts;literal@</else>
            }
        }
        locked_until {
            label "Lockout"
        }
        flush {
            label "Actions"
            sub_class narrow
            display_template {
                <a href="@login_attempts.flush_url;noquote@">Flush</a>
            }
        }
    }


ad_return_template
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
