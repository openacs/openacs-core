# Optional parameters:
#
# package_key
# locale

# Default params to empty string
# and build the link export list
set link_export_list [list]
foreach param {package_key locale} {
    if { ![info exists $param] } {
        set $param ""
    } else {
        # param provided
        lappend link_export_list $param
    }
}

set conflict_count [lang::message::conflict_count \
                        -package_key $package_key \
                        -locale $locale]

set message_conflicts_url [export_vars -base message-conflicts $link_export_list]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
