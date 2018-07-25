ad_library {

    An API for managing database queries.

    @creation-date 15 Apr 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @cvs-id $Id$
}

# Database caching.
#
# Values returned by a query are cached if you pass the "-cache_key" switch
# to the database procedure.  The switch value will be used as the key in the
# ns_cache eval call used to execute the query and processing code.  The
# db_flush proc should be called to flush the cache when appropriate.  The
# "-cache_pool" parameter can be used to specify the cache pool to be used,
# and defaults to db_cache_pool.  The # size of the default cache is governed
# by the kernel parameter "DBCacheSize" in the "caching" section.
#
# Currently db_string, db_list, db_list_of_lists, db_0or1row, and db_multirow support
# caching.
#
# Don Baccus 2/25/2006 - my 52nd birthday!

# As originally released in (at least) ACS 4.2 through OpenACS 4.6,
# this DB API supported only a single, default database.  You could
# define any number of different database drivers and pools in
# AOLserver, but could only use ONE database here.
#
# I have eliminated this restriction.  Now, in OpenACS 5.0 and later,
# to access a non-default database, simply pass the optional -dbn
# (Database Name) switch to any of the DB API procs which support it.
#
# Supported AOLserver database drivers:
#
# - Oracle (nsoracle): Everything should work.
#
# - PostgreSQL (nspostgres): Everything should work.
#
# - ODBC (nsodbc):
#   - Anything using bind variables will only work if you're using a
#     version of the driver with bind variable emulation hacked in
#     (copied from the PostgreSQL driver).
#   - Some features, like LOBs, simply won't work at all.
#   - The basic functionality worked fine back in Sept. 2001, but I
#     have NOT tested it since then at all, so maybe there are bugs.
#
# - Any others: Basic stuff using only the standard ns_db API will
#   likely work, but any special features of the driver (e.g., LOBs)
#   definitely won't.  Feel free to add support!
#
# --atp@piskorski.com, 2003/04/09 19:18 EDT

# Note that "-dbn" specifies a "Database Name", NOT a database pool!
#
# I could have provided access to secondary databases via a -pool
# rather than a -dbn switch, but chose not to, as the existing DB API
# already had the nicely general feature that if you try to do nested
# queries, the DB API will transparently grab a second database handle
# from another pool to make it work.  You can nest your queries as
# many levels deep as you have database pools defined for that
# database.  So, the existing API essentially already supported the
# notion of "binning" database pools into logical "databases", it just
# didn't provide any way to define more than the single, default
# database!  Thus I chose to preserve this "binning" by specifying
# databases via the -dbn switch rather than database pools via a -pool
# switch.

# (JoelA, 27 Dec 2004 - replaced example config.tcl with link)
#
# see http://openacs.org/doc/openacs-5-1/tutorial-second-database
# for config and usage examples

# TODO: The "driverkey_" overrides in the config file are NOT
# implemented yet!
#
# --atp@piskorski.com, 2003/03/16 21:30 EST

# NOTE: don't forget to add your new pools into the
# ns_section ns/db/pools


# The "driverkey" indirection layer:
#
# Note that in the AOLserver config file, you may optionally add one
# entry for each database defining its "driver key".  If you do NOT
# specify a driver key in the AOLserver config file, the appropriate
# key will be determined for you by calling "ns_db driver" once on
# startup for the first pool defined in each database.  Therefore,
# most people should NOT bother to give a driverkey in the config
# file.
#
# So, just what is this "driverkey" thing used for anyway?  AOLserver
# defines the ns_db API, and the OpenACS db_* API depends utterly on
# it.  However, there are a few holes in the functionality of the
# ns_db API, and each AOLserver database driver tends to fill in those
# holes by adding extra functionality with its own, drive specific
# functions.  Therefore, in order to make the db_* API work with
# multiple db drivers, we need to introduce some switches or if
# statements in our code.
#
# Currently (2003/04/08), at least for the Oracle, PostgreSQL, and
# ODBC drivers, the database driver name returned by "ns_db driver" is
# completely sufficient for these switch statements.  But, rather than
# using ns_db driver directly in the switches, we add the simple
# "driver key" layer of indirection between the two, to make the
# default behavior easier to override if that should ever be
# necessary.
#
# --atp@piskorski.com, 2003/04/08 03:39 EDT


# We now use the following global variables:
#
# Server-Wide NSV arrays, keys:
#     db_available_pools   $dbn
#     db_driverkey         $dbn
#     db_pool_to_dbn       $pool
#
# Global Variables
#    ::acs::default_database
#
# Per-thread Tcl global variables:
#   One Tcl Array per Database Name:
#     db_state_${dbn}
#
# The db_available_pools and db_state arrays are used in exactly the
# same manner as they were originally (in ACS 4.0 to OpenACS 4.6
# code), except that in the original DB API we had only one of each
# array total, while now we have one of each array per database.
#
# The db_pool_to_dbn nsv is simply a map to quickly tell use which dbn
# each AOLserver database pool belongs to.  (Any pools which do not
# belong to any dbn have no entry here.)
#
# We use the procs db_state_array_name_is, db_available_pools, and
# db_driverkey to help keep track of these different arrays.
# Note that most code should now NEVER read from any of the
# db_available_pools nsvs listed above, but should instead use the
# proc db_available_pools provided for that purpose.
#
# The original implementation comments on the use of these global
# variables are below:
#
# --atp@piskorski.com, 2003/03/16 21:30 EST


ad_proc -private db_state_array_name_is {
    {-dbn ""}
} {
    @return the name of the global db_state array for the given
    database name.

    @param dbn The database name to use.  If empty_string, uses the
    default database.

    @author Andrew Piskorski (atp@piskorski.com)
    @creation-date 2003/03/16
} {
    if { $dbn eq "" } {
        set dbn $::acs::default_database
    }
    return "db_state_${dbn}"
}


ad_proc -public db_driverkey {
    {-handle_p 0}
    dbn
} {
    Normally, a dbn is passed to this proc.  Unfortunately, there are
    one or two cases where a proc that needs to call this one has only
    a db handle, not the dbn that handle came from.  Therefore, they
    instead use <code>-handle_p 1</code> and pass the db handle.

    Hmm, as of 2018, it seems that in most cases, db_driverkey is
    called with a handle.

    @return The driverkey for use in db_* API switch statements.

    @author Andrew Piskorski (atp@piskorski.com)
    @creation-date 2003/04/08
} {
    if { $handle_p } {
        #
        # In the case, the passed "dbn" is actually a
        # handle. Determine from the handle the "pool" and from the
        # "pool" the "dbn".
        #
        set handle $dbn
        set pool [ns_db poolname $handle]
        set key ::acs::db_pool_to_dbn($pool)
        if {[info exists $key]} {
            #
            # First, try to get the variable from the per-thread
            # variable (which is part of the blueprint).
            #
            set dbn [set $key]
        } elseif { [nsv_exists db_pool_to_dbn $pool] } {
            #
            # Fallback to nsv (old style), when for whatever
            # reasonesm, the namespaced variable is not available.
            #
            ns_log notice "db_driverkey $handle_p dbn <$dbn> VIA NSV"
            set dbn [nsv_get db_pool_to_dbn $pool]
        } else {
            #
            # db_pool_to_dbn_init runs on startup, so other than some
            # broken code deleting the nsv key (very unlikely), the
            # only way this could happen is for someone to call this
            # proc with a db handle from a pool which is not part of
            # any dbn.

            error "No database name (dbn) found for pool '$pool'. Check the 'ns/server/[ns_info server]/acs/database' section of your config file."
        }
    }

    set key ::acs::db_driverkey($dbn)
    if {[info exists $key]} {
        return [set $key]
    }

    if { ![nsv_exists db_driverkey $dbn] } {
        # This ASSUMES that any overriding of this default value via
        # "ns_param driverkey_dbn" has already been done:

        if { $handle_p } {
            set driver [ns_db driver $handle]
        } else {
            db_with_handle -dbn $dbn handle {
                set driver [ns_db driver $handle]
            }
        }

        # These are the default driverkey values, if they are not set
        # in the config file:

        if { [string match "Oracle*" $driver] } {
            set driverkey {oracle}
        } elseif { $driver eq "PostgreSQL" } {
            set driverkey "postgresql"
        } elseif { $driver eq "ODBC" } {
            set driverkey "nsodbc"
        } else {
            set driverkey {}
            ns_log Error "db_driverkey: Unknown driver '$driver'."
        }

        nsv_set db_driverkey $dbn $driverkey
    }

    return [set $key [nsv_get db_driverkey $dbn]]
}


ad_proc -public db_type {} {
    @return the RDBMS type (i.e. oracle, postgresql) this OpenACS installation is using.
    The nsv ad_database_type is set up during the bootstrap process.
} {
    #
    # Currently this should always be either "oracle" or "postgresql":
    # --atp@piskorski.com, 2003/03/16 22:01 EST
    #
    # First check, if the database type exists in the namespaced
    # variable. This should be always the case. If this fail, fall
    # back to the old-style nsv (which can be costly in tight db loops)
    #
    if {[info exists ::acs::database_type]} {
        set result $::acs::database_type
    } else {
        set result [nsv_get ad_database_type .]
        ns_log Warning "db_type '$result' had to be obtained from the nsv 'ad_database_type'"
        set ::acs::database_type $result
    }
    return $result
}

ad_proc -public db_compatible_rdbms_p { db_type } {
    @return 1 if the given db_type is compatible with the current RDBMS.
} {
    return [expr { $db_type eq "" || [db_type] eq $db_type }]
}



ad_proc -private db_legacy_package_p { db_type_list } {
    @return 1 if the package is a legacy package.  We can only tell for certain if it explicitly supports Oracle 8.1.6 rather than the OpenACS more general oracle.
} {
    if {"oracle-8.1.6" in $db_type_list} {
        return 1
    }
    return 0
}

ad_proc -public db_version {} {
    @return the RDBMS version (i.e. 8.1.6 is a recent Oracle version; 7.1 a
                               recent PostgreSQL version)
} {
    return [nsv_get ad_database_version .]
}

ad_proc -public db_current_rdbms {} {
    @return the current rdbms type and version.
} {
    return [db_rdbms_create [db_type] [db_version]]
}

ad_proc -public db_known_database_types {} {
    @return a list of three-element lists describing the database engines known
    to OpenACS.  Each sublist contains the internal database name (used in file
                                                                   paths, etc), the driver name, and a "pretty name" to be used in selection
    forms displayed to the user.

    The nsv containing the list is initialized by the bootstrap script and should
    never be referenced directly by user code.
} {
    return $::acs::known_database_types
}


# db_null, db_quote, db_nullify_empty_string - were all previously
# defined Oracle only, no Postgres equivalent existed at all.  So, it
# can't hurt anything to have them defined in when OpenACS is using
# Postgres too.  --atp@piskorski.com, 2003/04/08 05:34 EDT

ad_proc db_null {} {
    @return an empty string, which Oracle thinks is null.  This routine was
    invented to provide an RDBMS-specific null value but doesn't actually
    work.  I (DRB) left it in to speed porting - we should really clean up
    the code an pull out the calls instead, though.
} {
    return ""
}

