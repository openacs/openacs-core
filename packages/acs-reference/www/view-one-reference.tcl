ad_page_contract {
    This page views one table of reference data
    
    @param repository_id 
    @author Jon Griffin (jon@jongriffin.com)
    @creation-date 17 Sept 2001
    @cvs-id $Id$
} {
    repository_id:integer,notnull
} -properties {
    context_bar:onevalue
    package_id:onevalue
    user_id:onevalue
    table_info:onerow
}

set package_id [ad_conn package_id]
set title "View one Table"
set context_bar [list [list "reference-list" "Reference List" ] "$title"]
set user_id [ad_verify_and_get_user_id]

db_1row get_table {
    select repository_id,
    table_name,
    internal_data_p,
    package_name,
    last_update,
    source,
    source_url,
    effective_date,
    expiry_date,
    maintainer_id
    from acs_reference_repositories r,cc_users u
    where repository_id= :repository_id
} -column_array table_info

ad_return_template
