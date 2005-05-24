ad_page_contract {

    @author Natalia Pérez (nperper@it.uc3m.es) 
    @creation_date 2005-03-28
    
} {
    object_id:notnull
    request_id:multiple
    type_id
    return_url         
} 

set request_count [llength $request_id]
for { set i 0} { $i < $request_count } { incr i } {
    db_transaction {
	set r_id [lindex $request_id $i]
	db_dml remove_notify { *SQL* }
    }
}

ad_returnredirect $return_url
