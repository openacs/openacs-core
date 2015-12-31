ALTER TABLE acs_permissions DROP CONSTRAINT IF EXISTS acs_permissions_grantee_id_fk;
ALTER TABLE acs_permissions ADD CONSTRAINT  acs_permissions_grantee_id_fk
      FOREIGN KEY (grantee_id) REFERENCES parties(party_id) ON DELETE CASCADE;

ALTER TABLE acs_permissions DROP CONSTRAINT IF EXISTS acs_permissions_on_what_id_fk;
ALTER TABLE acs_permissions DROP CONSTRAINT IF EXISTS acs_permissions_object_id_fk;
ALTER TABLE acs_permissions ADD CONSTRAINT  acs_permissions_object_id_fk
      FOREIGN KEY (object_id) REFERENCES acs_objects(object_id) ON DELETE CASCADE;

ALTER TABLE acs_permissions DROP CONSTRAINT IF EXISTS acs_permissions_priv_fk;
ALTER TABLE acs_permissions DROP CONSTRAINT IF EXISTS acs_permissions_privilege_fk;
ALTER TABLE acs_permissions ADD CONSTRAINT  acs_permissions_privilege_fk
      FOREIGN KEY (privilege) REFERENCES acs_privileges(privilege) ON DELETE CASCADE;

