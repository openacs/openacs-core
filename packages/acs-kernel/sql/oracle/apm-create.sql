--
-- /packages/acs-kernel/sql/apm-create.sql
--
-- Data model for the OpenACS Package Manager (APM)
--
-- @author Bryan Quinn (bquinn@arsdigita.com)
-- @author Jon Salz (jsalz@mit.edu)
-- @creation-date 2000/04/30
-- @cvs-id $Id$

-----------------------------
--     PACKAGE OBJECT	   --
-----------------------------

-----------------------------
--     Knowledge Level	   --
-----------------------------

create table apm_package_types (
    package_key			varchar2(100)
				constraint apm_package_types_pkg_key_pk primary key,
    pretty_name			varchar(100)
    	    	    	    	constraint apm_package_types_pretty_n_nn not null
				constraint apm_package_types_pretty_n_un unique,
    pretty_plural	        varchar2(100)
				constraint apm_package_types_pretty_pl_un unique,
    package_uri			varchar2(1500)
				constraint apm_packages_types_pkg_uri_nn not null
				constraint apm_packages_types_pkg_uri_un unique,
    package_type		varchar2(300)
				constraint apm_packages_pack_type_ck 
				check (package_type in ('apm_application', 'apm_service')),
    spec_file_path		varchar2(1500),
    spec_file_mtime		integer,
    initial_install_p		char(1) default 'f' not null
				constraint apm_packages_init_install_p_ck
				check (initial_install_p in ('t', 'f')),
    singleton_p			char(1) default 'f' not null
				constraint apm_packages_singleton_p_ck
				check (singleton_p in ('t', 'f')),
    implements_subsite_p        char(1) default 'f' not null
				constraint apm_packages_impl_subsite_p_ck
				check (implements_subsite_p in ('t', 'f')),
    inherit_templates_p         char(1) default 't' not null
				constraint apm_packages_inherit_t_p_ck
				check (inherit_templates_p in ('t', 'f'))
);

comment on table apm_package_types is '
 This table holds additional knowledge level attributes for the
 apm_package type and its subtypes.
';


comment on column apm_package_types.package_key is '
 The package_key is what we call the package on this system.
';

comment on column apm_package_types.package_uri is '
 The package URI indicates where the package can be downloaded and 
 is a unique identifier for the package.
';

comment on column apm_package_types.spec_file_path is '
 The path to the package specification file.
';

comment on column apm_package_types.spec_file_mtime is '
 The last time a spec file was modified.  This information is maintained in the 
database so that if a user changes the specification file by editing the file
(as opposed to using the UI, the system can read the .info file and update
the information in the database appropriately.
';

comment on column apm_package_types.singleton_p is '
 Indicates if the package can be used for subsites.  If this is set to 
 ''t'', the package can be enabled for any subsite.  Otherwise, it is 
 restricted to the acs-admin/ subsite.
';

comment on column apm_package_types.initial_install_p is '
 Indicates if the package should be installed during initial installation,
 in other words whether or not this package is part of the OpenACS core.
';

comment on column apm_package_types.implements_subsite_p is '
  If true, this package implements subsite semantics, typically by extending the
  acs-subsite package.  Used by the admin "mount subsite" UI, the request processor (for
  setting ad_conn''s subsite_* attributes), etc.
';

comment on column apm_package_types.inherit_templates_p is '
  If true, inherit templates from packages this package extends.  If false, only
  templates in this package''s www subdirectory tree will be mapped to URLs by the
  request processor.
';

begin
-- Create a new object type for packages.
 acs_object_type.create_type (
   supertype => 'acs_object',
   object_type => 'apm_package',
   pretty_name => 'Package',
   pretty_plural => 'Packages',
   table_name => 'apm_packages',
   id_column => 'package_id',
   package_name => 'apm_package',
   type_extension_table => 'apm_package_types',
   name_method => 'apm_package.name'
 );
end;
/
show errors;

declare
 attr_id acs_attributes.attribute_id%TYPE;
begin
-- Register the meta-data for APM-packages
 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package',
   attribute_name => 'package_key',
   datatype => 'string',
   pretty_name => 'Package Key',
   pretty_plural => 'Package Keys'
 );

end;
/
show errors;

create table apm_packages (
    package_id			constraint apm_packages_package_id_fk
				references acs_objects(object_id)
				constraint apm_packages_package_id_pk primary key,
    package_key			constraint apm_packages_package_key_fk
				references apm_package_types(package_key),
    instance_name		varchar2(300)
			        constraint apm_packages_instance_name_nn not null,
    -- default system locale for this package
    default_locale              varchar2(30)
);

-- create bitmap index apm_packages_package_key_idx on apm_packages (package_key);
create index apm_packages_package_key_idx on apm_packages (package_key);

-- This can't be added at table create time since acs_objects is created before apm_packages;
alter table acs_objects add constraint acs_objects_package_id_fk foreign key (package_id) references apm_packages(package_id) on delete set null;

comment on table apm_packages is '
   This table maintains the list of all package instances in the system. 
';

comment on column apm_packages.instance_name is '
   This column enables a name to associated with each instance of package.  This enables the storage
of a human-readable distinction between different package instances.  This is useful
if a site admin wishes to name an instance of an application, e.g. bboard, for a subsite.  The admin
might create one instance, "Boston Public Bboard" for managing public forums for the Boston subsite,
and "Boston Private Bboard" for managing private forums for the Boston subsite.
';

-----------------------------
--   Operational  Level	   --
-----------------------------

create table apm_package_versions (
    version_id         integer
                       constraint apm_package_vers_id_pk primary key
		       constraint apm_package_vers_id_fk	
		         references acs_objects(object_id),
    package_key        varchar2(100) 
		       constraint apm_package_vers_pack_key_nn not null
		       constraint apm_package_vers_pack_key_fk 
		         references apm_package_types(package_key),
    version_name       varchar2(100)
                       constraint apm_package_vers_ver_name_nn not null,
    version_uri        varchar2(1500)
                       constraint apm_package_vers_ver_uri_nn not null
                       constraint apm_package_vers_ver_uri_un unique,
    summary 	       varchar2(3000),
    description_format varchar2(100)
		       constraint apm_package_vers_desc_for_ck
		         check (description_format in ('text/html', 'text/plain')),
    description        varchar2(4000),
    release_date       date,
    vendor             varchar2(500),
    vendor_uri         varchar2(1500),
    enabled_p          char(1) default 'f'
                       constraint apm_package_vers_enabled_p_nn not null
                       constraint apm_package_vers_enabled_p_ck check(enabled_p in ('t','f')),
    installed_p        char(1) default 'f'
                       constraint apm_package_vers_inst_p_nn not null
                       constraint apm_package_vers_inst_p_ck check(installed_p in ('t','f')),
    tagged_p           char(1) default 'f'
                       constraint apm_package_vers_tagged_p_nn not null
                       constraint apm_package_vers_tagged_p_ck check(tagged_p in ('t','f')),
    imported_p         char(1) default 'f'
                       constraint apm_package_vers_imp_p_nn not null
                       constraint apm_package_vers_imp_p_ck check(imported_p in ('t','f')),
    data_model_loaded_p char(1) default 'f'
                       constraint apm_package_vers_dml_p_nn not null
                       constraint apm_package_vers_dml_p_ck check(data_model_loaded_p in ('t','f')),
    cvs_import_results clob,
    activation_date    date,
    deactivation_date  date,
    -- distribution_tarball blob,
    item_id            integer,
    content_length     integer,
    distribution_uri   varchar2(1500),
    distribution_date  date,
    auto_mount         varchar(50),
    constraint apm_package_vers_id_name_un unique(package_key, version_name)
);

comment on table apm_package_versions is '
 The table apm_package_versions contains one row for each version of each package
 we know about, e.g., acs-kernel-3.3, acs-kernel-3.3.1, bboard-1.0,
 bboard-1.0.1, etc.
';

comment on column apm_package_versions.version_name is '
A version number consists of: 
   1.A major version number. 
   2.Optionally, up to three minor version numbers. 
   3.One of the following: 
         The letter d, indicating a development-only version.
         The letter a, indicating an alpha release.
         The letter b, indicating a beta release. 
         No letter at all, indicating a final release.
In addition, the letters d, a, and b may be followed by another integer, indicating a version within the release. 
For those who like regular expressions: 
     version_number := integer (''.'' integer){0,3} ((''d''|''a''|''b'') integer?)?
So the following is a valid progression for version numbers: 
     0.9d, 0.9d1, 0.9a1, 0.9b1, 0.9b2, 0.9, 1.0, 1.0.1, 1.1b1, 1.1
';

comment on column apm_package_versions.version_uri is '
  This column should uniquely identify a package version.  This URI should in practice be a URL at which this specific
version can be downloaded.  
';

comment on column apm_package_versions.summary is '
Type a brief, one-sentence-or-less summary of the functionality of 
your package.  The summary should begin with a capital letter 
and end with a period. 
XXX (bquinn): Move to Content Repository?
';

comment on column apm_package_versions.description_format is '
 Must indicate whether the description is plain text or HTML.
';

comment on column apm_package_versions.description is '
Type a one-paragraph description of your package. This is probably analogous 
to the first paragraph in your package''s documentation.  This is used to describe
the system to users considering installing it.
';

comment on column apm_package_versions.release_date is '
This tracks when the package was released. Releasing a package means
freezing the code and files, creating an archive, and making the
package available for donwload. XXX (bquinn): I''m skeptical about the
usefulness of storing this information here.
';

comment on column apm_package_versions.vendor is '
If the package is being released by a company or some kind of organization, 
its name should go here.
';

comment on column apm_package_versions.vendor_uri is '
This should be a URL pointing to the vendor.
';

comment on column apm_package_versions.enabled_p is '
 Is the version scheduled to be loaded at startup?
';

comment on column apm_package_versions.installed_p is '
 Is the version actually present in the filesystem?
';

