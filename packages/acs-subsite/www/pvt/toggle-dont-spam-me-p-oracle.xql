<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="unused">      
      <querytext>
      update user_preferences set dont_spam_me_p = util.logical_negation(dont_spam_me_p) where user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
