--
-- packages/acs-kernel/sql/acs-create-2.sql
--
-- @author ben@openforce
-- @creation-date 2000-12-02
-- @cvs-id acs-create.sql,v 1.1.2.9 2000/08/24 07:09:18 rhs Exp
--

--
-- This code sets up additional root concepts, involving the
-- privacy control of personal information. For now, this sets
-- up an extremely simple concept of read_private_data that is NOT
-- derived from read, but rather from admin.
--

declare
begin
	acs_privilege.create_privilege('read_private_data');
	acs_privilege.add_child('admin','read_private_data');
end;
/
show errors


