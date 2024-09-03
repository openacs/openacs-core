ad_library {

    Low level interface for defining the basic classes for the DB interface.

    @author Gustaf Neumann
    @creation-date 2022-02-07
}


namespace eval ::acs {}
namespace eval ::acs::db {
    #
    # The details of the communication with the database server
    # (backend) is determined by the NaviServer/AOLserver database
    # driver and by the backend, which implies a different SQL dialect
    # (PostgreSQL or Oracle).
    #
    ::nx::Class create ::acs::db::SQL

    ##########################################################################
    #
    # PostgreSQL specific methods
    #
    ##########################################################################

    ::nx::Class create ::acs::db::postgresql -superclass ::acs::db::SQL

    ##########################################################################
    #
    # Oracle specific methods
    #
    ##########################################################################

    ::nx::Class create ::acs::db::oracle -superclass ::acs::db::SQL

    ##########################################################################
    #
    # Database Driver
    #
    # Abstract from the Tcl interface that the drivers are offering to
    # issue SQL commands and to perform profiling.
    #

    ::nx::Class create ::acs::db::Driver {
        :property backend
        :property driver
        :property {dbn ""}
        #
        # Define the "abstract" API (here via protected methods)
        #
        :method sets           {{-dbn ""} {-bind ""} -prepare qn sql} {}
        :method 0or1row        {{-dbn ""} {-bind ""} -prepare qn sql} {}
        :method 1row           {{-dbn ""} {-bind ""} -prepare qn sql} {}
        :method get_value      {{-dbn ""} {-bind ""} -prepare qn sql {default ""}} {}
        :method list_of_lists  {{-dbn ""} {-bind ""} -prepare qn sql} {}
        :method list           {{-dbn ""} {-bind ""} -prepare qn sql} {}
        :method dml            {{-dbn ""} {-bind ""} -prepare qn sql} {}
        :method foreach        {{-dbn ""} {-bind ""} -prepare qn sql {script}} {}
        :method row_lock       {{-dbn ""} {-bind ""} {-for "UPDATE"} -prepare qn sql} {}
        :method transaction    {{-dbn ""} script args} {}
        :method ds             {onOff} {}
        :method prepare        {-handle {-argtypes ""} sql} {}

        :public method qn {query_name} {
            #
            # Return fully qualified query name as used in OpenACS.
            #
            set prefix [expr {[info level] < 2 ? "topLevel" : [:uplevel {info level 0}]}]
            return "dbqd.$prefix.$query_name"
        }

        :method get_sql {{-dbn ""} qn} {
            set full_statement_name [db_qd_get_fullname $qn 2]
            set full_query [db_qd_fetch $full_statement_name $dbn]
            set sql [db_fullquery_get_querytext $full_query]
            #
            # todo: missing handling of substitution rules as
            # introduced with oacs-5-10
            #
            :uplevel 2 [list subst $sql]
        }

        :method map_default_dbn {dbn} {
            return [expr {$dbn eq "" && ${:dbn} ne "" ? ${:dbn} : $dbn}]
        }
    }

    #
    # Driver specific and Driver/backend specific hooks
    #
    ::nx::Class create ::acs::db::nsdb             -superclasses ::acs::db::Driver
    ::nx::Class create ::acs::db::nsdb-postgresql  -superclasses {::acs::db::nsdb ::acs::db::postgresql} {
        #
        # PostgreSQL backend for nsdb driver
        #
    }
    ::nx::Class create ::acs::db::nsdb-oracle      -superclasses {::acs::db::nsdb ::acs::db::oracle} {
        #
        # Oracle backend for nsdb driver
        #
    }

