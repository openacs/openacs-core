-- 
-- Upgrade script from 5.0d3 to 5.0d4
--
-- Adds table auth_driver_params
--
-- @author Simon Carstensen (simon@collaboraid.biz)
--
-- @cvs-id $Id$
--

create table auth_driver_params(
      authority_id    integer
                      constraint auth_driver_params_aid_fk 
                      references auth_authorities(authority_id)
                      constraint auth_driver_params_aid_nn
                      not null,
      impl_id         integer
                      constraint auth_driver_params_iid_fk
                      -- Cannot reference acs_sc_impls table as it doesn't exist yet
                      references acs_objects(object_id)
                      constraint auth_driver_params_iid_nn
                      not null,
      key             text,
      value           text,
      unique (authority_id, impl_id)
);
