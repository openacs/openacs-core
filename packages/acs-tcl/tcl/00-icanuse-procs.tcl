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

#
# Set "softrecreate" in nsf to true to avoid full cleanup on a
# redefinition of a class (e.g., during reloads, upgrading, etc.)
#
nsf::configure softrecreate true

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
        submethod is available, since there is in Tcl no generic way
        to determine subcommands for a command.

        Note: Use this with caution, this is NOT GUARANTEED to work
        with every command, since many commands require e.g. a
        connection or return different error messages. When using this
        in more cases, test first!

        Therefore, this is a PRIVATE function, not intenended for
        public use.
    } {
        catch [list $cmd ""] errorMsg
        regsub ", or " $errorMsg ", " errorMsg
        regsub "^.*must be " $errorMsg " " errorMsg
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
# routines. These features can be use via [::acs::icanuse FEATURENAME].
#
# Note that packages can register some optional features during boot
# up as well, but the developer has to care about the registration and
# loading order. The commands are executed very early, this means
# that, e.g., util::which is not yet available.
#
::acs::register_icanuse "gnugrep"                   [acs::cmd_error_contains [list exec grep -V] GNU]
::acs::register_icanuse "ns_asynclogfile"           {[info commands ::ns_asynclogfile] ne ""}
::acs::register_icanuse "ns_baseunit"               {[info commands ::ns_baseunit] ne ""}
::acs::register_icanuse "ns_conn contentsentlength" [acs::cmd_has_subcommand ns_conn contentsentlength]
::acs::register_icanuse "ns_conn partialtimes"      [acs::cmd_has_subcommand ns_conn partialtimes]
::acs::register_icanuse "ns_conn pool"              [acs::cmd_has_subcommand ns_conn pool]
::acs::register_icanuse "ns_crypto::argon2"         {[info commands ::ns_crypto::argon2] ne ""}
::acs::register_icanuse "ns_crypto::pbkdf2_hmac"    {[info commands ::ns_crypto::pbkdf2_hmac] ne ""}
::acs::register_icanuse "ns_crypto::randombytes"    {[info commands ::ns_crypto::randombytes] ne ""}
::acs::register_icanuse "ns_crypto::scrypt"         {[info commands ::ns_crypto::scrypt] ne ""}
::acs::register_icanuse "ns_db currenthandles"      [acs::cmd_has_subcommand ns_db currenthandles]
::acs::register_icanuse "ns_deletecookie -samesite" [acs::cmd_error_contains {ns_deletecookie} -samesite]
::acs::register_icanuse "ns_hash"                   {[info commands ::ns_hash] ne ""}
::acs::register_icanuse "ns_ictl trace idle"        [acs::cmd_error_contains {ns_ictl trace foo} idle]
::acs::register_icanuse "ns_info meminfo"           [acs::cmd_has_subcommand ns_info meminfo]
::acs::register_icanuse "ns_ip"                     {[info commands ::ns_ip] ne ""}
::acs::register_icanuse "ns_mkdtemp"                {[info commands ::ns_mkdtemp] ne ""}
::acs::register_icanuse "ns_parsehtml"              {[info commands ::ns_parsehtml] ne ""}
::acs::register_icanuse "ns_parsequery -charset"    [acs::cmd_error_contains {ns_parsequery} -charset]
::acs::register_icanuse "ns_parseurl -strict"       [acs::cmd_error_contains ns_parseurl -strict]
::acs::register_icanuse "ns_pg pid"                 [acs::cmd_has_subcommand ns_pg pid]
::acs::register_icanuse "ns_reflow_text -offset"    [acs::cmd_error_contains {ns_reflow_text} -offset]
::acs::register_icanuse "ns_server hosts"           [acs::cmd_has_subcommand ns_server hosts]
::acs::register_icanuse "ns_server unmap"           [acs::cmd_has_subcommand ns_server unmap]
::acs::register_icanuse "ns_set keys"               [acs::cmd_has_subcommand ns_set keys]
::acs::register_icanuse "ns_set stats"              [acs::cmd_has_subcommand ns_set stats]
::acs::register_icanuse "ns_set values"             [acs::cmd_has_subcommand ns_set values]
::acs::register_icanuse "ns_setcookie -samesite"    [acs::cmd_error_contains ns_setcookie -samesite]
::acs::register_icanuse "ns_strcoll"                {[info commands ::ns_strcoll] ne ""}
::acs::register_icanuse "ns_subnetmatch"            {[info commands ::ns_subnetmatch] ne ""}
::acs::register_icanuse "ns_urlencode -part oauth1" [acs::cmd_error_contains {ns_urlencode -part xxx} oauth1]
::acs::register_icanuse "ns_writer"                 {[info commands ::ns_writer] ne ""}
::acs::register_icanuse "nsf::config profile"       [expr {[info exists ::nsf::config(profile)] ? $::nsf::config(profile) : 0}]
::acs::register_icanuse "nsf::parseargs -asdict"    [acs::cmd_error_contains {nsf::parseargs} -asdict]

#
# At the time "ns_trim -prefix was introduced in NaviServer, a memory
# leak in nsv_dict was removed that could lead to a growing size of
# nsd on busy sites.
#
::acs::register_icanuse "nsv_dict"                  [acs::cmd_error_contains {ns_trim} -prefix]

#
# At the time "ns_ip" was introduced in NaviServer, the member
# "proxied" was added to the result of "ns_conn details".
#
# The support for relative redirects was added to NaviServer shortly
# after this. Previous NaviServer version turned automatically
# relative URL references into absolute URL by prefixing it with the
# location as required by RFC 2614.  In 2014, RFC 7231 changed this
# requirement by supporting also relative redirects, ... which are
# also supported by newer NaviServer versions. Computing the proper
# location can be tricky and error-prone, especially when running
# behind a reverse proxy server and/or in containers, where it is hard
# to obtain validated host header information. Without proper
# validation, the "host" header field can be used to hijack
# connections to other sites.
#

::acs::register_icanuse "ns_conn proxied" {[info commands ::ns_ip] ne ""}
::acs::register_icanuse "relative redirects" {[info commands ::ns_ip] ne ""}

#
# When "nsf::parseargs -asdict" was introduced, the object aliasing
# was also introduced in nsf. .... But this feature is not ready yet.
#
#::acs::register_icanuse "nx::alias object"          [acs::cmd_error_contains {nsf::parseargs} -asdict]

#
# The following commands check indirectly the availability, since the
# commands require connections etc.  These features were introduced
# after the queried functionality was introduced.
#
::acs::register_icanuse "ns_http results dict"      [acs::cmd_has_subcommand ns_http stats]
::acs::register_icanuse "ns_conn peeraddr -source"  [acs::cmd_has_subcommand ns_connchan status]

#
# Add some compatibility procs for AOLserver or older NaviServer versions
#
# If the list of commands is getting longer we should probably add a
# own file. For now, it is handy to see, how to handle features, which
# can be relatively easy emulated, and other one, which can't be
# emulated.
#
if {[namespace which ns_base64urlencode] eq ""} {
    ns_log notice "... define compatibility version for ns_base64urlencode"

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
    ns_log notice "... define compatibility version for ns_dbquotelist"

    ad_proc -public ns_dbquotelist {
        list
        {type text}
    } {
        Quote a list as a safe SQL list to be used e.g. in "in"
        statements.

        Compatibility function for AOLserver or older versions of
        NaviServer. Newer versions of NaviServer provide this command
        as builtin.
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
if {![acs::cmd_error_contains {ns_trim} -prefix]} {
    ns_log notice "... define compatibility version for ns_trim"

    ad_proc ns_trim {
        {-delimiter ""}
        {-prefix ""}
        text
    } {
        Delimiter line trim command.

        Strip from the begin of every line characters whitespace followed
        by the specified delimiter character. Example:

        puts [ns_trim -delimiter | {
            | Hello
            | World!
        }]

        This function is part of NaviServer, the Tcl version is just a
        fallback, when older versions of NaviServer are used.
    } {
        if {$prefix ne ""} {
            set len [string length $prefix]
            set lines [lmap line [split $text \n] {
                if {[string range $line 0 $len-1] eq $prefix} {
                    set line [string range $line $len end]
                }
                set line
            }]
            set text [join $lines \n]
        } else {
            if {$delimiter ne ""} {
                set re "^\\s*\[$delimiter\](.*)$"
            } else {
                set re "^\\s*(\S*.*)$"
            }
            set text [join [lmap line [split $text \n] {
                regexp $re $line . line
                set line
            }] \n]
        }
        return $text
    }
}

if {[namespace which ::ns_uuid] eq ""} {
    ns_log notice "... define compatibility version for ns_uuid"

    ad_proc ns_uuid {} {

        Return a unique ID, based on the combination of high
        resolution time and a random token. The result should follow
        the syntax-requirements of the left token of Message-IDs (RFC
        5322).

        The result does not follow the format of RFC 4122 UUIDs, but
        this is just for backwards compatibility, when no recent
        NaviServer is used.

    } {
        return "[clock clicks -microseconds]-[sec_random_token]"
    }
}

if {[namespace which ::ns_parsehostport] eq ""} {
    ns_log notice "... define compatibility version for ns_parsehostport"

    ad_proc ns_parsehostport {hostport} {

        Backward compatibility function for parsing host and port.
        Earlier versions of "ns_parseurl" accepted also "urls" of the
        form host:port, where the input is not a proper URL according
        to RFC 3986. So newer versions of NaviServer introduced
        "ns_parsehostport", which can be emulated with the sloppy
        version of "ns_parseurl" of earlier versions.

    } {
        return [ns_parseurl $hostport]
    }
}

if {[info commands ::ns_baseunit] eq ""} {

    ad_proc ns_baseunit {-size -time} {

        Partial backward compatibility function of
           "ns_baseunit ?-size size? ?-time time?"
        Only the time unit part is partially implemented,
        therefore, icanuse is not set for that feature,
        since one should be able to trust blindly on this.

    } {
        if {[info exists size]} {
            #
            # Rough approximation for AOLserver and older versions of NaviServer.
            #
            if {![string is integer -strict $size]} {
                if {[regexp {^(\d+)([mk])b} [string tolower $specifiedSize] . amount unit]} {
                    set multipliers {k 1024 m 1048576}
                    set size [expr {[dict get $multipliers $unit] * $amount}]
                } else {
                    error "invalid size specification '$size'"
                }
            }
            return $size
        }
        if {![string is integer -strict $time]} {
            if {[regexp {^(\d+)d$} $time _ t]} {
                set time [expr {60*60*24*$t}]
            } elseif {[regexp {^(\d+)h$} $time _ t]} {
                set time [expr {60*60*$t}]
            } elseif {[regexp {^(\d+)m$} $time _ t]} {
                set time [expr {60*$t}]
            } else {
                error "rp_serve_resource_file: invalid time '$time' specified"
            }
        }
        return $time
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
