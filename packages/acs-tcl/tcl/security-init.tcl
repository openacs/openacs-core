ad_library {

    Provides methods for authorizing and identifying ACS 
    (both logged in and not) and tracking their sessions.

    @creation-date 16 Feb 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @author Richard Li (richardl@arsdigita.com)
    @cvs-id $Id$

}

# Schedule a procedure to sweep for sessions.
ad_schedule_proc -thread f [ad_parameter SessionSweepInterval security 7200] sec_sweep_sessions

# Verify that the secret_tokens table is populated
set secret_tokens_exists [db_string secret_tokens_exists "select decode(count(*),0,0,1) from secret_tokens"]

if { $secret_tokens_exists == 0 } {
    populate_secret_tokens_db
}

ns_log Notice "security-init.tcl: Creating secret_tokens ns_cache..."
ns_cache create secret_tokens -size 32768
ns_log Notice "security-init.tcl: Populating secret_tokens ns_cache..."
populate_secret_tokens_cache

# These procedures are dynamically defined so that ad_parameter
# does not need to be called directly in the RP. 
proc sec_session_timeout {} "
    return \"[ad_parameter -package_id [ad_acs_kernel_id] SessionTimeout security 1200]\"
"

proc sec_session_renew {} "
    return \"[expr [sec_session_timeout] - [ad_parameter -package_id [ad_acs_kernel_id] SessionRenew security 300]]\"
"

proc sec_login_timeout {} "
    return \"[ad_parameter -package_id [ad_acs_kernel_id] LoginTimeout security 28800]\"
"

