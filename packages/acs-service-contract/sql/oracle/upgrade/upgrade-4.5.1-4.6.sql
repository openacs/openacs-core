-- packages/acs-service-contract/sql/oracle/upgrade/upgrade-4.5.1-4.6.sql
--
-- @author Vinod Kurup (vinod@kurup.com)
-- @creation_date 2002-10-08
--
-- $Id$

-- UPGRADE ISSUE #1
-- add timestamp datatype

declare
    v_count       integer;
    v_msg_type_id	acs_sc_msg_types.msg_type_id%TYPE;
begin

        select count(*) into v_count from acs_sc_msg_types
        where msg_type_name = 'timestamp';

        if v_count = 0 then
           v_msg_type_id := acs_sc_msg_type.new('timestamp','');
        end if;
end;
/
show errors
