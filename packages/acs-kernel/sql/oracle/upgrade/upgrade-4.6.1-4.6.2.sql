-- Callbacks
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

-- Add column for auto-mount
alter table apm_package_versions add auto_mount varchar(50);

comment on column apm_package_versions.auto_mount is '
 A dir under the main site site node where an instance of the package will be mounted
 automatically upon installation. Useful for site-wide services that need mounting
 such as general-comments and notifications.
';

-- Recreate view for auto-mount
create or replace view apm_package_version_info as
    select v.package_key, t.package_uri, t.pretty_name, t.singleton_p, t.initial_install_p,
           v.version_id, v.version_name,
           v.version_uri, v.summary, v.description_format, v.description, v.release_date,
           v.vendor, v.vendor_uri, v.auto_mount, v.enabled_p, v.installed_p, v.tagged_p, v.imported_p, v.data_model_loaded_p,
           v.activation_date, v.deactivation_date,
           nvl(v.content_length,0) as tarball_length,
           distribution_uri, distribution_date
    from   apm_package_types t, apm_package_versions v
    where  v.package_key = t.package_key;

create or replace view apm_enabled_package_versions as
    select * from apm_package_version_info
    where  enabled_p = 't';

-- Change PLSQL code for auto-mount
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

  procedure delete (
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

  -- Add a file to the indicated version.
  function add_file(
    file_id			in apm_package_files.file_id%TYPE
				default null,
    version_id			in apm_package_versions.version_id%TYPE,
    path			in apm_package_files.path%TYPE,
    file_type			in apm_package_file_types.file_type_key%TYPE,
    db_type			in apm_package_db_types.db_type_key%TYPE
                                default null
  ) return apm_package_files.file_id%TYPE;

  -- Remove a file from the indicated version.
  procedure remove_file(
    version_id			in apm_package_versions.version_id%TYPE,
    path			in apm_package_files.path%TYPE
  );

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
    path			in apm_package_files.path%TYPE,
    initial_version_name	in apm_package_versions.version_name%TYPE,
    final_version_name		in apm_package_versions.version_name%TYPE
   ) return integer;

  procedure upgrade(
    version_id                  in apm_package_versions.version_id%TYPE
  );

end apm_package_version;
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
		object_type => 'apm_package_version'
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

    procedure delete (
      version_id		in apm_packages.package_id%TYPE
    )
    is
    begin
      delete from apm_package_owners 
      where version_id = apm_package_version.delete.version_id; 

      delete from apm_package_files
      where version_id = apm_package_version.delete.version_id;

      delete from apm_package_dependencies
      where version_id = apm_package_version.delete.version_id;

      delete from apm_package_versions 
	where version_id = apm_package_version.delete.version_id;

      acs_object.delete(apm_package_version.delete.version_id);

    end delete;

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
    
	insert into apm_package_dependencies(dependency_id, version_id, dependency_type, service_uri, service_version)
	    select acs_object_id_seq.nextval, v_version_id, dependency_type, service_uri, service_version
	    from apm_package_dependencies
	    where version_id = copy.version_id;
    
	insert into apm_package_files(file_id, version_id, path, file_type, db_type)
	    select acs_object_id_seq.nextval, v_version_id, path, file_type, db_type
	    from apm_package_files
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

  function add_file(
    file_id			in apm_package_files.file_id%TYPE
				default null,
    version_id			in apm_package_versions.version_id%TYPE,
    path			in apm_package_files.path%TYPE,
    file_type			in apm_package_file_types.file_type_key%TYPE,
    db_type			in apm_package_db_types.db_type_key%TYPE
                                default null
  ) return apm_package_files.file_id%TYPE
  is
    v_file_id apm_package_files.file_id%TYPE;
    v_file_exists_p integer;
  begin
	select file_id into v_file_id from apm_package_files
  	where version_id = add_file.version_id 
	and path = add_file.path;
        return v_file_id;
	exception 
	       when NO_DATA_FOUND
	       then
	       	if file_id is null then
	          select acs_object_id_seq.nextval into v_file_id from dual;
	        else
	          v_file_id := file_id;
	        end if;

  	        insert into apm_package_files 
		(file_id, version_id, path, file_type, db_type) 
		values 
		(v_file_id, add_file.version_id, add_file.path, add_file.file_type,
                 add_file.db_type);
	        return v_file_id;
     end add_file;

  -- Remove a file from the indicated version.
  procedure remove_file(
    version_id			in apm_package_versions.version_id%TYPE,
    path			in apm_package_files.path%TYPE
  )
  is
  begin
    delete from apm_package_files 
    where version_id = remove_file.version_id
    and path = remove_file.path;
  end remove_file; 


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
      (v_dep_id, add_dependency.version_id, 'requires', add_dependency.dependency_uri,
	add_dependency.dependency_version);
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
    path			in apm_package_files.path%TYPE,
    initial_version_name	in apm_package_versions.version_name%TYPE,
    final_version_name		in apm_package_versions.version_name%TYPE
   ) return integer
    is
	v_pos1 integer;
	v_pos2 integer;
	v_path apm_package_files.path%TYPE;
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
