--
-- acs-kernel/sql/acs-objects-drop.sql
--
-- DDL commands to purge the ACS Objects data model
--
-- @author Lars Pind (lars@pinds.com)
-- @creation-date 2000-22-18
-- @cvs-id journal-drop.sql,v 1.5 2000/10/24 22:26:20 bquinn Exp
--

\t
create function inline_0 () returns integer as '
begin
  PERFORM acs_object_type__drop_type(
    ''journal_entry'', ''f''
  );
  return null;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();
select drop_package('journal_entry');
\t
drop table journal_entries;
