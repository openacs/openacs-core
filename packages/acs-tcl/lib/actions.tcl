# Generate an html version of the given package_id's admin actions.
# expects to be in a conn.
#
# @param package_id
# @param package_key
# @param return_url

set user_id [ad_conn user_id]

multirow create actions type url_stub text title_text long_text

if {![catch {
    lindex [callback -catch -impl $package_key navigation::package_admin -user_id $user_id -package_id $package_id -return_url $return_url] 0
} action_list]} {

    foreach action $action_list {

        if {[lindex $action 0] eq "LINK"} {
            lassign $action type stub text title long
            multirow append actions $type "$base_url$stub" $text $title $long

        } elseif {[lindex $action 0] eq "SECTION"} {
            lassign $action type title long
            multirow append actions $type {} {} $title $long

        } else {
            error "actions.tcl: type [lindex $action 0] unknown"
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
