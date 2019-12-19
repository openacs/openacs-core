ad_include_contract {
    Display occurrences of specified message key. Used while
    translating.

    @author Peter Marklund (peter@collaboraid.biz)
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
} {
    message_key:token,notnull
    package_key:token,notnull
}

set full_key "$package_key.$message_key"

# Since acs-lang.localization- messages use the lc_get proc (that
# leaves out the acs-lang.localization- part) for lookups we need a
# special regexp for them

if { [string match "acs-lang.localization-*" $full_key] } {
    set grepfor "${full_key}|lc_get \[\"\{\]?[string range $message_key [string length "localization-"] end]\[\"\}\]?"
} else {
    set grepfor "\\W${full_key}\\W"
}

multirow create message_usage file code

ad_try {
    exec find $::acs::rootdir -type f -regex ".*\\.\\(info\\|adp\\|sql\\|tcl\\)" -follow \
        | xargs egrep "$grepfor" 2>/dev/null

} on error {errorMsg} {
    foreach line [split $errorMsg "\n"] {
        if { [string first "child process exited abnormally" $line] == -1 } {
            set colon [string first ":" $line]

            multirow append message_usage \
                [string range $line 0 $colon-1] \
                [string trim [string range $line $colon+1 end]]
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
