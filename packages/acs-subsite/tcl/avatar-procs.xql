<?xml version="1.0"?>
<queryset>

<fullquery name="avatar::set_public_p.update_public_avatar_p">
    <querytext>

        update  user_preferences
        set     public_avatar_p = :value
        where   user_id = :user_id

    </querytext>
</fullquery>


<fullquery name="avatar::get_public_p.get_public_avatar_p">
    <querytext>

        select  public_avatar_p
        from    user_preferences
        where   user_id = :user_id

    </querytext>
</fullquery>

</queryset>
