<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="db_nextval.nextval_sequence">
    <querytext>
      select nextval(:sequence) as nextval
      where (select relkind 
             from pg_class 
             where relname = :sequence) = 'S'
    </querytext>
  </fullquery>

  <fullquery name="db_nextval.nextval_view">
    <querytext>
      select nextval 
      from ${sequence}
    </querytext>
  </fullquery>

</queryset>
