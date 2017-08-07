ad_page_contract {
    @author Neophytos Demetriou
} {
    
    {q:trim,notnull ""}
    {num:range(1|200),notnull 0}
    
} -validate {
    
    check_q -requires q {
        if {[string length $q] < 3} {
            set name q
            set min_length 3
            set actual_length [string length $q]
            ad_complain [_ acs-tcl.lt_name_is_too_short__Pl]
        }
    }
    
    csrf { csrf::validate }
}

set package_id [ad_conn package_id]

if { $num == 0 } {
    set num [parameter::get -package_id $package_id -parameter LimitDefault]
}

set title "Advanced Search"
set context "advanced search"
set context_bar [ad_context_bar $title]


ad_return_template
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
