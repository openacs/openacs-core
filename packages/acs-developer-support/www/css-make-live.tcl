# 

ad_page_contract {
    
    make a css revision the live one
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2007-09-30
    @cvs-id $Id$
} {
    {revision_id:naturalnum,notnull}
    {file_location }
    {return_url_2 "/"}
} -properties {
} -validate {
} -errors {
}

ds_require_permission [ad_conn package_id] "admin"

content::item::set_live_revision -revision_id $revision_id

set item_id [content::revision::item_id -revision_id $revision_id]
#set target [content::item::get_name -item_id $item_id]
set target $file_location
set source [content::revision::get_cr_file_path -revision_id $revision_id]

#todo check if files are stored in db
file copy -force -- $source $target

ad_returnredirect $return_url_2

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
