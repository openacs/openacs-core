#/packages/acs-lang/www/show-catalog.tcl
ad_page_contract {

    List contents of message catalog

    @author Henry Minsky (hqm@ardigita.com)
    @creation-date 29 September 2000
    @cvs-id $Id$
} { }

set title "Show Message Catalog"
set header [ad_header $title]
# set navbar [ad_context_bar "Show Message Catalog "]
set footer [ad_footer]

# Test 3 checks that the timezone tables are installed
# Need this data to check that test 4 works
set cat_sql "SELECT key, locale, message, registered_p
               FROM lang_messages
              ORDER BY key, locale"

db_multirow catalog catalog_data $cat_sql

ad_return_template
