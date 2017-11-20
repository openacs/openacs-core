<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="acs_user::delete.permanent_delete">
      <querytext>
          select acs__remove_user(:user_id);
      </querytext>
</fullquery>

<fullquery name="person::delete.delete_person">      
      <querytext>

            select person__delete(:person_id);
        
      </querytext>
</fullquery>
 
</queryset>
