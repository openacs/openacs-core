ad_library {

    Manage external links in the content repository

    @author Dave Bauer (dave@thedesignexperience.org) 
    @cvs-d $Id:

}

namespace eval content_symlink {}

ad_proc -deprecated content_symlink::new {
    {-symlink_id ""}
    -target_id:required
    -parent_id:required
    {-name ""}
    {-label ""}
    {-package_id ""}
} {

    Create a new internal link.

    @symlink_id Optional pre-assigned object_id for the link
    @target_id The item_id of the target of the link
    @parent_id The folder that will contain this symlink
    @name Name to assign the object (defaults to the name of the target item)
    @label Label for the symlink (defaults to the URL)
    @description An extended description of the link (defaults to NULL)
    @package_id Package Id of the package that created the link
    @see content::symlink::new

} {

    set creation_user [ad_conn user_id]
    set creation_ip [ad_conn peeraddr]

    if {$package_id eq ""} {
	set package_id [ad_conn package_id]
    }

    return [db_exec_plsql symlink_new {}]

}

ad_proc content_symlink::edit {
    -symlink_id:required
    -target_id:required
    -label:required
} {

    Edit an existing internal link.  The parameters are required because it
    is assumed that the caller will be pulling the existing values out of
    the database before editing them.

    @symlink_id Optional pre-assigned object_id for the link
    @target_id The target item_id of the link
    @label Label for the symlink (defaults to the target_id item title)
    @description An extended description of the link (defaults to NULL)

} {

    set modifying_user [ad_conn user_id]
    set modifying_ip [ad_conn peeraddr]

    db_transaction {
        db_dml symlink_update_object {}
        db_dml symlink_update_symlink {}
    }

}

ad_proc -deprecated content_symlink::delete {
    -symlink_id:required
} {

    Delete an external link.

    @symlink_id  The object id of the link to delete
    @see content::symlink::delete

} {
    db_exec_plsql symlink_delete {}
}

ad_proc -deprecated content_symlink::symlink_p {
    -item_id:required
} {

    Returns true if the given item is a symlink

    @symlink_id  The object id of the item to check.
    @see content::symlink::is_symlink

} {
    return [db_string symlink_check {}]
}

ad_proc content_symlink::symlink_name {
    -item_id:required
} {

    Returns the name of an symlink

    @item_id  The object id of the item to check.

} {
    return [db_string symlink_name {}]
}

ad_proc -public -deprecated content_symlink::resolve {
	-item_id:required
} {
	@param item)id item_id of content_symlink item to resolve

	@return item_id of symlink target
	@see content::symlink::resolve
} {

	return [db_exec_plsql resolve_symlink ""]

}

ad_proc -public -deprecated content_symlink::resolve_content_type {
	-item_id:required
} {

	@param item_id item_id of symlink

	@return content_type of target item
	@see content::symlink::resolve_content_type

} {

	return [db_exec_plsql resolve_content_type ""]

}
