ad_library {

    @author rhs@mit.edu
    @creation-date 2000-09-09
    @cvs-id $Id$
}

if {$::tcl_version eq "8.5"} {
    #
    # In Tcl 8.5, "::try" was not yet a built-in of Tcl
    #
    package require try
}
if {[namespace which ::try] eq ""} {
    error "This version of OpenACS requires the ::try command (built-in in 8.6+, package for 8.5"
}

ad_proc -public ad_raise {exception {value ""}} {
    Raise an exception.

    If you use this I will kill you.

    Note: despite the warning, this proc has been used in
    acs-authentication.

    @author rhs@mit.edu
    @creation-date 2000-09-09
} {
    return -code error -errorcode [list "AD" "EXCEPTION" $exception] $value
}

ad_proc -public ad_exception {errorCode} {
    @author gustaf.neumann@wu-wien.ac.at
    @creation-date 2015-12-31

    Check if the exception was caused by ad_raise (i.e. was an OpenACS
    exception)

    @return ad_exception value or empty, in case the exception had other causes
} {
    lassign $errorCode flag type value
    if {$flag eq "AD" && $type eq "EXCEPTION"} {
        return $value
    }
    return ""
}

if {$::tcl_version >= 8.6} {
    #
    # Tcl 8.6 (or newer) variant of ad_try
    #

    ad_proc ad_try {
        {-auto_abort:boolean true}
        body
        args
    } {

        Generic code for OpenACS to handle exceptions and traps based on
        Tcl's primitives. This implementation is a slight generalization
        of the Tcl 8.6 built-in ::try, which handles ad_script_aborts
        automatically.

        The command "ad_try" should replace the various exception handling
        constructs such as "catch", which tend to swallow often error
        conditions, making debugging unnecessarily hard.  It will make
        "with_finally" and "with_catch" obsolete, which should be marked
        as deprecated in the not-to-far future.

        @see with_finally
        @see with_catch

    } {
        #
        # Per default, ad_script_abort exceptions are automatically passed
        # through the higher handlers, aborting all execution levels. Only
        # the top-level processor should handle these cases (probably
        # silently).
        #
        set extraTraps {}
        if {$auto_abort_p} {
            #
            # Add silent handling of "ad_script_abort" to
            # the traps.
            #
            lappend extraTraps \
                trap {AD EXCEPTION ad_script_abort} {result} {
                    ::throw {AD EXCEPTION ad_script_abort} $result
                }
        }
        #
        # Call the Tcl 8.6 built-in/compliant ::try in the scope of the caller
        #
        #puts stderr EXEC=[list ::try $body {*}$extraTraps {*}$args]

        tailcall ::try $body {*}$extraTraps {*}$args
    }

} else {
    # version for Tcl 8.5

    ad_proc ad_try {
        {-auto_abort:boolean true}
        body
        args
    } {

        Generic code for OpenACS to handle exceptions and traps based on
        Tcl's primitives. This implementation is a slight generalization
        of the Tcl 8.6 built-in ::try, which handles ad_script_aborts
        automatically.

        The command "ad_try" should replace the various exception handling
        constructs such as "catch", which tend to swallow often error
        conditions, making debugging unnecessarily hard.  It will make
        "with_finally" and "with_catch" obsolete, which should be marked
        as deprecated in the not-to-far future.

        @see with_finally
        @see with_catch

    } {
        #
        # Per default, ad_script_abort exceptions are automatically passed
        # through the higher handlers, aborting all execution levels. Only
        # the top-level processor should handle these cases (probably
        # silently).
        #
        set extraTraps {}
        if {$auto_abort_p} {
            #
            # Add silent handling of "ad_script_abort" to
            # the traps.
            #
            lappend extraTraps \
                trap {AD EXCEPTION ad_script_abort} {result} {
                    ::throw {AD EXCEPTION ad_script_abort} $result
                }
        }
        #
        # Call the Tcl 8.6 built-in/compliant ::try in the scope of the caller
        #
        #puts stderr EXEC=[list ::try $body {*}$extraTraps {*}$args]

        #uplevel [list ::try $body {*}$extraTraps {*}$args]

        if {[catch {uplevel [list ::try $body {*}$extraTraps {*}$args]} msg opts]} {
            dict incr opts -level
            return {*}$opts $msg
        } else {
            return $msg
        }
    }
}

ad_proc ad_unless_script_abort {
    body
    non_abort_action
} {

    Execute the provided body in the callers' environment. When the
    body does not raise an "ad_script_abort" exception, the
    "non_abort_action" is also executed. This pattern is useful when
    handling client requests and where the "non_abort_action" is used
    to return results to the client. When "ad_script_abort" is
    executed, the connection is usually closed, and any attempt to
    talk to the client over the closed connection will fail.

    The handling of script_abort exceptions is done usually in the
    request processor. The function is useful when registering own
    request procs (e.g., via "ns_register_proc") where the OpenACS
    request processor is not involved.

    @param body script, which is always executed
    @param non_abort_action script, which is executed unless the
           body was aborted.

    @see ad_script_abort
} {
    ad_try -auto_abort=false {
        uplevel $body
    } trap {AD EXCEPTION ad_script_abort} {r} {
        # do nothing
    } on ok RESULT {
        uplevel $non_abort_action
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
