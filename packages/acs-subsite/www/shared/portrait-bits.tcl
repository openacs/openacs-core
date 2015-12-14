ad_page_contract {
    spits out correctly MIME-typed bits for a user's portrait

    @author philg@mit.edu
    @creation-date 26 Sept 1999
    @cvs-id $Id$
} {
    user_id:naturalnum,notnull
    {size ""}
}

set item_id [acs_user::get_portrait_id -user_id $user_id]

if { $size eq "" } {
    cr_write_content -item_id $item_id
} else {
    ad_returnredirect "/image/${item_id}/${size}"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
