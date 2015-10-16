#####
#
# Perform database-specific checks for the bootstrap and installer scripts.
#
#####

proc db_bootstrap_checks { errors error_p } {

    upvar $errors my_errors
    upvar $error_p my_error_p

    set my_errors "We found the following problems with your PostgreSQL installation:<p><ul>\n"

    foreach pool [db_available_pools {}] {
        if { [catch { set db [ns_db gethandle -timeout 15 $pool]}] || $db eq "" } {
            # This should never happened - we were able to grab a handle previously, why not now?
            append my_errors "<li>(db_bootstrap_checks) Internal error accessing pool \"$pool\".<br>"
            set my_error_p 1
        } else {
            ns_db releasehandle $db
        }
    }

    set db [ns_db gethandle [lindex [db_available_pools {}] 0]]

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

    if { $version < 9.0 } {
        append my_errors "<li>Your installed version of Postgres is too old.  Please install PostgreSQL 9.0 or later.\n"
        set my_error_p 1
    }

    if { [catch { ns_pg_bind 1row $db "select count(*) from pg_class" }] } {
        append my_errors "<li>Your Postgres driver is either too old or was not compiled with <code>ACS=1</code>.  Please update to a version 2.3 or higher and compile it with <code>ACS=1</code>.\n"
        set my_error_p 1
    }


    ## Make sure the __test__() function is dropped if it exists
    if {[ns_db 0or1row $db "select proname from pg_proc where proname = '__test__' and pronargs = 0"] ne ""} {
	catch { ns_db dml $db "drop function __test__();" }
    }

    if { [catch { ns_db dml $db "create function __test__() returns integer as 'begin end;' language 'plpgsql'" } errmsg] } {
        append my_errors "<li>PL/pgSQL has not been created in your database.  Execute the following command while logged in as a PostgreSQL \"superuser\": <blockquote><pre>createlang plpgsql your_database_name</pre></blockquote>\n"  
        set my_error_p 1
    } elseif { [catch { ns_db dml $db "drop function __test__();" } errmsg] } {
        append my_errors "<li>An unexpected error was encountered while testing for the of existence PL/pgSQL.  Here's the error messsage: <blockquote><pre>$errmsg</pre></blockquote>\n"
        set my_error_p 1
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


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
