<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="unused">      
      <querytext>
      update user_preferences set dont_spam_me_p = util__logical_negation(dont_spam_me_p) where user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
