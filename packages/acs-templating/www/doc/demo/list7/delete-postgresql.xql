<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="note_delete">      
      <querytext>
      
    select note__delete( :note_id );

      </querytext>
</fullquery>

 
</queryset>
