-- $Id$
begin
   delete from acs_objects where object_type ='acs_sc_implementation';
   acs_object_type.drop_type('acs_sc_implementation');

   delete from acs_objects where object_type ='acs_sc_operation';
   acs_object_type.drop_type('acs_sc_operation');
 
   delete from acs_objects where object_type ='acs_sc_contract';
   acs_object_type.drop_type('acs_sc_contract');   
end;
/
show errors

