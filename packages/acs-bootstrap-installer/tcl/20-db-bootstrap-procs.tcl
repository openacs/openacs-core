
ad_proc -private db_available_pools {dbn} {
    Returns a list of the available pools for the given database name.

    <p>
    We define this here in 20-db-bootstrap-procs.tcl rather than
    acs-tcl/tcl/00-database-procs.tcl, as we also need to call it from
    db_bootstrap_set_db_type, below, and from db_bootstrap_checks,
    before all the rest of the db_* api code in 00-database-procs.tcl
    is sourced.

    @param dbn The database name to use.  If empty_string, uses the default database.

    @author Andrew Piskorski (atp@piskorski.com)
    @creation-date 2003/03/16
} {
    if { $dbn eq "" } {
        set dbn $::acs::default_database
    }
    return [nsv_get db_available_pools $dbn]
}

ad_proc -private db_pool_to_dbn_init {} {
    Simply initializes the <code>db_pool_to_dbn</code> nsv, which is
    used by "<code>db_driverkey -handle</code>".

    @author Andrew Piskorski (atp@piskorski.com)
    @creation-date 2003/04/09

    @see db_driverkey
} {
    foreach dbn [nsv_array names db_available_pools] {
        foreach pool [db_available_pools $dbn] {
            nsv_set db_pool_to_dbn $pool $dbn
        }
    }
}


