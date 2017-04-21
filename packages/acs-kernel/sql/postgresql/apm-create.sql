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
    package_key			varchar(100)
				constraint apm_package_types_p_key_pk primary key,
    pretty_name			varchar(100)
    	    	    	    	constraint apm_package_types_pretty_n_nn not null
				constraint apm_package_types_pretty_n_un unique,
    pretty_plural	        varchar(100)
				constraint apm_package_types_pretty_pl_un unique,
    package_uri			varchar(1500)
				constraint apm_packages_types_p_uri_nn not null
				constraint apm_packages_types_p_uri_un unique,
    package_type		varchar(300)
				constraint apm_packages_pack_type_ck 
				check (package_type in ('apm_application', 'apm_service')),
    spec_file_path		varchar(1500),
    spec_file_mtime		integer,
    initial_install_p		boolean default 'f'
                                constraint apm_packages_in_inst_nn
                                not null,
    singleton_p			boolean default 'f'
                                constraint apm_packages_singleton_nn
                                not null,
    implements_subsite_p        boolean default 'f'
                                constraint apm_packages_impl_subs_p_nn
                                not null,
    inherit_templates_p         boolean default 't'
                                constraint inherit_templates_p_nn
                                not null
);

comment on table apm_package_types is $$
 This table holds additional knowledge level attributes for the
 apm_package type and its subtypes.
$$;


comment on column apm_package_types.package_key is $$
 The package_key is what we call the package on this system.
$$;

comment on column apm_package_types.package_uri is $$
 The package URI indicates where the package can be downloaded and 
 is a unique identifier for the package.
$$;

comment on column apm_package_types.spec_file_path is $$
 The path to the package specification file.
$$;

comment on column apm_package_types.spec_file_mtime is $$
 The last time a spec file was modified.  This information is maintained in the 
