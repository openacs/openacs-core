ad_page_contract {
   Ask for confirmation for view on public site_map
    @author Viaro Networks (vivian@viaro.net)
    @cvs-id $id:

} {
    checkbox:integer,multiple,optional
    return_url
} 

set user_id [ad_maybe_redirect_for_registration]

if { ![info exist checkbox] } {
    set checkbox ""
}


db_transaction {
    db_dml delete_nodes { *SQL* }
    foreach checkbox $checkbox {
	db_dml insert_nodes { *SQL* }
    }
}

ad_returnredirect $return_url