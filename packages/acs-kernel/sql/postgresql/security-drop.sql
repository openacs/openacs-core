--
-- /packages/acs-kernel/sql/security-drop.sql
--
-- DDL statements to purge the Security data model
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @creation-date 2000-07-27
-- @cvs-id security-drop.sql,v 1.9.2.1 2000/12/07 15:02:15 richardl Exp
--

drop view sec_id_seq;
drop sequence t_sec_id_seq;
drop view sec_security_token_id_seq;
drop sequence t_sec_security_token_id_seq;
drop table sec_session_properties;
drop index sec_sessions_by_server;
drop table secret_tokens;
