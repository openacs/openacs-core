--
-- acs-kernel/sql/acs-objects-drop.sql
--
-- DDL commands to purge the ACS Objects data model
--
-- @author Lars Pind (lars@pinds.com)
-- @creation-date 2000-22-18
-- @cvs-id $Id$
--

begin
  acs_object_type.drop_type(
    object_type => 'journal_entry'
  );
end;
/
show errors

drop package journal_entry;
drop table journal_entries;
