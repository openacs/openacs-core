ad_page_contract {
    This is the view-edit page for notes.

    @author Your Name (you@example.com)
    @cvs-id $Id$
 
    @param item_id If present, assume we are editing that note.  Otherwise, we are creating a new note.
} {
    item_id:integer,optional
}

ad_form -name note -form {
    {item_id:key}
    {title:text {label Title}}
} -new_request {
    auth::require_login
    permission::require_permission -object_id [ad_conn package_id] -privilege create
    set page_title "Add a Note"
    set context [list $page_title]
} -edit_request {
    auth::require_login
    permission::require_write_permission -object_id $item_id
    mfp::note::get \
	-item_id $item_id \
	-array note_array 

    set title $note_array(title)

    set page_title "Edit a Note"
    set context [list $page_title]
} -new_data {
    mfp::note::add \
	-title $title
} -edit_data {
    mfp::note::edit \
	-item_id $item_id \
	-title $title
} -after_submit {
    ad_returnredirect "."
    ad_script_abort
}