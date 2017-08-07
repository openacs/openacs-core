--
-- This change is required by a change of behavior in PostgreSQL 9.3
-- (analysis and fix by Guenter Ernst).
--
-- The old trigger tried to update a deleted ROW,
-- 03/Jan/2017:16:00:36][4864.7f6e84a99700][-conn:production:7-]
-- ERROR:  tuple to be updated was already modified by an operation triggered by the current command
-- HINT:  Consider using an AFTER trigger instead of a BEFORE trigger to propagate changes to other rows.
-- CONTEXT:  SQL statement "delete from cr_revisions where revision_id =  4844142"
-- PL/pgSQL function acs_object__delete(integer) line 37 at EXECUTE
-- SQL statement "SELECT acs_object__delete(v_revision_val.revision_id)"
-- PL/pgSQL function content_item__del(integer) line 17 at PERFORM
-- SQL:
--     select content_item__del('4844140')
--
-- A similar error is found on the postgres mailing list:
-- https://www.postgresql.org/message-id/20140427111305.GF13906%40alap3.anarazel.de
--
-- More background: https://www.postgresql.org/docs/9.6/static/trigger-definition.html
-- 
-- Typically, row-level BEFORE triggers are used for checking or
-- modifying the data that will be inserted or updated. For example, a
-- BEFORE trigger might be used to insert the current time into a
-- timestamp column, or to check that two elements of the row are
-- consistent. Row-level AFTER triggers are most sensibly used to
-- propagate the updates to other tables, or make consistency checks
-- against other tables. The reason for this division of labor is that
-- an AFTER trigger can be certain it is seeing the final value of the
-- row, while a BEFORE trigger cannot; there might be other BEFORE
-- triggers firing after it. If you have no specific reason to make a
-- trigger BEFORE or AFTER, the BEFORE case is more efficient, since
-- the information about the operation doesn't have to be saved until
-- end of statement.

DROP TRIGGER cr_revisions_lob_trig ON cr_revisions;

CREATE TRIGGER cr_revisions_lob_trig AFTER UPDATE or DELETE or INSERT ON cr_revisions
FOR EACH ROW EXECUTE PROCEDURE  on_lob_ref(); 