comment on column apm_package_versions.tagged_p is '
 Have we ever assigned all the files in this version a CVS tag.
 XXX (bquinn): deprecated.  CVS management should not be through
 this table.
';

comment on column apm_package_versions.imported_p is '
 Did we perform a vendor import on this version?
 XXX (bquinn): deprecated.  CVS management should not be through
 this table.
';

comment on column apm_package_versions.data_model_loaded_p is '
 Have we brought the data model up to date for this version.
 XXX (bquinn): deprecated.  Its not useful to track this information.
';

comment on column apm_package_versions.cvs_import_results is '
 Store the results of an attempted CVS import.
 XXX (bquinn): deprecated.  CVS management should not be through
 this table.
';

comment on column apm_package_versions.activation_date is '
 When was the version last enabled?
 XXX (bquinn): do we really care about this enough to keep the information around?
';

comment on column apm_package_versions.deactivation_date is '
 When was the version last disabled?
 XXX (bquinn): do we really care about this enough to keep the information around?
';

comment on column apm_package_versions.item_id is '
 The archive of the distribution.
 XXX (bquinn):   This should definitely be moved
 to the content repository and renamed distribution_archive, or simply 
 stored in the file system.
';

comment on column apm_package_versions.distribution_uri is '
 Where was the distribution tarball downloaded from.
';

comment on column apm_package_versions.distribution_date is '
 When was the distribution tarball downloaded.
';

comment on column apm_package_versions.auto_mount is '
 A dir under the main site site node where an instance of the package will be mounted
 automatically upon installation. Useful for site-wide services that need mounting
 such as general-comments and notifications.
';

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

-- Metadata for the apm_package_versions object.

declare
 attr_id acs_attributes.attribute_id%TYPE;
begin
 acs_object_type.create_type (
   supertype => 'acs_object',
   object_type => 'apm_package_version',
   pretty_name => 'Package Version',
   pretty_plural => 'Package Versions',
   table_name => 'apm_package_versions',
   id_column => 'version_id',
   package_name => 'apm_package_version'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'package_key',
   datatype => 'string',
   pretty_name => 'Package Key',
   pretty_plural => 'Package Keys'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'version_name',
   datatype => 'string',
   pretty_name => 'Version Name',
   pretty_plural => 'Version Names'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'version_uri',
   datatype => 'string',
   pretty_name => 'Version URI',
   pretty_plural => 'Version URIs'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'summary',
   datatype => 'string',
   pretty_name => 'Summary',
   pretty_plural => 'Summaries'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'description_format',
   datatype => 'string',
   pretty_name => 'Description Format',
   pretty_plural => 'Description Formats'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'description',
   datatype => 'string',
   pretty_name => 'Description',
   pretty_plural => 'Descriptions'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'vendor',
   datatype => 'string',
   pretty_name => 'Vendor',
   pretty_plural => 'Vendors'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'vendor_uri',
   datatype => 'string',
   pretty_name => 'Vendor URI',
   pretty_plural => 'Vendor URIs'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'enabled_p',
   datatype => 'boolean',
   pretty_name => 'Enabled',
   pretty_plural => 'Enabled'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'activation_date',
   datatype => 'date',
   pretty_name => 'Activation Date',
   pretty_plural => 'Activation Dates'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'deactivation_date',
   datatype => 'date',
   pretty_name => 'Deactivation Date',
   pretty_plural => 'Deactivation Dates'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'distribution_uri',
   datatype => 'string',
   pretty_name => 'Distribution URI',
   pretty_plural => 'Distribution URIs'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_package_version',
   attribute_name => 'distribution_date',
   datatype => 'date',
   pretty_name => 'Distribution Date',
   pretty_plural => 'Distribution Dates'
 );

end;
/
show errors;

-- Who owns a version?
create table apm_package_owners (
    version_id         constraint apm_package_owners_ver_id_fk references apm_package_versions on delete cascade,
    -- if the uri is an email address, it should look like 'mailto:someguy@openacs.org'
    owner_uri          varchar2(1500),
    owner_name         varchar2(200)
                       constraint apm_package_owners_name_nn not null,
    sort_key           integer
);

create index apm_pkg_owners_version_idx on apm_package_owners (version_id);

comment on table apm_package_owners is '
 This table tracks all of the owners of a particular package, and their email information.  The sort_key column
 manages the order of the authors.
';

create table apm_package_callbacks (
    version_id         integer 
                       constraint apm_package_callbacks_vid_fk 
                       references apm_package_versions(version_id)
                       on delete cascade,
    type               varchar(40),
    proc               varchar(300),
    constraint apm_package_callbacks_vt_un
    unique (version_id, type)
);

comment on table apm_package_callbacks is '
  This table holds names of Tcl procedures to invoke at the time (before or after) the package is
  installed, instantiated, or mounted.        
';

comment on column apm_package_callbacks.proc is '
  Name of the Tcl proc.
';

comment on column apm_package_callbacks.type is '
  Indicates when the callback proc should be invoked, for example after-install. Valid
  values are given by the Tcl proc apm_supported_callback_types.
';

-- Ths view facilitates accessing information about package versions by joining
-- the apm_package_types information and acs_object_types information (which is
-- invariant across versions) with the specific version information.

-- DCW - 2001-05-04, converted tarball storage to use content repository.
create or replace view apm_package_version_info as
    select v.package_key, t.package_uri, t.pretty_name, t.singleton_p, t.initial_install_p,
           v.version_id, v.version_name,
           t.inherit_templates_p, t.implements_subsite_p,
           v.version_uri, v.summary, v.description_format, v.description, v.release_date,
           v.vendor, v.vendor_uri, v.auto_mount, v.enabled_p, v.installed_p, v.tagged_p,
           v.imported_p, v.data_model_loaded_p,
           v.activation_date, v.deactivation_date,
           nvl(v.content_length,0) as tarball_length,
           distribution_uri, distribution_date
    from   apm_package_types t, apm_package_versions v
    where  v.package_key = t.package_key;

-- A useful view for simply determining which packages are eanbled.
create or replace view apm_enabled_package_versions as
    select * from apm_package_version_info
    where  enabled_p = 't';

create table apm_package_db_types (
    db_type_key      varchar2(50)
                       constraint apm_package_db_types_pk primary key,
    pretty_db_name   varchar2(200)
                       constraint apm_package_db_types_name_nn not null
);

comment on table apm_package_db_types is '
  A list of all the different kinds of database engines that an APM package can
  support.  This table is initialized in acs-tcl/tcl/apm-init.tcl rather than in
  PL/SQL in order to guarantee that the list of supported database engines is
  consistent between the bootstrap code and the package manager.
';

create table apm_parameters (
	parameter_id		constraint apm_parameters_parameter_id_fk 
				references acs_objects(object_id)
			        constraint apm_parameters_parameter_id_pk primary key,
	package_key		varchar2(100)
				constraint apm_parameters_package_key_nn not null 	
				constraint apm_parameters_package_key_fk
			        references apm_package_types (package_key),
	parameter_name		varchar2(100) 
				constraint apm_pack_params_name_nn not null,
        scope                   varchar2(20) default 'instance'
                                constraint apm_parameters_scope_ck
                                check (scope in ('global','instance'))
                                constraint apm_parameters_scope_nn not null,
        description		varchar2(2000),
	section_name		varchar2(200),
	datatype	        varchar2(100) 
				constraint apm_parameters_datatype_nn not null
			        constraint apm_parameters_datatype_ck 
				check(datatype in ('number', 'string','text')),
	default_value		varchar2(4000),
	min_n_values		integer default 1 
				constraint apm_parameters_min_n_values_nn not null
			        constraint apm_parameters_min_n_values_ck
			        check (min_n_values >= 0),
	max_n_values		integer default 1 
				constraint apm_parameters_max_n_values_nn not null
			        constraint apm_paramaters_max_n_values_ck
			        check (max_n_values >= 0),
	constraint apm_paramters_attr_name_un
	unique (parameter_name, package_key),
	constraint apm_paramters_n_values_ck
	check (min_n_values <= max_n_values)
);

create index apm_parameters_package_idx on apm_parameters (package_key);

comment on table apm_parameters is '
  This table stores information about parameters on packages.  Every package parameter
is specific to a particular package instance and is queryable with the Tcl call 
parameter::get.
';

comment on column apm_parameters.parameter_name is '
  This is the name of the parameter, for example "DebugP."
';

comment on column apm_parameters.scope is '
  If the scope is "global", only one value of the parameter exists for the entire site.
  If "instance", each package instance has its own value.
';

comment on column apm_parameters.description is '
  A human readable description of what the parameter is used for.
';

comment on column apm_parameters.datatype is '
 Acceptable datatypes for parameters.  Currently only numbers and strings.
 XXX (bquinn): Integrate with acs objects metadata system.  It is not 
 currently so integrated because of fluctuations with the general 
 storage mechanism during development.
';

comment on column apm_parameters.default_value is '
  The default value that any package instance will inherit unless otherwise
  specified. 
';

comment on column apm_parameters.min_n_values is '
  The minimum number of values that this parameter can take.  Zero values means
  that the default is always enforced (but is somewhat pointless).  One value means that
  it can only be set to one value.  Increasing this number beyond one enables associating 
  a list of values with a parameter.  
  XXX (bquinn): More than one value is not supported by the parameter::get call at this time.
';

comment on column apm_parameters.max_n_values is '
The maximum number of values that any attribute with this datatype
 can have. 
';

create table apm_parameter_values (
	value_id		constraint apm_parameter_values_fk
				references acs_objects(object_id)
				constraint apm_parameter_values_pk primary key,
	package_id		constraint apm_pack_values_obj_id_fk
				references apm_packages (package_id) on delete cascade,
	parameter_id		constraint apm_pack_values_parm_id_fk
				references apm_parameters (parameter_id),
	attr_value		varchar2(4000),
	constraint apm_parameter_values_un 
	unique (package_id, parameter_id)
);

