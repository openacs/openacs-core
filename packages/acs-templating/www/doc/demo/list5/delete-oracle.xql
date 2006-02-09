<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="template_demo_note_delete">      
      <querytext>
      
  begin
    template_demo_note.del(:template_demo_note_id);
  end;

      </querytext>
</fullquery>

 
</queryset>
