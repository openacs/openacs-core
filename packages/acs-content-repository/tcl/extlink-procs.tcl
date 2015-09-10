ad_library {

    Manage external links in the content repository

    @author Don Baccus (dhogaza@pacifier.com)
    @cvs-id $Id$

}

namespace eval content_extlink {}

ad_proc -deprecated content_extlink::new {
    {-extlink_id ""}
    -url:required
    -parent_id:required
    {-name ""}
    {-label ""}
    {-description ""}
    {-package_id ""}
} {

    Create a new external link.

    @see content::extlink::new

    @param extlink_id Optional pre-assigned object_id for the link
    @param url The URL of the external resource
    @param parent_id The folder that will contain this extlink
    @param name Name to assign the object (defaults to "link extlink_id")
    @param label Label for the extlink (defaults to the URL)
    @param description An extended description of the link (defaults to NULL)
    @param package_id Package Id of the package that created the link

} {

    set creation_user [ad_conn user_id]
    set creation_ip [ad_conn peeraddr]

    if {$package_id eq ""} {
	set package_id [ad_conn package_id]
    }

    return [db_exec_plsql extlink_new {}]

}

ad_proc -deprecated content_extlink::edit {
    -extlink_id:required
    -url:required
    -label:required
    -description:required
} {

    Edit an existing external link.  The parameters are required because it
    is assumed that the caller will be pulling the existing values out of
    the database before editing them.

    @param extlink_id Optional pre-assigned object_id for the link
    @param url The URL of the external resource
    @param label Label for the extlink (defaults to the URL)
    @param description An extended description of the link (defaults to NULL)

    @see content::extlink::edit
} {

    set modifying_user [ad_conn user_id]
    set modifying_ip [ad_conn peeraddr]

    db_transaction {
        db_dml extlink_update_object {}
        db_dml extlink_update_extlink {}
    }
}

ad_proc -deprecated content_extlink::delete {
    -extlink_id:required
} {

    Delete an external link.
    @see content::extlink::delete

    @param extlink_id  The object id of the link to delete

} {
    db_exec_plsql extlink_delete {}
}

ad_proc -deprecated content_extlink::extlink_p {
    -item_id:required
} {

    Returns true if the given item is an external link.

    @see content::extlink::is_extlink
    @param extlink_id  The object id of the item to check.

} {
    return [db_string extlink_check {}]
}

ad_proc -deprecated content_extlink::extlink_name {
    -item_id:required
} {

    Returns the name of an extlink

    @param item_id  The object id of the item to check.

    @see content::extlink::name
} {
    return [db_string extlink_name {}]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
