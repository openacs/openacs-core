# @input message_key:multiple 
# @input package_key
#
# @author Peter Marklund (peter@collaboraid.biz)
# @author Lars Pind (lars@collaboraid.biz)
# @cvs-id $Id$

set full_key_pattern "${package_key}.([join $message_key "|"])"

multirow create message_usage file code

with_catch errmsg {
    exec find [acs_root_dir] -type f -regex ".*\\.\\(info\\|adp\\|sql\\|tcl\\)" -follow | xargs egrep "${full_key_pattern}" 2>/dev/null
} {
    #error "find [acs_root_dir] -type f -regex \".*\\.\\(info\\|adp\\|sql\\|tcl\\)\" -follow | xargs egrep \"${full_key_pattern}\""
    global errorInfo

    foreach line [split $errmsg "\n"] {
        if { [string first "child process exited abnormally" $line] == -1 } {
            set colon [string first ":" $line]
            
            multirow append message_usage \
                [string range $line 0 [expr $colon-1]] \
                [string trim [string range $line [expr $colon+1] end]]
        }
    }
}
