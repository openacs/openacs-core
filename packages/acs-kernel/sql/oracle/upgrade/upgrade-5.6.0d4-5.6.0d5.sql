alter table apm_parameters add scope varchar(10) default 'instance' check (scope in ('global','instance')) not null;

declare
 attr_id acs_attributes.attribute_id%TYPE;
begin
 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_parameter',
   attribute_name => 'scope',
   datatype => 'string',
   pretty_name => 'Scope',
   pretty_plural => 'Scope'
 );
end;
/
show errors;