create index apm_par_vals_parameter_idx on apm_parameter_values (parameter_id);

comment on table apm_parameter_values is '
 This table holds the values of parameters for package instances.
';

comment on column apm_parameter_values.attr_value is '
 This column holds the value for the instance parameter.
';

-- Metadata for the apm_parameter and apm_parameter_value system.

declare
 attr_id acs_attributes.attribute_id%TYPE;
begin
 acs_object_type.create_type (
   supertype => 'acs_object',
   object_type => 'apm_parameter',
   pretty_name => 'Package Parameter',
   pretty_plural => 'Package Parameters',
   table_name => 'apm_parameters',
   id_column => 'parameter_id',
   package_name => 'apm_parameter'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_parameter',
   attribute_name => 'package_key',
   datatype => 'string',
   pretty_name => 'Package Key',
   pretty_plural => 'Package Keys'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_parameter',
   attribute_name => 'parameter_name',
   datatype => 'string',
   pretty_name => 'Parameter Name',
   pretty_plural => 'Parameter Name'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_parameter',
   attribute_name => 'scope',
   datatype => 'string',
   pretty_name => 'Scope',
   pretty_plural => 'Scope'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_parameter',
   attribute_name => 'datatype',
   datatype => 'string',
   pretty_name => 'Datatype',
   pretty_plural => 'Datatypes'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_parameter',
   attribute_name => 'default_value',
   datatype => 'string',
   pretty_name => 'Default Value',
   pretty_plural => 'Default Values'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_parameter',
   attribute_name => 'min_n_values',
   datatype => 'number',
   pretty_name => 'Minimum Number of Values',
   pretty_plural => 'Minimum Numer of Values Settings',
   default_value => 1
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_parameter',
   attribute_name => 'max_n_values',
   datatype => 'integer',
   pretty_name => 'Maximum Number of Values',
   pretty_plural => 'Maximum Number of Values Settings',
   default_value => 1
 );
end;
/
show errors;


declare
 attr_id acs_attributes.attribute_id%TYPE;
begin
 acs_object_type.create_type (
   supertype => 'acs_object',
   object_type => 'apm_parameter_value',
   pretty_name => 'APM Package Parameter Value',
   pretty_plural => 'APM Package Parameter Values',
   table_name => 'apm_parameter_values',
   id_column => 'value_id',
   package_name => 'apm_parameter_value'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_parameter_value',
   attribute_name => 'package_id',
   datatype => 'number',
   pretty_name => 'Package ID',
   pretty_plural => 'Package IDs'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_parameter_value',
   attribute_name => 'parameter_id',
   datatype => 'number',
   pretty_name => 'Parameter ID',
   pretty_plural => 'Parameter IDs'
 );

 attr_id := acs_attribute.create_attribute(
   object_type => 'apm_parameter_value',
   attribute_name => 'attr_value',
   datatype => 'string',
   pretty_name => 'Parameter Value',
   pretty_plural => 'Parameter Values'
 );
end;
/
show errors;

create table apm_package_dependencies (
    dependency_id      integer 
                       constraint apm_package_deps_id_pk primary key,
    version_id         constraint apm_package_deps_version_id_fk references apm_package_versions on delete cascade
                       constraint apm_package_deps_version_id_nn not null,
    dependency_type    varchar2(20)
                       constraint apm_package_deps_type_nn not null
                       constraint apm_package_deps_type_ck
                       check(dependency_type in ('embeds', 'extends', 'provides','requires')),
    service_uri        varchar2(1500)
                       constraint apm_package_deps_uri_nn not null,
    service_version    varchar2(100)
                       constraint apm_package_deps_ver_name_nn not null,
    constraint apm_package_deps_un unique(version_id, service_uri)
);

comment on table apm_package_dependencies is '
 This table indicates what services are provided or required by a particular version.
';

comment on column apm_package_dependencies.service_version is '
 The restrictions on service version should match those on apm_package_versions.version_name.
';


create table apm_applications (
       application_id		integer
				constraint applications_application_id_fk
				references apm_packages(package_id)
				constraint applications_pk primary key
);

comment on table apm_applications is '
This table records data on all of the applications registered in OpenACS.
';


create table apm_services (
       service_id			integer
					constraint apm_services_service_id_fk
					references apm_packages(package_id)
				        constraint apm_services_service_id_pk primary key
);

comment on table apm_services is '
This table records data on all of the services registered in OpenACS. 
';


begin
-- Create a new object type for applications.
 acs_object_type.create_type (
   supertype => 'apm_package',
   object_type => 'apm_application',
   pretty_name => 'Application',
   pretty_plural => 'Applications',
   table_name => 'apm_applications',
   id_column => 'application_id',
   package_name => 'apm_application'
 );
end;
/
show errors


begin
-- Create a new object type for services.
 acs_object_type.create_type (
   supertype => 'apm_package',
   object_type => 'apm_service',
   pretty_name => 'Service',
   pretty_plural => 'Services',
   table_name => 'apm_services',
   id_column => 'service_id',
   package_name => 'apm_service'
 );
end;
/
show errors

