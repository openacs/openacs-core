<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="create_rel">
        <querytext>

        select acs_rel__new (
         null,
         'user_portrait_rel',
         :user_id,
         :item_id,
         null,
         null,
         null
        )


        </querytext>
</fullquery>

</queryset>
