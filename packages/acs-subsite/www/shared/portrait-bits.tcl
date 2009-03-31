ad_page_contract {
    spits out correctly MIME-typed bits for a user's portrait

    @author philg@mit.edu
    @creation-date 26 Sept 1999
    @cvs-id $Id$
} {
    user_id:integer
    {item_id ""}
    {size ""}
}


# If the item_id is provided then we are fine
if {$item_id eq ""} {
    if { ![db_0or1row get_item_id ""] } {
	#    ad_return_error "Couldn't find portrait" "Couldn't find a portrait for User $user_id"
	ad_return_string_as_file -string "" -mime_type "image/jpeg" -filename ""
	return
    }
}    

if { $size eq "" } {
    cr_write_content -item_id $item_id
} else {	
    ad_returnredirect "/image/${item_id}/${size}"
}
