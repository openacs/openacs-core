<?xml version="1.0"?>
<queryset>

<fullquery name="name_get">      
      <querytext>
      select first_names, last_name, email, url from persons, parties where persons.person_id = parties.party_id and party_id =:user_id
      </querytext>
</fullquery>

 
<fullquery name="alerts_list">      
      <querytext>
      
    select bea.valid_p, bea.frequency, bea.keywords, bt.topic, bea.rowid
    from bboard_email_alerts bea, bboard_topics bt
    where bea.user_id = :user_id
    and bea.topic_id = bt.topic_id
    order by bea.frequency
      </querytext>
</fullquery>

 
</queryset>
