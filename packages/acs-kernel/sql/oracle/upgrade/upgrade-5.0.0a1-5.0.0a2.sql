--
-- Upgrade script for acs-kernel
-- 
-- Changes wrong unique constraint on auth_driver_params table to a primary key on authority_id, impl_id, key.
--
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @creation-date 2003-10-16
--
-- @cvs-id $Id$
--

alter table auth_driver_params drop unique (authority_id, impl_id);

alter table auth_driver_params add constraint auth_driver_params_pk
      primary key (authority_id, impl_id, key);