    ::nx::Class create ::acs::db::nsdbi            -superclasses ::acs::db::Driver
    ::nx::Class create ::acs::db::nsdbi-postgresql -superclasses {::acs::db::nsdbi ::acs::db::postgresql} {
        #
        # PostgreSQL backend for nsdbi driver
        #
    }
    #
    # Preliminary list of functions (to be extended/refined)
    #
    ::acs::db::nsdb public method list_of_lists {{-dbn ""} {-bind ""} -prepare qn sql} {
        set bindOpt [expr {$bind ne "" ? [list -bind $bind] : ""}]
        if {$sql eq ""} {
            set qn [uplevel [list [self] qn $qn]]
        }
        return [:uplevel [list ::db_list_of_lists -dbn [:map_default_dbn $dbn] $qn $sql {*}$bindOpt]]
    }

    ::acs::db::nsdb public method list {{-dbn ""} {-bind ""} -prepare qn sql} {
        set bindOpt [expr {$bind ne "" ? [list -bind $bind] : ""}]
        if {$sql eq ""} {
            set qn [uplevel [list [self] qn $qn]]
        }
        uplevel [list ::db_list -dbn [:map_default_dbn $dbn] $qn $sql {*}$bindOpt]
    }

    ::acs::db::nsdbi public method list_of_lists {{-dbn ""} {-bind ""} -prepare qn sql} {
        if {$sql eq ""} {
            set sql [:get_sql $qn]
        }
        set dbn [:map_default_dbn $dbn]
        return [:uplevel [list ::dbi_rows \
                              {*}[expr {$dbn ne "" ? [list -db $dbn] : ""}] \
                              {*}[expr {$bind ne "" ? [list -bind $bind] : ""}] \
                              -result lists -max 1000000 -- $sql]]
    }

    ::acs::db::nsdbi public method list {{-dbn ""} {-bind ""} -prepare qn sql} {
        if {$sql eq ""} {
            set sql [:get_sql $qn]
        }
        set dbn [:map_default_dbn $dbn]
        set flat [:uplevel [list ::dbi_rows -columns __columns \
                                {*}[expr {$dbn ne "" ? [list -db $dbn] : ""}] \
                                {*}[expr {$bind ne "" ? [list -bind $bind] : ""}] \
                                -- $sql]]
        if {[:uplevel {llength $__columns}] > 1} {
            error "query is returning more than one column"
        }
        return $flat
    }

    ##########################################################################
    #
    # Depending on the configured and available driver, select the SQL
    # interface.  For the time being, we use just a single DB backend
    # per server and therefore a single database connection object,
    # namely ::acs::dc (short for database connection). One can
    # certainly define for multiple backends and drivers multiple such
    # interface objects.
    #
    ##########################################################################

    ad_proc -private ::acs::db::require_dc {
        {-backend ""}
        {-driver ""}
        {-name "::acs::dc"}
    } {

        Select the driver based on the specified argument (either DB
        or DBI) or based on the defaults for the configuration.  This
        function can be used to switch the driver as well dynamically.

        @param driver "nsdb" or "nsdbi" or empty. When empty, assume
            "nsdb" unless "preferdbi" is set.
        @param backend "postgresql" or "oracle" or empty. When empty,
            determine backed from db_driverkey.
        @param name of the interface object (defaults to "::acs::dc")

        @return database interface object

    } {
        if {$backend eq ""} {
            set backend [db_driverkey ""]
        }
        if {$driver eq ""} {
            set driver nsdb
            if {[info exists ::acs::preferdbi]} {
                set driver nsdbi
            }
        }

        return [::acs::db::$driver-$backend create $name \
                    -backend $backend \
                    -driver $driver]
    }

    #
    # Currently, the call to "::acs::db::require_dc" is performed at
    # load time before ::ds_collect_db_call is defined. We could
    # probably define it later. For the time being, we define a dummy
    # placeolder in case it is not yet defined.
    #
    if {[info commands "::ds_collect_db_call"] eq ""} {
        proc ::ds_collect_db_call args {}
    }
    ::acs::db::require_dc

}

#
# Whenever this file is loaded, load as well the dependent
# subcomponents.
#
foreach file [lsort [glob $::acs::rootdir/packages/acs-tcl/tcl/acs-db-1*-procs.tcl]] {
    ns_log notice "... sourcing dependent: $file"
    source $file
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
