ad_page_contract {
    Cancels all watches in given package.

    @author Peter Marklund
    @cvs-id $Id$
} {
    package_key
    {return_url "index"}
} 

apm_cancel_all_watches $package_key

ad_returnredirect $return_url
