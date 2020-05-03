ad_library {

    An API for checking optional features (name inspired by caniuse.com)

    @creation-date 4th June 2019
    @author Gustaf Neumann
}

namespace eval ::acs {
    ad_proc -public icanuse {feature} {

        Check, if a (previously registered) feature can be used in an
        installation. These features are typically version dependent
        features of NaviServer. The checking of the availability of
        these feratures is typically more complex than a plain "info
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
}


#
# Register features provided by the server, available to all packages.
# These features can typically not easily be provided by compatiblity
# routines.
#
# Note that packages can register some optional features during bootup
# as well, but the developer has to care about the registration and
# loading order.
#

::acs::register_icanuse "ns_db currenthandles" [acs::cmd_has_subcommand ns_db currenthandles]
::acs::register_icanuse "ns_server ummap" [acs::cmd_has_subcommand ns_server unmap]

::acs::register_icanuse "ns_conn partialtimes" [acs::cmd_has_subcommand ns_conn partialtimes]
::acs::register_icanuse "ns_conn contentsentlength" [acs::cmd_has_subcommand ns_conn contentsentlength]

::acs::register_icanuse "ns_crypto::randombytes" {[info commands ::ns_crypto::randombytes] ne ""}

::acs::register_icanuse "ns_asynclogfile" {[info commands ::ns_asynclogfile] ne ""}
::acs::register_icanuse "ns_writer"       {[info commands ::ns_writer]       ne ""}
::acs::register_icanuse "ns_hash"         {[info commands ::ns_hash]         ne ""}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
