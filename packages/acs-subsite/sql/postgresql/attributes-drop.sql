--
-- packages/acs-subsite/sql/attributes-drop.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-02-02
-- @cvs-id $Id$
--
--

declare
  result	varchar2(10);
begin
  result := acs_attribute.create_attribute (
    object_type => 'person',
    attribute_name => 'bio',
    datatype => 'string',
    pretty_name => 'Biography',
    pretty_plural => 'Biographies',
    min_n_values => 0,
    max_n_values => 1,
    storage => 'generic'
  );

  commit;
end;
/
show errors
