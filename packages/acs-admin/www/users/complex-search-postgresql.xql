<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<partialquery name="registration_before_days">      
      <querytext>

        creation_date < now() - (:registration_before_days || ' days')::interval

      </querytext>
</partialquery>

<partialquery name="registration_after_days">      
      <querytext>

        creation_date >= now() - (:registration_after_days || ' days')::interval

      </querytext>
</partialquery>

 <partialquery name="last_visit_before_days">      
      <querytext>

        last_visit < now() - (:last_visit_before_days || ' days')::interval

      </querytext>
</partialquery>

<partialquery name="last_visit_after_days">      
      <querytext>

        last_visit >= now() - (:last_visit_after_days || ' days')::interval

      </querytext>
</partialquery>

</queryset>

