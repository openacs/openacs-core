#####
#
# Perform database-specific checks for the bootstrap and installer scripts.
#
#####

proc db_bootstrap_checks { errors error_p } {

    upvar $errors my_errors
    upvar $error_p my_error_p

    foreach pool [nsv_get db_available_pools .] {
        if { [catch { set db [ns_db gethandle -timeout 15 $pool]}] || ![string compare $db ""] } {
            # This should never happened - we were able to grab a handle previously, why not now?
            append my_errors "(db_bootstrap_checks) Internal error accessing pool \"$pool\".<br>"
            set my_error_p 1
        } elseif { [catch { ns_db 1row $db "select count(*) from pg_class pg1 left join pg_class pg2 using (relname)" }] } {
            set my_errors "Your installed version of Postgres does not support outer joins.  Please install Postgres V7.1 or later."
            set my_error_p 1
        } elseif { [catch { ns_pg_bind 1row $db "select count(*) from pg_class" }] } {
            set my_errors "Your Postgres driver is too old.  You need to update."
            set my_error_p 1
        } elseif { [empty_string_p [ns_db 0or1row $db "select 1 where 'a' > 'A'"] ] } {
                set my_errors "You have enabled locale support and did an initdb with the environment variable \"LANG\" set to something other than \"C\".  OpenACS won't work unless PostgreSQL's collation order is set to match \"C\"."
                set my_error_p 1
        }
        ns_db releasehandle $db
    }
    if { ![info exists my_error_p] } {
        # DRB: I don't know how to get this from PG...
        nsv_set ad_database_version . "7.1"
    }
}

proc db_installer_checks { errors error_p } {
}

proc db_helper_checks { errors error_p } {
}

