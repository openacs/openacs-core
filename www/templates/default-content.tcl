# /packages/editthispage/templates/article-index.tcl

ad_page_contract {
    @author Luke Pond (dlpond@pobox.com)
    @creation-date 2001-06-01

    This is the default page used to display content pages
    for an Edit This Page package instance.  It assumes a 
    content type with no extended attributes, and presents
    the content item with a standard article layout.
    <p>
    If you want to use some other page instead, specify it with 
    the content_template package parameter.

} {
} -properties {
    pa:onerow
}

set package_id [ad_conn package_id]

etp::get_page_attributes
# comment out, we haven't decided how best to use general comments
# DaveB 2002-12-10, in response to email from Janine Sisk
if {[parameter::get -package_id $package_id -parameter commentable_p -default 0]} {
etp::get_gc_link 
}