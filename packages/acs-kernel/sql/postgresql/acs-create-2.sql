--
-- packages/acs-kernel/sql/acs-create-2.sql
--
-- @author ben@openforce
-- @creation-date 2000-12-02
-- @cvs-id $Id$
--

--
-- This code sets up additional root concepts, involving the
-- privacy control of personal information. For now, this sets
-- up an extremely simple concept of read_private_data that is NOT
-- derived from read, but rather from admin.
--

select acs_privilege__create_privilege('read_private_data');
select acs_privilege__add_child('admin','read_private_data');


