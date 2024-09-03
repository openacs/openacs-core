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
    set grepfor "${full_key}|lc_get \[\"\{\]?[string range $message_key [string length localization-] end]\[\"\}\]?"
} else {
    set grepfor "\\W${full_key}\\W"
}

multirow create message_usage file code

set egrepCmd [::util::which egrep]
ad_try {

    if {[::acs::icanuse gnugrep]} {
        exec -ignorestderr $egrepCmd -r \
            --include=*.tcl \
            --include=*.adp \
            --include=*.sql \
            --include=*.info \
            $grepfor $::acs::rootdir/packages
        
    } else {
        set findCmd [::util::which find]
        set xargsCmd [::util::which xargs]
        exec -ignorestderr $findCmd $::acs::rootdir/packages -type f -follow \
            | $egrepCmd .(tcl|adp|sql|info) \
            | $xargsCmd $egrepCmd $grepfor
    }

} on ok {findResult} {
    #
    # Successful operation. Strip the leading root directory path fore
    # more compact display.
    #
    regsub -all $::acs::rootdir/packages/ $findResult "" findResult
    
    multirow append message_usage \
        "Found Occurrences of this message key:" $findResult
    
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
