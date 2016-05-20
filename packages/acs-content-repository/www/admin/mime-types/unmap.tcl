ad_page_contract {
   
    @author Emmanuelle Raffenne (eraffenne@gmail.com)
    @creation-date 22-feb-2010
    @cvs-id $Id$

} {
    extension:notnull
    mime_type:notnull
    {return_url:localurl ""}
}

if { $return_url eq "" } {
    set return_url "index"
}

db_dml extension_unmap {}

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
