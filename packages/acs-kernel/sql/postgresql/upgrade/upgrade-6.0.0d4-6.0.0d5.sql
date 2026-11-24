-- Obsolete overloads left by historical upgrades. Keep the varchar
-- IP-address forms and the one- and two-argument timestamp wrappers.
-- Include the names used when these overloads were temporarily retired.
drop function if exists
    acs_object__update_last_modified(integer, integer, integer),
    acs_object__update_last_modified(integer, integer, integer, timestamptz),
    acs_object_type__drop_type(varchar, boolean, boolean, boolean),
    acs_object__update_last_modified_retired(integer, integer, integer),
    acs_object__update_last_modified_retired(integer, integer, integer, timestamptz),
    acs_object_type__drop_type_retired(varchar, boolean, boolean, boolean)
restrict;