database so that if a user changes the specification file by editing the file
(as opposed to using the UI, the system can read the .info file and update
the information in the database appropriately.
$$;

comment on column apm_package_types.initial_install_p is $$
 Indicates if the package should be installed during initial installation,
 in other words whether or not this package is part of the OpenACS core.
$$;

comment on column apm_package_types.singleton_p is $$
 Indicates if the package can be used for subsites.  If this is set to 
 't', the package can be enabled for any subsite.  Otherwise, it is 
 restricted to the acs-admin/ subsite.
$$;

comment on column apm_package_types.implements_subsite_p is $$
  If true, this package implements subsite semantics, typically by extending the
  acs-subsite package.  Used by the admin "mount subsite" UI, the request processor (for
  setting ad_conn's subsite_* attributes), etc.
$$;  -- '

comment on column apm_package_types.inherit_templates_p is $$
  If true, inherit templates from packages this package extends.  If false, only
  templates in this package's www subdirectory tree will be mapped to URLs by the
  request processor.
$$;  -- '

CREATE OR REPLACE FUNCTION inline_0 () RETURNS integer AS $$
BEGIN
-- Create a new object type for packages.
 PERFORM acs_object_type__create_type (
   'apm_package',         -- object_type
   'Package',             -- pretty_name
   'Packages',            -- pretty_plural
   'acs_object',          -- supertype
   'apm_packages',        -- table_name
   'package_id',          -- id_column
   'apm_package',         -- package_name
   'f',                   -- abstract_p
   'apm_package_types',   -- type_extension_table
   'apm_package__name'     -- name_method
   );

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_0 ();

drop function inline_0 ();


-- show errors



--
-- procedure inline_1/0
--
CREATE OR REPLACE FUNCTION inline_1(

) RETURNS integer AS $$
DECLARE
 attr_id acs_attributes.attribute_id%TYPE;
BEGIN
-- Register the meta-data for APM-packages
 attr_id := acs_attribute__create_attribute (
   'apm_package',
   'package_key',
   'string',
   'Package Key',
   'Package Keys',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_1 ();

drop function inline_1 ();


-- show errors

create table apm_packages (
    package_id			integer constraint apm_packages_package_id_fk
				references acs_objects(object_id)
				constraint apm_packages_package_id_pk primary key,
    package_key			varchar(100) constraint apm_packages_package_key_fk
				references apm_package_types(package_key),
    instance_name		varchar(300)
			        constraint apm_packages_instance_name_nn not null,
    -- default system locale for this package
    default_locale              varchar(30)
);

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
    package_key        varchar(100) 
		       constraint apm_package_vers_pack_key_nn not null
		       constraint apm_package_vers_pack_key_fk 
		         references apm_package_types(package_key),
    version_name       varchar(100)
                       constraint apm_package_vers_ver_name_nn not null,
    version_uri        varchar(1500)
                       constraint apm_package_vers_ver_uri_nn not null
                       constraint apm_package_vers_ver_uri_un unique,
    summary 	       varchar(3000),
    description_format varchar(100)
		       constraint apm_package_vers_desc_for_ck
		         check (description_format in ('text/html', 'text/plain')),
    description        text,
    release_date       timestamptz,
    vendor             varchar(500),
    vendor_uri         varchar(1500),
    enabled_p          boolean default 'f'
                       constraint apm_package_vers_enabled_p_nn not null,
    installed_p        boolean default 'f'
                       constraint apm_package_vers_inst_p_nn not null,
    tagged_p           boolean default 'f'
                       constraint apm_package_vers_tagged_p_nn not null,
    imported_p         boolean default 'f'
                       constraint apm_package_vers_imp_p_nn not null,
    data_model_loaded_p boolean default 'f'
                       constraint apm_package_vers_dml_p_nn not null,
    cvs_import_results text,
    activation_date    timestamptz,
    deactivation_date  timestamptz,
    -- FIXME: store the tarball in the content-repository
    -- distribution_tarball blob,
    item_id            integer,
    -- This constraint can't be added yet, as the cr_items table 
    -- has not been created yet.
                       -- constraint apm_package_ver_item_id_fk 
                       -- references cr_items(item_id),
    content_length     integer,
    distribution_uri   varchar(1500),
    distribution_date  timestamptz,
    auto_mount         varchar(50) default null,
    constraint apm_package_vers_id_name_un unique(package_key, version_name)
);

comment on table apm_package_versions is '
 The table apm_package_versions contains one row for each version of each package
 we know about, e.g., acs-kernel-3.3, acs-kernel-3.3.1, bboard-1.0,
 bboard-1.0.1, etc.
';

comment on column apm_package_versions.version_name is $$
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
     version_number := integer ('.' integer){0,3} (('d'|'a'|'b') integer?)?
So the following is a valid progression for version numbers: 
     0.9d, 0.9d1, 0.9a1, 0.9b1, 0.9b2, 0.9, 1.0, 1.0.1, 1.1b1, 1.1
$$;

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

comment on column apm_package_versions.description is $$
Type a one-paragraph description of your package. This is probably analogous 
to the first paragraph in your package's documentation.  This is used to describe
the system to users considering installing it.
$$;

comment on column apm_package_versions.release_date is $$
This tracks when the package was released. Releasing a package means
freezing the code and files, creating an archive, and making the
package available for donwload. XXX (bquinn): I'm skeptical about the
usefulness of storing this information here.
$$;

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
 item_id is a reference to the distribution_tarball which is stored in the content
 repository.
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



--
-- procedure inline_2/0
--
CREATE OR REPLACE FUNCTION inline_2(

) RETURNS integer AS $$
DECLARE
 attr_id acs_attributes.attribute_id%TYPE;
BEGIN
 attr_id := acs_object_type__create_type (
   'apm_package_version',
   'Package Version',
   'Package Versions',
   'acs_object',
   'apm_package_versions',
   'version_id',
   'apm_package_version',
   'f',
   null,
   null
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'package_key',
   'string',
   'Package Key',
   'Package Keys',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'version_name',
   'string',
   'Version Name',
   'Version Names',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'version_uri',
   'string',
   'Version URI',
   'Version URIs',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'summary',
   'string',
   'Summary',
   'Summaries',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'description_format',
   'string',
   'Description Format',
   'Description Formats',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'description',
   'string',
   'Description',
   'Descriptions',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'vendor',
   'string',
   'Vendor',
   'Vendors',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'vendor_uri',
   'string',
   'Vendor URI',
   'Vendor URIs',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'enabled_p',
   'boolean',
   'Enabled',
   'Enabled',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'activation_date',
   'date',
   'Activation Date',
   'Activation Dates',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'deactivation_date',
   'date',
   'Deactivation Date',
   'Deactivation Dates',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'distribution_uri',
   'string',
   'Distribution URI',
   'Distribution URIs',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_package_version',
   'distribution_date',
   'date',
   'Distribution Date',
   'Distribution Dates',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_2 ();

drop function inline_2 ();


-- show errors

-- Who owns a version?
create table apm_package_owners (
    version_id         integer constraint apm_package_owners_ver_id_fk references apm_package_versions on delete cascade,
    -- if the uri is an email address, it should look like 'mailto:someguy@openacs.org'
    owner_uri          varchar(1500),
    owner_name         varchar(200)
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
create view apm_package_version_info as
    select v.package_key, t.package_uri, t.pretty_name, t.singleton_p, t.initial_install_p,
           t.inherit_templates_p, t.implements_subsite_p,
           v.version_id, v.version_name,
           v.version_uri, v.summary, v.description_format, v.description, v.release_date,
           v.vendor, v.vendor_uri, v.auto_mount, v.enabled_p, v.installed_p, v.tagged_p,
           v.imported_p, v.data_model_loaded_p,
           v.activation_date, v.deactivation_date,
           coalesce(v.content_length,0) as tarball_length,
           distribution_uri, distribution_date
    from   apm_package_types t, apm_package_versions v 
    where  v.package_key = t.package_key;


-- A useful view for simply determining which packages are eanbled.
create view apm_enabled_package_versions as
    select * from apm_package_version_info
    where  enabled_p = 't';

create table apm_package_db_types (
    db_type_key      varchar(50)
                       constraint apm_package_db_types_pk primary key,
    pretty_db_name   varchar(200)
                       constraint apm_package_db_types_name_nn not null
);

comment on table apm_package_db_types is '
  A list of all the different kinds of database engines that an APM package can
  support.  This table is initialized in acs-tcl/tcl/apm-init.tcl rather than in
  PL/SQL in order to guarantee that the list of supported database engines is
  consistent between the bootstrap code and the package manager.
';

create table apm_parameters (
	parameter_id		integer constraint apm_parameters_parameter_id_fk 
				references acs_objects(object_id)
			        constraint apm_parameters_parameter_id_pk primary key,
	package_key		varchar(100)
				constraint apm_parameters_package_key_nn not null 	
				constraint apm_parameters_package_key_fk
			        references apm_package_types (package_key),
	parameter_name		varchar(100) 
				constraint apm_pack_params_name_nn not null,
        description		varchar(2000),
	section_name		varchar(200),
	datatype	        varchar(100) not null
			        constraint apm_parameters_datatype_ck 
				check(datatype in ('number', 'string','text')),
        scope                   varchar(10) default 'instance'
                                constraint apm_parameters_scope_ck
                                check (scope in ('global','instance'))
                                constraint apm_parameters_scope_nn
                                not null,
	default_value		text,
	min_n_values		integer default 1 not null
			        constraint apm_parameters_min_n_values_ck
			        check (min_n_values >= 0),
	max_n_values		integer default 1 not null
			        constraint apm_parameters_max_n_values_ck
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
  XXX (bquinn): More than one value is not supported by parameter::get call at this time.
';

comment on column apm_parameters.max_n_values is '
The maximum number of values that any attribute with this datatype
 can have. 
';

create table apm_parameter_values (
	value_id		integer constraint apm_parameter_values_fk
				references acs_objects(object_id)
				constraint apm_parameter_values_pk primary key,
	package_id		integer constraint apm_parameter_values_pk_id_fk 
				references apm_packages (package_id) on delete cascade,
	parameter_id		integer constraint apm_parameter_values_pm_id_fk
				references apm_parameters (parameter_id),
	attr_value		text,
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



--
-- procedure inline_4/0
--
CREATE OR REPLACE FUNCTION inline_4(

) RETURNS integer AS $$
DECLARE
 attr_id acs_attributes.attribute_id%TYPE;
BEGIN
 attr_id := acs_object_type__create_type (
   'apm_parameter',
   'Package Parameter',
   'Package Parameters',
   'acs_object',
   'apm_parameters',
   'parameter_id',
   'apm_parameter',
   'f',
   null,
   null
   );

 attr_id := acs_attribute__create_attribute (
   'apm_parameter',
   'package_key',
   'string',
   'Package Key',
   'Package Keys',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_parameter',
   'parameter_name',
   'string',
   'Parameter Name',
   'Parameter Name',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

attr_id := acs_attribute__create_attribute (
   'apm_parameter',
   'scope',
   'string',
   'Scope',
   'Scope',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   ); 

 attr_id := acs_attribute__create_attribute (
   'apm_parameter',
   'datatype',
   'string',
   'Datatype',
   'Datatypes',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_parameter',
   'default_value',
   'string',
   'Default Value',
   'Default Values',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_parameter',
   'min_n_values',
   'number',
   'Minimum Number of Values',
   'Minimum Numer of Values Settings',
   null,
   null,
   1,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_parameter',
   'max_n_values',
   'integer',
   'Maximum Number of Values',
   'Maximum Number of Values Settings',
   null,
   null,
   1,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_4 ();

drop function inline_4 ();


-- show errors




--
-- procedure inline_5/0
--
CREATE OR REPLACE FUNCTION inline_5(

) RETURNS integer AS $$
DECLARE
 attr_id acs_attributes.attribute_id%TYPE;
BEGIN
 attr_id := acs_object_type__create_type (
   'apm_parameter_value',
   'APM Package Parameter Value',
   'APM Package Parameter Values',
   'acs_object',
   'apm_parameter_values',
   'value_id',
   'apm_parameter_value',
   'f',
   null,
   null
   );

 attr_id := acs_attribute__create_attribute (
   'apm_parameter_value',
   'package_id',
   'number',
   'Package ID',
   'Package IDs',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_parameter_value',
   'parameter_id',
   'number',
   'Parameter ID',
   'Parameter IDs',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'apm_parameter_value',
   'attr_value',
   'string',
   'Parameter Value',
   'Parameter Values',
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_5 ();

drop function inline_5 ();


-- show errors

create table apm_package_dependencies (
    dependency_id      integer 
                       constraint apm_package_deps_id_pk primary key,
    version_id         integer constraint apm_package_deps_version_id_fk references apm_package_versions on delete cascade
                       constraint apm_package_deps_version_id_nn not null,
    dependency_type    varchar(20)
                       constraint apm_package_deps_type_nn not null
                       constraint apm_package_deps_type_ck
                       check(dependency_type in ('embeds', 'extends', 'provides','requires')),
    service_uri        varchar(1500)
                       constraint apm_package_deps_uri_nn not null,
    service_version    varchar(100)
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
				constraint apm_applications_aplt_id_fk
				references apm_packages(package_id)
				constraint apm_applications_pk primary key
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




--
-- procedure inline_6/0
--
CREATE OR REPLACE FUNCTION inline_6(

) RETURNS integer AS $$
DECLARE 
        dummy   integer;
BEGIN
-- Create a new object type for applications.
 dummy :=  acs_object_type__create_type (
   'apm_application',
   'Application',
   'Applications',
   'apm_package',
   'apm_applications',
   'application_id',
   'apm_application',
   'f',
   null,
   null
   );

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_6 ();

drop function inline_6 ();


-- show errors




--
-- procedure inline_7/0
--
CREATE OR REPLACE FUNCTION inline_7(

) RETURNS integer AS $$
DECLARE
        dummy   integer;
BEGIN
-- Create a new object type for services.
 dummy := acs_object_type__create_type (
   'apm_service',
   'Service',
   'Services',
   'apm_package',
   'apm_services',
   'service_id',
   'apm_service',
   'f',
   null,
   null
   );

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_7 ();

drop function inline_7 ();



-- added
select define_function_args('apm__register_package','package_key,pretty_name,pretty_plural,package_uri,package_type,initial_install_p;f,singleton_p;f,implements_subsite_p;f,inherit_templates_p;f,spec_file_path;null,spec_file_mtime;null');

--
-- procedure apm__register_package/11
--
CREATE OR REPLACE FUNCTION apm__register_package(
   package_key varchar,
   pretty_name varchar,
   pretty_plural varchar,
   package_uri varchar,
   package_type varchar,
   initial_install_p boolean,    -- default 'f'
   singleton_p boolean,          -- default 'f'
   implements_subsite_p boolean, -- default 'f'
   inherit_templates_p boolean,  -- default 'f'
   spec_file_path varchar,       -- default null
   spec_file_mtime integer       -- default null

) RETURNS integer AS $$
DECLARE
BEGIN
    PERFORM apm_package_type__create_type(
    	package_key,
	pretty_name,
	pretty_plural,
	package_uri,
	package_type,
	initial_install_p,
	singleton_p,
        implements_subsite_p,
        inherit_templates_p,
	spec_file_path,
	spec_file_mtime
    );

    return 0; 
END;
$$ LANGUAGE plpgsql;

-- function update_package


-- added
select define_function_args('apm__update_package','package_key,pretty_name;null,pretty_plural;null,package_uri;null,package_type;null,initial_install_p;null,singleton_p;null,implements_subsite_p;f,inherit_templates_p;f,spec_file_path;null,spec_file_mtime;null');

--
-- procedure apm__update_package/11
--
CREATE OR REPLACE FUNCTION apm__update_package(
   package_key varchar,
   pretty_name varchar,          -- default null
   pretty_plural varchar,        -- default null
   package_uri varchar,          -- default null
   package_type varchar,         -- default null
   initial_install_p boolean,    -- default null
   singleton_p boolean,          -- default null
   implements_subsite_p boolean, -- default 'f'
   inherit_templates_p boolean,  -- default 'f'
   spec_file_path varchar,       -- default null
   spec_file_mtime integer       -- default null

) RETURNS varchar AS $$
DECLARE
BEGIN
 
    return apm_package_type__update_type(
    	package_key,
	pretty_name,
	pretty_plural,
	package_uri,
	package_type,
	initial_install_p,
	singleton_p,
        implements_subsite_p,
        inherit_templates_p,
	spec_file_path,
	spec_file_mtime
    );
END;
$$ LANGUAGE plpgsql;

-- procedure unregister_package


-- added
select define_function_args('apm__unregister_package','package_key,cascade_p;t');

--
-- procedure apm__unregister_package/2
--
CREATE OR REPLACE FUNCTION apm__unregister_package(
   package_key varchar,
   p_cascade_p boolean -- default 't'

) RETURNS integer AS $$
DECLARE
  v_cascade_p            boolean;
BEGIN
   if cascade_p is null then 
	v_cascade_p := 't';
   else 
       v_cascade_p := p_cascade_p;
   end if;

   PERFORM apm_package_type__drop_type(
	package_key,
	v_cascade_p
   );

   return 0; 
END;
$$ LANGUAGE plpgsql;


-- function register_p


-- added
select define_function_args('apm__register_p','package_key');

--
-- procedure apm__register_p/1
--
CREATE OR REPLACE FUNCTION apm__register_p(
   register_p__package_key varchar
) RETURNS integer AS $$
DECLARE
  v_register_p                       integer;       
BEGIN
    select case when count(*) = 0 then 0 else 1 end into v_register_p 
    from apm_package_types 
    where package_key = register_p__package_key;

    return v_register_p;
   
END;
$$ LANGUAGE plpgsql stable;


-- procedure register_application


-- added
select define_function_args('apm__register_application','package_key,pretty_name,pretty_plural,package_uri,initial_install_p;f,singleton_p;f,implements_subsite_p;f,inherit_templates_p;f,spec_file_path;null,spec_file_mtime;null');

--
-- procedure apm__register_application/10
--
CREATE OR REPLACE FUNCTION apm__register_application(
   package_key varchar,
   pretty_name varchar,
   pretty_plural varchar,
   package_uri varchar,
   initial_install_p boolean,    -- default 'f'
   singleton_p boolean,          -- default 'f'
   implements_subsite_p boolean, -- default 'f'
   inherit_templates_p boolean,  -- default 'f'
   spec_file_path varchar,       -- default null
   spec_file_mtime integer       -- default null

) RETURNS integer AS $$
DECLARE
BEGIN
   PERFORM apm__register_package(
	package_key,
	pretty_name,
	pretty_plural,
	package_uri,
	'apm_application',
	initial_install_p,
	singleton_p,
        implements_subsite_p,
        inherit_templates_p,
	spec_file_path,
	spec_file_mtime
   ); 

   return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure unregister_application


-- added
select define_function_args('apm__unregister_application','package_key,cascade_p;f');

--
-- procedure apm__unregister_application/2
--
CREATE OR REPLACE FUNCTION apm__unregister_application(
   package_key varchar,
   p_cascade_p boolean -- default 'f'

) RETURNS integer AS $$
DECLARE
  v_cascade_p            boolean;
BEGIN
   if p_cascade_p is null then 
	v_cascade_p := 'f';
   else 
       v_cascade_p := p_cascade_p;
   end if;

   PERFORM apm__unregister_package (
        package_key,
        v_cascade_p
   );

   return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure register_service


-- added
select define_function_args('apm__register_service','package_key,pretty_name,pretty_plural,package_uri,initial_install_p;f,singleton_p;f,implements_subsite_p;f,inherit_templates_p;f,spec_file_path;null,spec_file_mtime;null');

--
-- procedure apm__register_service/10
--
CREATE OR REPLACE FUNCTION apm__register_service(
   package_key varchar,
   pretty_name varchar,
   pretty_plural varchar,
   package_uri varchar,
   initial_install_p boolean,    -- default 'f'
   singleton_p boolean,          -- default 'f'
   implements_subsite_p boolean, -- default 'f'
   inherit_templates_p boolean,  -- default 'f'
   spec_file_path varchar,       -- default null
   spec_file_mtime integer       -- default null

) RETURNS integer AS $$
DECLARE
BEGIN
   PERFORM apm__register_package(
	package_key,
	pretty_name,
	pretty_plural,
	package_uri,
	'apm_service',
	initial_install_p,
	singleton_p,
        implements_subsite_p,
        inherit_templates_p,
	spec_file_path,
	spec_file_mtime
   );  
 
   return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure unregister_service


-- added
select define_function_args('apm__unregister_service','package_key,cascade_p;f');

--
-- procedure apm__unregister_service/2
--
CREATE OR REPLACE FUNCTION apm__unregister_service(
   package_key varchar,
   p_cascade_p boolean -- default 'f'

) RETURNS integer AS $$
DECLARE
  v_cascade_p           boolean;
BEGIN
   if p_cascade_p is null then 
	v_cascade_p := 'f';
   else 
	v_cascade_p := p_cascade_p;
   end if;

   PERFORM apm__unregister_package (
	package_key,
	v_cascade_p
   );

   return 0; 
END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('apm__register_parameter','parameter_id;null,package_key,parameter_name,description;null,scope,datatype;string,default_value;null,section_name;null,min_n_values;1,max_n_values;1');

--
-- procedure apm__register_parameter/10
--
CREATE OR REPLACE FUNCTION apm__register_parameter(
   register_parameter__parameter_id integer,  -- default null
   register_parameter__package_key varchar,
   register_parameter__parameter_name varchar,
   register_parameter__description varchar,   -- default null
   register_parameter__scope varchar,
   register_parameter__datatype varchar,      -- default 'string'
   register_parameter__default_value varchar, -- default null
   register_parameter__section_name varchar,  -- default null
   register_parameter__min_n_values integer,  -- default 1
   register_parameter__max_n_values integer   -- default 1

) RETURNS integer AS $$
DECLARE

  v_parameter_id         apm_parameters.parameter_id%TYPE;
  v_value_id             apm_parameter_values.value_id%TYPE;
  v_pkg                  record;

BEGIN
    -- Create the new parameter.    
    v_parameter_id := acs_object__new(
       register_parameter__parameter_id,
       'apm_parameter',
       now(),
       null,
       null,
       null,
       't',
       register_parameter__package_key || ' - ' || register_parameter__parameter_name,
       null
    );
    
    insert into apm_parameters 
    (parameter_id, parameter_name, scope, description, package_key, datatype, 
    default_value, section_name, min_n_values, max_n_values)
    values
    (v_parameter_id, register_parameter__parameter_name, register_parameter__scope,
     register_parameter__description, register_parameter__package_key, 
     register_parameter__datatype, register_parameter__default_value, 
     register_parameter__section_name, register_parameter__min_n_values, 
     register_parameter__max_n_values);

    -- Propagate parameter to new instances.	
    if register_parameter__scope = 'instance' then
      for v_pkg in
          select package_id
  	from apm_packages
  	where package_key = register_parameter__package_key
        loop
          v_value_id := apm_parameter_value__new(
  	    null,
  	    v_pkg.package_id,
  	    v_parameter_id, 
  	    register_parameter__default_value); 	
        end loop;		
     else
       v_value_id := apm_parameter_value__new(
  	 null,
  	 null,
  	 v_parameter_id, 
  	 register_parameter__default_value); 	
     end if;
	
    return v_parameter_id;
   
END;
$$ LANGUAGE plpgsql;

-- For backwards compatibility, register a parameter with "instance" scope.



--
-- procedure apm__register_parameter/9
--
CREATE OR REPLACE FUNCTION apm__register_parameter(
   register_parameter__parameter_id integer,  -- default null
   register_parameter__package_key varchar,
   register_parameter__parameter_name varchar,
   register_parameter__description varchar,   -- default null
   register_parameter__datatype varchar,      -- default 'string'
   register_parameter__default_value varchar, -- default null
   register_parameter__section_name varchar,  -- default null
   register_parameter__min_n_values integer,  -- default 1
   register_parameter__max_n_values integer   -- default 1

) RETURNS integer AS $$
DECLARE

BEGIN
  return
    apm__register_parameter(register_parameter__parameter_id, register_parameter__package_key,
                           register_parameter__parameter_name, register_parameter__description,
                           'instance',  register_parameter__datatype,
                           register_parameter__default_value, register_parameter__section_name,
                           register_parameter__min_n_values, register_parameter__max_n_values);
END;
$$ LANGUAGE plpgsql;

-- function update_parameter


-- added
select define_function_args('apm__update_parameter','parameter_id,parameter_name;null,description;null,datatype;string,default_value;null,section_name;null,min_n_values;1,max_n_values;1');

--
-- procedure apm__update_parameter/8
--
CREATE OR REPLACE FUNCTION apm__update_parameter(
   update_parameter__parameter_id integer,
   update_parameter__parameter_name varchar, -- default null
   update_parameter__description varchar,    -- default null
   update_parameter__datatype varchar,       -- default 'string'
   update_parameter__default_value varchar,  -- default null
   update_parameter__section_name varchar,   -- default null
   update_parameter__min_n_values integer,   -- default 1
   update_parameter__max_n_values integer    -- default 1

) RETURNS varchar AS $$
DECLARE
BEGIN
    update apm_parameters 
	set parameter_name = coalesce(update_parameter__parameter_name, parameter_name),
            default_value  = coalesce(update_parameter__default_value, default_value),
            datatype       = coalesce(update_parameter__datatype, datatype), 
	    description	   = coalesce(update_parameter__description, description),
	    section_name   = coalesce(update_parameter__section_name, section_name),
            min_n_values   = coalesce(update_parameter__min_n_values, min_n_values),
            max_n_values   = coalesce(update_parameter__max_n_values, max_n_values)
      where parameter_id = update_parameter__parameter_id;

    update acs_objects
       set title = (select package_key || ': Parameter ' || parameter_name
                    from apm_parameters
                    where parameter_id = update_parameter__parameter_id)
     where object_id = update_parameter__parameter_id;

    return parameter_id;
     
END;
$$ LANGUAGE plpgsql;


-- function parameter_p


-- added
select define_function_args('apm__parameter_p','package_key,parameter_name');

--
-- procedure apm__parameter_p/2
--
CREATE OR REPLACE FUNCTION apm__parameter_p(
   parameter_p__package_key varchar,
   parameter_p__parameter_name varchar
) RETURNS integer AS $$
DECLARE
  v_parameter_p                       integer;       
BEGIN
    select case when count(*) = 0 then 0 else 1 end into v_parameter_p 
    from apm_parameters
    where package_key = parameter_p__package_key
    and parameter_name = parameter_p__parameter_name;

    return v_parameter_p;
   
END;
$$ LANGUAGE plpgsql stable;


-- procedure unregister_parameter


-- added
select define_function_args('apm__unregister_parameter','parameter_id;null');

--
-- procedure apm__unregister_parameter/1
--
CREATE OR REPLACE FUNCTION apm__unregister_parameter(
   unregister_parameter__parameter_id integer -- default null

) RETURNS integer AS $$
DECLARE
BEGIN
    delete from apm_parameter_values 
    where parameter_id = unregister_parameter__parameter_id;
    delete from apm_parameters 
    where parameter_id = unregister_parameter__parameter_id;
    PERFORM acs_object__delete(unregister_parameter__parameter_id);

    return 0; 
END;
$$ LANGUAGE plpgsql;



-- added

--
-- procedure apm__id_for_name/2
--
CREATE OR REPLACE FUNCTION apm__id_for_name(
   id_for_name__package_id integer,
   id_for_name__parameter_name varchar
) RETURNS integer AS $$
DECLARE
  a_parameter_id                      apm_parameters.parameter_id%TYPE;
BEGIN
    select parameter_id into a_parameter_id 
    from apm_parameters 
    where parameter_name = id_for_name__parameter_name
      and package_key = (select package_key from apm_packages
                         where package_id = id_for_name__package_id);

    if NOT FOUND
      then
      	raise EXCEPTION '-20000: The specified package % AND/OR parameter % do not exist in the system', id_for_name__package_id, id_for_name__parameter_name;
    end if;

    return a_parameter_id;
   
END;
$$ LANGUAGE plpgsql stable strict;



-- added
select define_function_args('apm__id_for_name','package_key,parameter_name');

--
-- procedure apm__id_for_name/2
--
CREATE OR REPLACE FUNCTION apm__id_for_name(
   id_for_name__package_key varchar,
   id_for_name__parameter_name varchar
) RETURNS integer AS $$
DECLARE
  a_parameter_id                      apm_parameters.parameter_id%TYPE;
BEGIN
    select parameter_id into a_parameter_id
    from apm_parameters p
    where p.parameter_name = id_for_name__parameter_name and
          p.package_key = id_for_name__package_key;

    if NOT FOUND
      then
      	raise EXCEPTION '-20000: The specified package % AND/OR parameter % do not exist in the system', id_for_name__package_key, id_for_name__parameter_name;
    end if;

    return a_parameter_id;
   
END;
$$ LANGUAGE plpgsql stable strict;



-- added

--
-- procedure apm__get_value/2
--
CREATE OR REPLACE FUNCTION apm__get_value(
   get_value__package_id integer,
   get_value__parameter_name varchar
) RETURNS varchar AS $$
DECLARE
  v_parameter_id                    apm_parameter_values.parameter_id%TYPE;
  value                             apm_parameter_values.attr_value%TYPE;
BEGIN
    v_parameter_id := apm__id_for_name (get_value__package_id, get_value__parameter_name);

    select attr_value into value from apm_parameter_values v
    where v.package_id = get_value__package_id
    and parameter_id = v_parameter_id;

    return value;
   
END;
$$ LANGUAGE plpgsql stable strict;



-- added
select define_function_args('apm__get_value','package_key,parameter_name');

--
-- procedure apm__get_value/2
--
CREATE OR REPLACE FUNCTION apm__get_value(
   get_value__package_key varchar,
   get_value__parameter_name varchar
) RETURNS varchar AS $$
DECLARE
  v_parameter_id                    apm_parameter_values.parameter_id%TYPE;
  value                             apm_parameter_values.attr_value%TYPE;
BEGIN
    v_parameter_id := apm__id_for_name (get_value__package_key, get_value__parameter_name);

    select attr_value into value from apm_parameter_values v
    where v.package_id is null
    and parameter_id = v_parameter_id;

    return value;
   
END;
$$ LANGUAGE plpgsql stable strict;



-- added

--
-- procedure apm__set_value/3
--
CREATE OR REPLACE FUNCTION apm__set_value(
   set_value__package_id integer,
   set_value__parameter_name varchar,
   set_value__attr_value varchar
) RETURNS integer AS $$
DECLARE
  v_parameter_id                    apm_parameter_values.parameter_id%TYPE;
  v_value_id                        apm_parameter_values.value_id%TYPE;
BEGIN
    v_parameter_id := apm__id_for_name (set_value__package_id, set_value__parameter_name);

    -- Determine if the value exists
    select value_id into v_value_id from apm_parameter_values 
     where parameter_id = v_parameter_id 
     and package_id = set_value__package_id;
    update apm_parameter_values set attr_value = set_value__attr_value
     where value_id = v_value_id;
    update acs_objects set last_modified = now() 
     where object_id = v_value_id;
   --  exception 
     if NOT FOUND
       then
         v_value_id := apm_parameter_value__new(
            null,
            set_value__package_id,
            v_parameter_id,
            set_value__attr_value
         );
     end if;

    return 0; 
END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('apm__set_value','package_key,parameter_name,attr_value');

--
-- procedure apm__set_value/3
--
CREATE OR REPLACE FUNCTION apm__set_value(
   set_value__package_key varchar,
   set_value__parameter_name varchar,
   set_value__attr_value varchar
) RETURNS integer AS $$
DECLARE
  v_parameter_id                    apm_parameter_values.parameter_id%TYPE;
  v_value_id                        apm_parameter_values.value_id%TYPE;
BEGIN
    v_parameter_id := apm__id_for_name (set_value__package_key, set_value__parameter_name);

    -- Determine if the value exists
    select value_id into v_value_id from apm_parameter_values 
     where parameter_id = v_parameter_id 
     and package_id is null;
    update apm_parameter_values set attr_value = set_value__attr_value
     where value_id = v_value_id;
    update acs_objects set last_modified = now() 
     where object_id = v_value_id;
   --  exception 
     if NOT FOUND
       then
         v_value_id := apm_parameter_value__new(
            null,
            null,
            v_parameter_id,
            set_value__attr_value
         );
     end if;

    return 0; 
END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('apm_package__is_child','parent_package_key,child_package_key');

--
-- procedure apm_package__is_child/2
--
CREATE OR REPLACE FUNCTION apm_package__is_child(
   parent_package_key varchar,
   child_package_key varchar
) RETURNS boolean AS $$
DECLARE
  dependency               record;
BEGIN

  if parent_package_key = child_package_key then
    return 't';
  end if;

  for dependency in 
    select apd.service_uri
    from apm_package_versions apv, apm_package_dependencies apd
    where apd.version_id = apv.version_id
      and apv.enabled_p
      and apd.dependency_type in ('embeds', 'extends')
      and apv.package_key = child_package_key
  loop
    if dependency.service_uri = parent_package_key or
      apm_package__is_child(parent_package_key, dependency.service_uri) then
      return 't';
    end if;
  end loop;
      
  return 'f';
END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('apm_package__initialize_parameters','package_id,package_key');

--
-- procedure apm_package__initialize_parameters/2
--
CREATE OR REPLACE FUNCTION apm_package__initialize_parameters(
   ip__package_id integer,
   ip__package_key varchar
) RETURNS integer AS $$
DECLARE
  v_value_id                 apm_parameter_values.value_id%TYPE;
  cur_val                    record;
BEGIN
    -- need to initialize all params for this type
    for cur_val in select parameter_id, default_value
       from apm_parameters
       where package_key = ip__package_key
         and scope = 'instance'
      loop
        v_value_id := apm_parameter_value__new(
          null,
          ip__package_id,
          cur_val.parameter_id,
          cur_val.default_value
        ); 
      end loop;   

      return 0; 
END;
$$ LANGUAGE plpgsql;


-- function new


-- added
select define_function_args('apm_package__new','package_id;null,instance_name;null,package_key,object_type;apm_package,creation_date;now(),creation_user;null,creation_ip;null,context_id;null');

--
-- procedure apm_package__new/8
--
CREATE OR REPLACE FUNCTION apm_package__new(
   new__package_id integer,        -- default null
   new__instance_name varchar,     -- default null
   new__package_key varchar,
   new__object_type varchar,       -- default 'apm_package'
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__context_id integer         -- default null

) RETURNS integer AS $$
DECLARE
  v_singleton_p               integer;       
  v_package_type              apm_package_types.package_type%TYPE;
  v_num_instances             integer;       
  v_package_id                apm_packages.package_id%TYPE;
  v_instance_name             apm_packages.instance_name%TYPE;
BEGIN
   v_singleton_p := apm_package__singleton_p(
			new__package_key
		    );
   v_num_instances := apm_package__num_instances(
			new__package_key
		    );
  
   if v_singleton_p = 1 and v_num_instances >= 1 then
       select package_id into v_package_id 
       from apm_packages
       where package_key = new__package_key;

       return v_package_id;
   else
       v_package_id := acs_object__new(
          new__package_id,
          new__object_type,
          new__creation_date,
          new__creation_user,
	  new__creation_ip,
	  new__context_id
	 );
       if new__instance_name is null or new__instance_name = '' then 
	 v_instance_name := new__package_key || ' ' || v_package_id;
       else
	 v_instance_name := new__instance_name;
       end if;

       select package_type into v_package_type
       from apm_package_types
       where package_key = new__package_key;

       insert into apm_packages
       (package_id, package_key, instance_name)
       values
       (v_package_id, new__package_key, v_instance_name);

       update acs_objects
       set title = v_instance_name,
           package_id = v_package_id
       where object_id = v_package_id;

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

       PERFORM apm_package__initialize_parameters(
	   v_package_id,
	   new__package_key
       );

       return v_package_id;

  end if;
END;
$$ LANGUAGE plpgsql;
  


-- added
select define_function_args('apm_package__delete','package_id');

--
-- procedure apm_package__delete/1
--
CREATE OR REPLACE FUNCTION apm_package__delete(
   delete__package_id integer
) RETURNS integer AS $$
DECLARE
   cur_val              record;
   v_folder_row         record;
BEGIN
    -- Delete all parameters.
    for cur_val in select value_id from apm_parameter_values
	where package_id = delete__package_id loop
    	PERFORM apm_parameter_value__delete(cur_val.value_id);
    end loop;    

   -- Delete the folders
    for v_folder_row in select
        folder_id
        from cr_folders
        where package_id = delete__package_id
    loop
        perform content_folder__del(v_folder_row.folder_id,'t');
    end loop;

    delete from apm_applications where application_id = delete__package_id;
    delete from apm_services where service_id = delete__package_id;
    delete from apm_packages where package_id = delete__package_id;
    -- Delete the site nodes for the objects.
    for cur_val in select node_id from site_nodes
	where object_id = delete__package_id loop
    	PERFORM site_node__delete(cur_val.node_id);
    end loop;

    -- Delete the object.
    PERFORM acs_object__delete (
       delete__package_id
    );   

    return 0;
END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('apm_package__initial_install_p','package_key');

--
-- procedure apm_package__initial_install_p/1
--
CREATE OR REPLACE FUNCTION apm_package__initial_install_p(
   initial_install_p__package_key varchar
) RETURNS integer AS $$
DECLARE
        v_initial_install_p             integer;
BEGIN
        select 1 into v_initial_install_p
	from apm_package_types
	where package_key = initial_install_p__package_key
        and initial_install_p = 't';
	
        if NOT FOUND then 
           return 0;
        else
           return v_initial_install_p;
        end if;
END;
$$ LANGUAGE plpgsql stable;



-- added
select define_function_args('apm_package__singleton_p','package_key');

--
-- procedure apm_package__singleton_p/1
--
CREATE OR REPLACE FUNCTION apm_package__singleton_p(
   singleton_p__package_key varchar
) RETURNS integer AS $$
DECLARE
        v_singleton_p                   integer;
BEGIN
        select count(*) into v_singleton_p
	from apm_package_types
	where package_key = singleton_p__package_key
        and singleton_p = 't';

        return v_singleton_p;
END;
$$ LANGUAGE plpgsql stable;



-- added
select define_function_args('apm_package__num_instances','package_key');

--
-- procedure apm_package__num_instances/1
--
CREATE OR REPLACE FUNCTION apm_package__num_instances(
   num_instances__package_key varchar
) RETURNS integer AS $$
DECLARE
        v_num_instances                integer;
BEGIN
        select count(*) into v_num_instances
	from apm_packages
	where package_key = num_instances__package_key;

        return v_num_instances;

END;
$$ LANGUAGE plpgsql stable;



-- added
select define_function_args('apm_package__name','package_id');

--
-- procedure apm_package__name/1
--
CREATE OR REPLACE FUNCTION apm_package__name(
   name__package_id integer
) RETURNS varchar AS $$
DECLARE
    v_result               apm_packages.instance_name%TYPE;
BEGIN
    select instance_name into v_result
    from apm_packages
    where package_id = name__package_id;

    return v_result;

END;
$$ LANGUAGE plpgsql stable strict;



-- added
select define_function_args('apm_package__highest_version','package_key');

--
-- procedure apm_package__highest_version/1
--
CREATE OR REPLACE FUNCTION apm_package__highest_version(
   highest_version__package_key varchar
) RETURNS integer AS $$
DECLARE
     v_version_id                    apm_package_versions.version_id%TYPE;
     v_max_version                   varchar;
BEGIN
     select max(apm_package_version__sortable_version_name(v.version_name)) into v_max_version 
       from apm_package_version_info v where v.package_key = highest_version__package_key;

     select version_id into v_version_id from apm_package_version_info i 
	where apm_package_version__sortable_version_name(version_name) = v_max_version and i.package_key = highest_version__package_key;

      if NOT FOUND then 
         return 0;
      else
         return v_version_id;
      end if;
END;
$$ LANGUAGE plpgsql stable;



-- added
select define_function_args('apm_package__parent_id','parent_id__package_id');

--
-- procedure apm_package__parent_id/1
--
CREATE OR REPLACE FUNCTION apm_package__parent_id(
   apm_package__parent_id__package_id integer
) RETURNS integer AS $$
DECLARE
    v_package_id apm_packages.package_id%TYPE;
BEGIN
    select sn1.object_id
    into v_package_id
    from site_nodes sn1
    where sn1.node_id = (select sn2.parent_id
                         from site_nodes sn2
                         where sn2.object_id = apm_package__parent_id__package_id);

    return v_package_id;

END;
$$ LANGUAGE plpgsql stable strict;

-- create or replace package body apm_package_version 


-- added
select define_function_args('apm_package_version__new','version_id;null,package_key,version_name;null,version_uri,summary,description_format,description,release_date,vendor,vendor_uri,auto_mount,installed_p;f,data_model_loaded_p;f');

--
-- procedure apm_package_version__new/13
--
CREATE OR REPLACE FUNCTION apm_package_version__new(
   apm_pkg_ver__version_id integer,         -- default null
   apm_pkg_ver__package_key varchar,
   apm_pkg_ver__version_name varchar,       -- default null
   apm_pkg_ver__version_uri varchar,
   apm_pkg_ver__summary varchar,
   apm_pkg_ver__description_format varchar,
   apm_pkg_ver__description varchar,
   apm_pkg_ver__release_date timestamptz,
   apm_pkg_ver__vendor varchar,
   apm_pkg_ver__vendor_uri varchar,
   apm_pkg_ver__auto_mount varchar,
   apm_pkg_ver__installed_p boolean,        -- default 'f'
   apm_pkg_ver__data_model_loaded_p boolean -- default 'f'

) RETURNS integer AS $$
DECLARE
      v_version_id                      apm_package_versions.version_id%TYPE;
BEGIN
      if apm_pkg_ver__version_id is null then
         select nextval('t_acs_object_id_seq')
	 into v_version_id
	 from dual;
      else
         v_version_id := apm_pkg_ver__version_id;
      end if;

      v_version_id := acs_object__new(
		v_version_id,
		'apm_package_version',
                now(),
                null,
                null,
                null,
                't',
                apm_pkg_ver__package_key || ', Version ' || apm_pkg_ver__version_name,
                null
        );

      insert into apm_package_versions
      (version_id, package_key, version_name, version_uri, summary, description_format, description,
      release_date, vendor, vendor_uri, auto_mount, installed_p, data_model_loaded_p)
      values
      (v_version_id, apm_pkg_ver__package_key, apm_pkg_ver__version_name, 
       apm_pkg_ver__version_uri, apm_pkg_ver__summary, 
       apm_pkg_ver__description_format, apm_pkg_ver__description,
       apm_pkg_ver__release_date, apm_pkg_ver__vendor, apm_pkg_ver__vendor_uri, apm_pkg_ver__auto_mount,
       apm_pkg_ver__installed_p, apm_pkg_ver__data_model_loaded_p);

      return v_version_id;		
  
END;
$$ LANGUAGE plpgsql;


-- procedure delete


-- added
select define_function_args('apm_package_version__delete','version_id');

--
-- procedure apm_package_version__delete/1
--
CREATE OR REPLACE FUNCTION apm_package_version__delete(
   delete__version_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
      delete from apm_package_owners 
      where version_id = delete__version_id; 

      delete from apm_package_dependencies
      where version_id = delete__version_id;

      delete from apm_package_versions 
	where version_id = delete__version_id;

      PERFORM acs_object__delete(delete__version_id);

      return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure enable


-- added
select define_function_args('apm_package_version__enable','version_id');

--
-- procedure apm_package_version__enable/1
--
CREATE OR REPLACE FUNCTION apm_package_version__enable(
   enable__version_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
      update apm_package_versions set enabled_p = 't'
      where version_id = enable__version_id;	

      return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure disable


-- added
select define_function_args('apm_package_version__disable','version_id');

--
-- procedure apm_package_version__disable/1
--
CREATE OR REPLACE FUNCTION apm_package_version__disable(
   disable__version_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
      update apm_package_versions 
      set enabled_p = 'f'
      where version_id = disable__version_id;	

      return 0; 
END;
$$ LANGUAGE plpgsql;


-- function copy


-- added
select define_function_args('apm_package_version__copy','version_id,new_version_id;null,new_version_name,new_version_uri,copy_owners_p');

--
-- procedure apm_package_version__copy/5
--
CREATE OR REPLACE FUNCTION apm_package_version__copy(
   copy__version_id integer,
   copy__new_version_id integer, -- default null
   copy__new_version_name varchar,
   copy__new_version_uri varchar,
   copy__copy_owners_p boolean

) RETURNS integer AS $$
DECLARE
  v_version_id                 integer;       
BEGIN
	v_version_id := acs_object__new(
		copy__new_version_id,
		'apm_package_version',
                now(),
                null,
                null,
                null
        );    

	insert into apm_package_versions(version_id, package_key, version_name,
					version_uri, summary, description_format, description,
					release_date, vendor, vendor_uri, auto_mount)
	    select v_version_id, package_key, copy__new_version_name,
		   copy__new_version_uri, summary, description_format, description,
		   release_date, vendor, vendor_uri, auto_mount
	    from apm_package_versions
	    where version_id = copy__version_id;
    
        update acs_objects
        set title = (select v.package_key || ', Version ' || v.version_name
                     from apm_package_versions v
                     where v.version_id = copy__version_id)
        where object_id = copy__version_id;

	insert into apm_package_dependencies(dependency_id, version_id, dependency_type, service_uri, service_version)
	    select nextval('t_acs_object_id_seq'), v_version_id, dependency_type, service_uri, service_version
	    from apm_package_dependencies
	    where version_id = copy__version_id;
    
        insert into apm_package_callbacks (version_id, type, proc)
                select v_version_id, type, proc
                from apm_package_callbacks
                where version_id = copy__version_id;
    
        if copy__copy_owners_p then
            insert into apm_package_owners(version_id, owner_uri, owner_name, sort_key)
                select v_version_id, owner_uri, owner_name, sort_key
                from apm_package_owners
                where version_id = copy__version_id;
        end if;
    
	return v_version_id;
   
END;
$$ LANGUAGE plpgsql;


-- function edit


-- added
select define_function_args('apm_package_version__edit','new_version_id;null,version_id,version_name;null,version_uri,summary,description_format,description,release_date,vendor,vendor_uri,auto_mount,installed_p;f,data_model_loaded_p;f');

--
-- procedure apm_package_version__edit/13
--
CREATE OR REPLACE FUNCTION apm_package_version__edit(
   edit__new_version_id integer,     -- default null
   edit__version_id integer,
   edit__version_name varchar,       -- default null
   edit__version_uri varchar,
   edit__summary varchar,
   edit__description_format varchar,
   edit__description varchar,
   edit__release_date timestamptz,
   edit__vendor varchar,
   edit__vendor_uri varchar,
   edit__auto_mount varchar,
   edit__installed_p boolean,        -- default 'f'
   edit__data_model_loaded_p boolean -- default 'f'

) RETURNS integer AS $$
DECLARE
  v_version_id                 apm_package_versions.version_id%TYPE;
  version_unchanged_p          integer;       
BEGIN
       -- Determine if version has changed.
       select case when count(*) = 0 then 0 else 1 end into version_unchanged_p
       from apm_package_versions
       where version_id = edit__version_id
       and version_name = edit__version_name;
       if version_unchanged_p <> 1 then
         v_version_id := apm_package_version__copy(
			 edit__version_id,
			 edit__new_version_id,
			 edit__version_name,
			 edit__version_uri,
                         'f'
			);
         else 
	   v_version_id := edit__version_id;			
       end if;
       
       update apm_package_versions 
		set version_uri = edit__version_uri,
		summary = edit__summary,
		description_format = edit__description_format,
		description = edit__description,
		release_date = date_trunc('days',now()),
		vendor = edit__vendor,
		vendor_uri = edit__vendor_uri,
                auto_mount = edit__auto_mount,
		installed_p = edit__installed_p,
		data_model_loaded_p = edit__data_model_loaded_p
	    where version_id = v_version_id;

	return v_version_id;
     
END;
$$ LANGUAGE plpgsql;

-- function add_interface


-- added
select define_function_args('apm_package_version__add_interface','interface_id;null,version_id,interface_uri,interface_version');

--
-- procedure apm_package_version__add_interface/4
--
CREATE OR REPLACE FUNCTION apm_package_version__add_interface(
   add_interface__interface_id integer, -- default null
   add_interface__version_id integer,
   add_interface__interface_uri varchar,
   add_interface__interface_version varchar

) RETURNS integer AS $$
DECLARE
  v_dep_id                            apm_package_dependencies.dependency_id%TYPE;
BEGIN
      if add_interface__interface_id is null then
          select nextval('t_acs_object_id_seq') into v_dep_id from dual;
      else
          v_dep_id := add_interface__interface_id;
      end if;
  
      insert into apm_package_dependencies
      (dependency_id, version_id, dependency_type, service_uri, service_version)
      values
      (v_dep_id, add_interface__version_id, 'provides', add_interface__interface_uri,
	add_interface__interface_version);

      return v_dep_id;
   
END;
$$ LANGUAGE plpgsql;


-- procedure remove_interface


-- added

--
-- procedure apm_package_version__remove_interface/1
--
CREATE OR REPLACE FUNCTION apm_package_version__remove_interface(
   remove_interface__interface_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    delete from apm_package_dependencies 
    where dependency_id = remove_interface__interface_id;

    return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure remove_interface


-- added
select define_function_args('apm_package_version__remove_interface','interface_uri,interface_version,version_id');

--
-- procedure apm_package_version__remove_interface/3
--
CREATE OR REPLACE FUNCTION apm_package_version__remove_interface(
   remove_interface__interface_uri varchar,
   remove_interface__interface_version varchar,
   remove_interface__version_id integer
) RETURNS integer AS $$
DECLARE
  v_dep_id                           apm_package_dependencies.dependency_id%TYPE;
BEGIN
      select dependency_id into v_dep_id from apm_package_dependencies
      where service_uri = remove_interface__interface_uri 
      and interface_version = remove_interface__interface_version;
      PERFORM apm_package_version__remove_interface(v_dep_id);

      return 0; 
END;
$$ LANGUAGE plpgsql;


-- function add_dependency


-- added
select define_function_args('apm_package_version__add_dependency','dependency_type,dependency_id;null,version_id,dependency_uri,dependency_version');

--
-- procedure apm_package_version__add_dependency/5
--
CREATE OR REPLACE FUNCTION apm_package_version__add_dependency(
   add_dependency__dependency_type varchar,
   add_dependency__dependency_id integer, -- default null
   add_dependency__version_id integer,
   add_dependency__dependency_uri varchar,
   add_dependency__dependency_version varchar

) RETURNS integer AS $$
DECLARE
  v_dep_id                            apm_package_dependencies.dependency_id%TYPE;
BEGIN
      if add_dependency__dependency_id is null then
          select nextval('t_acs_object_id_seq') into v_dep_id from dual;
      else
          v_dep_id := add_dependency__dependency_id;
      end if;
  
      insert into apm_package_dependencies
      (dependency_id, version_id, dependency_type, service_uri, service_version)
      values
      (v_dep_id, add_dependency__version_id, add_dependency__dependency_type,
        add_dependency__dependency_uri, add_dependency__dependency_version);

      return v_dep_id;
   
END;
$$ LANGUAGE plpgsql;


-- procedure remove_dependency


-- added

--
-- procedure apm_package_version__remove_dependency/1
--
CREATE OR REPLACE FUNCTION apm_package_version__remove_dependency(
   remove_dependency__dependency_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    delete from apm_package_dependencies 
    where dependency_id = remove_dependency__dependency_id;

    return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure remove_dependency


-- added
select define_function_args('apm_package_version__remove_dependency','dependency_uri,dependency_version,version_id');

--
-- procedure apm_package_version__remove_dependency/3
--
CREATE OR REPLACE FUNCTION apm_package_version__remove_dependency(
   remove_dependency__dependency_uri varchar,
   remove_dependency__dependency_version varchar,
   remove_dependency__version_id integer
) RETURNS integer AS $$
DECLARE
  v_dep_id                           apm_package_dependencies.dependency_id%TYPE;
BEGIN
      select dependency_id into v_dep_id from apm_package_dependencies 
      where service_uri = remove_dependency__dependency_uri 
      and service_version = remove_dependency__dependency_version;
      PERFORM apm_package_version__remove_dependency(v_dep_id);

      return 0; 
END;
$$ LANGUAGE plpgsql;


-- function sortable_version_name


-- added
select define_function_args('apm_package_version__sortable_version_name','version_name');

--
-- procedure apm_package_version__sortable_version_name/1
--
CREATE OR REPLACE FUNCTION apm_package_version__sortable_version_name(
   version_name varchar
) RETURNS varchar AS $$
DECLARE
  a_fields               integer;       
  a_start                integer;       
  a_end                  integer;       
  a_order                varchar(1000) default ''; 
  a_char                 char(1);       
  a_seen_letter          boolean default 'f';        
BEGIN
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
		    a_order := a_order || repeat('0000.',7 - a_fields) || '  3F.';
		end if;
		return a_order;
	    end if;
    
	    -- what's the next character? if a period, just skip it
	    a_char := substr(version_name, a_end, 1);
	    if a_char = '.' then
	    else
		-- if the next character was a letter, append the appropriate characters
		if a_char = 'd' then
		    a_order := a_order || repeat('0000.',7 - a_fields) || '  0D.';
		else if a_char = 'a' then
		    a_order := a_order || repeat('0000.',7 - a_fields) || '  1A.';
		else if a_char = 'b' then
		    a_order := a_order || repeat('0000.',7 - a_fields) || '  2B.';
		end if; end if; end if;
    
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
    
END;
$$ LANGUAGE plpgsql immutable;

-- function version_name_greater


-- added
select define_function_args('apm_package_version__version_name_greater','version_name_one,version_name_two');

--
-- procedure apm_package_version__version_name_greater/2
--
CREATE OR REPLACE FUNCTION apm_package_version__version_name_greater(
   version_name_one varchar,
   version_name_two varchar
) RETURNS integer AS $$
DECLARE
  a_order_a		 varchar(250);
  a_order_b		 varchar(250);  
BEGIN
	a_order_a := apm_package_version__sortable_version_name(version_name_one);
	a_order_b := apm_package_version__sortable_version_name(version_name_two);
	if a_order_a < a_order_b then
	    return -1;
	else if a_order_a > a_order_b then
	    return 1;
	end if; end if;

	return 0;   
END;
$$ LANGUAGE plpgsql immutable;

-- function upgrade_p


-- added
select define_function_args('apm_package_version__upgrade_p','path,initial_version_name,final_version_name');

--
-- procedure apm_package_version__upgrade_p/3
--
CREATE OR REPLACE FUNCTION apm_package_version__upgrade_p(
   upgrade_p__path varchar,
   upgrade_p__initial_version_name varchar,
   upgrade_p__final_version_name varchar
) RETURNS integer AS $$
DECLARE
  v_pos1                            integer;       
  v_pos2                            integer;       
  v_tmp                             varchar(1500);
  v_path                            varchar(1500);
  v_version_from                    apm_package_versions.version_name%TYPE;
  v_version_to                      apm_package_versions.version_name%TYPE;
BEGIN

	-- Set v_path to the tail of the path (the file name).        
	v_path := substr(upgrade_p__path, instr(upgrade_p__path, '/', -1) + 1);

	-- Remove the extension, if it is .sql.
	v_pos1 := position('.sql' in v_path);
	if v_pos1 > 0 then
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

	if apm_package_version__version_name_greater(upgrade_p__initial_version_name, v_version_from) <= 0 and
	   apm_package_version__version_name_greater(upgrade_p__final_version_name, v_version_to) >= 0 then
	    return 1;
	end if;

	return 0;
        -- exception when others then
	-- Invalid version number.
	-- return 0;
   
END;
$$ LANGUAGE plpgsql immutable;


-- procedure upgrade


-- added
select define_function_args('apm_package_version__upgrade','version_id');

--
-- procedure apm_package_version__upgrade/1
--
CREATE OR REPLACE FUNCTION apm_package_version__upgrade(
   upgrade__version_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    update apm_package_versions
    	set enabled_p = 'f',
	    installed_p = 'f'
	where package_key = (select package_key from apm_package_versions
	    	    	     where version_id = upgrade__version_id);
    update apm_package_versions
    	set enabled_p = 't',
	    installed_p = 't'
	where version_id = upgrade__version_id;			  
    
    return 0; 
END;
$$ LANGUAGE plpgsql;



-- show errors

-- create or replace package body apm_package_type
-- procedure create_type


-- added
select define_function_args('apm_package_type__create_type','package_key,pretty_name,pretty_plural,package_uri,package_type,initial_install_p,singleton_p,implements_subsite_p,inherit_templates_p,spec_file_path;null,spec_file_mtime;null');

--
-- procedure apm_package_type__create_type/11
--
CREATE OR REPLACE FUNCTION apm_package_type__create_type(
   create_type__package_key varchar,
   create_type__pretty_name varchar,
   create_type__pretty_plural varchar,
   create_type__package_uri varchar,
   create_type__package_type varchar,
   create_type__initial_install_p boolean,
   create_type__singleton_p boolean,
   create_type__implements_subsite_p boolean,
   create_type__inherit_templates_p boolean,
   create_type__spec_file_path varchar, -- default null
   create_type__spec_file_mtime integer -- default null

) RETURNS integer AS $$
DECLARE
BEGIN
   insert into apm_package_types
    (package_key, pretty_name, pretty_plural, package_uri, package_type,
    spec_file_path, spec_file_mtime, initial_install_p, singleton_p,
    implements_subsite_p, inherit_templates_p)
   values
    (create_type__package_key, create_type__pretty_name, create_type__pretty_plural,
     create_type__package_uri, create_type__package_type, create_type__spec_file_path, 
     create_type__spec_file_mtime, create_type__initial_install_p, create_type__singleton_p,
     create_type__implements_subsite_p, create_type__inherit_templates_p);

   return 0; 
END;
$$ LANGUAGE plpgsql;


-- function update_type


-- added
select define_function_args('apm_package_type__update_type','package_key,pretty_name;null,pretty_plural;null,package_uri;null,package_type;null,initial_install_p;null,singleton_p;null,implements_subsite_p;null,inherit_templates_p;null,spec_file_path;null,spec_file_mtime;null');

--
-- procedure apm_package_type__update_type/11
--
CREATE OR REPLACE FUNCTION apm_package_type__update_type(
   update_type__package_key varchar,
   update_type__pretty_name varchar,          -- default null
   update_type__pretty_plural varchar,        -- default null
   update_type__package_uri varchar,          -- default null
   update_type__package_type varchar,         -- default null
   update_type__initial_install_p boolean,    -- default null
   update_type__singleton_p boolean,          -- default null
   update_type__implements_subsite_p boolean, -- default null
   update_type__inherit_templates_p boolean,  -- default null
   update_type__spec_file_path varchar,       -- default null
   update_type__spec_file_mtime integer       -- default null

) RETURNS varchar AS $$
DECLARE
BEGIN
      UPDATE apm_package_types SET
      	pretty_name = coalesce(update_type__pretty_name, pretty_name),
    	pretty_plural = coalesce(update_type__pretty_plural, pretty_plural),
    	package_uri = coalesce(update_type__package_uri, package_uri),
    	package_type = coalesce(update_type__package_type, package_type),
    	spec_file_path = coalesce(update_type__spec_file_path, spec_file_path),
    	spec_file_mtime = coalesce(update_type__spec_file_mtime, spec_file_mtime),
    	singleton_p = coalesce(update_type__singleton_p, singleton_p),
    	initial_install_p = coalesce(update_type__initial_install_p, initial_install_p),
    	implements_subsite_p = coalesce(update_type__implements_subsite_p, implements_subsite_p),
    	inherit_templates_p = coalesce(update_type__inherit_templates_p, inherit_templates_p)
      where package_key = update_type__package_key;

      return update_type__package_key;
   
END;
$$ LANGUAGE plpgsql;


-- procedure drop_type


-- added
select define_function_args('apm_package_type__drop_type','package_key,cascade_p;f');

--
-- procedure apm_package_type__drop_type/2
--
CREATE OR REPLACE FUNCTION apm_package_type__drop_type(
   drop_type__package_key varchar,
   drop_type__cascade_p boolean -- default 'f'

) RETURNS integer AS $$
DECLARE
  cur_val                           record; 
BEGIN
    if drop_type__cascade_p = 't' then
        for cur_val in select package_id
       from apm_packages
       where package_key = drop_type__package_key
        loop
            PERFORM apm_package__delete(
	        cur_val.package_id
	    );
        end loop;
	-- Unregister all parameters.
        for cur_val in select parameter_id from apm_parameters
       where package_key = drop_type__package_key
	loop
	    PERFORM apm__unregister_parameter(cur_val.parameter_id);
	end loop;
  
        -- Unregister all versions
	for cur_val in select version_id from apm_package_versions
       where package_key = drop_type__package_key
	loop
	    PERFORM apm_package_version__delete(cur_val.version_id);
        end loop;
    end if;
    delete from apm_package_types
    where package_key = drop_type__package_key;

    return 0; 
END;
$$ LANGUAGE plpgsql;


-- function num_parameters


-- added
select define_function_args('apm_package_type__num_parameters','package_key');

--
-- procedure apm_package_type__num_parameters/1
--
CREATE OR REPLACE FUNCTION apm_package_type__num_parameters(
   num_parameters__package_key varchar
) RETURNS integer AS $$
DECLARE
  v_count                                integer;       
BEGIN
    select count(*) into v_count
    from apm_parameters
    where package_key = num_parameters__package_key;

    return v_count;
   
END;
$$ LANGUAGE plpgsql stable;





-- show errors

-- create or replace package body apm_parameter_value
-- function new


-- added
select define_function_args('apm_parameter_value__new','value_id;null,package_id,parameter_id,attr_value');

--
-- procedure apm_parameter_value__new/4
--
CREATE OR REPLACE FUNCTION apm_parameter_value__new(
   new__value_id integer, -- default null
   new__package_id integer,
   new__parameter_id integer,
   new__attr_value varchar

) RETURNS integer AS $$
DECLARE
  v_value_id                  apm_parameter_values.value_id%TYPE;
  v_title                     acs_objects.title%TYPE;
BEGIN
   select pkg.package_key || ': ' || pkg.instance_name || ' - ' || par.parameter_name into v_title from apm_packages pkg, apm_parameters par where pkg.package_id = new__package_id and par.parameter_id = new__parameter_id;

   v_value_id := acs_object__new(
     new__value_id,
     'apm_parameter_value',
     now(),
     null,
     null,
     null,
     't',
     v_title,
     new__package_id
   );

   insert into apm_parameter_values
    (value_id, package_id, parameter_id, attr_value)
     values
    (v_value_id, new__package_id, new__parameter_id, new__attr_value);

   return v_value_id;

END;
$$ LANGUAGE plpgsql;


-- procedure delete


-- added
select define_function_args('apm_parameter_value__delete','value_id;null');

--
-- procedure apm_parameter_value__delete/1
--
CREATE OR REPLACE FUNCTION apm_parameter_value__delete(
   delete__value_id integer -- default null

) RETURNS integer AS $$
DECLARE
BEGIN
    delete from apm_parameter_values 
    where value_id = delete__value_id;
    PERFORM acs_object__delete(delete__value_id);

    return 0; 
END;
$$ LANGUAGE plpgsql;


-- function new


-- added
select define_function_args('apm_application__new','application_id;null,instance_name;null,package_key,object_type;apm_application,creation_date;now(),creation_user;null,creation_ip;null,context_id;null');

--
-- procedure apm_application__new/8
--
CREATE OR REPLACE FUNCTION apm_application__new(
   application_id integer,    -- default null
   instance_name varchar,     -- default null
   package_key varchar,
   object_type varchar,       -- default 'apm_application'
   creation_date timestamptz, -- default now()
   creation_user integer,     -- default null
   creation_ip varchar,       -- default null
   context_id integer         -- default null

) RETURNS integer AS $$
DECLARE
  v_application_id       integer;       
BEGIN
    v_application_id := apm_package__new (
      application_id,
      instance_name,
      package_key,
      object_type,
      creation_date,
      creation_user,
      creation_ip,
      context_id
    );

    return v_application_id;
   
END;
$$ LANGUAGE plpgsql;


-- procedure delete


-- added
select define_function_args('apm_application__delete','application_id');

--
-- procedure apm_application__delete/1
--
CREATE OR REPLACE FUNCTION apm_application__delete(
   delete__application_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    delete from apm_applications
    where application_id = delete__application_id;
    PERFORM apm_package__delete(
        delete__application_id
    );

    return 0; 
END;
$$ LANGUAGE plpgsql;



-- show errors

-- create or replace package body apm_service
-- function new


-- added
select define_function_args('apm_service__new','service_id;null,instance_name;null,package_key,object_type;apm_service,creation_date;now(),creation_user;null,creation_ip;null,context_id;null');

--
-- procedure apm_service__new/8
--
CREATE OR REPLACE FUNCTION apm_service__new(
   service_id integer,        -- default null
   instance_name varchar,     -- default null
   package_key varchar,
   object_type varchar,       -- default 'apm_service'
   creation_date timestamptz, -- default now()
   creation_user integer,     -- default null
   creation_ip varchar,       -- default null
   context_id integer         -- default null

) RETURNS integer AS $$
DECLARE
  v_service_id           integer;       
BEGIN
    v_service_id := apm_package__new (
      service_id,
      instance_name,
      package_key,
      object_type,
      creation_date,
      creation_user,
      creation_ip,
      context_id
    );

    return v_service_id;
   
END;
$$ LANGUAGE plpgsql;


-- procedure delete


-- added
select define_function_args('apm_service__delete','service_id');

--
-- procedure apm_service__delete/1
--
CREATE OR REPLACE FUNCTION apm_service__delete(
   delete__service_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    delete from apm_services
    where service_id = delete__service_id;
    PERFORM apm_package__delete(
	delete__service_id
    );

    return 0; 
END;
$$ LANGUAGE plpgsql;