ad_proc -public db_quote { string } {
    Quotes a string value to be placed in a SQL statement.
} {
    regsub -all {'} "$string" {''} result
    return $result
}

ad_proc -public db_nullify_empty_string { string } {
    A convenience function that returns [db_null] if $string is the empty string.
} {
    if { $string eq "" } {
        return [db_null]
    } else {
        return $string
    }
}

ad_proc -public db_boolean { bool } {
    Converts a Tcl boolean (1/0) into a SQL boolean (t/f)
    @return t or f
} {
    if { $bool } {
        return "t"
    } else {
        return "f"
    }
}

ad_proc -public db_nextval {
    { -dbn "" }
    sequence
} {

    Example:

    <pre>
    set new_object_id [db_nextval acs_object_id_seq]
    </pre>

    @return the next value for a sequence. This can utilize a pool of
    sequence values.

    @param sequence the name of an sql sequence

    @param dbn The database name to use.  If empty_string, uses the default database.

    @see <a href="/doc/db-api-detailed">/doc/db-api-detailed</a>
} {
    set driverkey [db_driverkey $dbn]

    # PostgreSQL has a special implementation here, any other db will
    # probably work with the default:

    switch -- $driverkey {

        postgresql {
            #             # the following query will return a nextval if the sequnce
            #             # is of relkind = 'S' (a sequnce).  if it is not of relkind = 'S'
            #             # we will try querying it as a view:

            #             if { [db_0or1row -dbn $dbn nextval_sequence "
            #                 select nextval('${sequence}') as nextval
            #                 where (select relkind
            #                        from pg_class
            #                        where relname = '${sequence}') = 'S'
            #             "]} {
            #                 return $nextval
            #             } else {
            #                 ns_log debug "db_nextval: sequence($sequence) is not a real sequence.  perhaps it uses the view hack."
            #                 db_0or1row -dbn $dbn nextval_view "select nextval from ${sequence}"
            #                 return $nextval
            #             }
            #
            # The code above is just for documentation, how it worked
            # before the change below. We keep now a per-thread table of
            # the "known" sequences to avoid at runtime the query,
            # whether the specified sequence is a real sequence or a
            # view. This change makes this function more than a factor
            # of 2 faster than before.
            #
            # Note, that solely the per-thread information won't work for
            # freshly created sequences. Therefore, we keep the old
            # code for checking at runtime in the database for such
            # occurrences.
            #
            # Note, that the sequence handling in OpenACS is quite a
            # mess.  Some sequences are named t_SEQUENCE (10 in
            # dotlrn), others are called just SEQUENCE (18 in dotlrn),
            # for some sequences, additional views are defined with an
            # attribute 'nextval', and on top of this, db_nextval is
            # called sometimes with the view name and sometimes with
            # the sequence name. Checking this at runtime is
            # unnecessary complex and costly.
            #
            # The best solution would certainly be to call "db_nextval"
            # only with real sequence names (as defined in SQL). In that
            # case, the whole function would for postgres would collapse
            # to a single line, without any need for sequence name
            # caching. But in that case, one should rename the sequences
            # from t_SEQUENCE to SEQUENCE for postgres.
            #
            # However, since Oracle uses the pseudo column ".nextval",
            # which is emulated via the view, it is not clear, how
            # feasible this is to remove all such views without breaking
            # installed applications.  We keep for such cases the view,
            # but nevertheless, the function "db_nextval" should always
            # be called with names without the "t_" prefix to achieve
            # Oracle compatibility.

            if {![info exists ::db::sequences]} {
                ns_log notice "-- creating per thread sequence table"
                namespace eval ::db {}
                foreach s [db_list -dbn $dbn relnames "select relname, relkind  from pg_class where relkind = 'S'"] {
                    set ::db::sequences($s) 1
                }
            }
            if {[info exists ::db::sequences(t_$sequence)]} {
                #ns_log notice "-- found t_$sequence"
                set nextval [db_string -dbn $dbn nextval "select nextval('t_$sequence')"]
            } elseif {[info exists ::db::sequences($sequence)]} {
                #ns_log notice "-- found $sequence"
                set nextval [db_string -dbn $dbn nextval "select nextval('$sequence')"]
                if {[string match t_* $sequence]} {
                    ad_log Warning "For portability, db_nextval should be called without the leading 't_' prefix: 't_$sequence'"
                }
            } elseif { [db_0or1row -dbn $dbn nextval_sequence "
                 select nextval('${sequence}') as nextval
                 where (select relkind
                        from pg_class
                        where relname = '${sequence}') = 'S'
             "]} {
                #
                # We do not have an according sequence-table. Use the system catalog to check
                # for the sequence
                #
                # ... the query sets nextval if it succeeds
                #
                ad_log Warning "Probably deprecated sequence name '$sequence' is used (no sequence table found)"
            } else {
                #
                # finally, there might be a view with a nextval
                #
                ns_log debug "db_nextval: sequence($sequence) is not a real sequence.  perhaps it uses the view hack."
                set nextval [db_string -dbn $dbn nextval "select nextval from $sequence"]
                ad_log Warning "Using deprecated sequence view hack for '$sequence'. Is there not real sequence?"
            }

            return $nextval
        }

        oracle -
        nsodbc -
        default {
            return [db_string -dbn $dbn nextval "select $sequence.nextval from dual"]
        }
    }
}

ad_proc -public db_nth_pool_name {
    { -dbn "" }
    n
} {
    @return the name of the pool used for the nth-nested selection (0-relative).
    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    set available_pools [db_available_pools $dbn]

    if { $n < [llength $available_pools] } {
        set pool [lindex $available_pools $n]
    } else {
        return -code error "Ran out of database pools ($available_pools)"
    }
    return $pool
}


ad_proc -public db_with_handle {
    { -dbn "" }
    db code_block
} {

    Places a usable database handle in <i>db</i> and executes <i>code_block</i>.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    upvar 1 $db dbh
    upvar "#0" [db_state_array_name_is -dbn $dbn] db_state

    # Initialize bookkeeping variables.
    if { ![info exists db_state(handles)] } {
        set db_state(handles) [list]
    }
    if { ![info exists db_state(n_handles_used)] } {
        set db_state(n_handles_used) 0
    }
    if { $db_state(n_handles_used) >= [llength $db_state(handles)] } {
        set pool [db_nth_pool_name -dbn $dbn $db_state(n_handles_used)]
        set start_time [expr {[clock clicks -microseconds]/1000.0}]
        set errno [catch {
            set db [ns_db gethandle $pool]
        } error]
        ds_collect_db_call $db gethandle "" $pool $start_time $errno $error
        lappend db_state(handles) $db
        if { $errno } {
            return -code $errno -errorcode $::errorCode -errorinfo $::errorInfo $error
        }
    }
    set my_dbh [lindex $db_state(handles) $db_state(n_handles_used)]
    set dbh $my_dbh
    set db_state(last_used) $my_dbh

    incr db_state(n_handles_used)
    set errno [catch { uplevel 1 $code_block } error]
    incr db_state(n_handles_used) -1

    # This may have changed while the code_block was being evaluated.
    set db_state(last_used) $my_dbh

    # Unset dbh, so any subsequence use of this variable will bomb.
    unset -nocomplain dbh

    # If errno is 1, it's an error, so return errorCode and errorInfo;
    # if errno = 2, it's a return, so don't try to return errorCode/errorInfo
    # errno = 3 or 4 give undefined results

    if { $errno == 1 } {
        # A real error occurred
        return -code $errno -errorcode $::errorCode -errorinfo $::errorInfo $error
    }

    if { $errno == 2 } {

        # The code block called a "return", so pass the message through but don't try
        # to return errorCode or errorInfo since they may not exist

        return -code $errno $error
    }
}


ad_proc -public db_exec_plsql {
    {-dbn ""}
    statement_name
    sql
    args
} {

    <strong>Oracle:</strong>
    Executes a PL/SQL statement, and returns the variable of bind
    variable <code>:1</code>.

    <p>
    <strong>PostgreSQL:</strong>
    Performs a pl/pgsql function or procedure call.  The caller must
    perform a select query that returns the value of the function.

    <p>
    Examples:

    <p>
    <pre>
    # Oracle:
    db_exec_plsql delete_note {
        begin  note.del(:note_id);  end;
    }

    # PostgreSQL:
    db_exec_plsql delete_note {
        select note__delete(:note_id);
    }
    </pre>

    <p>
    If you need the return value, then do something like this:

    <p>
    <pre>
    # Oracle:
    set new_note_id [db_exec_plsql create_note {
        begin
        :1 := note.new(
                       owner_id => :user_id,
                       title    => :title,
                       body     => :body,
                       creation_user => :user_id,
                       creation_ip   => :peeraddr,
                       context_id    => :package_id
                       );
        end;
    }]

    # PostgreSQL:
    set new_note_id [db_exec_plsql create_note {
        select note__new(
                         null,
                         :user_id,
                         :title,
                         :body,
                         'note',
                         now(),
                         :user_id,
                         :peeraddr,
                         :package_id
                         );
    }]
    </pre>

    <p>
    You can call several pl/sql statements at once, like this:

    <p>
    <pre>
    # Oracle:
    db_exec_plsql delete_note {
        begin
        note.del(:note_id);
        note.del(:another_note_id);
        note.del(:yet_another_note_id);
        end;
    }

    # PostgreSQL:
    db_exec_plsql delete_note {
        select note__delete(:note_id);
        select note__delete(:another_note_id);
        select note__delete(:yet_another_note_id);
    }
    </pre>

    If you are using xql files then put the body of the query in a
    <code>yourfilename-oracle.xql</code> or <code>yourfilename-postgresql.xql</code> file, as appropriate. E.g. the first example
    transformed to use xql files looks like this:


    <p>
    <code>yourfilename.tcl</code>:<br>
    <p>
    <pre>
    db_exec_plsql delete_note {}</pre>

    <p>
    <code>yourfilename-oracle.xql</code>:<br>
    <p>
    <pre>
    &lt;fullquery name="delete_note">
    &lt;querytext>
    begin
    note.del(:note_id);
    end;
    &lt;/querytext>
    &lt;/fullquery></pre>

    <p>
    <code>yourfilename-postgresql.xql</code>:<br>
    <p>
    <pre>
    &lt;fullquery name="delete_note">
    &lt;querytext>
    select note__delete(:note_id);
    &lt;/querytext>
    &lt;/fullquery></pre>


    @param dbn The database name to use.  If empty_string, uses the default database.

    @see <a href="/doc/db-api-detailed">/doc/db-api-detailed</a>
} {
    ad_arg_parser { bind_output bind } $args

    # Query Dispatcher (OpenACS - ben)
    set full_statement_name [db_qd_get_fullname $statement_name]

    if { [info exists bind_output] } {
        return -code error "the -bind_output switch is not currently supported"
    }

    set driverkey [db_driverkey $dbn]
    switch -- $driverkey {
        postgresql {
            set postgres_p 1
        }

        oracle -
        nsodbc -
        default {
            set postgres_p 0
        }
    }

    if { ! $postgres_p } {
        db_with_handle -dbn $dbn db {
            # Right now, use :1 as the output value if it occurs in the statement,
            # or not otherwise.
            set test_sql [db_qd_replace_sql $full_statement_name $sql]
            if { [regexp {:1} $test_sql] } {
                return [db_exec exec_plsql_bind $db $full_statement_name $sql 2 1 ""]
            } else {
                return [db_exec dml $db $full_statement_name $sql]
            }
        }
    } else {
        # Postgres doesn't have PL/SQL, of course, but it does have
        # PL/pgSQL and other procedural languages.  Rather than assign the
        # result to a bind variable which is then returned to the caller,
        # the Postgres version of OpenACS requires the caller to perform a
        # select query that returns the value of the function.

        # We are no longer calling db_string, which screws up the bind
        # variable stuff otherwise because of calling environments. (ben)

        ad_arg_parser { bind_output bind } $args

        # I'm not happy about having to get the fullname here, but right now
        # I can't figure out a cleaner way to do it. I will have to
        # revisit this ASAP. (ben)
        set full_statement_name [db_qd_get_fullname $statement_name]

        if { [info exists bind_output] } {
            return -code error "the -bind_output switch is not currently supported"
        }

        db_with_handle -dbn $dbn db {
            # plsql calls that are simple selects bypass the plpgsql
            # mechanism for creating anonymous functions (OpenACS - Dan).
            # if a table is being created, we need to bypass things, too (OpenACS - Ben).
            set test_sql [db_qd_replace_sql $full_statement_name $sql]
            if {[regexp -nocase -- {^\s*select} $test_sql match]} {
                # ns_log Debug "PLPGSQL: bypassed anon function"
                set selection [db_exec 0or1row $db $full_statement_name $sql]
            } elseif {[regexp -nocase -- {^\s*(create|drop) table} $test_sql match]} {
                ns_log Debug "PLPGSQL: bypassed anon function for create/drop table"
                set selection [db_exec dml $db $full_statement_name $sql]
                return ""
            } else {
                # ns_log Debug "PLPGSQL: using anonymous function"
                set selection [db_exec_plpgsql $db $full_statement_name $sql $statement_name]
            }
            return [ns_set value $selection 0]
        }
    }
}


ad_proc -private db_exec_plpgsql { db statement_name pre_sql fname } {

    <strong>PostgreSQL only.</strong>
    <p>

    A helper procedure to execute a SQL statement, potentially binding
    depending on the value of the $bind variable in the calling environment
    (if set).

    <p>
    Low level replacement for db_exec which replaces inline code with a proc.
    db proc is dropped after execution.  This is a temporary fix until we can
    port all of the db_exec_plsql calls to simple selects of the inline code
    wrapped in function calls.

    <p>
    emulation of plsql calls from oracle.  This routine takes the plsql
    statements and wraps them in a function call, calls the function, and then
    drops the function. Future work might involve converting this to cache the
    function calls

    <p>
    This proc is <b>private</b> - use db_exec_plsql instead!

    @see db_exec_plsql

} {
    set start_time [expr {[clock clicks -microseconds]/1000.0}]

    set sql [db_qd_replace_sql $statement_name $pre_sql]

    set unique_id [db_nextval "anon_func_seq"]

    set function_name "__exec_${unique_id}_${fname}"

    # insert Tcl variable values (OpenACS - Dan)
    if {$sql ne $pre_sql } {
        set sql [uplevel 2 [list subst -nobackslashes $sql]]
    }
    ns_log Debug "PLPGSQL: converted: $sql to: select $function_name ()"

    # create a function definition statement for the inline code
    # binding is emulated in tcl. (OpenACS - Dan)

    set errno [catch {
        upvar bind bind
        if { [info exists bind] && [llength $bind] != 0 } {
            if { [llength $bind] == 1 } {
                set bind_vars [list]
                set len [ns_set size $bind]
                for {set i 0} {$i < $len} {incr i} {
                    lappend bind_vars [ns_set key $bind $i] \
                        [ns_set value $bind $i]
                }
                set proc_sql [db_bind_var_substitution $sql $bind_vars]
            } else {
                set proc_sql [db_bind_var_substitution $sql $bind]
            }
        } else {
            set proc_sql [uplevel 2 [list db_bind_var_substitution $sql]]
        }

        ns_db dml $db "create function $function_name () returns varchar as [::ns_dbquotevalue $proc_sql] language 'plpgsql'"

        set ret_val [ns_db 0or1row $db "select $function_name ()"]

        # drop the anonymous function (OpenACS - Dan)
        # JCD: ignore return code -- maybe we should be smarter about this though.
        catch {ns_db dml $db "drop function $function_name ()"}

        return $ret_val

    } error]

    set errinfo $::errorInfo
    set errcode $::errorCode

    ds_collect_db_call $db 0or1row $statement_name $sql $start_time $errno $error

    if { $errno == 2 } {
        return $error
    } else {
        catch {ns_db dml $db "drop function $function_name ()"}
    }

    return -code $errno -errorinfo $errinfo -errorcode $errcode $error
}

ad_proc -private db_get_quote_indices { sql } {
    Given a piece of SQL, return the indices of single quotes.
    This is useful when we do bind var substitution because we should
    not attempt bind var substitution inside quotes. Examples:

    <pre>
    sql          return value
    {'a'}           {0 2}
    {'a''}           {}
    {'a'a'a'}       {0 2 4 6}
    {a'b'c'd'}      {1 3 5 7}
    </pre>

    @see db_bind_var_substitution
} {
    set quote_indices [list]

    # Returns a list on the format
    # Example - for sql={'a'a'a'} returns
    # {0 2} {0 0} {2 2} {3 6} {4 4} {6 6}
    set all_indices [regexp -inline -indices -all -- {(?:^|[^'])(')(?:[^']|'')+(')(?=$|[^'])} $sql]

    for {set i 0} { $i < [llength $all_indices] } { incr i 3 } {
        lappend quote_indices [lindex $all_indices $i+1 0] [lindex $all_indices $i+2 0]
    }

    return $quote_indices
}

ad_proc -private db_bind_var_quoted_p { sql bind_start_idx bind_end_idx} {

} {
    foreach {quote_start_idx quote_end_idx} [db_get_quote_indices $sql] {
        if { $bind_start_idx > $quote_start_idx && $bind_end_idx < $quote_end_idx } {
            return 1
        }
    }

    return 0
}

ad_proc -private db_bind_var_substitution { sql { bind "" } } {

    This proc emulates the bind variable substitution in the PostgreSQL driver.
    Since this is a temporary hack, we do it in Tcl instead of hacking up the
    driver to support plsql calls.  This is only used for the db_exec_plpgsql
    function.

} {
    if {$bind eq ""} {
        upvar __db_sql lsql
        set lsql $sql
        uplevel {
            set __db_lst [regexp -inline -indices -all -- {:?:\w+} $__db_sql]
            for {set __db_i [expr {[llength $__db_lst] - 1}]} {$__db_i >= 0} {incr __db_i -1} {
                set __db_ws [lindex $__db_lst $__db_i 0]
                set __db_we [lindex $__db_lst $__db_i 1]
                set __db_bind_var [string range $__db_sql $__db_ws $__db_we]
                if {![string match "::*" $__db_bind_var] && ![db_bind_var_quoted_p $__db_sql $__db_ws $__db_we]} {
                    set __db_tcl_var [string range $__db_bind_var 1 end]
                    set __db_tcl_var [set $__db_tcl_var]
                    if {$__db_tcl_var eq ""} {
                        set __db_tcl_var null
                    } else {
                        set __db_tcl_var "[::ns_dbquotevalue $__db_tcl_var]"
                    }
                    set __db_sql [string replace $__db_sql $__db_ws $__db_we $__db_tcl_var]
                }
            }
        }
    } else {

        array set bind_vars $bind

        set lsql $sql
        set lst [regexp -inline -indices -all -- {:?:\w+} $sql]
        for {set i [expr {[llength $lst] - 1}]} {$i >= 0} {incr i -1} {
            set ws [lindex $lst $i 0]
            set we [lindex $lst $i 1]
            set bind_var [string range $sql $ws $we]
            if {![string match "::*" $bind_var] && ![db_bind_var_quoted_p $lsql $ws $we]} {
                set tcl_var [string range $bind_var 1 end]
                set val $bind_vars($tcl_var)
                if {$val eq ""} {
                    set val null
                } else {
                    set val "[::ns_dbquotevalue $val]"
                }
                set lsql [string replace $lsql $ws $we $val]
            }
        }
    }

    return $lsql
}


ad_proc -public db_release_unused_handles {{-dbn ""}} {

    Releases any database handles that are presently unused.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    upvar "#0" [db_state_array_name_is -dbn $dbn] db_state

    if { [info exists db_state(n_handles_used)] } {
        # Examine the elements at the end of db_state(handles), killing off
        # handles that are unused and not engaged in a transaction.

        set index_to_examine [expr { [llength $db_state(handles)] - 1 }]
        while { $index_to_examine >= $db_state(n_handles_used) } {
            set db [lindex $db_state(handles) $index_to_examine]

            # Stop now if the handle is part of a transaction.
            if { [info exists db_state(transaction_level,$db)]
                 && $db_state(transaction_level,$db) > 0
             } {
                break
            }

            set start_time [expr {[clock clicks -microseconds]/1000.0}]
            ns_db releasehandle $db
            ds_collect_db_call $db releasehandle "" "" $start_time 0 ""
            incr index_to_examine -1
        }
        set db_state(handles) [lrange $db_state(handles) 0 $index_to_examine]
    }
}


ad_proc -private db_getrow { db selection } {

    A helper procedure to perform an ns_db getrow, invoking developer support
    routines as necessary.

} {
    set start_time [expr {[clock clicks -microseconds]/1000.0}]
    set errno [catch { return [ns_db getrow $db $selection] } error]
    ds_collect_db_call $db getrow "" "" $start_time $errno $error
    if { $errno == 2 } {
        return $error
    }
    return -code $errno -errorinfo $::errorInfo -errorcode $::errorCode $error
}


ad_proc -public db_exec { type db statement_name pre_sql {ulevel 2} args } {

    A helper procedure to execute a SQL statement, potentially binding
    depending on the value of the $bind variable in the calling environment
    (if set).

} {
    set start_time [expr {[clock clicks -microseconds]/1000.0}]
    set driverkey [db_driverkey -handle_p 1 $db]

    # Note: Although marked as private, db_exec is in fact called
    # extensively from several other packages.  We DEFINITELY don't
    # want to have to change all those procs to pass in the
    # (redundant) $dbn just so we can use it in the call to
    # db_driverkey, so db_driverkey MUST support its -handle switch.
    # --atp@piskorski.com, 2003/04/09 12:13 EDT

    set sql [db_qd_replace_sql $statement_name $pre_sql]

    # insert Tcl variable values (OpenACS - Dan)
    if {$sql ne $pre_sql } {
        set sql [uplevel $ulevel [list subst -nobackslashes $sql]]
    }

    set errno [catch {
        upvar bind bind

        if { [info exists bind] && [llength $bind] != 0 } {
            if { [llength $bind] == 1 } {
                # $bind is an ns_set id:

                switch -- $driverkey {
                    oracle {
                        return [ns_ora $type $db -bind $bind $sql {*}$args]
                    }
                    postgresql {
                        return [ns_pg_bind $type $db -bind $bind $sql]
                    }
                    nsodbc {
                        return [ns_odbc_bind $type $db -bind $bind $sql]
                    }
                    default {
                        error "Unknown database driver.  Bind variables not supported for this database."
                    }
                }

            } else {
                # $bind is a Tcl list, convert it to an ns_set:
                set bind_vars [ns_set create]
                foreach { name value } $bind {
                    ns_set put $bind_vars $name $value
                }
            }

            switch -- $driverkey {
                oracle {
                    # TODO: Using $args outside the list is
                    # potentially bad here, depending on what is in
                    # args and if the items contain any embedded
                    # whitespace.  Or maybe it works fine.  But it's
                    # hard to know.  Document or fix.
                    # --atp@piskorski.com, 2003/04/09 15:33 EDT

                    return [ns_ora $type $db -bind $bind_vars $sql {*}$args]
                }
                postgresql {
                    return [ns_pg_bind $type $db -bind $bind_vars $sql]
                }
                nsodbc {
                    return [ns_odbc_bind $type $db -bind $bind_vars $sql]
                }
                default {
                    error "Unknown database driver.  Bind variables not supported for this database."
                }
            }

        } else {
            # Bind variables, if any, are defined solely as individual
            # Tcl variables:

            switch -- $driverkey {
                oracle {
                    return [uplevel $ulevel [list ns_ora $type $db $sql] $args]
                }
                postgresql {
                    return [uplevel $ulevel [list ns_pg_bind $type $db $sql]]
                }
                nsodbc {
                    return [uplevel $ulevel [list ns_odbc_bind $type $db $sql]]
                }
                default {
                    # Using plain ns_db like this will work ONLY if
                    # the query is NOT using bind variables:
                    # --atp@piskorski.com, 2001/09/03 08:41 EDT
                    return [uplevel $ulevel [list ns_db $type $db $sql] $args]
                }
            }
        }
    } error]

    # JCD: we log the clicks, dbname, query time, and statement to catch long running queries.
    # If we took more than 3 seconds yack about it.
    if { [clock clicks -milliseconds] - $start_time > 3000 } {
        set duration [format %.2f [expr {[clock clicks -milliseconds] - $start_time}]]
        ns_log Warning "db_exec: longdb $duration ms $db $type $statement_name"
    } else {
        #set duration [format %.2f [expr {[clock clicks -milliseconds] - $start_time}]]
        #ns_log Debug "db_exec: timing $duration seconds $db $type $statement_name"
    }

    ds_collect_db_call $db $type $statement_name $sql $start_time $errno $error
    if { $errno == 2 } {
        return $error
    }

    return -code $errno -errorinfo $::errorInfo -errorcode $::errorCode $error
}


ad_proc -public db_string {
    {-dbn ""}
    -cache_key
    {-cache_pool db_cache_pool}
    statement_name
    sql
    args
} {

    Usage: <b>db_string</b> <i>statement-name sql</i> [ <tt>-default</tt> <i>default</i> ] [ <tt>-bind</tt> <i>bind_set_id</i> | <tt>-bind</tt> <i>bind_value_list</i> ]

    @return the first column of the result of the SQL query <i>sql</i>.  If the query doesn't return a row, returns <i>default</i> or raises an error if no <i>default</i> is provided.

    @param dbn The database name to use.  If empty_string, uses the default database.
    @param cache_key Cache the result using given value as the key.  Default is to not cache.
    @param cache_pool Override the default db_cache_pool
} {
    # Query Dispatcher (OpenACS - ben)
    set full_name [db_qd_get_fullname $statement_name]

    ad_arg_parser { default bind } $args

    if { [info exists cache_key] } {
        set value [ns_cache eval $cache_pool $cache_key {
            db_with_handle -dbn $dbn db {
                set selection [db_exec 0or1row $db $full_name $sql]
            }
            if { $selection ne ""} {
                set selection [list [ns_set value $selection 0]]
            }
            set selection
        }]
        if { $value eq "" } {
            if { [info exists default] } {
                return $default
            }
            return -code error "Selection did not return a value, and no default was provided"
        } else {
            return [lindex $value 0]
        }
    } else {
        db_with_handle -dbn $dbn db {
            set selection [db_exec 0or1row $db $full_name $sql]
        }
        if { $selection eq ""} {
            if { [info exists default] } {
                return $default
            }
            return -code error "Selection did not return a value, and no default was provided"
        }
        return [ns_set value $selection 0]
    }

}


ad_proc -public db_list {
    {-dbn ""}
    -cache_key
    {-cache_pool db_cache_pool}
    statement_name
    sql
    args
} {

    Usage: <b>db_list</b> <i>statement-name sql</i> [ <tt>-bind</tt> <i>bind_set_id</i> | <tt>-bind</tt> <i>bind_value_list</i> ]

    @return a Tcl list of the values in the first column of the result of SQL query <tt>sql</tt>.
    If <tt>sql</tt> doesn't return any rows, returns an empty list.

    @param dbn The database name to use.  If empty_string, uses the default database.
    @param cache_key Cache the result using given value as the key.  Default is to not cache.
    @param cache_pool Override the default db_cache_pool
} {
    ad_arg_parser { bind } $args

    # Query Dispatcher (OpenACS - SDW)
    set full_statement_name [db_qd_get_fullname $statement_name]

    # Can't use db_foreach in this proc, since we need to use the ns_set directly.

    if { [info exists cache_key] } {
        return [ns_cache eval $cache_pool $cache_key {
            db_with_handle -dbn $dbn db {
                set selection [db_exec select $db $full_statement_name $sql]
                set result [list]
                while { [db_getrow $db $selection] } {
                    lappend result [ns_set value $selection 0]
                }
            }
            set result
        }]
    }

    db_with_handle -dbn $dbn db {
        set selection [db_exec select $db $full_statement_name $sql]
        set result [list]
        while { [db_getrow $db $selection] } {
            lappend result [ns_set value $selection 0]
        }
    }
    return $result

}


ad_proc -public db_list_of_lists {
    {-dbn ""}
    -cache_key
    {-cache_pool db_cache_pool}
    statement_name
    sql
    args
} {

    Usage: <b>db_list_of_lists</b> <i>statement-name sql</i> [ <tt>-bind</tt> <i>bind_set_id</i> | <tt>-bind</tt> <i>bind_value_list</i> ]

    @return a Tcl list, each element of which is a list of all column
    values in a row of the result of the SQL query<tt>sql</tt>. If
    <tt>sql</tt> doesn't return any rows, returns an empty list.

    It checks if the element is I18N and replaces it, thereby
    reducing the need to do this with every single package

    @param dbn The database name to use.  If empty_string, uses the default database.
    @param cache_key Cache the result using given value as the key.  Default is to not cache.
    @param cache_pool Override the default db_cache_pool
} {
    ad_arg_parser { bind } $args

    # Query Dispatcher (OpenACS - SDW)
    set full_statement_name [db_qd_get_fullname $statement_name]

    # Can't use db_foreach here, since we need to use the ns_set directly.

    if { [info exists cache_key] } {
        return [ns_cache eval $cache_pool $cache_key {
            db_with_handle -dbn $dbn db {
                set selection [db_exec select $db $full_statement_name $sql]
                set result [list]
                while { [db_getrow $db $selection] } {
                    set this_result [list]
                    for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
                        lappend this_result  [ns_set value $selection $i]
                    }
                    lappend result $this_result
                }
            }
            set result
        }]
    }

    db_with_handle -dbn $dbn db {
        set selection [db_exec select $db $full_statement_name $sql]
        set result [list]
        while { [db_getrow $db $selection] } {
            set this_result [list]
            for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
                lappend this_result  [ns_set value $selection $i]
            }
            lappend result $this_result
        }
    }
    return $result

}


ad_proc -public db_list_of_ns_sets {
    {-dbn ""}
    statement_name
    sql
    args
} {
    Usage: <b>db_list_of_ns_sets</b> <i>statement-name sql</i> [ <tt>-bind</tt> <i>bind_set_id</i> | <tt>-bind</tt> <i>bind_value_list</i> ]

    @return a list of ns_sets with the values of each column of each row
    returned by the sql query specified.

    @param statement_name The name of the query.
    @param sql The SQL to be executed.
    @param args Any additional arguments.

    @return list of ns_sets, one per each row return by the SQL query

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    ad_arg_parser { bind } $args

    set full_statement_name [db_qd_get_fullname $statement_name]

    db_with_handle -dbn $dbn db {
        set result [list]
        set selection [db_exec select $db $full_statement_name $sql]

        while {[db_getrow $db $selection]} {
            lappend result [ns_set copy $selection]
        }
    }

    return $result
}


ad_proc -public db_foreach {
    {-dbn ""}
    statement_name
    sql
    args
} {

    Usage:
    <blockquote>
    db_foreach <em><i>statement-name sql</i></em> [ -bind <em><i>bind_set_id</i></em> | -bind <em><i>bind_value_list</i></em> ] \
        [ -column_array <em><i>array_name</i></em> | -column_set <em><i>set_name</i></em> ] \
        <em><i>code_block</i></em> [ if_no_rows <em><i>if_no_rows_block</i> ]</em>

    </blockquote>

    <p>Performs the SQL query <em><i><tt>sql</tt></i></em>, executing
    <em><i><tt>code_block</tt></i></em> once for each row with variables set to
    column values (or a set or array populated if <tt>-column_array</tt> or
                   <tt>column_set</tt> is specified). If the query returns no rows, executes
    <em><i><tt>if_no_rows_block</tt></i></em> (if provided). </p>

    <p>Example:

    <blockquote><pre>db_foreach greeble_query "select foo, bar from greeble" {
        ns_write "&lt;li&gt;foo=$foo; bar=$bar\n"
    } if_no_rows {
        # This block is optional.
        ns_write "&lt;li&gt;No greebles!\n"
    }</pre></blockquote>

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    # Query Dispatcher (OpenACS - ben)
    set full_statement_name [db_qd_get_fullname $statement_name]

    ad_arg_parser { bind column_array column_set args } $args

    # Do some syntax checking.
    set arglength [llength $args]
    if { $arglength == 1 } {
        # Have only a code block.
        set code_block [lindex $args 0]
    } elseif { $arglength == 3 } {
        # Should have code block + if_no_rows + code block.
        if { [lindex $args 1] ne "if_no_rows"
             && [lindex $args 1] ne "else"
         } {
            return -code error "Expected if_no_rows as second-to-last argument"
        }
        lassign $args code_block . if_no_rows_code_block
    } else {
        return -code error "Expected 1 or 3 arguments after switches"
    }

    if { [info exists column_array] && [info exists column_set] } {
        return -code error "Can't specify both column_array and column_set"
    }

    if { [info exists column_array] } {
        upvar 1 $column_array array_val
    }

    if { [info exists column_set] } {
        upvar 1 $column_set selection
    }

    db_with_handle -dbn $dbn db {
        set selection [db_exec select $db $full_statement_name $sql]

        set counter 0
        while { [db_getrow $db $selection] } {
            incr counter
            unset -nocomplain array_val

            if { ![info exists column_set] } {
                for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
                    if { [info exists column_array] } {
                        set array_val([ns_set key $selection $i]) [ns_set value $selection $i]
                    } else {
                        upvar 1 [ns_set key $selection $i] column_value
                        set column_value [ns_set value $selection $i]
                    }
                }
            }
            set errno [catch { uplevel 1 $code_block } error]

            # Handle or propagate the error. Can't use the usual "return -code $errno..." trick
            # due to the db_with_handle wrapped around this loop, so propagate it explicitly.
            switch -- $errno {
                0 {
                    # TCL_OK
                }
                1 {
                    # TCL_ERROR
                    error $error $::errorInfo $::errorCode
                }
                2 {
                    # TCL_RETURN
                    error "Cannot return from inside a db_foreach loop"
                }
                3 {
                    # TCL_BREAK
                    ns_db flush $db
                    break
                }
                4 {
                    # TCL_CONTINUE - just ignore and continue looping.
                }
                default {
                    error "Unknown return code: $errno"
                }
            }
        }
        # If the if_no_rows_code is defined, go ahead and run it.
        if { $counter == 0 && [info exists if_no_rows_code_block] } {
            uplevel 1 $if_no_rows_code_block
        }
    }
}


proc db_multirow_helper {} {
    uplevel 1 {
        if { !$append_p || ![info exists counter]} {
            set counter 0
        }

        db_with_handle -dbn $dbn db {
            set selection [db_exec select $db $full_statement_name $sql]
            set local_counter 0

            # Make sure 'next_row' array doesn't exist
            # The this_row and next_row variables are used to always execute the code block one result set row behind,
            # so that we have the opportunity to peek ahead, which allows us to do group by's inside
            # the multirow generation
            # Also make the 'next_row' array available as a magic __db_multirow__next_row variable
            upvar 1 __db_multirow__next_row next_row
            unset -nocomplain next_row

            set more_rows_p 1
            while { 1 } {

                if { $more_rows_p } {
                    set more_rows_p [db_getrow $db $selection]
                } else {
                    break
                }

                # Setup the 'columns' part, now that we know the columns in the result set
                # And save variables which we might clobber, if '-unclobber' switch is specified.
                if { $local_counter == 0 } {
                    for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
                        lappend local_columns [ns_set key $selection $i]
                    }
                    lappend local_columns {*}$extend
                    if { !$append_p || ![info exists columns] } {
                        # store the list of columns in the var_name:columns variable
                        set columns $local_columns
                    } else {
                        # Check that the columns match, if not throw an error
                        if { [join [lsort -ascii $local_columns]] ne [join [lsort -ascii $columns]] } {
                            error "Appending to a multirow with differing columns.
    Original columns     : [join [lsort -ascii $columns] ", "].
    Columns in this query: [join [lsort -ascii $local_columns] ", "]" "" "ACS_MULTIROW_APPEND_COLUMNS_MISMATCH"
                        }
                    }

                    # Save values of columns which we might clobber
                    if { $unclobber_p && $code_block ne "" } {
                        foreach col $columns {
                            upvar 1 $col column_value __saved_$col column_save

                            if { [info exists column_value] } {
                                if { [array exists column_value] } {
                                    array set column_save [array get column_value]
                                } else {
                                    set column_save $column_value
                                }

                                # Clear the variable
                                unset column_value
                            }
                        }
                    }
                }

                if { $code_block eq "" } {
                    # No code block - pull values directly into the var_name array.

                    # The extra loop after the last row is only for when there's a code block
                    if { !$more_rows_p } {
                        break
                    }
                    incr counter
                    upvar $level_up "$var_name:$counter" array_val
                    set array_val(rownum) $counter
                    for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
                        set array_val([ns_set key $selection $i]) \
                            [ns_set value $selection $i]
                    }
                } else {
                    # There is a code block to execute

                    # Copy next_row to this_row, if it exists
                    unset -nocomplain this_row
                    set array_get_next_row [array get next_row]
                    if { $array_get_next_row ne "" } {
                        array set this_row [array get next_row]
                    }

                    # Pull values from the query into next_row
                    unset -nocomplain next_row
                    if { $more_rows_p } {
                        for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
                            set next_row([ns_set key $selection $i]) [ns_set value $selection $i]
                        }
                    }

                    # Process the row
                    if { [info exists this_row] } {
                        # Pull values from this_row into local variables
                        foreach name [array names this_row] {
                            upvar 1 $name column_value
                            set column_value $this_row($name)
                        }

                        # Initialize the "extend" columns to the empty string
                        foreach column_name $extend {
                            upvar 1 $column_name column_value
                            set column_value ""
                        }

                        # Execute the code block
                        set errno [catch { uplevel 1 $code_block } error]

                        # Handle or propagate the error. Can't use the usual
                        # "return -code $errno..." trick due to the db_with_handle
                        # wrapped around this loop, so propagate it explicitly.
                        switch -- $errno {
                            0 {
                                # TCL_OK
                            }
                            1 {
                                # TCL_ERROR
                                error $error $::errorInfo $::errorCode
                            }
                            2 {
                                # TCL_RETURN
                                error "Cannot return from inside a db_multirow loop"
                            }
                            3 {
                                # TCL_BREAK
                                ns_db flush $db
                                break
                            }
                            4 {
                                # TCL_CONTINUE
                                continue
                            }
                            default {
                                error "Unknown return code: $errno"
                            }
                        }

                        # Pull the local variables back out and into the array.
                        incr counter
                        upvar $level_up "$var_name:$counter" array_val
                        set array_val(rownum) $counter
                        foreach column_name $columns {
                            upvar 1 $column_name column_value
                            set array_val($column_name) $column_value
                        }
                    }
                }
                incr local_counter
            }
        }

        # Restore values of columns which we've saved
        if { $unclobber_p && $code_block ne "" && $local_counter > 0 } {
            foreach col $columns {
                upvar 1 $col column_value __saved_$col column_save

                # Unset it first, so the road's paved to restoring
                unset -nocomplain column_value

                # Restore it
                if { [info exists column_save] } {
                    if { [array exists column_save] } {
                        array set column_value [array get column_save]
                    } else {
                        set column_value $column_save
                    }

                    # And then remove the saved col
                    unset column_save
                }
            }
        }
        # Unset the next_row variable, just in case
        unset -nocomplain next_row
    }
}

ad_proc -public db_multirow {
    -local:boolean
    -append:boolean
    {-upvar_level 1}
    -unclobber:boolean
    {-extend {}}
    {-dbn ""}
    -cache_key
    {-cache_pool db_cache_pool}
    var_name
    statement_name
    sql
    args
} {
    @param dbn The database name to use.  If empty_string, uses the default database.
    @param cache_key Cache the result using given value as the key.  Default is to not cache.
    @param cache_pool Override the default db_cache_pool

    @param unclobber If set, will cause the proc to not overwrite local variables. Actually, what happens
    is that the local variables will be overwritten, so you can access them within the code block. However,
    if you specify -unclobber, we will revert them to their original state after execution of this proc.

    Usage:
    <blockquote>
    db_multirow [ -local ] [ -upvar_level <em><i>n_levels_up</i></em> ] [ -append ] [ -extend <em><i>column_list</i></em> ] \
        <em><i>var-name statement-name sql</i></em> [ -bind <em><i>bind_set_id</i></em> | -bind <em><i>bind_value_list</i></em> ] \
        <em><i>code_block</i></em> [ if_no_rows <em><i>if_no_rows_block</i> ]</em>

    </blockquote>

    <p>Performs the SQL query <code>sql</code>, saving results in variables
    of the form
    <code><i>var_name</i>:1</code>, <code><i>var_name</i>:2</code>, etc,
    setting <code><i>var_name</i>:rowcount</code> to the total number
    of rows, and setting <code><i>var_name</i>:columns</code> to a
    list of column names.

    <p>

    If "cache_key" is set, cache the array that results from the query *and*
    any code block for future use.  When this result is returned from cache,
    THE CODE BLOCK IS NOT EXECUTED.  Therefore any values calculated by the
    code block that aren't listed as arguments to "extend" will
    not be created.  In practice this impacts relatively few queries, but do
    take care.

    <p>

    You can not simultaneously append to and cache a non-empty multirow.

    <p>

    Each row also has a column, rownum, automatically
    added and set to the row number, starting with 1. Note that this will
    override any column in the SQL statement named 'rownum', also if you're
    using the Oracle rownum pseudo-column.

    <p>

    If the <code>-local</code> is passed, the variables defined
    by db_multirow will be set locally (useful if you're compiling dynamic templates
                                        in a function or similar situations). Use the <code>-upvar_level</code>
    switch to specify how many levels up the variable should be set.

    <p>

    You may supply a code block, which will be executed for each row in
    the loop. This is very useful if you need to make computations that
    are better done in Tcl than in SQL, for example using ns_urlencode
    or ad_quotehtml, etc. When the Tcl code is executed, all the columns
    from the SQL query will be set as local variables in that code. Any
    changes made to these local variables will be copied back into the
    multirow.

    <p>

    You may also add additional, computed columns to the multirow, using the
    <code>-extend { <i>col_1</i> <i>col_2</i> ... }</code> switch. This is
    useful for things like constructing a URL for the object retrieved by
    the query.

    <p>

    If you're constructing your multirow through multiple queries with the
    same set of columns, but with different rows, you can use the
    <code>-append</code> switch. This causes the rows returned by this query
    to be appended to the rows already in the multirow, instead of starting
    a clean multirow, as is the normal behavior. The columns must match the
    columns in the original multirow, or an error will be thrown.

    <p>

    Your code block may call <code>continue</code> in order to skip a row
    and not include it in the multirow. Or you can call <code>break</code>
    to skip this row and quit looping.

    <p>

    Notice the nonstandard numbering (everything
                                      else in Tcl starts at 0); the reason is that the graphics designer, a non
    programmer, may wish to work with row numbers.

    <p>

    Example:
    <pre>db_multirow -extend { user_url } users users_query {
        select user_id first_names, last_name, email from cc_users
    } {
        set user_url [acs_community_member_url -user_id $user_id]
    }</pre>

    @see template::multirow
} {
    # Query Dispatcher (OpenACS - ben)
    set full_statement_name [db_qd_get_fullname $statement_name]

    if { $local_p } {
        set level_up $upvar_level
    } else {
        set level_up \#[template::adp_level]
    }

    ad_arg_parser { bind args } $args

    # Do some syntax checking.
    set arglength [llength $args]
    if { $arglength == 0 } {
        # No code block.
        set code_block ""
    } elseif { $arglength == 1 } {
        # Have only a code block.
        set code_block [lindex $args 0]
    } elseif { $arglength == 3 } {
        # Should have code block + if_no_rows + code block.
        if { [lindex $args 1] ne "if_no_rows"
             && [lindex $args 1] ne "else"
         } {
            return -code error "Expected if_no_rows as second-to-last argument"
        }
        lassign $args code_block . if_no_rows_code_block
    } else {
        return -code error "Expected 1 or 3 arguments after switches"
    }

    upvar $level_up "$var_name:rowcount" counter
    upvar $level_up "$var_name:columns" columns

    if { [info exists cache_key]
         && $append_p
         && [info exists counter] && $counter > 0
     } {
        return -code error "Can't append and cache a non-empty multirow datasource simultaneously"
    }

    if { [info exists cache_key] } {

        set value [ns_cache eval $cache_pool $cache_key {
            db_multirow_helper

            set values [list]

            for { set count 1 } { $count <= $counter } { incr count } {
                upvar $level_up "$var_name:[expr {$count}]" array_val
                lappend values [array get array_val]
            }

            return [list $counter $columns $values]
        }]

        lassign $value counter columns values

        set count 1
        foreach value $values {
            upvar $level_up "$var_name:[expr {$count}]" array_val
            array set array_val $value
            incr count
        }
    } else {
        db_multirow_helper
    }


    # If the if_no_rows_code is defined, go ahead and run it.
    if { $counter == 0 && [info exists if_no_rows_code_block] } {
        uplevel 1 $if_no_rows_code_block
    }
}

ad_proc -public db_multirow_group_last_row_p {
    {-column:required}
} {
    Used inside the code_block to db_multirow to ask whether this row is the last row
    before the value of 'column' changes, or the last row of the result set.

    <p>

    This is useful when you want to build up a multirow for a master/slave table pair,
    where you only want one row per row in the master table, but you want to include
    data from the slave table in a column of the multirow.

    <p>

    Here's an example:

    <pre>
    # Initialize the lines variable to hold a list of order line summaries
    set lines [list]

    # Start building the multirow. We add the dynamic column 'lines_pretty', which will
    # contain the pretty summary of the order lines.
    db_multirow -extend { lines_pretty } orders select_orders_and_lines {
        select o.order_id,
        o.customer_name,
        l.item_name,
        l.quantity
        from   orders o,
        order_lines l
        where  l.order_id = o.order_id
        order  by o.order_id, l.item_name
    } {
        lappend lines "$quantity $item_name"
        if { [db_multirow_group_last_row_p -column order_id] } {
            # Last row of this order, prepare the pretty version of the order lines
            set lines_pretty [join $lines ", "]

            # Reset the lines list, so we start from a fresh with the next row
            set lines [list]
        } else {
            # There are yet more order lines to come for this order,
            # continue until we've collected all the order lines
            # The 'continue' keyword means this line will not be added to the resulting multirow
            continue
        }
    }
    </pre>

    @author Lars Pind (lars@collaboraid.biz)

    @param column The name of the column defining the groups.

    @return 1 if this is the last row before the column value changes, 0 otherwise.
} {
    upvar 1 __db_multirow__next_row next_row
    if { ![info exists next_row] } {
        # If there is no next row, this is the last row
        return 1
    }
    upvar 1 $column column_value
    # Otherwise, it's the last row in the group if the next row has a different value than this row
    return [expr {$column_value ne $next_row($column) }]
}


ad_proc -public db_dml {{-dbn ""} statement_name sql args } {
    Do a DML statement.

    <p>

    args can be one of: -clobs, -blobs, -clob_files or -blob_files. See the db-api doc referenced below for more information.

    @param dbn The database name to use.  If empty_string, uses the default database.

    @see <a href="/doc/db-api-detailed">/doc/db-api-detailed</a>
} {
    ad_arg_parser { clobs blobs clob_files blob_files bind } $args
    set driverkey [db_driverkey $dbn]

    switch -- $driverkey {
        postgresql {
            set postgres_p 1
        }
        oracle -
        nsodbc -
        default {
            set postgres_p 0
        }
    }

    # Query Dispatcher (OpenACS - ben)
    set full_statement_name [db_qd_get_fullname $statement_name]

    # This "only one of..." check didn't exist in the PostgreSQL
    # version, but it shouldn't't hurt anything: --atp@piskorski.com,
    # 2003/04/08 06:19 EDT

    # Only one of clobs, blobs, clob_files, and blob_files is allowed.
    # Remember which one (if any) is provided:

    set lob_argc 0
    set lob_argv [list]
    set command "dml"
    if { [info exists clobs] } {
        set command "clob_dml"
        set lob_argv $clobs
        incr lob_argc
    }
    if { [info exists blobs] } {
        set command "blob_dml"
        set lob_argv $blobs
        incr lob_argc
    }
    if { [info exists clob_files] } {
        set command "clob_dml_file"
        set lob_argv $clob_files
        incr lob_argc
    }
    if { [info exists blob_files] } {
        set command "blob_dml_file"
        set lob_argv $blob_files
        incr lob_argc
    }
    if { $lob_argc > 1 } {
        error "Only one of -clobs, -blobs, -clob_files, or -blob_files may be specified as an argument to db_dml"
    }

    if { ! $postgres_p } {
        # Oracle:
        db_with_handle -dbn $dbn db {
            if { $lob_argc == 1 } {
                # Bind :1, :2, ..., :n as LOBs (where n = [llength $lob_argv])
                set bind_vars [list]
                for { set i 1 } { $i <= [llength $lob_argv] } { incr i } {
                    lappend bind_vars $i
                }
                eval [list db_exec "${command}_bind" $db $full_statement_name $sql 2 $bind_vars] $lob_argv
            } else {
                eval [list db_exec $command $db $full_statement_name $sql] $lob_argv
            }
        }

    } elseif {$command eq "blob_dml_file"} {
        # PostgreSQL:
        db_with_handle -dbn $dbn db {
            # another ugly hack to avoid munging Tcl files.
            # __lob_id needs to be set inside of a query (.xql) file for this
            # to work.  Say for example that you need to create a lob. In
            # Oracle, you would do something like:

            # db_dml update_photo  "update foo set bar = empty_blob()
            #                       where bar = :bar
            #                       returning foo into :1" -blob_files [list $file]
            # for PostgreSQL we can do the equivalent by placing the following
            # in a query file:
            # update foo set bar = [set __lob_id [db_string get_id "select empty_lob()"]]
            # where bar = :bar

            # __lob_id acts as a flag that signals that blob_dml_file is
            # required, and it is also used to pass along the lob_id.  It
            # is unsert afterwards to avoid name clashes with other invocations
            # of this routine.
            # (DanW - Openacs)

            db_exec dml $db $full_statement_name $sql
            if {[uplevel {info exists __lob_id}]} {
                ns_pg blob_dml_file $db [uplevel {set __lob_id}] $blob_files
                uplevel {unset __lob_id}
            }
        }

    } else {
        # PostgreSQL:
        db_with_handle -dbn $dbn db {
            db_exec dml $db $full_statement_name $sql
        }
    }
}


ad_proc -public db_resultrows {{-dbn ""}} {
    @return the number of rows affected by the last DML command.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    upvar "#0" [db_state_array_name_is -dbn $dbn] db_state
    set driverkey [db_driverkey $dbn]

    switch -- $driverkey {
        oracle {
            return [ns_ora resultrows $db_state(last_used)]
        }
        postgresql {
            return [ns_pg ntuples $db_state(last_used)]
        }
        nsodbc {
            error "db_resultrows is not supported for this database."
        }
        default {
            error "Unknown database driver.  db_resultrows is not supported for this database."
        }
    }
}


ad_proc -public db_0or1row {
    {-dbn ""}
    -cache_key
    {-cache_pool db_cache_pool}
    statement_name
    sql
    args
} {

    Usage:
    <blockquote>
    db_0or1row <i>statement-name sql</i> [ -bind <i>bind_set_id</i> | -bind <i>bind_value_list</i> ] \
        [ -column_array <i>array_name</i> | -column_set <i>set_name</i> ]

    </blockquote>

    <p>Performs the SQL query sql. If a row is returned, sets variables
    to column values (or a set or array populated if -column_array
                      or column_set is specified) and returns 1. If no rows are returned,
    returns 0.

    @return 1 if variables are set, 0 if no rows are returned.  If more than one row is returned, throws an error.

    @param dbn The database name to use.  If empty_string, uses the default database.
    @param cache_key Cache the result using given value as the key.  Default is to not cache.
    @param cache_pool Override the default db_cache_pool
} {
    ad_arg_parser { bind column_array column_set } $args

    # Query Dispatcher (OpenACS - ben)
    set full_statement_name [db_qd_get_fullname $statement_name]

    if { [info exists column_array] && [info exists column_set] } {
        return -code error "Can't specify both column_array and column_set"
    }

    if { [info exists column_array] } {
        upvar 1 $column_array array_val
        unset -nocomplain array_val
    }

    if { [info exists column_set] } {
        upvar 1 $column_set selection
    }

    if { [info exists cache_key] } {
        set values [ns_cache eval $cache_pool $cache_key {
            db_with_handle -dbn $dbn db {
                set selection [db_exec 0or1row $db $full_statement_name $sql]
            }

            set values [list]

            if { $selection ne "" } {
                for {set i 0} { $i < [ns_set size $selection] } {incr i} {
                    lappend values [list [ns_set key $selection $i] [ns_set value $selection $i]]
                }
            }

            set values
        }]

        if { $values eq "" } {
            set selection ""
        } else {
            set selection [ns_set create]

            foreach value $values {
                ns_set put $selection [lindex $value 0] [lindex $value 1]
            }
        }
    } else {
        db_with_handle -dbn $dbn db {
            set selection [db_exec 0or1row $db $full_statement_name $sql]
        }
    }

    if { $selection eq "" } {
        return 0
    }

    if { [info exists column_array] } {
        array set array_val [ns_set array $selection]
    } elseif { ![info exists column_set] } {
        for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
            uplevel 1 [list set [ns_set key $selection $i] [ns_set value $selection $i]]
        }
    }

    return 1
}


ad_proc -public db_1row { args } {

    A wrapper for db_0or1row, which produces an error if no rows are returned.

    @param args Arguments to be passed to db_0or1row. Check db_0or1row proc doc
                for details.

    @see db_0or1row

    @return 1 if variables are set.

} {
    if { ![uplevel ::db_0or1row $args] } {
        return -code error "Query did not return any rows."
    }
}

if {[info commands ns_cache_transaction_begin] eq ""} {
    #
    # When the server has no support for ns_cache_transaction_*,
    # provide dummy procs to avoid runtime "if" statements.
    #
    proc ns_cache_transaction_begin args {;}
    proc ns_cache_transaction_commit args {;}
    proc ns_cache_transaction_rollback args {;}
}

ad_proc -public db_transaction {{ -dbn ""} transaction_code args } {
    Usage: <b><i>db_transaction</i></b> <i>transaction_code</i> [ on_error { <i>error_code_block</i> } ]

    Executes transaction_code with transactional semantics.  This means that either all of the database commands
    within transaction_code are committed to the database or none of them are.  Multiple <code>db_transaction</code>s may be
    nested (end transaction is transparently ns_db dml'ed when the outermost transaction completes).<p>

    To handle errors, use <code>db_transaction {transaction_code} on_error {error_code_block}</code>.  Any error generated in
    <code>transaction_code</code> will be caught automatically and process control will transfer to <code>error_code_block</code>
    with a variable <code>errmsg</code> set.  The error_code block can then clean up after the error, such as presenting a usable
    error message to the user.  Following the execution of <code>error_code_block</code> the transaction will be aborted.
    If you want to explicitly abort the transaction, call <code>db_abort_transaction</code>
    from within the transaction_code block or the error_code block.<p>

    Example 1:<br>
    In this example, db_dml triggers an error, so control passes to the on_error block which prints a readable error.
    <pre>
    db_transaction {
        db_dml test "nonsense"
    } on_error {
        ad_return_error "Error in blah/foo/bar" "The error was: $errmsg"
    }
    </pre>

    Example 2:<br>
    In this example, the second command, "nonsense" triggers an error.  There is no on_error block, so the
    transaction is immediately halted and aborted.
    <pre>
    db_transaction {
        db_dml test {insert into footest values(1)}
        nonsense
        db_dml test {insert into footest values(2)}
    }
    </pre>

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    upvar "#0" [db_state_array_name_is -dbn $dbn] db_state

    set syn_err "db_transaction: Invalid arguments. Use db_transaction { code } \[on_error { error_code_block }\] "
    set arg_c [llength $args]

    if { $arg_c != 0 && $arg_c != 2 } {
        # Either this is a transaction with no error handling or there must be an on_error { code } block.
        error $syn_err
    }  elseif { $arg_c == 2 } {
        # We think they're specifying an on_error block
        if {[lindex $args 0] ne "on_error"  } {
            # Unexpected: they put something besides on_error as a connector.
            error $syn_err
        } else {
            # Success! We got an on_error code block.
            set on_error [lindex $args 1]
        }
    }
    # Make the error message and database handle available to the on_error block.
    upvar errmsg errmsg

    db_with_handle -dbn $dbn db {
        # Preserve the handle, since db_with_handle kills it after executing
        # this block.
        set dbh $db
        # Remember that there's a transaction happening on this handle.
        if { ![info exists db_state(transaction_level,$dbh)] } {
            set db_state(transaction_level,$dbh) 0
        }
        set level [incr db_state(transaction_level,$dbh)]
        if { $level == 1 } {
            ns_db dml $dbh "begin transaction"
            ns_cache_transaction_begin
        }
    }
    # Execute the transaction code.
    set errno [catch {
        uplevel 1 $transaction_code
    } errmsg]
    incr db_state(transaction_level,$dbh) -1

    set err_p 0
    switch -- $errno {
        0 {
            # TCL_OK
        }
        2 {
            # TCL_RETURN
        }
        3 {
            # TCL_BREAK - Abort the transaction and do the break.
            ns_db dml $dbh "abort transaction"
            ns_cache_transaction_rollback
            db_release_unused_handles -dbn $dbn
            break
        }
        4 {
            # TCL_CONTINUE - just ignore.
        }
        default {
            # TCL_ERROR or unknown error code: Its a real error.
            set err_p 1
        }
    }

    if { $err_p || [db_abort_transaction_p -dbn $dbn]} {
        # An error was triggered or the transaction has been aborted.
        db_abort_transaction -dbn $dbn
        if { [info exists on_error] && $on_error ne "" } {

            if {"postgresql" eq [db_type]} {

                # JCD: with postgres we abort the transaction prior to
                # executing the on_error block since there is nothing
                # you can do to "fix it" and keeping it meant things like
                # queries in the on_error block would then fail.
                #
                # Note that the semantics described in the proc doc
                # are not possible to support on PostgreSQL.

                # DRB: I removed the db_release_unused_handles call that
                # this patch included because additional aborts further
                # down triggered an illegal db handle error.  I'm going to
                # have the code start a new transaction as well.  If we
                # don't, if a transaction fails and the on_error block
                # fails, the on_error block DML will have been committed.
                # Starting a new transaction here means that DML by both
                # the transaction and on_error clause will be rolled back.
                # On the other hand, if the on_error clause doesn't fail,
                # any DML in that block will be committed.  This seems more
                # useful than simply punting ...

                ns_db dml $dbh "abort transaction"
                ns_cache_transaction_rollback
                ns_db dml $dbh "begin transaction"
                ns_cache_transaction_begin

            }

            # An on_error block exists, so execute it.

            set errno  [catch {
                uplevel 1 $on_error
            } on_errmsg]

            # Determine what do with the error.
            set err_p 0
            switch -- $errno {
                0 {
                    # TCL_OK
                }

                2 {
                    # TCL_RETURN
                }
                3 {
                    # TCL_BREAK
                    ns_db dml $dbh "abort transaction"
                    ns_cache_transaction_rollback
                    db_release_unused_handles
                    break
                }
                4 {
                    # TCL_CONTINUE - just ignore.
                }
                default {
                    # TCL_ERROR or unknown error code: Its a real error.
                    set err_p 1
                }
            }

            if { $err_p } {
                # An error was generated from the $on_error block.
                if { $level == 1} {
                    # We're at the top level, so we abort the transaction.
                    set db_state(db_abort_p,$dbh) 0
                    ns_db dml $dbh "abort transaction"
                    ns_cache_transaction_rollback
                }
                # We throw this error because it was thrown from the error handling code that the programmer must fix.
                error $on_errmsg $::errorInfo $::errorCode
            } else {
                # Good, no error thrown by the on_error block.
                if { [db_abort_transaction_p -dbn $dbn] } {
                    # This means we should abort the transaction.
                    if { $level == 1 } {
                        set db_state(db_abort_p,$dbh) 0
                        ns_db dml $dbh "abort transaction"
                        ns_cache_transaction_rollback
                        # We still have the transaction generated error.  We don't want to throw it, so we log it.
                        ns_log Error "Aborting transaction due to error:\n$errmsg"
                    } else {
                        # Propagate the error up to the next level.
                        error $errmsg $::errorInfo $::errorCode
                    }
                } else {
                    # The on_error block has resolved the transaction error.  If we're at the top, commit and exit.
                    # Otherwise, we continue on through the lower transaction levels.
                    if { $level == 1} {
                        ns_db dml $dbh "end transaction"
                        ns_cache_transaction_commit
                    }
                }
            }
        } else {
            # There is no on_error block, yet there is an error, so we propagate it.
            if { $level == 1 } {
                set db_state(db_abort_p,$dbh) 0
                ns_db dml $dbh "abort transaction"
                ns_cache_transaction_rollback
                error "Transaction aborted: $errmsg" $::errorInfo $::errorCode
            } else {
                db_abort_transaction -dbn $dbn
                error $errmsg $::errorInfo $::errorCode
            }
        }
    } else {
        # There was no error from the transaction code.
        if { [db_abort_transaction_p -dbn $dbn] } {
            # The user requested the transaction be aborted.
            if { $level == 1 } {
                set db_state(db_abort_p,$dbh) 0
                ns_db dml $dbh "abort transaction"
                ns_cache_transaction_rollback
            }
        } elseif { $level == 1 } {
            # Success!  No errors and no requested abort.  Commit.
            ns_db dml $dbh "end transaction"
            ns_cache_transaction_commit
        }
    }
}


ad_proc -public db_abort_transaction {{-dbn ""}} {

    Aborts all levels of a transaction. That is if this is called within
    several nested transactions, all of them are terminated. Use this
    instead of db_dml "abort" "abort transaction".

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    upvar "#0" [db_state_array_name_is -dbn $dbn] db_state

    db_with_handle -dbn $dbn db {
        # We set the abort flag to true.
        set db_state(db_abort_p,$db) 1
    }
}


ad_proc -private db_abort_transaction_p {{-dbn ""}} {
    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    upvar "#0" [db_state_array_name_is -dbn $dbn] db_state

    db_with_handle -dbn $dbn db {
        if { [info exists db_state(db_abort_p,$db)] } {
            return $db_state(db_abort_p,$db)
        } else {
            # No abort flag registered, so we assume everything is ok.
            return 0
        }
    }
}


ad_proc -public db_name {{-dbn ""}} {

    @return the name of the database as reported by the driver.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    db_with_handle -dbn $dbn db {
        set dbtype [ns_db dbtype $db]
    }
    return $dbtype
}


ad_proc -public db_get_username {{-dbn ""}} {
    @return the username parameter from the driver section of the
    first database pool for the dbn.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    set pool [lindex [db_available_pools $dbn] 0]
    return [ns_config "ns/db/pool/$pool" User]
}

ad_proc -public db_get_password {{-dbn ""}} {
    @return the password parameter from the driver section of the
    first database pool for the dbn.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    set pool [lindex [db_available_pools $dbn] 0]
    return [ns_config "ns/db/pool/$pool" Password]
}

ad_proc -public db_get_sql_user {{-dbn ""}} {
    <strong>Oracle only.</strong>

    <p>
    @return a valid Oracle user@database/password string to access a
    database through sqlplus.

    <p>
    This proc may well <em>work</em> for databases other than Oracle,
    but its return value won't really be of any use.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    set pool [lindex [db_available_pools $dbn] 0]
    set datasource [ns_config "ns/db/pool/$pool" DataSource]
    if { $datasource ne "" && ![string is space $datasource] } {
        return "[ns_config ns/db/pool/$pool User]/[ns_config ns/db/pool/$pool Password]@$datasource"
    } else {
        return "[ns_config ns/db/pool/$pool User]/[ns_config ns/db/pool/$pool Password]"
    }
}

ad_proc -public db_get_pgbin {{-dbn ""}} {
    <strong>PostgreSQL only.</strong>

    <p>
    @return the pgbin parameter from the driver section of the first database pool.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    set pool [lindex [db_available_pools $dbn] 0]
    set driver [ns_config "ns/db/pool/$pool" Driver]
    return [ns_config "ns/db/driver/$driver" pgbin]
}


ad_proc -public db_get_port {{-dbn ""}} {
    <strong>PostgreSQL only.</strong>

    <p>
    @return the port number from the first database pool.  It assumes the
    datasource is properly formatted since we've already verified that we
    can connect to the pool.
    It returns an empty string for an empty port value.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    set pool [lindex [db_available_pools $dbn] 0]
    set datasource [ns_config "ns/db/pool/$pool" DataSource]
    set last_colon_pos [string last ":" $datasource]
    if { $last_colon_pos == -1 } {
        ns_log Error "datasource contains no \":\"? datasource = $datasource"
        return ""
    }
    set first_colon_pos [string first ":" $datasource]

    if { $first_colon_pos == $last_colon_pos || ($last_colon_pos - $first_colon_pos) == 1 } {
        # No port specified
        return ""
    }

    return [string range $datasource $first_colon_pos+1 $last_colon_pos-1]
}


ad_proc -public db_get_database {{-dbn ""}} {
    <strong>PostgreSQL only.</strong>

    <p>
    @return the database name from the first database pool.  It assumes the
    datasource is properly formatted since we've already verified that we
    can connect to the pool.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    set pool [lindex [db_available_pools $dbn] 0]
    set datasource [ns_config "ns/db/pool/$pool" DataSource]
    set last_colon_pos [string last ":" $datasource]
    if { $last_colon_pos == -1 } {
        ns_log Error "datasource contains no \":\"? datasource = $datasource"
        return ""
    }
    return [string range $datasource $last_colon_pos+1 end]
}


ad_proc -public db_get_dbhost {
    {-dbn ""}
} {
    <strong>PostgreSQL only.</strong>

    <p>
    @return the name of the database host from the first database pool.
    It assumes the datasource is properly formatted since we've already
    verified that we can connect to the pool.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    set pool [lindex [db_available_pools $dbn] 0]
    set datasource [ns_config "ns/db/pool/$pool" DataSource]
    set first_colon_pos [string first ":" $datasource]
    if { $first_colon_pos == -1 } {
        ns_log Error "datasource contains no \":\"? datasource = $datasource"
        return ""
    }
    return [string range $datasource 0 $first_colon_pos-1]
}

ad_proc -public db_source_sql_file {
    {-dbn ""}
    {-callback apm_ns_write_callback}
    file
} {
    Sources a SQL file into Oracle (SQL*Plus format file) or
    PostgreSQL (psql format file).

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    set proc_name {db_source_sql_file}
    set driverkey [db_driverkey $dbn]

    switch -- $driverkey {

        oracle {
            set user_pass [db_get_sql_user -dbn $dbn]
            cd [file dirname $file]
            set fp [open "|[file join $::env(ORACLE_HOME) bin sqlplus] $user_pass @$file" "r+"]
            fconfigure $fp -buffering line
            puts $fp "exit"

            while { [gets $fp line] >= 0 } {
                # Don't bother writing out lines which are purely whitespace.
                if { ![string is space $line] } {
                    apm_callback_and_log $callback "[ns_quotehtml $line]\n"
                }
            }
            close $fp
        }

        postgresql {
            set file_name [file tail $file]

            set pguser [db_get_username]
            if { $pguser ne "" } {
                set pguser "-U $pguser"
            }

            set pgport [db_get_port]
            if { $pgport ne "" } {
                set pgport "-p $pgport"
            }

            set pgpass [db_get_password]
            if { $pgpass ne "" } {
                set pgpass "<<$pgpass"
            }

            # DRB: Submitted patch was in error - the driver opens a -h hostname connection
            # unless the hostname is localhost.   We need to do the same here.  The submitted
            # patch checked for a blank hostname, which fails in the driver.  Arguably the
            # driver's wrong but a lot of non-OpenACS folks use it, and even though I'm the
            # maintainer we shouldn't break existing code over such trivialities...
            # GN: windows requires $pghost "-h ..."

            if { ([db_get_dbhost] eq "localhost" || [db_get_dbhost] eq "")
                 && $::tcl_platform(platform) ne "windows"
             } {
                set pghost ""
            } else {
                set pghost "-h [db_get_dbhost]"
            }

            set errno [catch {
                cd [file dirname $file]
                set fp [open "|[file join [db_get_pgbin] psql] $pghost $pgport $pguser -f $file [db_get_database] $pgpass" "r"]
            } errorMsg]

            if {$errno > 0} {
                set error_found 1
                set error_lines $errorMsg
            } else {
                while { [gets $fp line] >= 0 } {
                    # Don't bother writing out lines which are purely whitespace.
                    if { ![string is space $line] } {
                        apm_callback_and_log $callback "[ns_quotehtml $line]\n"
                    }
                }

                # PSQL dumps errors and notice information on stderr, and has no option to turn
                # this off.  So we have to chug through the "error" lines looking for those that
                # really signal an error.

                set errno [ catch {
                    close $fp
                } error]

                if { $errno == 2 } {
                    return $error
                }

                # Just filter out the "NOTICE" lines, so we get the stack dump along with real
                # ERRORs.  This could be done with a couple of opaque-looking regexps...

                set error_found 0
                foreach line [split $error "\n"] {
                    if { [string first NOTICE $line] == -1 } {
                        append error_lines "$line\n"
                        set error_found [expr { $error_found
                                                || [string first ERROR $line] != -1
                                                || [string first FATAL $line] != -1 } ]
                    }
                }
            }

            if { $error_found } {
                return -code error -errorinfo $error_lines -errorcode $::errorCode $error_lines
            }

        }

        nsodbc {
            error "$proc_name is not supported for this database."
        }
        default {
            error "$proc_name is not supported for this database."
        }
    }
}

ad_proc -public db_load_sql_data {
    {-dbn ""}
    {-callback apm_ns_write_callback}
    file
} {
    Loads a CSV formatted file into a table using PostgreSQL's COPY command or
    Oracle's SQL*Loader utility.  The file name format consists of a sequence
    number used to control the order in which tables are loaded, and the table
    name with "-" replacing "_".  This is a bit of a kludge but greatly speeds
    the loading of large amounts of data, such as is done when various "ref-*"
    packages are installed.

    @param dbn The database name to use.  If empty_string, uses the default database.
    @param file Filename in the format dd-table-name.ctl where 'dd' is a sequence number
    used to control the order in which data is loaded.  This file is an
    RDBMS-specific data loader control file.

} {

    switch [db_driverkey $dbn] {

        oracle {
            set user_pass [db_get_sql_user -dbn $dbn]
            set tmpnam [ad_tmpnam]

            set fd [open $file r]
            set file_contents [read $fd]
            close $fd

            set file_contents [subst $file_contents]

            set fd1 [open "${tmpnam}.ctl" w]
            puts $fd1 $file_contents
            close $fd1

            cd [file dirname $file]

            set fd [open "|[file join $::env(ORACLE_HOME) bin sqlldr] userid=$user_pass control=$tmpnam" "r"]

            while { [gets $fd line] >= 0 } {
                # Don't bother writing out lines which are purely whitespace.
                if { ![string is space $line] } {
                    apm_callback_and_log $callback "[ns_quotehtml $line]\n"
                }
            }
            close $fd
        }

        postgresql {
            set pguser [db_get_username]
            if { $pguser ne "" } {
                set pguser "-U $pguser"
            }

            set pgport [db_get_port]
            if { $pgport ne "" } {
                set pgport "-p $pgport"
            }

            set pgpass [db_get_password]
            if { $pgpass ne "" } {
                set pgpass "<<$pgpass"
            }

            if { [db_get_dbhost] eq "localhost" || [db_get_dbhost] eq "" } {
                set pghost ""
            } else {
                set pghost "-h [db_get_dbhost]"
            }

            set fd [open $file r]
            set copy_command [subst -nobackslashes [read $fd]]
            close $fd
            set copy_file [ns_mktemp /tmp/psql-copyfile-XXXXXX]
            set fd [open $copy_file "CREAT EXCL WRONLY" 0600]
            puts $fd $copy_command
            close $fd

            if { $::tcl_platform(platform) eq "windows" } {
                set fp [open "|[file join [db_get_pgbin] psql] -f $copy_file $pghost $pgport $pguser [db_get_database]" "r"]
            } else {
                set fp [open "|[file join [db_get_pgbin] psql] -f $copy_file $pghost $pgport $pguser [db_get_database] $pgpass" "r"]
            }

            while { [gets $fp line] >= 0 } {
                # Don't bother writing out lines which are purely whitespace.
                if { ![string is space $line] } {
                    apm_callback_and_log $callback "[ns_quotehtml $line]\n"
                }
            }

            # PSQL dumps errors and notice information on stderr, and has no option to turn
            # this off.  So we have to chug through the "error" lines looking for those that
            # really signal an error.

            set errno [ catch {
                close $fp
            } error]

            # remove the copy file.
            file delete -force -- $copy_file

            if { $errno == 2 } {
                return $error
            }

            # Just filter out the "NOTICE" lines, so we get the stack dump along with real
            # ERRORs.  This could be done with a couple of opaque-looking regexps...

            set error_found 0
            foreach line [split $error "\n"] {
                if { [string first NOTICE $line] == -1 } {
                    append error_lines "$line\n"
                    set error_found [expr { $error_found
                                            || [string first ERROR $line] != -1
                                            || [string first FATAL $line] != -1 } ]
                }
            }

            if { $error_found } {
                return -code error -errorinfo $error_lines -errorcode $::errorCode $error_lines
            }

        }

        nsodbc {
            error "db_load_sql_data is not supported for this database."
        }
        default {
            error "db_load_sql_data is not supported for this database."
        }
    }
}

ad_proc -public db_source_sqlj_file {
    {-dbn ""}
    {-callback apm_ns_write_callback}
    file
} {
    <strong>Oracle only.</strong>
    <p>
    Sources a SQLJ file using loadjava.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    set user_pass [db_get_sql_user -dbn $dbn]
    set fp [open "|[file join $::env(ORACLE_HOME) bin loadjava] -verbose -user $user_pass $file" "r"]

    # Despite the fact that this works, the text does not get written to the stream.
    # The output is generated as an error when you attempt to close the input stream as
    # done below.
    while { [gets $fp line] >= 0 } {
        # Don't bother writing out lines which are purely whitespace.
        if { ![string is space $line] } {
            apm_callback_and_log $callback "[ns_quotehtml $line]\n"
        }
    }
    if { [catch {
        close $fp
    } errmsg] } {
        apm_callback_and_log $callback "[ns_quotehtml $errmsg]\n"
    }
}


ad_proc -public db_tables {
    -pattern
    {-dbn ""}
} {
    @return a Tcl list of all the tables owned by the connected user.

    @param pattern Will be used as LIKE 'pattern%' to limit the number of tables returned.

    @param dbn The database name to use.  If empty_string, uses the default database.

    @author Don Baccus (dhogaza@pacifier.com)
    @author Lars Pind (lars@pinds.com)

    @change-log yon@arsdigita.com 20000711 changed to return lower case table names
} {
    set proc_name {db_tables}
    set driverkey [db_driverkey $dbn]

    switch -- $driverkey {
        oracle {
            set sql_table_names_with_pattern {
                select lower(table_name) as table_name
                from user_tables
                where table_name like upper(:pattern)
            }
            set sql_table_names_without_pattern {
                select lower(table_name) as table_name
                from user_tables
            }
        }

        postgresql {
            set sql_table_names_with_pattern {
                select relname as table_name
                from pg_class
                where relname like lower(:pattern) and
                relname !~ '^pg_' and relkind = 'r'
            }
            set sql_table_names_without_pattern {
                select relname as table_name
                from pg_class
                where relname !~ '^pg_' and relkind = 'r'
            }
        }

        nsodbc -
        default {
            error "$proc_name is not supported for this database."
        }
    }

    set tables [list]
    if { [info exists pattern] } {
        db_foreach -dbn $dbn table_names_with_pattern \
            $sql_table_names_with_pattern {
                lappend tables $table_name
            }
    } else {
        db_foreach -dbn $dbn table_names_without_pattern \
            $sql_table_names_without_pattern {
                lappend tables $table_name
            }
    }

    return $tables
}


ad_proc -public db_table_exists {{-dbn ""} table_name } {
    @return 1 if a table with the specified name exists in the database, otherwise 0.

    @param dbn The database name to use.  If empty_string, uses the default database.

    @author Don Baccus (dhogaza@pacifier.com)
    @author Lars Pind (lars@pinds.com)
} {
    set proc_name {db_table_exists}
    set driverkey [db_driverkey $dbn]

    switch -- $driverkey {
        oracle {
            set n_rows [db_string -dbn $dbn table_count {
                select count(*) from user_tables
                where table_name = upper(:table_name)
            }]
        }

        postgresql {
            set n_rows [db_string -dbn $dbn table_count {
                select count(*) from pg_class
                where relname = lower(:table_name) and
                relname !~ '^pg_' and relkind = 'r'
            }]
        }

        nsodbc -
        default {
            error "$proc_name is not supported for this database."
        }
    }

    return $n_rows
}


ad_proc -public db_columns {{-dbn ""} table_name } {
    @return a Tcl list of all the columns in the table with the given name.

    @param dbn The database name to use.  If empty_string, uses the default database.

    @author Lars Pind (lars@pinds.com)

    @change-log yon@arsdigita.com 20000711 changed to return lower case column names
} {
    set columns [list]

    # Works for both Oracle and PostgreSQL:
    db_foreach -dbn $dbn table_column_names {
        select lower(column_name) as column_name
        from user_tab_columns
        where table_name = upper(:table_name)
    } {
        lappend columns $column_name
    }

    return $columns
}


ad_proc -public db_column_exists {{-dbn ""} table_name column_name } {
    @return 1 if the row exists in the table, 0 if not.

    @param dbn The database name to use.  If empty_string, uses the default database.

    @author Lars Pind (lars@pinds.com)
} {
    set columns [list]

    # Works for both Oracle and PostgreSQL:
    set n_rows [db_string -dbn $dbn column_exists {
        select count(*)
        from user_tab_columns
        where table_name = upper(:table_name)
        and column_name = upper(:column_name)
    }]

    return [expr {$n_rows > 0}]
}


ad_proc -public db_column_type {{-dbn ""} table_name column_name } {

    @return the Oracle Data Type for the specified column.
    @return -1 if the table or column doesn't exist.

    @param dbn The database name to use.  If empty_string, uses the default database.

    @author Yon Feldman (yon@arsdigita.com)

    @change-log 10 July, 2000: changed to return error
    if column name doesn't exist
    (mdettinger@arsdigita.com)

    @change-log 11 July, 2000: changed to return lower case data types
    (yon@arsdigita.com)

    @change-log 11 July, 2000: changed to return error using the db_string default clause
    (yon@arsdigita.com)

} {
    # Works for both Oracle and PostgreSQL:
    return [db_string -dbn $dbn column_type_select "
    select data_type as data_type
      from user_tab_columns
     where upper(table_name) = upper(:table_name)
       and upper(column_name) = upper(:column_name)
    " -default "-1"]
}


ad_proc -public ad_column_type {{-dbn ""} table_name column_name } {

    @return 'numeric' for number type columns, 'text' otherwise
    Throws an error if no such column exists.

    @param dbn The database name to use.  If empty_string, uses the default database.

    @author Yon Feldman (yon@arsdigita.com)

} {
    set column_type [db_column_type -dbn $dbn $table_name $column_name]

    if { $column_type == -1 } {
        return "Either table $table_name doesn't exist or column $column_name doesn't exist"
    } elseif {$column_type ne "NUMBER"  } {
        return "numeric"
    } else {
        return "text"
    }
}


ad_proc -public db_write_clob {{-dbn ""} statement_name sql args } {
    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    ad_arg_parser { bind } $args
    set proc_name {db_write_clob}
    set driverkey [db_driverkey $dbn]

    # TODO: Below, is db_qd_get_fullname necessary?  Why this
    # difference between Oracle and Postgres code?
    # --atp@piskorski.com, 2003/04/09 10:00 EDT

    switch -- $driverkey {
        oracle {
            set full_statement_name [db_qd_get_fullname $statement_name]
            db_with_handle -dbn $dbn db {
                db_exec write_clob $db $full_statement_name $sql
            }
        }

        postgresql {
            db_with_handle -dbn $dbn db {
                db_exec write_clob $db $statement_name $sql
            }
        }

        nsodbc -
        default {
            error "$proc_name is not supported for this database."
        }
    }
}


ad_proc -public db_write_blob {{-dbn ""} statement_name sql args } {
    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    ad_arg_parser { bind } $args
    set full_statement_name [db_qd_get_fullname $statement_name]
    db_with_handle -dbn $dbn db {
        db_exec_lob write_blob $db $full_statement_name $sql
    }
}


ad_proc -public db_blob_get_file {{-dbn ""} statement_name sql args } {
    @param dbn The database name to use.  If empty_string, uses the default database.

    <p>
    <strong>TODO:</strong>
    This proc should probably be changed to take a final
    <code>file</code> argument, <em>only</em>, rather than the current
    <code>args</code> variable length argument list.  Currently, it is
    called only 4 places in OpenACS, and each place <code>args</code>,
    if used at all, is always "<code>-file $file</code>".  However,
    such a change might break custom code...  I'm not sure.
    --atp@piskorski.com, 2003/04/09 11:39 EDT

} {
    ad_arg_parser { bind file args } $args
    set proc_name {db_blob_get_file}
    set driverkey [db_driverkey $dbn]

    set full_statement_name [db_qd_get_fullname $statement_name]

    switch -- $driverkey {
        oracle {
            db_with_handle -dbn $dbn db {
                db_exec_lob blob_get_file $db $full_statement_name $sql $file
            }
        }

        postgresql {
            db_with_handle -dbn $dbn db {
                db_exec_lob blob_select_file $db $full_statement_name $sql $file
            }
        }

        nsodbc -
        default {
            error "$proc_name is not supported for this database."
        }
    }
}


ad_proc -public db_blob_get {{-dbn ""} statement_name sql args } {
    <strong>PostgreSQL only.</strong>

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    ad_arg_parser { bind } $args
    set proc_name {db_blob_get}
    set driverkey [db_driverkey $dbn]

    switch -- $driverkey {

        postgresql {
            set full_statement_name [db_qd_get_fullname $statement_name]
            db_with_handle -dbn $dbn db {
                set data [db_exec_lob blob_get $db $full_statement_name $sql]
            }
            return $data
        }

        oracle {
            set pre_sql $sql
            set full_statement_name [db_qd_get_fullname $statement_name]
            set sql [db_qd_replace_sql $full_statement_name $pre_sql]

            # insert Tcl variable values (borrowed from Dan W - olah)
            if {$sql ne $pre_sql } {
                set sql [uplevel 2 [list subst -nobackslashes $sql]]
            }

            set data [db_string dummy_statement_name $sql]
            return $data
        }

        nsodbc -
        default {
            error "$proc_name is not supported for this database."
        }
    }
}


ad_proc -private db_exec_lob {
    {-ulevel 2}
    type
    db
    statement_name
    pre_sql
    {file ""}
} {
    A helper procedure to execute a SQL statement, potentially binding
    depending on the value of the $bind variable in the calling environment
    (if set).
} {
    set proc_name {db_exec_lob}
    set driverkey [db_driverkey -handle_p 1 $db]

    # Note: db_exec_lob is marked as private and in the entire
    # toolkit, is ONLY called from a few other procs defined in this
    # same file.  So we definitely could change it to take a -dbn
    # switch and remove the passed in db handle altogether, and call
    # 'db_driverkey -dbn' rather than 'db_driverkey -handle'.  But,
    # db_exec NEEDS 'db_driverkey -handle', so we might as well use it
    # here too.  --atp@piskorski.com, 2003/04/09 12:13 EDT

    # TODO: Using this as a wrapper for the separate _oracle and
    # _postgresql versions of this proc is ugly.  But also simplest
    # and safest at this point, as it let me change as little as
    # possible of those two relatively complex procs.
    # --atp@piskorski.com, 2003/04/09 11:55 EDT

    switch -- $driverkey {
        oracle {
            set which_proc {db_exec_lob_oracle}
        }
        postgresql {
            set which_proc {db_exec_lob_postgresql}
        }

        nsodbc -
        default {
            error "$proc_name is not supported for this database."
        }
    }

    ns_log Debug "$proc_name: $which_proc -ulevel [expr {$ulevel +1}] $type $db $statement_name $pre_sql $file"
    return [$which_proc -ulevel [expr {$ulevel +1}] $type $db $statement_name $pre_sql $file]
}


ad_proc -private db_exec_lob_oracle {
    {-ulevel 2}
    type
    db
    statement_name
    pre_sql
    {file ""}
} {
    A helper procedure to execute a SQL statement, potentially binding
    depending on the value of the $bind variable in the calling environment
    (if set).
} {
    set start_time [expr {[clock clicks -microseconds]/1000.0}]

    set sql [db_qd_replace_sql $statement_name $pre_sql]

    # insert Tcl variable values (OpenACS - Dan)
    if {$sql ne $pre_sql } {
        set sql [uplevel $ulevel [list subst -nobackslashes $sql]]
    }

    set file_storage_p 0
    upvar $ulevel storage_type storage_type

    if {[info exists storage_type] && $storage_type eq "file"} {
        set file_storage_p 1
        set original_type $type
        set qtype 1row
        ns_log Debug "db_exec_lob: file storage in use"
    } else {
        set qtype $type
        ns_log Debug "db_exec_lob: blob storage in use"
    }

    set errno [catch {
        upvar bind bind

        # Below, note that 'ns_ora blob_get_file' takes 3 parameters,
        # while 'ns_ora write_blob' takes only 2.  So if file is empty
        # string (which it always will/should be for $qtype
        # write_blob), we must not pass any 3rd parameter to the
        # ns_ora command: --atp@piskorski.com, 2003/04/09 15:10 EDT

        if { [info exists bind] && [llength $bind] != 0 } {
            if { [llength $bind] == 1 } {
                if { $file eq "" } {
                    # gn: not sure, why the eval was ever needed (4 times)
                    set selection [eval [list ns_ora $qtype $db -bind $bind $sql]]
                } else {
                    set selection [eval [list ns_ora $qtype $db -bind $bind $sql $file]]
                }

            } else {
                set bind_vars [ns_set create]
                foreach { name value } $bind {
                    ns_set put $bind_vars $name $value
                }
                if { $file eq "" } {
                    set selection [eval [list ns_ora $qtype $db -bind $bind_vars $sql]]
                } else {
                    set selection [eval [list ns_ora $qtype $db -bind $bind_vars $sql $file]]
                }
            }

        } else {
            if { $file eq "" } {
                set selection [uplevel $ulevel [list ns_ora $qtype $db $sql]]
            } else {
                set selection [uplevel $ulevel [list ns_ora $qtype $db $sql $file]]
            }
        }

        if {$file_storage_p} {
            set content [ns_set value $selection 0]
            for {set i 0} {$i < [ns_set size $selection]} {incr i} {
                set name [ns_set key $selection $i]
                if {$name eq "content"} {
                    set content [ns_set value $selection $i]
                }
            }

            switch -- $original_type {

                blob_get_file {
                    if {[file exists $content]} {
                        file copy -- $content $file
                        return $selection
                    } else {
                        error "file: $content doesn't exist"
                    }
                }

                write_blob {

                    if {[file exists $content]} {
                        set ofp [open $content r]
                        fconfigure $ofp -encoding binary
                        ns_writefp $ofp
                        close $ofp
                        return $selection
                    } else {
                        error "file: $content doesn't exist"
                    }
                }
            }
        } else {
            return $selection
        }

    } error]

    ds_collect_db_call $db $type $statement_name $sql $start_time $errno $error
    if { $errno == 2 } {
        return $error
    }

    return -code $errno -errorinfo $::errorInfo -errorcode $::errorCode $error
}


ad_proc -private db_exec_lob_postgresql {
    {-ulevel 2}
    type
    db
    statement_name
    pre_sql
    {file ""}
} {
    A helper procedure to execute a SQL statement, potentially binding
    depending on the value of the $bind variable in the calling environment
    (if set).

    Low level replacement for db_exec which emulates blob handling.

} {
    set start_time [expr {[clock clicks -microseconds]/1000.0}]

    # Query Dispatcher (OpenACS - ben)
    set sql [db_qd_replace_sql $statement_name $pre_sql]

    # insert Tcl variable values (OpenACS - Dan)
    if {$sql ne $pre_sql } {
        set sql [uplevel $ulevel [list subst -nobackslashes $sql]]
    }
    # create a function definition statement for the inline code
    # binding is emulated in tcl. (OpenACS - Dan)

    set errno [catch {
        upvar bind bind
        if { [info exists bind] && [llength $bind] != 0 } {
            if { [llength $bind] == 1 } {
                set bind_vars [list]
                set len [ns_set size $bind]
                for {set i 0} {$i < $len} {incr i} {
                    lappend bind_vars [ns_set key $bind $i] \
                        [ns_set value $bind $i]
                }
                set lob_sql [db_bind_var_substitution $sql $bind_vars]
            } else {
                set lob_sql [db_bind_var_substitution $sql $bind]
            }
        } else {
            set lob_sql [uplevel $ulevel [list db_bind_var_substitution $sql]]
        }

        # get the content - asssume it is in column 0, or optionally it can
        # be returned as "content" with the storage type indicated by the
        # "storage_type" column.

        set selection [ns_db 1row $db $lob_sql]
        set content [ns_set value $selection 0]
        for {set i 0} {$i < [ns_set size $selection]} {incr i} {
            set name [ns_set key $selection $i]
            if {$name eq "storage_type"} {
                set storage_type [ns_set value $selection $i]
            } elseif {$name eq "content"} {
                set content [ns_set value $selection $i]
            }
        }

        # this is an ugly hack, but it allows content to be written
        # to a file/connection if it is stored as a lob or if it is
        # stored in the content-repository as a file. (DanW - Openacs)

        switch -- $type {

            blob_get {

                if {[info exists storage_type]} {
                    switch -- $storage_type {
                        file {
                            if {[file exists $content]} {
                                set ifp [open $content r]

                                # DRB: this could be made faster by setting the buffersize
                                # to the size of the file, but for very large files allocating
                                # that much more memory on top of that needed by Tcl for storage
                                # of the data might not be wise.

                                fconfigure $ifp -translation binary

                                set data [read $ifp]
                                close $ifp
                                return $data
                            } else {
                                error "file: $content doesn't exist"
                            }
                        }

                        lob {
                            if {[regexp {^[0-9]+$} $content match]} {
                                return [ns_pg blob_get $db $content]
                            } else {
                                error "invalid lob_id: should be an integer"
                            }
                        }

                        default {
                            error "invalid storage type"
                        }
                    }
                } elseif {[file exists $content]} {
                    set ifp [open $content r]
                    fconfigure $ifp -translation binary
                    set data [read $ifp]
                    close $ifp
                    return $data
                } elseif {[regexp {^[0-9]+$} $content match]} {
                    return [ns_pg blob_get $db $content]
                } else {
                    error "invalid query"
                }
            }

            blob_select_file {

                if {[info exists storage_type]} {
                    switch -- $storage_type {
                        file {
                            if {[file exists $content]} {
                                file copy -- $content $file
                            } else {
                                error "file: $content doesn't exist"
                            }
                        }

                        lob {
                            if {[regexp {^[0-9]+$} $content match]} {
                                ns_pg blob_select_file $db $content $file
                            } else {
                                error "invalid lob_id: should be an integer"
                            }
                        }

                        default {
                            error "invalid storage type"
                        }
                    }
                } elseif {[file exists $content]} {
                    file copy -- $content $file
                } elseif {[regexp {^[0-9]+$} $content match]} {
                    ns_pg blob_select_file $db $content $file
                } else {
                    error "invalid query"

                    # TODO: Page /file-storage/download-archive/index
                    # fails here on cvs head both before and after my
                    # mult-db db_* API work, I don't know why.  See bug:
                    #   http://openacs.org/bugtracker/openacs/com/file-storage/bug?bug%5fnumber=427
                    # --atp@piskorski.com, 2003/04/09 18:04 EDT
                }
            }

            write_blob {

                if {[info exists storage_type]} {
                    switch -- $storage_type {
                        file {
                            if {[file exists $content]} {
                                set ofp [open $content r]
                                fconfigure $ofp -encoding binary
                                ns_writefp $ofp
                                close $ofp
                            } else {
                                error "file: $content doesn't exist"
                            }
                        }

                        text {
                            ns_write $content
                        }

                        lob {
                            if {[regexp {^[0-9]+$} $content match]} {
                                ns_pg blob_write $db $content
                            } else {
                                error "invalid lob_id: should be an integer"
                            }
                        }

                        default {
                            error "invalid storage type"
                        }
                    }
                } elseif {[file exists $content]} {
                    set ofp [open $content r]
                    fconfigure $ofp -encoding binary
                    ns_writefp $ofp
                    close $ofp
                } elseif {[regexp {^[0-9]+$} $content match]} {
                    ns_pg blob_write $db $content
                } else {
                    ns_write $content
                }
            }
        }

        return

    } error]

    set errinfo $::errorInfo
    set errcode $::errorCode

    ds_collect_db_call $db 0or1row $statement_name $sql $start_time $errno $error

    if { $errno == 2 } {
        return $error
    }

    return -code $errno -errorinfo $errinfo -errorcode $errcode $error
}

ad_proc -public db_flush_cache {
    {-cache_key_pattern *}
    {-cache_pool db_cache_pool}
} {

    Flush the given cache of entries with keys that match the given pattern.

    @param cache_key_pattern The "string match" pattern used to flush keys (default is to flush all entries)
    @param cache_pool The pool to flush (default is to flush db_cache_pool)
    @author Don Baccus (dhogasa@pacifier.com)

} {
    #
    # If the key pattern has meta characters, iterate over the entries.
    # Otherwise, make a direct lookup, without retrieving the all keys
    # from the cache, which can cause large mutex lock times.
    #
    if {[regexp {[*\]\[]} $cache_key_pattern]} {
        foreach key [ns_cache names $cache_pool $cache_key_pattern] {
            ns_cache flush $cache_pool $key
        }
    } else {
        ns_cache flush $cache_pool $cache_key_pattern
    }
}

ad_proc -public db_bounce_pools {{-dbn ""}} {
    @return Call ns_db bouncepool on all pools for the named database.
    @param dbn The database name to use.  Uses the default database if not supplied.
} {
    foreach pool [db_available_pools $dbn] {
        ns_db bouncepool $pool
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
