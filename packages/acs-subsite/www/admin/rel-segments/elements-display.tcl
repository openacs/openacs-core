# included from elements.
permission::require_permission -object_id $segment_id -privilege "read"

set write_p [permission::permission_p -object_id $segment_id -privilege "write"]

set package_url [ad_conn package_url]
set user_id [ad_conn user_id]

db_multirow elements elements_select {}




# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
