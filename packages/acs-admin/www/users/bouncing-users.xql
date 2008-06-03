<?xml version="1.0"?>

<queryset>

    <fullquery name="select_bouncing_users">
        <querytext>
	    select username, (first_names || ' ' || last_name) as full_name, user_id 
            from cc_users u
            where u.email_bouncing_p = 't'
        [template::list::orderby_clause -name bouncing_users -orderby]
        </querytext>
    </fullquery>

</queryset>
