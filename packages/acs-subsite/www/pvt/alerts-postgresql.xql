<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="alerts_list">      
      <querytext>
      
    select bea.valid_p, bea.frequency, bea.keywords, bt.topic, bea.oid as rowid
    from bboard_email_alerts bea, bboard_topics bt
    where bea.user_id = :user_id
    and bea.topic_id = bt.topic_id
    order by bea.frequency
      </querytext>
</fullquery>

 
<fullquery name="alerts_list_2">      
      <querytext>
      
    select cea.valid_p,
           ad.domain,
           cea.alert_id,
           cea.expires,
           cea.frequency,
           cea.alert_type,
           cea.category,
           cea.keywords
    from   classified_email_alerts cea, ad_domains ad
    where  user_id = :user_id
    and    ad.domain_id = cea.domain_id
    and    current_timestamp <= expires
    order by expires desc
      </querytext>
</fullquery>

 
</queryset>
