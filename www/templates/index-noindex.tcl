# /packages/editthispage/templates/article-index.tcl

ad_page_contract {
    @author Luke Pond (dlpond@pobox.com)
    @creation-date 2001-06-01

    This is the default page used to display an index listing
    for an Edit This Page package instance.  It assumes a 
    content type with no extended attributes, and presents
    a listing of all content pages belonging to this package.
    <p>
    If you want to use some other page instead, specify it with 
    the index_template package parameter.

} {
} -properties {
    pa:onerow
    content_pages:multirow
}

etp::get_page_attributes
etp::get_content_items

set etp_link [etp::get_etp_link]

