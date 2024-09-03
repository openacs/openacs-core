--
-- function content_item__rename() was renamed in 2004 by
--   https://github.com/openacs/openacs-core/commit/513b47f52b4729dbf4dca5fcf6dd66eb67f65353#diff-96167ce458e0f45c4293fd88602a92d1
-- but never properly from existing instances
--
DROP FUNCTION IF EXISTS content_item__rename(integer, character varying);


--
-- The following functions were commented out deactivated in 2003
--    https://github.com/openacs/openacs-core/commit/d0332ae883a6ac6af954e0b53fbb3ce95e487507
-- but never deleted properly from existing instances.

DROP FUNCTION IF EXISTS content_item__create_rel_cursor(integer, integer);
DROP FUNCTION IF EXISTS content_item__create_abs_cursor(integer, integer);
DROP FUNCTION IF EXISTS content_item__rel_cursor_next_pos();
DROP FUNCTION IF EXISTS content_item__abs_cursor_next_pos();
DROP FUNCTION IF EXISTS content_item__cleanup_cursors(integer);

--
-- The origins of the following function could not be traced back
--
DROP FUNCTION IF EXISTS content_item__new_temp(character varying, integer, integer, character varying, timestamp with time zone, integer, integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying);
DROP FUNCTION IF EXISTS content_item__new_temp(character varying, integer, integer, character varying, timestamp with time zone, integer, integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, integer);


--
-- The following functions were removed in 2005 by
--     https://github.com/openacs/openacs-core/commit/1cf48b17dd5faa0a2cbd988ab28d3127d3e25c61#diff-f580056c1afc98a3c8bda629878b7ea8
-- but not deleted properly from existing instances
--
DROP FUNCTION IF EXISTS content_revision__import_xml (integer,integer,numeric);
DROP FUNCTION IF EXISTS content_revision__export_xml (integer);
DROP FUNCTION IF EXISTS content_revision__index_attributes (integer);
