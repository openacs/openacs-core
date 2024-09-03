<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="drop_relationship_type">      
      <querytext>
	select acs_rel_type__drop_type(:rel_type,'t')
      </querytext>
</fullquery>

</queryset>
