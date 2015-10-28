# /packages/mbryzek-subsite/www/admin/attribute-add.tcl

ad_page_contract {

    Adds attributes

    @author mbryzek@arsdigita.com
    @creation-date Tue Nov  7 12:14:42 2000
    @cvs-id $Id$

} {
    attribute_id:naturalnum,notnull
    attribute_enum_values:array,trim,optional
    { operation:trim "Finish adding values" }
    { return_url "" }
}

set max_sort_order [db_string select_max_sort_order {
    select nvl(max(v.sort_order),0)
      from acs_enum_values v
     where v.attribute_id = :attribute_id
}]

db_transaction {
    foreach ideal_sort_order [array names attribute_enum_values] {
	set sort_order [expr {$ideal_sort_order + $max_sort_order}]
	set pretty_name $attribute_enum_values($ideal_sort_order)
	# delete if the value is empty. Update otherwise
	if { $pretty_name eq "" } {
	    db_dml delete_enum_value {
		delete from acs_enum_values 
		 where attribute_id = :attribute_id 
		   and sort_order = :sort_order
	    }
	} else {
	    db_dml update_enum_value {
		update acs_enum_values v
		   set v.pretty_name = :pretty_name
		 where v.attribute_id = :attribute_id
		   and v.sort_order = :sort_order
	    }
	    if { [db_resultrows] == 0 } {
		# No update - insert the row. Set the enum_value to
		# the pretty_name
		db_dml insert_enum_value {}
	    }
	}
    }
}

db_release_unused_handles

if {$operation eq "Add more values"} {
    # redirect to add more values
    set return_url [export_vars -base enum-add {attribute_id return_url}]
} elseif { $return_url eq "" } {
    set return_url [export_vars -base one attribute_id]
}

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
