<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="email_image::add_relation.add_relation">
     <querytext>
	select acs_rel__new (
        null,
        'email_image_rel',
        :user_id,
        :item_id,
        null,
        null,
        null
        )
     </querytext>
</fullquery>

</queryset>
