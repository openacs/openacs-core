ad_page_contract {
    This page views the table structure
    
    @param table_name 
    @author Jon Griffin (jon@jongriffin.com)
    @creation-date 17 Sept 2001
    @cvs-id $Id$
} {
    table_name:notnull
} -properties {
    context_bar:onevalue
    package_id:onevalue
    user_id:onevalue
    table_info:onerow
}

set package_id [ad_conn package_id]
set title "View one Table Structure"
set context_bar [list "$title"]
set user_id [ad_conn user_id]


ad_return_template