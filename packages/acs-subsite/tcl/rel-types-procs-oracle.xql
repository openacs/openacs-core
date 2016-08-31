<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="rel_types::new.drop_type">
<querytext>
begin acs_rel_type.drop_type(:rel_type); end;
</querytext>
</fullquery>

<fullquery name="rel_types::new.create_type">
<querytext>
	    begin
	    acs_rel_type.create_type (	
            rel_type          => :rel_type,
            supertype         => :supertype,
            pretty_name       => :pretty_name,
            pretty_plural     => :pretty_plural,
            table_name        => :table_name,
            id_column         => 'rel_id',
            package_name      => :package_name,
            object_type_one   => :object_type_one, 
            role_one          => :role_one,
            min_n_rels_one    => :min_n_rels_one,
            max_n_rels_one    => :max_n_rels_one,
            object_type_two   => :object_type_two, 
            role_two          => :role_two,
            min_n_rels_two    => :min_n_rels_two,
            max_n_rels_two    => :max_n_rels_two,
            composable_p      => :composable_p
	    );
	    end;
</querytext>
</fullquery>

<fullquery name="rel_types::create_role.create_role">
<querytext>
begin  acs_rel_type.create_role(:role, :pretty_name, :pretty_plural);
end;
</querytext>
</fullquery>

<fullquery name="rel_types::additional_rel_types_group_p.group_rel_type_exists">      
<querytext>
     select case when exists (select 1
                              from acs_object_types t
                              where t.object_type not in (select g.rel_type
                                                          from group_rels g
                                                          where g.group_id = :group_id)
                              connect by prior t.object_type = t.supertype
                              start with t.object_type in ('membership_rel','composition_rel'))
            then 1 else 0 end
            from dual
</querytext>
</fullquery>

<fullquery name="rel_types::additional_rel_types_group_type_p.group_rel_type_exists">      
<querytext>
     select case when exists (select 1
                              from acs_object_types t
                              where t.object_type not in (select g.rel_type
                                                          from group_type_rels g
                                                          where g.group_type = :group_type)
                              connect by prior t.object_type = t.supertype
                              start with t.object_type in ('membership_rel','composition_rel'))
            then 1 else 0 end
            from dual
</querytext>
</fullquery>


</queryset>
