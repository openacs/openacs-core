--
-- acs-kernel/sql/acs-objects-drop.sql
--
-- DDL commands to purge the ACS Objects data model
--
-- @author Lars Pind (lars@pinds.com)
-- @creation-date 2000-22-18
-- @cvs-id $Id$
--

\t
CREATE OR REPLACE FUNCTION inline_0 () RETURNS integer AS $$
BEGIN
  PERFORM acs_object_type__drop_type(
    'journal_entry', 'f'
  );
  return null;
END;
$$ LANGUAGE plpgsql;

select inline_0 ();
drop function inline_0 ();
select drop_package('journal_entry');
\t
drop table journal_entries;
