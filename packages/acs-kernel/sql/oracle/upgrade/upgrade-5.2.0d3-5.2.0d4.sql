-- Use this table to make it easy to change the attribute set of package versions
-- TODO: Migrate this to use acs_attributes instead?
create table apm_package_version_attr (
    version_id         integer
                       constraint apm_package_vers_attr_vid_fk
                       references apm_package_versions(version_id)
                       on delete cascade
                       constraint apm_package_vers_attr_vid_nn
                       not null,
    attribute_name     varchar(100)
                       constraint apm_package_vers_attr_an_nn
                       not null,
    attribute_value    varchar(4000),
    constraint apm_package_vers_attr_pk
    primary key (version_id, attribute_name)
);