ad_proc db_bootstrap_set_db_type { errors } {

    @author Don Baccus (dhogaza@pacifier.com)
    @param errors Name of variable in caller's space that should receive
    error messages.

    Determine which database engine the user's configured, and do
    db-independent errors checking.

    The "errors" param hack should change eventually, I don't have
    time at the moment to change how the bootstrapper communicates
    database problems to the installer.
} {
    set proc_name {Database API}

    # Might as well get el grosso hacko out of the way...
    upvar $errors database_problem

    # DRB: I've reorganized this a bit from the standard ACS 4.1.  In their
    # version, they'd allocate a handle from the server default pool, check
    # for a recent Oracle driver and assume everything was A-OK if the check
    # succeeded.
    #
    # There are some problems with this approach:
    #
    # 1. The "AvailablePool" parameter specifies the pools to be used by the ACS. 
    #    The default pool needn't be listed as an available pool, therefore in a
    #    mixed db environment the check strategy described above might not actually
    #    be checking any pool designated for ACS use.
    #
    #    In fact, if it weren't for the bootstrap check code there would be no
    #    need at all to configure a default database pool!
    #
    #    The standard ACS check was fine as far as it went in the normal case
    #    where no AvailablePool parameters exist, as in that case the ACS
    #    slurps up all pools.  I expect mixed db environments to be more common
    #    within the OpenACS community, though, so we should do a better job of
    #    checking.  This will especially be true of users migrating from an
    #    [Open]ACS 3.x site or ACS 4.x classic site.
    #
    # 2. There was no checking to make sure that *all* pools are correctly
    #    configured.  Even in an Oracle-only environment one could easy mistype a
    #    user name or the like for one of the pools set aside for ACS use, and
    #    this would not be cleanly caught and reported.
    #
    # 3. There was no checking to make sure that *all* pools are of the same RDBMS
    #    type.  This is important in a mixed-db environment.
    #
    # The strategy I've adopted is to initialize the list of available pools in the
    # bootstrap code, then check that each pool can be allocated, that each is of
    # a recognized database type (oracle and postgres as of 3/2001), and that each
    # pool is of the same database type.  We could also make certain that we're
    # connecting to the same database and user in each pool, but at the moment
    # that's seems anal even by DRB's standards.

    # The same information is as well in 0-acs-init.tcl; it is kept
    # here for a while to guarantee a smooth migration, since the
    # db-interface is essential and we have to deal with situations,
    # where still an old 0-acs-init.tcl is active. This could be
    # removed around OpenACS 6.*
    #
    set ::acs::known_database_types {
        {oracle Oracle Oracle}
        {postgresql PostgreSQL PostgreSQL}
    }


    #
    # Initialize the list of available pools
    #

    set server_name [ns_info server]
    set config_path "ns/server/$server_name/acs/database"
    set all_pools [ns_db pools]

    set database_names [ns_config $config_path {database_names}]

    if { [llength $database_names] <= 0 } {
        # Fall back to old OpenACS 4.6.x pre-multi-db style.
        set old_availablepool_p 1
        set default_dbn {default}
    } else {
        # The config file is using the new multi-db format.
        set old_availablepool_p 0

        set default_dbn [lindex $database_names 0]
        if { $default_dbn eq "" } {
            set default_dbn {default}
            set old_availablepool_p 1

        } else {
            foreach dbn $database_names {
                # TODO: For each pool, may want to add a check against
                # all_pools to ensure that the pool is valid.

                set dbn_pools [ns_config $config_path "pools_${dbn}"]
                nsv_set db_available_pools $dbn $dbn_pools
                ns_log Notice "$proc_name: For database '$dbn', the following pools are available: $dbn_pools"
            }

            if { [db_available_pools $default_dbn] eq "" } {
                ns_log Error "$proc_name: No pools specified for database '$default_dbn'." 
                set old_availablepool_p 1
            }
        }
    }

    set ::acs::default_database $default_dbn

    ns_log Notice "$proc_name: Default database (dbn) is: '$default_dbn'"

    if { $old_availablepool_p } {
        # We ONLY do this as a fallback, if something was wrong with
        # the newer multi-db config above, or if it was simply missing
        # entirely:  --atp@piskorski.com, 2003/03/17 00:55 EST

        set dbn_pools [list]
        set the_set [ns_configsection $config_path]
        if { $the_set ne "" } {
            for {set i 0} {$i < [ns_set size $the_set]} {incr i} {
                if { [string tolower [ns_set key $the_set $i]] ==  "availablepool" } {
                    lappend dbn_pools [ns_set value $the_set $i]
                }
            }
        }

        nsv_set {db_available_pools} $default_dbn $dbn_pools
    }

    set pools [db_available_pools {}]
    if { [llength $pools] <= 0 } {
        nsv_set {db_available_pools} $default_dbn $all_pools
        set pools $all_pools
        ns_log Notice "$proc_name: Using ALL database pools for OpenACS."
    }
    db_pool_to_dbn_init
    ns_log Notice "$proc_name: The following pools are available for OpenACS: $pools"

    # DRB: if the user hasn't given us enough database pools might as well tell
    # them in plain english

    if { [llength $pools] == 0 } {
        set database_problem "There are no database pools specified in your NaviServer configuration file."
    } elseif { [llength $pools] < 3 } {
        set database_problem "OpenACS requires three database pools in order to run correctly."
    }

    # We're done with the mult-db dbn stuff, from now on we deal only
    # with the OpenACS default database pools:
    #
    # TODO: For now the below pool-checking code runs ONLY for the
    # default database.  Should probalby extend the checking to all
    # configured databases:
    #
    # --atp@piskorski.com, 2003/03/17 00:53 EST

    # DRB: Try to allocate a handle from each pool and determine its database type.
    # I wrote this to break after the first allocation failure because a defunct
    # oracle process is created if Oracle's not running at all, causing AOLserver
    # to hang on the second attempt to allocate a handle.   At least on my RH 6.2
    # Linux box, it does.

    nsv_set ad_database_type . ""
    nsv_set ad_database_version . ""

    set bad_pools [list]
    set long_error 0
    foreach pool $pools {
        if { [catch { set db [ns_db gethandle -timeout 15 $pool]} errorMsg] || $db eq "" } {
            ns_log Warning "$proc_name: couldn't allocate a handle from database pool \"$pool\"."
            lappend bad_pools "<li>OpenACS could not allocate a handle from database pool \"$pool\"."
            set long_error 1
            break
        } else {
            set this_suffix ""
            if { [catch { set driver [ns_db dbtype $db] } errmsg] } {
                set database_problem "RDBMS type could not be determined: $errmsg"
                ns_log Error "$proc_name: RDBMS type could not be determined: $errmsg"
            } else {
                foreach known_database_type $::acs::known_database_types {

                    set this_type [lindex $known_database_type 1]

                    # we do a string match here, because we want to
                    # match against Oracle, Oracle8, Oracle10, etc..
                    if { [string match ${this_type}* $driver] } {
                        set this_suffix [lindex $known_database_type 0]
                        break
                    }
                }
            }

            ns_db releasehandle $db
            if { $this_suffix eq "" } {
                ns_log Notice "$proc_name: couldn't determine RDBMS type of database pool \"$pool\"."
                lappend bad_pools "<li>OpenACS could not determine the RDBMS type associated with pool \"$pool\"."
                set long_error 1
            } elseif { [nsv_get ad_database_type .] eq "" } {
                nsv_set ad_database_type . $this_suffix
                #
                # For the time being, keep the info in the nsv for
                # backwards compatibility and and a version in a
                # per-thead (namespaced) variable
                #
                set ::acs::database_type $this_suffix
                
            } elseif { ![string match $this_suffix [nsv_get ad_database_type .]] } {
                ns_log Notice "$proc_name: Database pool \"$pool\" type \"$this_suffix\" differs from \"[nsv_get ad_database_type .]\"."
                lappend bad_pools "<li>Database pool \"$pool\" is of type \"$this_suffix\".  The
    first database pool available to OpenACS was of type \"[nsv_get ad_database_type .]\".  All database
    pools must be configured to use the same RDMBS engine, user and database."
            }
        }
    }

    if { [nsv_get ad_database_type .] eq "" } {
        set database_problem "RDBMS type could not be determined for any pool."
        ns_log Error "$proc_name: RDBMS type could not be determined for any pool."
    }

    if { [llength $bad_pools] > 0 } {
        set database_problem "<p>The following database pools generated errors:
    <ul>[join $bad_pools "\n"]</ul><p>\n"
        if { $long_error } {
            append database_problem "Possible causes might include:<p>
    <ul>
    <li>The database is not running.
    <li>The database driver has not been correctly installed.
    <li>The datasource or database user/password are incorrect.
    <li>You didn't define any database pools.
    </ul><p>"
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
