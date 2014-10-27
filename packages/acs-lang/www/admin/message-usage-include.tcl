# @input message_key
# @input package_key
#
# @author Peter Marklund (peter@collaboraid.biz)
# @author Lars Pind (lars@collaboraid.biz)
# @cvs-id $Id$

set full_key "$package_key.$message_key"

# Since acs-lang.localization- messages use the lc_get proc (that leaves out the acs-lang.localization- part)
# for lookups we need a special regexp for them 
if { [string match "acs-lang.localization-*" $full_key] } {
    set grepfor "${full_key}|lc_get \[\"\{\]?[string range $message_key [string length "localization-"] end]\[\"\}\]?"
} else {
    set grepfor "\\W${full_key}\\W"
}

multirow create message_usage file code

with_catch errmsg {
    exec find $::acs::rootdir -type f -regex ".*\\.\\(info\\|adp\\|sql\\|tcl\\)" -follow | xargs egrep "$grepfor" 2>/dev/null
} {
    #error "find $::acs::rootdir -type f -regex \".*\\.\\(info\\|adp\\|sql\\|tcl\\)\" -follow | xargs egrep \"${full_key_pattern}\""
    global errorInfo

    foreach line [split $errmsg "\n"] {
        if { [string first "child process exited abnormally" $line] == -1 } {
            set colon [string first ":" $line]
            
            multirow append message_usage \
                [string range $line 0 $colon-1] \
                [string trim [string range $line $colon+1 end]]
        }
    }
}
