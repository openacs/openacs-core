ad_page_contract {
    Script that deletes an authority.

    @author Peter Marklund
    @creation-date 2003-09-08
} {
    authority_id:integer
}

auth::authority::delete -authority_id $authority_id

ad_returnredirect "."
