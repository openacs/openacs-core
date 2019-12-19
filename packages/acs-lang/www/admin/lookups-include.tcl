ad_include_contract {
    Display message key occurrences on the system.
} {
    package_key:token,notnull
    message_key_list:notnull
}

set full_key_pattern "${package_key}.([join $message_key_list "|"])"

set message_key_context ""
if { [catch {set message_key_context [exec find $::acs::rootdir -type f -regex ".*\\.\\(info\\|adp\\|sql\\|tcl\\)" | xargs egrep "${full_key_pattern}"]} error] } {
    regexp "^(.*)child process exited abnormally" $::errorInfo match message_key_context
    set message_key_context [ns_quotehtml $message_key_context]
    regsub -all "${full_key_pattern}" $message_key_context {<b>\0</b>} message_key_context
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
