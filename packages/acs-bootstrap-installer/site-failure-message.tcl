# In case there is a database failure, return a static html page.
# It needs to be enabled manually by the admin of the site. The path
# is hardcoded: www/global/site-failure.html

proc site_failure_handler { conn arg why } {

    ns_returnfile 500 text/html "[acs_root_dir]/www/global/site-failure.html"
    return "filter_return"
}

# Register the handler for all URLs.
ns_register_filter preauth GET * site_failure_handler
ns_register_filter preauth POST * site_failure_handler
ns_register_filter preauth HEAD * site_failure_handler
