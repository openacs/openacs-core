<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="subsite::after_mount.add_constraint">      
      <querytext>
      
		    BEGIN
			:1 := rel_constraint.new(
			constraint_name => :constraint_name,
			rel_segment => :segment_id,
			rel_side => 'two',
			required_rel_segment => rel_segment.get(:supersite_group_id, 'membership_rel'),
			creation_user => :user_id,
			creation_ip => :creation_ip
			);
		    END;
		
      </querytext>
</fullquery>

 
<fullquery name="subsite::auto_mount_application.select_package_object_names">      
      <querytext>
      
	    select t.pretty_name as package_name, acs_object.name(s.object_id) as object_name
	      from site_nodes s, apm_package_types t
	     where s.node_id = :node_id
	       and t.package_key = :package_key
	
      </querytext>
</fullquery>

 
<fullquery name="subsite::util::sub_type_exists_p.sub_type_exists_p">      
      <querytext>
      
	select case 
                 when exists (select 1 from acs_object_types 
                              where supertype = :object_type)
                 then 1 
                 else 0 
               end
        from dual
    
      </querytext>
</fullquery>

 
<fullquery name="subsite::util::object_type_path_list.select_object_type_path">      
      <querytext>
      
	select object_type
	from acs_object_types
	start with object_type = :object_type
	connect by object_type = prior supertype
    
      </querytext>
</fullquery>

    <fullquery name="subsite::get_application_options.package_types">
        <querytext>

    select pretty_name, package_key
    from   apm_package_types
    where  not (apm_package.singleton_p(package_key) = 1 and
                apm_package.num_instances(package_key) >= 1)
    and    package_key != 'acs-subsite'
    order  by upper(pretty_name)

        </querytext>
    </fullquery>
 
</queryset>
