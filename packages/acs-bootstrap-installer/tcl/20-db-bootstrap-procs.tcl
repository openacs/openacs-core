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

    # Initialize the list of known database types .  User code should use the database
    # API routine db_known_database_types rather than reference the nsv list directly.
    # We might change the way this is implemented later.  Each database type is
    # represented by a list consisting of the internal name, driver name, and
    # "pretty name" (used by the APM to list the available database engines that 
    # one's package can choose to support).  The driver name and "pretty name" happen
    # to be the same for Postgres and Oracle but let's not depend on that being true
    # in all cases...

    nsv_set ad_known_database_types . \
        [list [list "oracle" "Oracle8" "Oracle8"] [list "postgresql" "PostgreSQL" "PostgreSQL"]]

    #
    # Initialize the list of available pools
    #

    set server_name [ns_info server]
    append config_path "ns/server/$server_name/acs/database"
    set the_set [ns_configsection $config_path]
    set pools [list]

    if { [string length $the_set] > 0 } {
        for {set i 0} {$i < [ns_set size $the_set]} {incr i} {
            if { [string tolower [ns_set key $the_set $i]] ==  "availablepool" } {
                lappend pools [ns_set value $the_set $i]
            }
        }
    }

    if { [llength $pools] == 0 } {
        set pools [ns_db pools]
    }

    # DRB: if the user hasn't given us enough database pools might as well tell
    # them in plain english

    if { [llength $pools] == 0 } {
        set database_problem "There are no database pools specified in your OpenNSD
    configuration file."
    } elseif { [llength $pools] < 3 } {
        set database_problem "OpenACS requires three database pools in order to
    run correctly."
    }

    ns_log Notice "Database API: The following pools are available: $pools"
    nsv_set db_available_pools . $pools

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
        if { [catch { set db [ns_db gethandle -timeout 15 $pool]}] || ![string compare $db ""] } {
            ns_log Notice "Couldn't allocate a handle from database pool \"$pool\"."
            lappend bad_pools "<li>OpenACS could not allocate a handle from database pool \"$pool\"."
            set long_error 1
            break
        } else {
            set this_suffix ""
            if { [catch { set driver [ns_db dbtype $db] } errmsg] } {
                set database_problem "RDBMS type could not be determined: $errmsg"
                ns_log Error "RDBMS type could not be determined: $errmsg"
            } else {
                foreach known_database_type [nsv_get ad_known_database_types .] {
                    if { ![string compare $driver [lindex $known_database_type 1]] } {
                        set this_suffix [lindex $known_database_type 0]
                        break
                    }
                }
            }
            ns_db releasehandle $db
            if { [string length $this_suffix] == 0 } {
                ns_log Notice "Couldn't determine RDBMS type of database pool \"$pool\"."
                lappend bad_pools "<li>OpenACS could not determine the RDBMS type associated with
    pool \"$pool\"."
                set long_error 1
            } elseif { [string length [nsv_get ad_database_type .]] == 0 } {
                nsv_set ad_database_type . $this_suffix
            } elseif { ![string match $this_suffix [nsv_get ad_database_type .]] } {
                ns_log Notice "Database pool \"$pool\" type \"$this_suffix\" differs from
    \"[nsv_get ad_database_type .]\"."
                lappend bad_pools "<li>Database pool \"$pool\" is of type \"$this_suffix\".  The
    first database pool available to OpenACS was of type \"[nsv_get ad_database_type .]\".  All database
    pools must be configured to use the same RDMBS engine, user and database."
            }
        }
    }

    if { [string length [nsv_get ad_database_type .]] == 0 } {
        set database_problem "RDBMS type could not be determined for any pool."
        ns_log Error "RDBMS type could not be determined for any pool."
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
