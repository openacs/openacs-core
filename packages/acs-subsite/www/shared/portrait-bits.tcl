ad_page_contract {
    spits out correctly MIME-typed bits for a user's portrait

    @author philg@mit.edu
    @creation-date 26 Sept 1999
    @cvs-id $Id$
} {
    user_id:integer
}

if { ![db_0or1row get_item_id ""] } {
    ad_return_error "Couldn't find portrait" "Couldn't find a portrait for User $user_id"
    return
}

cr_write_content -item_id $item_id

