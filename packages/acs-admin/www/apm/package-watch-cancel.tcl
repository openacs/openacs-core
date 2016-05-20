ad_page_contract {
    Cancels all watches in given package.

    @author Peter Marklund
    @cvs-id $Id$
} {
    package_key
    {return_url:localurl "index"}
} 

apm_cancel_all_watches $package_key

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
