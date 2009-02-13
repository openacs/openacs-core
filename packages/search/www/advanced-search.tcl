ad_page_contract {
    @author Neophytos Demetriou
} {
    {q ""}
    {num 0}
}

set package_id [ad_conn package_id]

if { $num == 0 } {
    set num [parameter::get -package_id $package_id -parameter LimitDefault]
}

set title "Advanced Search"
set context "advanced search"
set context_bar [ad_context_bar $title]


ad_return_template