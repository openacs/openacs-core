<?xml version="1.0"?>
<queryset>

    <fullquery name="user_information">      
        <querytext>
            select first_names, 
                   last_name,
                   email,
                   url
            from cc_users
            where user_id = :user_id
        </querytext>
    </fullquery>
 
</queryset>
