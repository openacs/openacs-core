# /packages/mbryzek-subsite/www/admin/attributes/delete-2.tcl

ad_page_contract {

    Deletes the attribute and all values

    @author mbryzek@arsdigita.com
    @creation-date Sun Nov 12 18:03:50 2000
    @cvs-id $Id$

} {
    attribute_id:notnull,naturalnum,attribute_dynamic_p
    { return_url "" }
    { operation "" }
}

if {$operation eq "Yes, I really want to delete this attribute"} {
    db_transaction {
	set object_type [db_string select_object_type {
	    select attr.object_type 
	      from acs_attributes attr
	     where attr.attribute_id = :attribute_id
	} -default ""]

	# If object type is empty, that means the attribute doesn't exist
	if { $object_type ne "" && [attribute::delete $attribute_id] } {
	    # Recreate all the packages to use the new attribute
	    package_recreate_hierarchy $object_type
	}
    }
} elseif { $return_url eq "" } {
    set return_url [export_vars -base one attribute_id]
}

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
