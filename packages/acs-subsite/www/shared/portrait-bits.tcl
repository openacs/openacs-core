ad_page_contract {
    spits out correctly MIME-typed bits for a user's portrait

    @author philg@mit.edu
    @creation-date 26 Sept 1999
    @cvs-id $Id$
} {
    user_id:integer
}

if ![db_0or1row get_item_id "select cr.revision_id, c.item_id, mime_type
from acs_rels a, cr_items c, cr_revisions cr
where a.object_id_two = c.item_id
and c.live_revision = cr.revision_id
and a.object_id_one = :user_id
and a.rel_type = 'user_portrait_rel'"] {
    ad_return_error "Couldn't find portrait" "Couldn't find a portrait for User $user_id"
    return
}

ReturnHeaders $mime_type

db_write_blob output_portrait "select content
from cr_revisions
where revision_id = $revision_id"
 

