<?xml version="1.0"?>

<queryset>
<fullquery name="get_table">
 <querytext>
    select repository_id,
    table_name,
    internal_data_p,
    package_name,
    last_update,
    source,
    source_url,
    effective_date,
    expiry_date,
    (select user_id
     from cc_users u
     where user_id = maintainer_id) as maintainer_id
    from acs_reference_repositories r
    where repository_id= :repository_id
</querytext>
</fullquery>
</queryset>