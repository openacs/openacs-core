ad_library {

    Manage external links in the content repository

    @author Don Baccus (dhogaza@pacifier.com)
    @cvs-d $Id$

}

namespace eval content_extlink {}

ad_proc content_extlink::new {
    {-extlink_id ""}
    -url:required
    -parent_id:required
    {-name ""}
    {-label ""}
    {-description ""}
} {

    Create a new external link.

    @extlink_id Optional pre-assigned object_id for the link
    @url The URL of the external resource
    @parent_id The folder that will contain this extlink
    @name Name to assign the object (defaults to "link extlink_id")
    @label Label for the extlink (defaults to the URL)
    @description An extended description of the link (defaults to NULL)

} {

    set creation_user [ad_conn user_id]
    set creation_ip [ad_conn peeraddr]

    return [db_exec_plsql extlink_new {}]

}

ad_proc content_extlink::edit {
    -extlink_id:required
    -url:required
    -label:required
    -description:required
} {

    Edit an existing external link.  The parameters are required because it
    is assumed that the caller will be pulling the existing values out of
    the database before editing them.

    @extlink_id Optional pre-assigned object_id for the link
    @url The URL of the external resource
    @label Label for the extlink (defaults to the URL)
    @description An extended description of the link (defaults to NULL)

} {

    set modifying_user [ad_conn user_id]
    set modifying_ip [ad_conn peeraddr]

    db_transaction {
        db_dml extlink_update_object {}
        db_dml extlink_update_extlink {}
    }

}

ad_proc content_extlink::delete {
    -extlink_id:required
} {

    Delete an external link.

    @extlink_id  The object id of the link to delete

} {
    db_exec_plsql extlink_delete {}
}

ad_proc content_extlink::extlink_p {
    -item_id:required
} {

    Returns true if the given item is an external link.

    @extlink_id  The object id of the item to check.

} {
    return [db_string extlink_check {}]
}

ad_proc content_extlink::extlink_name {
    -item_id:required
} {

    Returns the name of an extlink

    @item_id  The object id of the item to check.

} {
    return [db_string extlink_name {}]
}
