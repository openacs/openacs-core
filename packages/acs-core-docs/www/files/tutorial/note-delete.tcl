ad_page_contract {
    This deletes a note

    @author Your Name (you@example.com)
    @cvs-id $Id$
 
    @param item_id The item_id of the note to delete
} {
    item_id:integer
}

permission::require_write_permission -object_id $item_id
set title [item::get_title $item_id]
mfp::note::delete -item_id $item_id

ad_returnredirect "."
# stop running this code, since we're redirecting
abort
