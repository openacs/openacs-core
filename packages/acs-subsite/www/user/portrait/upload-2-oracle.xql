<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_rel">
        <querytext>

        begin
          :1 := acs_rel.new (
                 rel_type => 'user_portrait_rel',
                 object_id_one => :user_id,
                 object_id_two => :item_id);
        end;

        </querytext>
</fullquery>

</queryset>
