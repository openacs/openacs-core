# www/templates/companies-index.tcl

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
# alphabetical order for companies
etp::get_content_items -orderby "lower(title)"

set etp_link [etp::get_etp_link]

ad_return_template "default-index.adp"