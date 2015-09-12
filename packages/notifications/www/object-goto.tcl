ad_page_contract {
    go to an object

    @author Tracy Adams (teadams@alum.mit.edu)
    @creation-date 22 July 2002
    @cvs-id $Id$
} {
    object_id:naturalnum,notnull
    type_id:naturalnum,notnull
} 


# added type_id parameter to redirect to the correct page for an object
# we need the implementation name which is not the same as the object_type

# look in tcl/delivery-procs.tcl, there is a get_impl_key proc that 
# queries the acs_sc_impls table for the implementation name
# but the query is delivery_type specific, so we can't use it here

set sc_impl_name [db_string get_notif_type {}]

set url [acs_sc::invoke -contract NotificationType -operation GetURL -call_args [list $object_id] -impl $sc_impl_name]

ad_returnredirect $url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
