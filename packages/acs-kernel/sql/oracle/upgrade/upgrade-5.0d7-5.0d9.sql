-- Remove obsolete parts of the APM datamodel
--
-- @author Peter Marklund

-- *** Remove a column not needed
-- See http://openacs.org/bugtracker/openacs/bug?bug%5fnumber=555
alter table apm_packages drop column enabled_p;

-- *** Get rid of file-related data no longer used
drop table apm_package_file_types cascade constraints;
drop table apm_package_files cascade constraints;
drop view apm_file_info;
-- Recreating apm_version_package and apm_package packages to remove the following procs and functions:
-- apm_package_version.add_file
-- apm_package_version.remove_file
-- apm_package.enable
-- apm_package.disable
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
    spec_file_path		in apm_package_types.spec_file_path%TYPE default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE default null
  ) 
  is
  begin
   insert into apm_package_types
    (package_key, pretty_name, pretty_plural, package_uri, package_type,
    spec_file_path, spec_file_mtime, initial_install_p, singleton_p)
   values
    (create_type.package_key, create_type.pretty_name, create_type.pretty_plural,
     create_type.package_uri, create_type.package_type, create_type.spec_file_path, 
     create_type.spec_file_mtime, create_type.initial_install_p, create_type.singleton_p);
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
    	singleton_p = nvl(update_type.singleton_p, singleton_p)
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

end apm_package;
/
show errors


create or replace package site_node
as

  -- Create a new site node. If you set directory_p to be 'f' then you
  -- cannot create nodes that have this node as their parent.

  function new (
    node_id             in site_nodes.node_id%TYPE default null,
    parent_id           in site_nodes.node_id%TYPE default null,
    name                in site_nodes.name%TYPE,
    object_id           in site_nodes.object_id%TYPE default null,
    directory_p         in site_nodes.directory_p%TYPE,
    pattern_p           in site_nodes.pattern_p%TYPE default 'f',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return site_nodes.node_id%TYPE;

  -- Delete a site node.

  procedure del (
    node_id             in site_nodes.node_id%TYPE
  );

  -- Return the node_id of a url. If the url begins with '/' then the
  -- parent_id must be null. This will raise the no_data_found
  -- exception if there is no mathing node in the site_nodes table.
  -- This will match directories even if no trailing slash is included
  -- in the url.

  function node_id (
    url                 in varchar2,
    parent_id   in site_nodes.node_id%TYPE default null
  ) return site_nodes.node_id%TYPE;

  -- Return the url of a node_id.

  function url (
    node_id             in site_nodes.node_id%TYPE
  ) return varchar2;

end;
/
show errors

create or replace package body site_node
as

  function new (
    node_id             in site_nodes.node_id%TYPE default null,
    parent_id           in site_nodes.node_id%TYPE default null,
    name                in site_nodes.name%TYPE,
    object_id           in site_nodes.object_id%TYPE default null,
    directory_p         in site_nodes.directory_p%TYPE,
    pattern_p           in site_nodes.pattern_p%TYPE default 'f',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return site_nodes.node_id%TYPE
  is
    v_node_id           site_nodes.node_id%TYPE;
    v_directory_p       site_nodes.directory_p%TYPE;
  begin
    if parent_id is not null then
      select directory_p into v_directory_p
      from site_nodes
      where node_id = new.parent_id;

      if v_directory_p = 'f' then
        raise_application_error (
          -20000,
          'Node ' || parent_id || ' is not a directory'
        );
      end if;
    end if;

    v_node_id := acs_object.new (
      object_id => node_id,
      object_type => 'site_node',
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into site_nodes
     (node_id, parent_id, name, object_id, directory_p, pattern_p)
    values
     (v_node_id, new.parent_id, new.name, new.object_id,
      new.directory_p, new.pattern_p);

     return v_node_id;
  end;

  procedure del (
    node_id             in site_nodes.node_id%TYPE
  )
  is
  begin
    delete from site_nodes
    where node_id = site_node.del.node_id;

    acs_object.del(node_id);
  end;

  function find_pattern (
    node_id     in site_nodes.node_id%TYPE
  ) return site_nodes.node_id%TYPE
  is
    v_pattern_p site_nodes.pattern_p%TYPE;
    v_parent_id site_nodes.node_id%TYPE;
  begin
    if node_id is null then
      raise no_data_found;
    end if;

    select pattern_p, parent_id into v_pattern_p, v_parent_id
    from site_nodes
    where node_id = find_pattern.node_id;

    if v_pattern_p = 't' then
      return node_id;
    else
      return find_pattern(v_parent_id);
    end if;
  end;

  function node_id (
    url                 in varchar2,
    parent_id           in site_nodes.node_id%TYPE default null
  ) return site_nodes.node_id%TYPE
  is
    v_pos               integer;
    v_first             site_nodes.name%TYPE;
    v_rest              varchar2(4000);
    v_node_id           integer;
    v_pattern_p         site_nodes.pattern_p%TYPE;
    v_url               varchar2(4000);
    v_directory_p       site_nodes.directory_p%TYPE;
    v_trailing_slash_p  char(1);
  begin
    v_url := url;

    if substr(v_url, length(v_url), 1) = '/' then
      -- It ends with a / so it must be a directory.
      v_trailing_slash_p := 't';
      v_url := substr(v_url, 1, length(v_url) - 1);
    end if;

    v_pos := 1;

    while v_pos <= length(v_url) and substr(v_url, v_pos, 1) != '/' loop
      v_pos := v_pos + 1;
    end loop;

    if v_pos = length(v_url) then
      v_first := v_url;
      v_rest := null;
    else
      v_first := substr(v_url, 1, v_pos - 1);
      v_rest := substr(v_url, v_pos + 1);
    end if;

    begin
      -- Is there a better way to do these freaking null compares?
      select node_id, directory_p into v_node_id, v_directory_p
      from site_nodes
      where nvl(parent_id, 3.14) = nvl(site_node.node_id.parent_id, 3.14)
      and nvl(name, chr(10)) = nvl(v_first, chr(10));
    exception
      when no_data_found then
        return find_pattern(parent_id);
    end;

    if v_rest is null then
      if v_trailing_slash_p = 't' and v_directory_p = 'f' then
        return find_pattern(parent_id);
      else
        return v_node_id;
      end if;
    else
      return node_id(v_rest, v_node_id);
    end if;
  end;

  function url (
    node_id             in site_nodes.node_id%TYPE
  ) return varchar2
  is
    v_parent_id site_nodes.node_id%TYPE;
    v_name              site_nodes.name%TYPE;
    v_directory_p       site_nodes.directory_p%TYPE;
  begin
    if node_id is null then
      return '';
    end if;

    select parent_id, name, directory_p into
           v_parent_id, v_name, v_directory_p
    from site_nodes
    where node_id = url.node_id;

    if v_directory_p = 't' then
      return url(v_parent_id) || v_name || '/';
    else
      return url(v_parent_id) || v_name;
    end if;
  end;

end;
/


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
       where package_key = initialize_parameters.package_key;
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

       select package_type into v_package_type
       from apm_package_types
       where package_key = apm_package.new.package_key;

       insert into apm_packages
       (package_id, package_key, instance_name)
       values
       (v_package_id, package_key, v_instance_name);

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

end apm_package;
/
show errors


