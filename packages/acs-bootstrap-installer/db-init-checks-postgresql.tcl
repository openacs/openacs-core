#####
#
# Perform database-specific checks for the bootstrap and installer scripts.
#
#####

proc db_bootstrap_checks { errors error_p } {

    upvar $errors my_errors
    upvar $error_p my_error_p

    set my_errors "We found the following problems with your PostgreSQL installation:<p><ul>\n"

    foreach pool [nsv_get db_available_pools .] {
        if { [catch { set db [ns_db gethandle -timeout 15 $pool]}] || ![string compare $db ""] } {
            # This should never happened - we were able to grab a handle previously, why not now?
            append my_errors "<li>(db_bootstrap_checks) Internal error accessing pool \"$pool\".<br>"
            set my_error_p 1
        } else {
            ns_db releasehandle $db
        }
    }

    set db [ns_db gethandle [lindex [nsv_get db_available_pools .] 0]]

    # We'll just run the rest of the tests on a single pool ...

    if { [catch { set version [ns_set value [ns_db 1row $db "select version()"] 0] }] } {
        append my_errors "<li>(db_bootstrap_checks) Internal error querying for PostgreSQL version.\n"
        set my_error_p 1
        set version 0
    } else {
        # DRB: We only want the major.minor portion of the version, i.e. 7.1 not 7.1.3
        regexp {PostgreSQL ([0-9]*\.[0-9]*)} $version all version
        nsv_set ad_database_version . $version
    }

    if { $version < 7.1 } {
        append my_errors "<li>Your installed version of Postgres is too old.  Please install Postgres V7.1 or later.\n"
        set my_error_p 1
    } 

    if { [catch { ns_pg_bind 1row $db "select count(*) from pg_class" }] } {
        append my_errors "<li>Your Postgres driver is too old.  You need to update.\n"
        set my_error_p 1
    }


    ## Make sure the __test__() function is dropped if it exists
    if {![empty_string_p [ns_db 0or1row $db "select proname from pg_proc where proname = '__test__' and pronargs = 0"]]} {
	catch { ns_db dml $db "drop function __test__();" }
    }

    if { [catch { ns_db dml $db "create function __test__() returns integer as 'begin end;' language 'plpgsql'" } errmsg] } {
        append my_errors "<li>PL/pgSQL has not been created in your database.  Execute the following command while logged in as a PostgreSQL \"superuser\": <blockquote><pre>createlang plpgsql your_database_name</pre></blockquote>\n"  
        set my_error_p 1
    } elseif { [catch { ns_db dml $db "drop function __test__();" } errmsg] } {
        append my_errors "<li>An unexpected error was encountered while testing for the of existence PL/pgSQL.  Here's the error messsage: <blockquote><pre>$errmsg</pre></blockquote>\n"
        set my_error_p 1
    }

    # DRB: The PG user has to have "createuser" privs for the PG 7.1 install to work.  Not necessary for PG 7.2

    if { $version == 7.1 } {
        if { [catch { ns_db dml $db "create function __test__() returns integer as 'select 1' language 'sql'" } errmsg] } {
            append my_errors "<li>Unexpected error creating SQL function.  Check your AOLserver log for details.\n"
            set my_error_p 1
        } else {
            if { [catch { ns_db dml $db "update pg_proc set proname = '__test__' where proname = '__test__'" } errmsg] } {
                append my_errors "<li>To install the kernel datamodel in PostgreSQL 7.1 database user named in your AOLserver database pools must have the CREATEUSER privilege.   You must drop your database and user and recreate the user, answering \"yes\" when asked if the new user should be able to create other users.<p>After installation is complete we recommend that you remove this privilege using the following command:<blockquote><pre>alter user your_acs_postgres_user nocreatuser\;</pre></blockquote><p>If you upgrade to PostgreSQL 7.2 you can avoid the need to grant this privilege."
                set my_error_p 1
            }
            if { [catch { ns_db dml $db "drop function __test__();" } errmsg] } {
                append my_errors "<li>An unexpected error was encountered while dropping test function: <blockquote><pre>$errmsg</pre></blockquote>\n"
                set my_error_p 1
            }
        }
    }

    ns_db releasehandle $db

    if { [info exists my_error_p] } {
        append my_errors "</ul>"
    } else { 
        unset my_errors
    }
}

proc db_installer_checks { errors error_p } {
}

proc db_helper_checks { errors error_p } {
}