-- Public Programmer level API.
create or replace package apm
as
  procedure register_package (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    package_type		in apm_package_types.package_type%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default 'f',    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default 't',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  );

  function update_package (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE
    	    	    	    	default null,
    pretty_plural		in apm_package_types.pretty_plural%TYPE
    	    	    	    	default null,
    package_uri			in apm_package_types.package_uri%TYPE
    	    	    	    	default null,
    package_type		in apm_package_types.package_type%TYPE
    	    	    	    	default null,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
    	    	    	    	default null,    
    singleton_p			in apm_package_types.singleton_p%TYPE 
    	    	    	    	default null,    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default null,    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default null,    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
    	    	    	    	default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) return apm_package_types.package_type%TYPE;   
   
  procedure unregister_package (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 't'
  );

  function register_p (
    package_key		in apm_package_types.package_key%TYPE
  ) return integer;

  -- Informs the APM that this application is available for use.
  procedure register_application (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default 'f',    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default 't',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  );

  -- Remove the application from the system. 
  procedure unregister_application (
    package_key		in apm_package_types.package_key%TYPE,
    -- Delete all objects associated with this application.	
    cascade_p		in char default 'f'
  ); 

  procedure register_service (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default 'f',    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default 't',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  );

  -- Remove the service from the system. 
  procedure unregister_service (
    package_key		in apm_package_types.package_key%TYPE,
    -- Delete all objects associated with this service.	
    cascade_p		in char default 'f'
  ); 

  -- Indicate to APM that a parameter is available to the system.
  function register_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE 
				default null,
    package_key			in apm_parameters.package_key%TYPE,				
    parameter_name		in apm_parameters.parameter_name%TYPE,
    description			in apm_parameters.description%TYPE
				default null,
    scope                       in apm_parameters.scope%TYPE
                                default 'instance',
    datatype			in apm_parameters.datatype%TYPE 
				default 'string',
    default_value		in apm_parameters.default_value%TYPE 
				default null,
    section_name		in apm_parameters.section_name%TYPE
				default null,
    min_n_values		in apm_parameters.min_n_values%TYPE 
				default 1,
    max_n_values		in apm_parameters.max_n_values%TYPE 
				default 1
  ) return apm_parameters.parameter_id%TYPE;

  function update_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
    	    	    	    	default null,
    description			in apm_parameters.description%TYPE
				default null,
    datatype			in apm_parameters.datatype%TYPE 
				default 'string',
    default_value		in apm_parameters.default_value%TYPE 
				default null,
    section_name		in apm_parameters.section_name%TYPE
				default null,
    min_n_values		in apm_parameters.min_n_values%TYPE 
				default 1,
    max_n_values		in apm_parameters.max_n_values%TYPE 
				default 1
  ) return apm_parameters.parameter_name%TYPE;

  function parameter_p(
    package_key                 in apm_package_types.package_key%TYPE,
    parameter_name              in apm_parameters.parameter_name%TYPE
  ) return integer;

  -- Remove any uses of this parameter.
  procedure unregister_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE 
				default null
  );

  function id_for_name (
    package_key in apm_parameters.package_key%TYPE,
    parameter_name in apm_parameters.parameter_name%TYPE
  ) return apm_parameters.parameter_id%TYPE;

  function id_for_name (
    package_id in apm_packages.package_id%TYPE,
    parameter_name in apm_parameters.parameter_name%TYPE
  ) return apm_parameters.parameter_id%TYPE;

  function get_value (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameter_values.attr_value%TYPE;

  function get_value (
    package_key			in apm_packages.package_key%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameter_values.attr_value%TYPE;

  procedure set_value (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  );	

  procedure set_value (
    package_key			in apm_packages.package_key%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  );	

end apm;
/
show errors

create or replace package apm_package
as

function new (
  package_id		in apm_packages.package_id%TYPE 
			default null,
  instance_name		in apm_packages.instance_name%TYPE
			default null,
  package_key		in apm_packages.package_key%TYPE,
  object_type		in acs_objects.object_type%TYPE
			default 'apm_package', 
  creation_date		in acs_objects.creation_date%TYPE 
			default sysdate,
  creation_user		in acs_objects.creation_user%TYPE 
			default null,
  creation_ip		in acs_objects.creation_ip%TYPE 
			default null,
  context_id		in acs_objects.context_id%TYPE 
			default null
  ) return apm_packages.package_id%TYPE;

  procedure del (
   package_id		in apm_packages.package_id%TYPE
  );

  function initial_install_p (
	package_key		in apm_packages.package_key%TYPE
  ) return integer;

  function singleton_p (
	package_key		in apm_packages.package_key%TYPE
  ) return integer;

  function num_instances (
	package_key		in apm_package_types.package_key%TYPE
  ) return integer;

  function name (
    package_id		in apm_packages.package_id%TYPE
  ) return varchar2;

  function highest_version (
   package_key		in apm_package_types.package_key%TYPE
  ) return apm_package_versions.version_id%TYPE;
  
    function parent_id (
        package_id in apm_packages.package_id%TYPE
    ) return apm_packages.package_id%TYPE;

  function is_child (
    parent_package_key in apm_packages.package_key%TYPE,
    child_package_key in apm_packages.package_key%TYPE
  ) return char;

end apm_package;
/
show errors

create or replace package apm_package_version
as
  function new (
    version_id			in apm_package_versions.version_id%TYPE
					default null,
    package_key			in apm_package_versions.package_key%TYPE,
    version_name		in apm_package_versions.version_name%TYPE 
					default null,
    version_uri			in apm_package_versions.version_uri%TYPE,
    summary			in apm_package_versions.summary%TYPE,
    description_format		in apm_package_versions.description_format%TYPE,
    description			in apm_package_versions.description%TYPE,
    release_date		in apm_package_versions.release_date%TYPE,
    vendor			in apm_package_versions.vendor%TYPE,
    vendor_uri			in apm_package_versions.vendor_uri%TYPE,
    auto_mount                  in apm_package_versions.auto_mount%TYPE,
    installed_p			in apm_package_versions.installed_p%TYPE
					default 'f',
    data_model_loaded_p		in apm_package_versions.data_model_loaded_p%TYPE
				        default 'f'
  ) return apm_package_versions.version_id%TYPE;

  procedure del (
      version_id		in apm_packages.package_id%TYPE
  );

  procedure enable (
       version_id			in apm_package_versions.version_id%TYPE
  );

  procedure disable (
       version_id			in apm_package_versions.version_id%TYPE
  );

 function edit (
      new_version_id		in apm_package_versions.version_id%TYPE
				default null,
      version_id		in apm_package_versions.version_id%TYPE,
      version_name		in apm_package_versions.version_name%TYPE 
				default null,
      version_uri		in apm_package_versions.version_uri%TYPE,
      summary			in apm_package_versions.summary%TYPE,
      description_format	in apm_package_versions.description_format%TYPE,
      description		in apm_package_versions.description%TYPE,
      release_date		in apm_package_versions.release_date%TYPE,
      vendor			in apm_package_versions.vendor%TYPE,
      vendor_uri		in apm_package_versions.vendor_uri%TYPE,
      auto_mount                in apm_package_versions.auto_mount%TYPE,
      installed_p		in apm_package_versions.installed_p%TYPE
				default 'f',
      data_model_loaded_p	in apm_package_versions.data_model_loaded_p%TYPE
				default 'f'
    ) return apm_package_versions.version_id%TYPE;

  -- Add an interface provided by this version.
  function add_interface(
    interface_id		in apm_package_dependencies.dependency_id%TYPE
			        default null,
    version_id			in apm_package_versions.version_id%TYPE,
    interface_uri		in apm_package_dependencies.service_uri%TYPE,
    interface_version		in apm_package_dependencies.service_version%TYPE
  ) return apm_package_dependencies.dependency_id%TYPE;

  procedure remove_interface(
    interface_id		in apm_package_dependencies.dependency_id%TYPE
  );

  procedure remove_interface(
    interface_uri		in apm_package_dependencies.service_uri%TYPE,
    interface_version		in apm_package_dependencies.service_version%TYPE,
    version_id			in apm_package_versions.version_id%TYPE
  );

  -- Add a requirement for this version.  A requirement is some interface that this
  -- version depends on.
  function add_dependency(
    dependency_id		in apm_package_dependencies.dependency_id%TYPE
			        default null,
    dependency_type             in apm_package_dependencies.dependency_type%TYPE,
    version_id			in apm_package_versions.version_id%TYPE,
    dependency_uri		in apm_package_dependencies.service_uri%TYPE,
    dependency_version		in apm_package_dependencies.service_version%TYPE
  ) return apm_package_dependencies.dependency_id%TYPE;

  procedure remove_dependency(
    dependency_id		in apm_package_dependencies.dependency_id%TYPE
  );

  procedure remove_dependency(
    dependency_uri		in apm_package_dependencies.service_uri%TYPE,
    dependency_version		in apm_package_dependencies.service_version%TYPE,
    version_id			in apm_package_versions.version_id%TYPE
  );

  -- Given a version_name (e.g. 3.2a), return
  -- something that can be lexicographically sorted.
  function sortable_version_name (
    version_name		in apm_package_versions.version_name%TYPE
  ) return varchar2;

  -- Given two version names, return 1 if one > two, -1 if two > one, 0 otherwise. 
  -- Deprecate?
  function version_name_greater(
    version_name_one		in apm_package_versions.version_name%TYPE,
    version_name_two		in apm_package_versions.version_name%TYPE
  ) return integer;

  function upgrade_p(
    path			in varchar2,
    initial_version_name	in apm_package_versions.version_name%TYPE,
    final_version_name		in apm_package_versions.version_name%TYPE
   ) return integer;

  procedure upgrade(
    version_id                  in apm_package_versions.version_id%TYPE
  );

end apm_package_version;
/
show errors

create or replace package apm_package_type
as
 procedure create_type(
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in acs_object_types.pretty_name%TYPE,
    pretty_plural		in acs_object_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    package_type		in apm_package_types.package_type%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE,
    singleton_p			in apm_package_types.singleton_p%TYPE,
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE,
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE,
    spec_file_path		in apm_package_types.spec_file_path%TYPE default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE default null
  );

  function update_type (    
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in acs_object_types.pretty_name%TYPE
    	    	    	    	default null,
    pretty_plural		in acs_object_types.pretty_plural%TYPE
    	    	    	    	default null,
    package_uri			in apm_package_types.package_uri%TYPE
    	    	    	    	default null,    
    package_type		in apm_package_types.package_type%TYPE
    	    	    	    	default null,
    initial_install_p		in apm_package_types.initial_install_p%TYPE
    	    	    	    	default null,
    singleton_p			in apm_package_types.singleton_p%TYPE
    	    	    	    	default null,
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default null,
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default null,    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
    	    	    	    	default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE
    	    	    	    	 default null
  ) return apm_package_types.package_type%TYPE;
  
  procedure drop_type (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 'f'
  );

  function num_parameters (
    package_key         in apm_package_types.package_key%TYPE
  ) return integer;

end apm_package_type;
/
show errors



-- Private APM System API for managing parameter values.
create or replace package apm_parameter_value
as
  function new (
    value_id			in apm_parameter_values.value_id%TYPE default null,
    package_id			in apm_packages.package_id%TYPE,
    parameter_id		in apm_parameter_values.parameter_id%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  ) return apm_parameter_values.value_id%TYPE;

  procedure del (
    value_id			in apm_parameter_values.value_id%TYPE default null
  );
 end apm_parameter_value;
/
show errors

create or replace package apm_application
as

function new (
    application_id	in acs_objects.object_id%TYPE default null,
    instance_name	in apm_packages.instance_name%TYPE
			default null,
    package_key		in apm_package_types.package_key%TYPE,
    object_type		in acs_objects.object_type%TYPE
			   default 'apm_application',
    creation_date	in acs_objects.creation_date%TYPE default sysdate,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null,
    context_id		in acs_objects.context_id%TYPE default null
  ) return acs_objects.object_id%TYPE;

  procedure del (
    application_id		in acs_objects.object_id%TYPE
  );

end;
/
show errors


create or replace package apm_service
as

  function new (
    service_id		in acs_objects.object_id%TYPE default null,
    instance_name	in apm_packages.instance_name%TYPE
			default null,
    package_key		in apm_package_types.package_key%TYPE,
    object_type		in acs_objects.object_type%TYPE default 'apm_service',
    creation_date	in acs_objects.creation_date%TYPE default sysdate,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null,
    context_id		in acs_objects.context_id%TYPE default null
  ) return acs_objects.object_id%TYPE;

  procedure del (
    service_id		in acs_objects.object_id%TYPE
  );

end;
/
show errors

create or replace package body apm
as
  procedure register_package (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    package_type		in apm_package_types.package_type%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default 'f',    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default 't',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) 
  is
  begin
    apm_package_type.create_type(
    	package_key => register_package.package_key,
	pretty_name => register_package.pretty_name,
	pretty_plural => register_package.pretty_plural,
	package_uri => register_package.package_uri,
	package_type => register_package.package_type,
	initial_install_p => register_package.initial_install_p,
	singleton_p => register_package.singleton_p,
	implements_subsite_p => register_package.implements_subsite_p,
	inherit_templates_p => register_package.inherit_templates_p,
	spec_file_path => register_package.spec_file_path,
	spec_file_mtime => spec_file_mtime
    );
  end register_package;

  function update_package (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE
    	    	    	    	default null,
    pretty_plural		in apm_package_types.pretty_plural%TYPE
    	    	    	    	default null,
    package_uri			in apm_package_types.package_uri%TYPE
    	    	    	    	default null,
    package_type		in apm_package_types.package_type%TYPE
    	    	    	    	default null,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
    	    	    	    	default null,    
    singleton_p			in apm_package_types.singleton_p%TYPE 
    	    	    	    	default null,    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default null,
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default null,    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
    	    	    	    	default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) return apm_package_types.package_type%TYPE
  is
  begin
 
    return apm_package_type.update_type(
    	package_key => update_package.package_key,
	pretty_name => update_package.pretty_name,
	pretty_plural => update_package.pretty_plural,
	package_uri => update_package.package_uri,
	package_type => update_package.package_type,
	initial_install_p => update_package.initial_install_p,
	singleton_p => update_package.singleton_p,
	implements_subsite_p => update_package.implements_subsite_p,
	inherit_templates_p => update_package.inherit_templates_p,
	spec_file_path => update_package.spec_file_path,
	spec_file_mtime => update_package.spec_file_mtime
    );

  end update_package;    


 procedure unregister_package (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 't'
  )
  is
  begin
   apm_package_type.drop_type(
	package_key => unregister_package.package_key,
	cascade_p => unregister_package.cascade_p
   );
  end unregister_package;

  function register_p (
    package_key		in apm_package_types.package_key%TYPE
  ) return integer
  is
    v_register_p integer;
  begin
    select decode(count(*),0,0,1) into v_register_p from apm_package_types 
    where package_key = register_p.package_key;
    return v_register_p;
  end register_p;

  procedure register_application (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default 'f',    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default 't',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) 
  is
  begin
    apm.register_package(
	package_key => register_application.package_key,
	pretty_name => register_application.pretty_name,
	pretty_plural => register_application.pretty_plural,
	package_uri => register_application.package_uri,
	package_type => 'apm_application',
	initial_install_p => register_application.initial_install_p,
	singleton_p => register_application.singleton_p,
	implements_subsite_p => register_application.implements_subsite_p,
	inherit_templates_p => register_application.inherit_templates_p,
	spec_file_path => register_application.spec_file_path,
	spec_file_mtime => register_application.spec_file_mtime
   ); 
  end register_application;  

  procedure unregister_application (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 'f'
  )
  is
  begin
   apm.unregister_package (
	package_key => unregister_application.package_key,
	cascade_p => unregister_application.cascade_p
   );
  end unregister_application; 

  procedure register_service (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default 'f',    
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default 't',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) 
  is
  begin
   apm.register_package(
	package_key => register_service.package_key,
	pretty_name => register_service.pretty_name,
	pretty_plural => register_service.pretty_plural,
	package_uri => register_service.package_uri,
	package_type => 'apm_service',
	initial_install_p => register_service.initial_install_p,
	singleton_p => register_service.singleton_p,
	implements_subsite_p => register_service.implements_subsite_p,
	inherit_templates_p => register_service.inherit_templates_p,
	spec_file_path => register_service.spec_file_path,
	spec_file_mtime => register_service.spec_file_mtime
   );   
  end register_service;

  procedure unregister_service (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 'f'
  )
  is
  begin
   apm.unregister_package (
	package_key => unregister_service.package_key,
	cascade_p => unregister_service.cascade_p
   );
  end unregister_service;

  -- Indicate to APM that a parameter is available to the system.
  function register_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE 
				default null,
    package_key			in apm_parameters.package_key%TYPE,				
    parameter_name		in apm_parameters.parameter_name%TYPE,
    description			in apm_parameters.description%TYPE
				default null,
    scope                       in apm_parameters.scope%TYPE
                                default 'instance',
    datatype			in apm_parameters.datatype%TYPE 
				default 'string',
    default_value		in apm_parameters.default_value%TYPE 
				default null,
    section_name		in apm_parameters.section_name%TYPE
				default null,
    min_n_values		in apm_parameters.min_n_values%TYPE 
				default 1,
    max_n_values		in apm_parameters.max_n_values%TYPE 
				default 1
  ) return apm_parameters.parameter_id%TYPE
  is
    v_parameter_id apm_parameters.parameter_id%TYPE;
    v_value_id apm_parameter_values.value_id%TYPE;
  begin
    -- Create the new parameter.    
    v_parameter_id := acs_object.new(
       object_id => parameter_id,
       object_type => 'apm_parameter',
       title => register_parameter.package_key || ': Parameter ' || register_parameter.parameter_name
    );
    
    insert into apm_parameters 
    (parameter_id, parameter_name, description, package_key, datatype, scope,
    default_value, section_name, min_n_values, max_n_values)
    values
    (v_parameter_id, register_parameter.parameter_name, register_parameter.description,
    register_parameter.package_key, register_parameter.datatype, register_parameter.scope,
    register_parameter.default_value, register_parameter.section_name, 
    register_parameter.min_n_values, register_parameter.max_n_values);
    -- Propagate parameter to new instances.	
    if register_parameter.scope = 'instance' then
      for pkg in (select package_id from apm_packages where package_key = register_parameter.package_key)
        loop
        	v_value_id := apm_parameter_value.new(
  	                      package_id => pkg.package_id,
  	                      parameter_id => v_parameter_id, 
  	                      attr_value => register_parameter.default_value); 	
        end loop;		
    else
      v_value_id := apm_parameter_value.new(
  	                   package_id => null,
  	                   parameter_id => v_parameter_id, 
  	                   attr_value => register_parameter.default_value); 	
    end if;

    return v_parameter_id;
  end register_parameter;

    function update_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
    	    	    	    	default null,
    description			in apm_parameters.description%TYPE
				default null,
    datatype			in apm_parameters.datatype%TYPE 
				default 'string',
    default_value		in apm_parameters.default_value%TYPE 
				default null,
    section_name		in apm_parameters.section_name%TYPE
				default null,
    min_n_values		in apm_parameters.min_n_values%TYPE 
				default 1,
    max_n_values		in apm_parameters.max_n_values%TYPE 
				default 1
  ) return apm_parameters.parameter_name%TYPE
  is
  begin
    update apm_parameters 
	set parameter_name = nvl(update_parameter.parameter_name, parameter_name),
            default_value  = nvl(update_parameter.default_value, default_value),
            datatype       = nvl(update_parameter.datatype, datatype), 
	    description	   = nvl(update_parameter.description, description),
	    section_name   = nvl(update_parameter.section_name, section_name),
            min_n_values   = nvl(update_parameter.min_n_values, min_n_values),
            max_n_values   = nvl(update_parameter.max_n_values, max_n_values)
      where parameter_id = update_parameter.parameter_id;

    update acs_objects
       set title = (select package_key || ': Parameter ' || parameter_name
                    from apm_parameters
                    where parameter_id = update_parameter.parameter_id)
     where object_id = update_parameter.parameter_id;

    return parameter_id;
  end;

  function parameter_p(
    package_key                 in apm_package_types.package_key%TYPE,
    parameter_name              in apm_parameters.parameter_name%TYPE
  ) return integer 
  is
    v_parameter_p integer;
  begin
    select decode(count(*),0,0,1) into v_parameter_p 
    from apm_parameters
    where package_key = parameter_p.package_key
    and parameter_name = parameter_p.parameter_name;
    return v_parameter_p;
  end parameter_p;

  procedure unregister_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE 
				default null
  )
  is
  begin
    delete from apm_parameter_values 
    where parameter_id = unregister_parameter.parameter_id;
    delete from apm_parameters 
    where parameter_id = unregister_parameter.parameter_id;
    acs_object.del(parameter_id);
  end unregister_parameter;

  function id_for_name (
    package_key			in apm_parameters.package_key%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameters.parameter_id%TYPE
  is
    a_parameter_id apm_parameters.parameter_id%TYPE; 
  begin
    select parameter_id into a_parameter_id
    from apm_parameters p
    where p.parameter_name = id_for_name.parameter_name and
          p.package_key = id_for_name.package_key;

    return a_parameter_id;

    exception when no_data_found then
      raise_application_error(-20000, 'The specified package ' || 
        id_for_name.package_key || ' AND/OR parameter ' || id_for_name.package_key || 
        ' do not exist');

  end id_for_name;

  function id_for_name (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameters.parameter_id%TYPE
  is
    a_parameter_id apm_parameters.parameter_id%TYPE; 
  begin
    select parameter_id into a_parameter_id
    from apm_parameters p
    where p.parameter_name = id_for_name.parameter_name and
          p.package_key = (select package_key from apm_packages
                           where package_id = id_for_name.package_id);

    return a_parameter_id;

    exception when no_data_found then
      raise_application_error(-20000, 'The specified package ' || 
        id_for_name.package_id || ' AND/OR parameter ' || id_for_name.parameter_name || 
        ' do not exist');

  end id_for_name;

  function get_value (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameter_values.attr_value%TYPE
  is
    parameter_id apm_parameter_values.parameter_id%TYPE;
    value apm_parameter_values.attr_value%TYPE;
  begin
    parameter_id := apm.id_for_name(package_id, parameter_name);

    select attr_value into value
    from apm_parameter_values v
    where v.package_id = get_value.package_id
      and parameter_id = get_value.parameter_id;

    return value;
  end get_value;	

  function get_value (
    package_key			in apm_packages.package_key%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameter_values.attr_value%TYPE
  is
    parameter_id apm_parameter_values.parameter_id%TYPE;
    value apm_parameter_values.attr_value%TYPE;
  begin
    parameter_id := apm.id_for_name(package_key, parameter_name);

    select attr_value into value from apm_parameter_values v
    where v.package_id is null
      and parameter_id = get_value.parameter_id;

    return value;
  end get_value;	

  procedure set_value (
    package_key			in apm_packages.package_key%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  ) 
  is
    parameter_id apm_parameter_values.parameter_id%TYPE;
    value_id apm_parameter_values.value_id%TYPE;
  begin
    parameter_id := apm.id_for_name(package_key, parameter_name);

    select value_id into value_id from apm_parameter_values
    where parameter_id = set_value.parameter_id
      and package_id is null;

    update apm_parameter_values
    set attr_value = set_value.attr_value
    where parameter_id = set_value.parameter_id
    and package_id = null;


    exception
      when NO_DATA_FOUND
      then
        value_id := apm_parameter_value.new(
           package_id => null,
           parameter_id => set_value.parameter_id,
           attr_value => set_value.attr_value
        );

  end set_value;	

  procedure set_value (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  ) 
  is
    parameter_id apm_parameter_values.parameter_id%TYPE;
    value_id apm_parameter_values.value_id%TYPE;
  begin
    parameter_id := apm.id_for_name(package_id, parameter_name);

    select value_id into value_id from apm_parameter_values
    where parameter_id = set_value.parameter_id
      and package_id = set_value.package_id;

    update apm_parameter_values
    set attr_value = set_value.attr_value
    where parameter_id = set_value.parameter_id
    and package_id = set_value.package_id;


    exception
      when NO_DATA_FOUND
      then
        value_id := apm_parameter_value.new(
           package_id => set_value.package_id,
           parameter_id => set_value.parameter_id,
           attr_value => set_value.attr_value
        );

  end set_value;	

end apm;
/
show errors  

create or replace package body apm_package
as
  procedure initialize_parameters (
    package_id			in apm_packages.package_id%TYPE,
    package_key		        in apm_package_types.package_key%TYPE
  )
  is
   v_value_id apm_parameter_values.value_id%TYPE;
   cursor cur is
       select parameter_id, default_value
       from apm_parameters
       where package_key = initialize_parameters.package_key
         and scope = 'instance';
  begin
    -- need to initialize all params for this type
    for cur_val in cur
      loop
        v_value_id := apm_parameter_value.new(
          package_id => initialize_parameters.package_id,
          parameter_id => cur_val.parameter_id,
          attr_value => cur_val.default_value
        ); 
      end loop;   
  end initialize_parameters;

 function new (
  package_id		in apm_packages.package_id%TYPE 
			default null,
  instance_name		in apm_packages.instance_name%TYPE
			default null,
  package_key		in apm_packages.package_key%TYPE,
  object_type		in acs_objects.object_type%TYPE
			default 'apm_package', 
  creation_date		in acs_objects.creation_date%TYPE 
			default sysdate,
  creation_user		in acs_objects.creation_user%TYPE 
			default null,
  creation_ip		in acs_objects.creation_ip%TYPE 
			default null,
  context_id		in acs_objects.context_id%TYPE 
			default null
  ) return apm_packages.package_id%TYPE
  is 
   v_singleton_p integer;
   v_package_type apm_package_types.package_type%TYPE;
   v_num_instances integer;
   v_package_id apm_packages.package_id%TYPE;
   v_instance_name apm_packages.instance_name%TYPE; 
  begin
   v_singleton_p := apm_package.singleton_p(
			package_key => apm_package.new.package_key
		    );
   v_num_instances := apm_package.num_instances(
			package_key => apm_package.new.package_key
		    );
  
   if v_singleton_p = 1 and v_num_instances >= 1 then
       select package_id into v_package_id 
       from apm_packages
       where package_key = apm_package.new.package_key;
       return v_package_id;
   else
       v_package_id := acs_object.new(
          object_id => package_id,
          object_type => object_type,
          creation_date => creation_date,
          creation_user => creation_user,
	  creation_ip => creation_ip,
	  context_id => context_id
	 );

       if instance_name is null then 
	 v_instance_name := package_key || ' ' || v_package_id;
       else
	 v_instance_name := instance_name;
       end if;

       insert into apm_packages
       (package_id, package_key, instance_name)
       values
       (v_package_id, package_key, v_instance_name);

       update acs_objects
       set title = v_instance_name,
           package_id = v_package_id
       where object_id = v_package_id;

       select package_type into v_package_type
       from apm_package_types
       where package_key = apm_package.new.package_key;

       if v_package_type = 'apm_application' then
	   insert into apm_applications
	   (application_id)
	   values
	   (v_package_id);
       else
	   insert into apm_services
	   (service_id)
	   values
	   (v_package_id);
       end if;

       initialize_parameters(
	   package_id => v_package_id,
	   package_key => apm_package.new.package_key
       );
       return v_package_id;

  end if;
end new;
  
  procedure del (
   package_id		in apm_packages.package_id%TYPE
  )
  is
    cursor all_values is
    	select value_id from apm_parameter_values
	where package_id = apm_package.del.package_id;
    cursor all_site_nodes is
    	select node_id from site_nodes
	where object_id = apm_package.del.package_id;
  begin
    -- Delete all parameters.
    for cur_val in all_values loop
    	apm_parameter_value.del(value_id => cur_val.value_id);
    end loop;    
    delete from apm_applications where application_id = apm_package.del.package_id;
    delete from apm_services where service_id = apm_package.del.package_id;
    delete from apm_packages where package_id = apm_package.del.package_id;
    -- Delete the site nodes for the objects.
    for cur_val in all_site_nodes loop
    	site_node.del(cur_val.node_id);
    end loop;
    -- Delete the object.
    acs_object.del (
	object_id => package_id
    );
   end del;

    function initial_install_p (
	package_key		in apm_packages.package_key%TYPE
    ) return integer
    is
        v_initial_install_p integer;
    begin
        select 1 into v_initial_install_p
	from apm_package_types
	where package_key = initial_install_p.package_key
        and initial_install_p = 't';
	return v_initial_install_p;
	
	exception 
	    when NO_DATA_FOUND
            then
                return 0;
    end initial_install_p;

    function singleton_p (
	package_key		in apm_packages.package_key%TYPE
    ) return integer
    is
        v_singleton_p integer;
    begin
        select 1 into v_singleton_p
	from apm_package_types
	where package_key = singleton_p.package_key
        and singleton_p = 't';
	return v_singleton_p;
	
	exception 
	    when NO_DATA_FOUND
            then
                return 0;
    end singleton_p;

    function num_instances (
	package_key		in apm_package_types.package_key%TYPE
    ) return integer
    is
        v_num_instances integer;
    begin
        select count(*) into v_num_instances
	from apm_packages
	where package_key = num_instances.package_key;
        return v_num_instances;
	
	exception
	    when NO_DATA_FOUND
	    then
	        return 0;
    end num_instances;

  function name (
    package_id		in apm_packages.package_id%TYPE
  ) return varchar2
  is
    v_result apm_packages.instance_name%TYPE;
  begin
    select instance_name into v_result
    from apm_packages
    where package_id = name.package_id;

    return v_result;
  end name;

   function highest_version (
     package_key		in apm_package_types.package_key%TYPE
   ) return apm_package_versions.version_id%TYPE
   is
     v_version_id apm_package_versions.version_id%TYPE;
   begin
     select version_id into v_version_id
	from apm_package_version_info i 
	where apm_package_version.sortable_version_name(version_name) = 
             (select max(apm_package_version.sortable_version_name(v.version_name))
	             from apm_package_version_info v where v.package_key = highest_version.package_key)
	and package_key = highest_version.package_key;
     return v_version_id;
     exception
         when NO_DATA_FOUND
         then
         return 0;
   end highest_version;

    function parent_id (
        package_id in apm_packages.package_id%TYPE
    ) return apm_packages.package_id%TYPE
    is
        v_package_id apm_packages.package_id%TYPE;
    begin
        select sn1.object_id
        into v_package_id
        from site_nodes sn1
        where sn1.node_id = (select sn2.parent_id
                             from site_nodes sn2
                             where sn2.object_id = apm_package.parent_id.package_id);

        return v_package_id;

        exception when NO_DATA_FOUND then
            return -1;
    end parent_id;

  function is_child (
    parent_package_key in apm_packages.package_key%TYPE,
    child_package_key in apm_packages.package_key%TYPE
  ) return char
    is
    begin

      if parent_package_key = child_package_key then
        return 't';
      end if;

      for row in
        (select apd.service_uri
         from apm_package_versions apv, apm_package_dependencies apd
         where apd.version_id = apv.version_id
           and apv.enabled_p = 't'
           and apd.dependency_type in ('embeds', 'extends')
           and apv.package_key = child_package_key)
      loop
        if row.service_uri = parent_package_key or
          is_child(parent_package_key, row.service_uri) = 't' then
        return 't';
      end if;
    end loop;
 
    return 'f';
  end is_child;

end apm_package;
/
show errors


create or replace package body apm_package_version 
as
    function new (
      version_id		in apm_package_versions.version_id%TYPE
				default null,
      package_key		in apm_package_versions.package_key%TYPE,
      version_name		in apm_package_versions.version_name%TYPE 
				default null,
      version_uri		in apm_package_versions.version_uri%TYPE,
      summary			in apm_package_versions.summary%TYPE,
      description_format	in apm_package_versions.description_format%TYPE,
      description		in apm_package_versions.description%TYPE,
      release_date		in apm_package_versions.release_date%TYPE,
      vendor			in apm_package_versions.vendor%TYPE,
      vendor_uri		in apm_package_versions.vendor_uri%TYPE,
      auto_mount                in apm_package_versions.auto_mount%TYPE,
      installed_p		in apm_package_versions.installed_p%TYPE
				default 'f',
      data_model_loaded_p	in apm_package_versions.data_model_loaded_p%TYPE
				default 'f'
    ) return apm_package_versions.version_id%TYPE
    is
      v_version_id apm_package_versions.version_id%TYPE;
    begin
      if version_id is null then
         select acs_object_id_seq.nextval
	 into v_version_id
	 from dual;
      else
         v_version_id := version_id;
      end if;
	v_version_id := acs_object.new(
		object_id => v_version_id,
		object_type => 'apm_package_version',
                title => package_key || ', Version ' || version_name
        );
      insert into apm_package_versions
      (version_id, package_key, version_name, version_uri, summary, description_format, description,
      release_date, vendor, vendor_uri, auto_mount, installed_p, data_model_loaded_p)
      values
      (v_version_id, package_key, version_name, version_uri,
       summary, description_format, description,
       release_date, vendor, vendor_uri, auto_mount,
       installed_p, data_model_loaded_p);
      return v_version_id;		
    end new;

    procedure del (
      version_id		in apm_packages.package_id%TYPE
    )
    is
    begin
      delete from apm_package_owners 
      where version_id = apm_package_version.del.version_id; 

      delete from apm_package_dependencies
      where version_id = apm_package_version.del.version_id;

      delete from apm_package_versions 
	where version_id = apm_package_version.del.version_id;

      acs_object.del(apm_package_version.del.version_id);

    end del;

    procedure enable (
       version_id			in apm_package_versions.version_id%TYPE
    )
    is
    begin
      update apm_package_versions set enabled_p = 't'
      where version_id = enable.version_id;	
    end enable;
    
    procedure disable (
       version_id			in apm_package_versions.version_id%TYPE
    )
    is
    begin
      update apm_package_versions 
      set enabled_p = 'f'
      where version_id = disable.version_id;	
    end disable;

  function copy(
	version_id in apm_package_versions.version_id%TYPE,
	new_version_id in apm_package_versions.version_id%TYPE default null,
	new_version_name in apm_package_versions.version_name%TYPE,
	new_version_uri in apm_package_versions.version_uri%TYPE
  ) return apm_package_versions.version_id%TYPE
    is
	v_version_id integer;
    begin
	v_version_id := acs_object.new(
		object_id => new_version_id,
		object_type => 'apm_package_version'
        );    

	insert into apm_package_versions(version_id, package_key, version_name,
					version_uri, summary, description_format, description,
					release_date, vendor, vendor_uri, auto_mount)
	    select v_version_id, package_key, copy.new_version_name,
		   copy.new_version_uri, summary, description_format, description,
		   release_date, vendor, vendor_uri, auto_mount
	    from apm_package_versions
	    where version_id = copy.version_id;

        update acs_objects
        set title = (select v.package_key || ', Version ' || v.version_name
                     from apm_package_versions v
                     where v.version_id = copy.version_id)
        where object_id = copy.version_id;
    
	insert into apm_package_dependencies(dependency_id, version_id, dependency_type, service_uri, service_version)
	    select acs_object_id_seq.nextval, v_version_id, dependency_type, service_uri, service_version
	    from apm_package_dependencies
	    where version_id = copy.version_id;
    
        insert into apm_package_callbacks (version_id, type, proc)
                select v_version_id, type, proc
                from apm_package_callbacks
                where version_id = copy.version_id;
    
	insert into apm_package_owners(version_id, owner_uri, owner_name, sort_key)
	    select v_version_id, owner_uri, owner_name, sort_key
	    from apm_package_owners
	    where version_id = copy.version_id;
    
	return v_version_id;
    end copy;
    
    function edit (
      new_version_id		in apm_package_versions.version_id%TYPE
				default null,
      version_id		in apm_package_versions.version_id%TYPE,
      version_name		in apm_package_versions.version_name%TYPE 
				default null,
      version_uri		in apm_package_versions.version_uri%TYPE,
      summary			in apm_package_versions.summary%TYPE,
      description_format	in apm_package_versions.description_format%TYPE,
      description		in apm_package_versions.description%TYPE,
      release_date		in apm_package_versions.release_date%TYPE,
      vendor			in apm_package_versions.vendor%TYPE,
      vendor_uri		in apm_package_versions.vendor_uri%TYPE,
      auto_mount                in apm_package_versions.auto_mount%TYPE,
      installed_p		in apm_package_versions.installed_p%TYPE
				default 'f',
      data_model_loaded_p	in apm_package_versions.data_model_loaded_p%TYPE
				default 'f'
    ) return apm_package_versions.version_id%TYPE
    is 
      v_version_id apm_package_versions.version_id%TYPE;
      version_unchanged_p integer;
    begin
       -- Determine if version has changed.
       select decode(count(*),0,0,1) into version_unchanged_p
       from apm_package_versions
       where version_id = edit.version_id
       and version_name = edit.version_name;
       if version_unchanged_p <> 1 then
         v_version_id := copy(
			 version_id => edit.version_id,
			 new_version_id => edit.new_version_id,
			 new_version_name => edit.version_name,
			 new_version_uri => edit.version_uri
			);
         else 
	   v_version_id := edit.version_id;			
       end if;

       update apm_package_versions 
		set version_uri = edit.version_uri,
		summary = edit.summary,
		description_format = edit.description_format,
		description = edit.description,
		release_date = trunc(sysdate),
		vendor = edit.vendor,
		vendor_uri = edit.vendor_uri,
                auto_mount = edit.auto_mount,
		installed_p = edit.installed_p,
		data_model_loaded_p = edit.data_model_loaded_p
	    where version_id = v_version_id;
	return v_version_id;
    end edit;

-- Add an interface provided by this version.
  function add_interface(
    interface_id		in apm_package_dependencies.dependency_id%TYPE
			        default null,
    version_id			in apm_package_versions.version_id%TYPE,
    interface_uri		in apm_package_dependencies.service_uri%TYPE,
    interface_version		in apm_package_dependencies.service_version%TYPE
  ) return apm_package_dependencies.dependency_id%TYPE
  is
    v_dep_id apm_package_dependencies.dependency_id%TYPE;
  begin
      if add_interface.interface_id is null then
          select acs_object_id_seq.nextval into v_dep_id from dual;
      else
          v_dep_id := add_interface.interface_id;
      end if;
  
      insert into apm_package_dependencies
      (dependency_id, version_id, dependency_type, service_uri, service_version)
      values
      (v_dep_id, add_interface.version_id, 'provides', add_interface.interface_uri,
	add_interface.interface_version);
      return v_dep_id;
  end add_interface;

  procedure remove_interface(
    interface_id		in apm_package_dependencies.dependency_id%TYPE
  )
  is
  begin
    delete from apm_package_dependencies 
    where dependency_id = remove_interface.interface_id;
  end remove_interface;

  procedure remove_interface(
    interface_uri		in apm_package_dependencies.service_uri%TYPE,
    interface_version		in apm_package_dependencies.service_version%TYPE,
    version_id			in apm_package_versions.version_id%TYPE
  )
  is
      v_dep_id apm_package_dependencies.dependency_id%TYPE;
  begin
      select dependency_id into v_dep_id from apm_package_dependencies
      where service_uri = remove_interface.interface_uri 
      and interface_version = remove_interface.interface_version;
      remove_interface(v_dep_id);
  end remove_interface;

  -- Add a requirement for this version.  A requirement is some interface that this
  -- version depends on.
  function add_dependency(
    dependency_id		in apm_package_dependencies.dependency_id%TYPE
			        default null,
    dependency_type             in apm_package_dependencies.dependency_type%TYPE,
    version_id			in apm_package_versions.version_id%TYPE,
    dependency_uri		in apm_package_dependencies.service_uri%TYPE,
    dependency_version		in apm_package_dependencies.service_version%TYPE
  ) return apm_package_dependencies.dependency_id%TYPE
  is
    v_dep_id apm_package_dependencies.dependency_id%TYPE;
  begin
      if add_dependency.dependency_id is null then
          select acs_object_id_seq.nextval into v_dep_id from dual;
      else
          v_dep_id := add_dependency.dependency_id;
      end if;
  
      insert into apm_package_dependencies
      (dependency_id, version_id, dependency_type, service_uri, service_version)
      values
      (v_dep_id, add_dependency.version_id, add_dependency.dependency_type,
       add_dependency.dependency_uri, add_dependency.dependency_version);
      return v_dep_id;
  end add_dependency;

  procedure remove_dependency(
    dependency_id		in apm_package_dependencies.dependency_id%TYPE
  )
  is
  begin
    delete from apm_package_dependencies 
    where dependency_id = remove_dependency.dependency_id;
  end remove_dependency;


  procedure remove_dependency(
    dependency_uri		in apm_package_dependencies.service_uri%TYPE,
    dependency_version		in apm_package_dependencies.service_version%TYPE,
    version_id			in apm_package_versions.version_id%TYPE
  )
  is
    v_dep_id apm_package_dependencies.dependency_id%TYPE;
  begin
      select dependency_id into v_dep_id from apm_package_dependencies 
      where service_uri = remove_dependency.dependency_uri 
      and service_version = remove_dependency.dependency_version;
      remove_dependency(v_dep_id);
  end remove_dependency;

   function sortable_version_name (
    version_name		in apm_package_versions.version_name%TYPE
  ) return varchar2
    is
        a_fields integer;
	a_start integer;
	a_end   integer;
	a_order varchar2(1000);
	a_char  char(1);
	a_seen_letter char(1) := 'f';
    begin
        a_fields := 0;
	a_start := 1;
	loop
	    a_end := a_start;
    
	    -- keep incrementing a_end until we run into a non-number        
	    while substr(version_name, a_end, 1) >= '0' and substr(version_name, a_end, 1) <= '9' loop
		a_end := a_end + 1;
	    end loop;
	    if a_end = a_start then
	    	return -1;
		-- raise_application_error(-20000, 'Expected number at position ' || a_start);
	    end if;
	    if a_end - a_start > 4 then
	    	return -1;
		-- raise_application_error(-20000, 'Numbers within versions can only be up to 4 digits long');
	    end if;
    
	    -- zero-pad and append the number
	    a_order := a_order || substr('0000', 1, 4 - (a_end - a_start)) ||
		substr(version_name, a_start, a_end - a_start) || '.';
            a_fields := a_fields + 1;
	    if a_end > length(version_name) then
		-- end of string - we're outta here
		if a_seen_letter = 'f' then
		    -- append the "final" suffix if there haven't been any letters
		    -- so far (i.e., not development/alpha/beta)
		    a_order := a_order || lpad(' ',(7 - a_fields)*5,'0000.') || '  3F.';
		end if;
		return a_order;
	    end if;
    
	    -- what's the next character? if a period, just skip it
	    a_char := substr(version_name, a_end, 1);
	    if a_char = '.' then
		null;
	    else
		-- if the next character was a letter, append the appropriate characters
		if a_char = 'd' then
		    a_order := a_order || lpad(' ',(7 - a_fields)*5,'0000.') || '  0D.';
		elsif a_char = 'a' then
		    a_order := a_order || lpad(' ',(7 - a_fields)*5,'0000.') || '  1A.';
		elsif a_char = 'b' then
		    a_order := a_order || lpad(' ',(7 - a_fields)*5,'0000.') || '  2B.';
		end if;
    
		-- can't have something like 3.3a1b2 - just one letter allowed!
		if a_seen_letter = 't' then
		    return -1;
		    -- raise_application_error(-20000, 'Not allowed to have two letters in version name '''
		    --	|| version_name || '''');
		end if;
		a_seen_letter := 't';
    
		-- end of string - we're done!
		if a_end = length(version_name) then
		    return a_order;
		end if;
	    end if;
	    a_start := a_end + 1;
	end loop;
    end sortable_version_name;

  function version_name_greater(
    version_name_one		in apm_package_versions.version_name%TYPE,
    version_name_two		in apm_package_versions.version_name%TYPE
  ) return integer is
	a_order_a varchar2(1000);
	a_order_b varchar2(1000);
    begin
	a_order_a := sortable_version_name(version_name_one);
	a_order_b := sortable_version_name(version_name_two);
	if a_order_a < a_order_b then
	    return -1;
	elsif a_order_a > a_order_b then
	    return 1;
	end if;
	return 0;
    end version_name_greater;

  function upgrade_p(
    path			in varchar2,
    initial_version_name	in apm_package_versions.version_name%TYPE,
    final_version_name		in apm_package_versions.version_name%TYPE
   ) return integer
    is
	v_pos1 integer;
	v_pos2 integer;
	v_path varchar2(1500);
	v_version_from apm_package_versions.version_name%TYPE;
	v_version_to apm_package_versions.version_name%TYPE;
    begin

	-- Set v_path to the tail of the path (the file name).
	v_path := substr(upgrade_p.path, instr(upgrade_p.path, '/', -1) + 1);

	-- Remove the extension, if it's .sql.
	v_pos1 := instr(v_path, '.', -1);
	if v_pos1 > 0 and substr(v_path, v_pos1) = '.sql' then
	    v_path := substr(v_path, 1, v_pos1 - 1);
	end if;

	-- Figure out the from/to version numbers for the individual file.
	v_pos1 := instr(v_path, '-', -1, 2);
	v_pos2 := instr(v_path, '-', -1);
	if v_pos1 = 0 or v_pos2 = 0 then
	    -- There aren't two hyphens in the file name. Bail.
	    return 0;
	end if;

	v_version_from := substr(v_path, v_pos1 + 1, v_pos2 - v_pos1 - 1);
	v_version_to := substr(v_path, v_pos2 + 1);

	if version_name_greater(upgrade_p.initial_version_name, v_version_from) <= 0 and
	   version_name_greater(upgrade_p.final_version_name, v_version_to) >= 0 then
	    return 1;
	end if;

	return 0;
    exception when others then
	-- Invalid version number.
	return 0;
    end upgrade_p;
    
  procedure upgrade(
    version_id                  in apm_package_versions.version_id%TYPE
  )
  is
  begin
    update apm_package_versions
    	set enabled_p = 'f',
	    installed_p = 'f'
	where package_key = (select package_key from apm_package_versions
	    	    	     where version_id = upgrade.version_id);
    update apm_package_versions
    	set enabled_p = 't',
	    installed_p = 't'
	where version_id = upgrade.version_id;			  
    
  end upgrade;

end apm_package_version;
/
show errors

create or replace package body apm_package_type
as
 procedure create_type(
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in acs_object_types.pretty_name%TYPE,
    pretty_plural		in acs_object_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    package_type		in apm_package_types.package_type%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE,
    singleton_p			in apm_package_types.singleton_p%TYPE,
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE,
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE,
    spec_file_path		in apm_package_types.spec_file_path%TYPE default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE default null
  ) 
  is
  begin
   insert into apm_package_types
    (package_key, pretty_name, pretty_plural, package_uri, package_type,
    spec_file_path, spec_file_mtime, initial_install_p, singleton_p,
    implements_subsite_p, inherit_templates_p)
   values
    (create_type.package_key, create_type.pretty_name, create_type.pretty_plural,
     create_type.package_uri, create_type.package_type, create_type.spec_file_path, 
     create_type.spec_file_mtime, create_type.initial_install_p, create_type.singleton_p,
     create_type.implements_subsite_p, create_type.inherit_templates_p);
  end create_type;

  function update_type(    
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in acs_object_types.pretty_name%TYPE
    	    	    	    	default null,
    pretty_plural		in acs_object_types.pretty_plural%TYPE
    	    	    	    	default null,
    package_uri			in apm_package_types.package_uri%TYPE
    	    	    	    	default null,
    package_type		in apm_package_types.package_type%TYPE
    	    	    	        default null,
    initial_install_p		in apm_package_types.initial_install_p%TYPE
    	    	    	    	default null,
    singleton_p			in apm_package_types.singleton_p%TYPE
    	    	    	    	default null,
    implements_subsite_p        in apm_package_types.implements_subsite_p%TYPE 
				default null,
    inherit_templates_p         in apm_package_types.inherit_templates_p%TYPE 
				default null,    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
    	    	    	    	default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE
    	    	    	    	 default null
  ) return apm_package_types.package_type%TYPE
  is
  begin       
      UPDATE apm_package_types SET
      	pretty_name = nvl(update_type.pretty_name, pretty_name),
    	pretty_plural = nvl(update_type.pretty_plural, pretty_plural),
    	package_uri = nvl(update_type.package_uri, package_uri),
    	package_type = nvl(update_type.package_type, package_type),
    	spec_file_path = nvl(update_type.spec_file_path, spec_file_path),
    	spec_file_mtime = nvl(update_type.spec_file_mtime, spec_file_mtime),
    	initial_install_p = nvl(update_type.initial_install_p, initial_install_p),
    	singleton_p = nvl(update_type.singleton_p, singleton_p),
        implements_subsite_p = nvl(update_type.implements_subsite_p, implements_subsite_p),
        inherit_templates_p = nvl(update_type.inherit_templates_p, inherit_templates_p)
      where package_key = update_type.package_key;
      return update_type.package_key;
  end update_type;
  
  procedure drop_type (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 'f'
  )
  is
      cursor all_package_ids is
       select package_id
       from apm_packages
       where package_key = drop_type.package_key;
       
      cursor all_parameters is
       select parameter_id from apm_parameters
       where package_key = drop_type.package_key; 

      cursor all_versions is
       select version_id from apm_package_versions
       where package_key = drop_type.package_key;
  begin
    if cascade_p = 't' then
        for cur_val in all_package_ids
        loop
            apm_package.del(
	        package_id => cur_val.package_id
	    );
        end loop;
	-- Unregister all parameters.
        for cur_val in all_parameters 
	loop
	    apm.unregister_parameter(parameter_id => cur_val.parameter_id);
	end loop;
  
        -- Unregister all versions
	for cur_val in all_versions
	loop
	    apm_package_version.del(version_id => cur_val.version_id);
        end loop;
    end if;
    delete from apm_package_types
    where package_key = drop_type.package_key;
  end drop_type;

  function num_parameters (
    package_key         in apm_package_types.package_key%TYPE
  ) return integer
  is 
    v_count integer;
  begin
    select count(*) into v_count
    from apm_parameters
    where package_key = num_parameters.package_key;
    return v_count;
  end num_parameters;

end apm_package_type;


/
show errors

create or replace package body apm_parameter_value
as
   function new (
    value_id			in apm_parameter_values.value_id%TYPE default null,
    package_id			in apm_packages.package_id%TYPE,
    parameter_id		in apm_parameter_values.parameter_id%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  ) return apm_parameter_values.value_id%TYPE
  is 
  v_value_id apm_parameter_values.value_id%TYPE;
  begin
   v_value_id := acs_object.new(
     object_id => value_id,
     object_type => 'apm_parameter_value'
   );
   insert into apm_parameter_values 
    (value_id, package_id, parameter_id, attr_value)
     values
    (v_value_id, apm_parameter_value.new.package_id, 
    apm_parameter_value.new.parameter_id, 
    apm_parameter_value.new.attr_value);
   return v_value_id;
  end new;

  procedure del (
    value_id			in apm_parameter_values.value_id%TYPE default null
  )
  is
  begin
    delete from apm_parameter_values 
    where value_id = apm_parameter_value.del.value_id;
    acs_object.del(value_id);
  end del;

 end apm_parameter_value;
/
show errors;

create or replace package body apm_application
as

  function new (
    application_id	in acs_objects.object_id%TYPE default null,
    instance_name	in apm_packages.instance_name%TYPE
			default null,
    package_key		in apm_package_types.package_key%TYPE,
    object_type		in acs_objects.object_type%TYPE
			   default 'apm_application',
    creation_date	in acs_objects.creation_date%TYPE default sysdate,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null,
    context_id		in acs_objects.context_id%TYPE default null
  ) return acs_objects.object_id%TYPE
  is
    v_application_id	integer;
  begin
    v_application_id := apm_package.new (
      package_id => application_id,
      instance_name => instance_name,
      package_key => package_key,
      object_type => object_type,
      creation_date => creation_date,
      creation_user => creation_user,
      creation_ip => creation_ip,
      context_id => context_id
    );
    return v_application_id;
  end new;

  procedure del (
    application_id		in acs_objects.object_id%TYPE
  )
  is
  begin
    delete from apm_applications
    where application_id = apm_application.del.application_id;
    apm_package.del(
        package_id => application_id);
  end del;

end;
/
show errors

create or replace package body apm_service
as

  function new (
    service_id		in acs_objects.object_id%TYPE default null,
    instance_name	in apm_packages.instance_name%TYPE
			default null,
    package_key		in apm_package_types.package_key%TYPE,
    object_type		in acs_objects.object_type%TYPE default 'apm_service',
    creation_date	in acs_objects.creation_date%TYPE default sysdate,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null,
    context_id		in acs_objects.context_id%TYPE default null
  ) return acs_objects.object_id%TYPE
  is
    v_service_id	integer;
  begin
    v_service_id := apm_package.new (
      package_id => service_id,
      instance_name => instance_name,
      package_key => package_key,
      object_type => object_type,
      creation_date => creation_date,
      creation_user => creation_user,
      creation_ip => creation_ip,
      context_id => context_id
    );
    return v_service_id;
  end new;

  procedure del (
    service_id		in acs_objects.object_id%TYPE
  )
  is
  begin
    delete from apm_services
    where service_id = apm_service.del.service_id;
    apm_package.del(
	package_id => service_id
    );
  end del;

end;
/
show errors
