<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<partialquery name="registration_before_days">      
      <querytext>

        creation_date < sysdate - :registration_before_days

      </querytext>
</partialquery>

<partialquery name="registration_after_days">      
      <querytext>

        creation_date >= sysdate - :registration_after_days

      </querytext>
</partialquery>

 <partialquery name="last_visit_before_days">      
      <querytext>

        last_visit < sysdate - :last_visit_before_days

      </querytext>
</partialquery>

<partialquery name="last_visit_after_days">      
      <querytext>

        last_visit >= sysdate - :last_visit_after_days

      </querytext>
</partialquery>
 
</queryset>
