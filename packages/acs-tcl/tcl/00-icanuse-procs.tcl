ad_library {

    An API for checking optional features (name inspired by caniuse.com)

    @creation-date 4th June 2019
    @author Gustaf Neumann
}

if {[namespace which ::try] eq ""} {
    package require try
    ns_log warning "*******************************************"
    ns_log warning "* This version of OpenACS requires Tcl 8.6"
    ns_log warning "*******************************************"
}

namespace eval ::acs {
    ad_proc -public icanuse {feature} {

        Check, if a (previously registered) feature can be used in an
        installation. These features are typically version dependent
        features of NaviServer. The checking of the availability of
        these features is typically more complex than a plain "info
        commands ...".

        @param feature name for a feature, can contain blanks
        @return boolean value

    } {
        return [info exists ::acs::caniuse($feature)]
    }

    ad_proc -public register_icanuse {feature condition} {

        Registry function for acs::caniuse.

        @param feature name for a feature, can contain blanks
        @param condition expression to determine availability
    } {
        set success 0
        try {
            expr $condition
        } on ok {result} {
            set success $result
        } on error {errorMsg} {
            # just use the default
            ns_log warning "registry for caniuse $feature -> $errorMsg"
        }
        if {$success} {
            set ::acs::caniuse($feature) 1
        }
        ns_log notice "... I can use $feature -> $success"
    }

    ad_proc -private cmd_has_subcommand {cmd subcommand} {

        Helper proc abusing error messages to determine, whether as
        submethod is available.

    } {
        catch [list $cmd ""] errorMsg
        return [expr {" $subcommand" in [split $errorMsg ","]}]
    }

    ad_proc -private cmd_error_contains {cmd subcommand} {

        Helper proc abusing error messages to determine, whether the
        error message contains some string. This is a weeker form of
        cmd_has_subcommand.

    } {
        catch $cmd errorMsg
        return [string match *$subcommand* $errorMsg]
    }

}


#
# Register features provided by the server, available to all packages.
# These features can typically not easily be provided by compatibility
# routines.
#
# Note that packages can register some optional features during bootup
# as well, but the developer has to care about the registration and
# loading order.
#

::acs::register_icanuse "ns_asynclogfile"           {[info commands ::ns_asynclogfile] ne ""}
::acs::register_icanuse "ns_conn contentsentlength" [acs::cmd_has_subcommand ns_conn contentsentlength]
::acs::register_icanuse "ns_conn partialtimes"      [acs::cmd_has_subcommand ns_conn partialtimes]
::acs::register_icanuse "ns_conn pool"              [acs::cmd_has_subcommand ns_conn pool]
::acs::register_icanuse "ns_crypto::randombytes"    {[info commands ::ns_crypto::randombytes] ne ""}
::acs::register_icanuse "ns_db currenthandles"      [acs::cmd_has_subcommand ns_db currenthandles]
::acs::register_icanuse "ns_hash"                   {[info commands ::ns_hash] ne ""}
::acs::register_icanuse "ns_ictl trace idle"        [acs::cmd_error_contains {ns_ictl trace foo} idle]
::acs::register_icanuse "ns_server unmap"           [acs::cmd_has_subcommand ns_server unmap]
::acs::register_icanuse "ns_set keys"               [acs::cmd_has_subcommand ns_set keys]
::acs::register_icanuse "ns_setcookie -samesite"    [acs::cmd_error_contains ns_setcookie -samesite]
::acs::register_icanuse "ns_writer"                 {[info commands ::ns_writer] ne ""}
::acs::register_icanuse "nsv_dict"                  [acs::cmd_error_contains {nsv_dict get ""} -varname]

#
# Add some compatibility procs for AOLserver or older NaviServer versions
#
# If the list of commands is getting longer we should probably add a
# own file. For now, it is handy to see, how to handle features, which
# can be relatively easy emulated, and other one, which can't be
# emulated.
#
if {[namespace which ns_base64urlencode] eq ""} {
    #
    # Compatibility for AOLserver or NaviServer before 4.99.17
    #
    proc ns_base64urlencode {data} {
        return [string map {+ - / _ = {} \n {}} [ns_base64encode $data]]
    }
    proc ns_base64urldecode {data} {
        return [ns_base64decode [string map {- +  _ / } $data]]
    }
}

if {[namespace which ::ns_dbquotelist] eq ""} {
    ad_proc -public ns_dbquotelist {
        list
        {type text}
    } {
        Quote a list as a safe SQL list to be used e.g. in "in"
        statements.

        Compatibility function for AOLserver or older versions of
        NaviServer. Newer versions provide this command as builtin.
    } {
        set sql ""
        if { [llength $list] > 0 } {
            # replace single quotes by two single quotes
            regsub -all -- ' "$list" '' list
            append sql \
                "'" \
                [join $list "', '"] \
                "'"
        }
        return $sql
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
