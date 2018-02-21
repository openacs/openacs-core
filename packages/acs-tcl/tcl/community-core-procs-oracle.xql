<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="acs_user::delete.permanent_delete">
      <querytext>
          begin
              acs.remove_user(
                  user_id => :user_id
              );
          end;
      </querytext>
</fullquery>

<fullquery name="person::delete.delete_person">      
      <querytext>
	    begin
			person.del(
				person_id => :person_id
			);
		end;
      </querytext>
</fullquery>

<fullquery name="acs_user::create_portrait.create_rel">
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
