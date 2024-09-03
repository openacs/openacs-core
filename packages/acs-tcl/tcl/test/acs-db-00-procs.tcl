ad_library {

    Tests for low-level interface for defining the basic classes for
    the DB interface.

}

# aa_register_case \
#     -cats {smoke production_safe} \
#     acs_dc__no_warnings_when_resolving_query {
#         Check that using the acs::dc interface inside of a OO method
#         will not return a warning when we try to resolve the query.
#     } {
#         try {
#             proc count_warnings {command_string op} {
#                 set level [string tolower [lindex $command_string 1]]
#                 set msg [lindex $command_string 2]
#                 if {$level eq "warning" &&
#                     [string match "db_qd_get_fullname: there is no documented proc*" $msg]} {
#                     nsv_incr ::test::acs::dc warnings
#                 }
#             }
#             trace add execution ns_log enter count_warnings

#             ::nx::Class create ::test::TestClass {
#                 :public method get {} {
#                     acs::dc list query {
#                         select 1 from dual
#                     }
#                 }
#             }
#             ::test::TestClass create testObj
#             testObj get

#             aa_equals "No warnings have been triggered" \
#                 [nsv_incr ::test::acs::dc warnings] 1

#         } finally {
#             trace remove execution ns_log enter count_warnings
#             nsv_unset -nocomplain ::test::acs::dc
#         }
#     }
