<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="package_type_dynamic_p.object_type_dynamic_p">      
      <querytext>
      
    select case when exists (select 1 
                                   from acs_object_types t
                                  where t.dynamic_p = 't'
                                    and t.object_type = :object_type)
                then 1 else 0 end
      from dual
    
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_all_attributes">      
      <querytext>
      
    select upper(nvl(attr.table_name,t.table_name)) as attr_table_name, 
           upper(nvl(attr.column_name, attr.attribute_name)) as attr_column_name, 
           attr.ancestor_type, attr.min_n_values, attr.default_value
      from acs_object_type_attributes attr, 
           (select t.object_type, t.table_name, level as type_level
              from acs_object_types t
             start with t.object_type = :object_type
           connect by prior t.supertype = t.object_type) t
         where attr.ancestor_type = t.object_type
           and attr.object_type = :object_type
        order by t.type_level 
    
      </querytext>
</fullquery>

 
<fullquery name="package_recreate_hierarchy.select_object_types">      
      <querytext>
      
    select t.object_type
      from acs_object_types t
     where t.dynamic_p = 't'
     start with t.object_type = :object_type
       connect by prior t.object_type = t.supertype
    
      </querytext>
</fullquery>

 
<fullquery name="package_create.package_valid_p">      
      <querytext>
      
        select case when exists (select 1 
                                       from user_objects 
                                      where status = 'INVALID'
                                        and object_name = upper(:package_name)
                                        and object_type = upper(:type))
                        then 0 else 1 end
          from dual
    
      </querytext>
</fullquery>

 
<fullquery name="package_object_view_reset.select_ancestor_types">      
      <querytext>
      
    select t.object_type as ancestor_type
      from acs_object_types t 
     start with t.object_type = :object_type 
       connect by prior t.supertype = t.object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_object_view_reset.select_sub_types">      
      <querytext>
      
    select t.object_type as sub_type
      from acs_object_types t 
     start with t.object_type = :object_type 
       connect by prior t.object_type = t.supertype
    
      </querytext>
</fullquery>

 
<fullquery name="package_insert_default_comment.select_comments">      
      <querytext>
      
        select acs_object.name(:user_id) as author,
               sysdate as creation_date
          from dual
    
      </querytext>
</fullquery>

 
<fullquery name="package_insert_default_comment.select_comments">      
      <querytext>
      
        select acs_object.name(:user_id) as author,
               sysdate as creation_date
          from dual
    
      </querytext>
</fullquery>

 
<fullquery name="package_object_attribute_list.attributes_select">      
      <querytext>
      
    select a.attribute_id, 
           nvl(a.table_name, t.table_name) as table_name,
           nvl(a.column_name, a.attribute_name) as attribute_name, 
           a.pretty_name, 
           a.datatype, 
           case when a.min_n_values = 0 then 'f' else 't' end as required_p, 
               a.default_value, 
               t.table_name as object_type_table_name, 
               t.id_column as object_type_id_column
          from acs_object_type_attributes a, 
               (select t.object_type, t.table_name, t.id_column, level as type_level
                  from acs_object_types t
                 start with t.object_type=:start_with
               connect by prior t.object_type = t.supertype) t 
         where a.object_type = :object_type
           and t.object_type = a.ancestor_type $storage_clause
         order by type_level
      </querytext>
</fullquery>

 
<fullquery name="package_plsql_args.select_package_func_param_list">      
      <querytext>

    select args.argument_name
        from user_arguments args
        where args.position > 0
      and args.object_name = upper(:function_name)
      and args.package_name = upper(:package_name)
    
      </querytext>
</fullquery>

 
<fullquery name="package_table_columns_for_type.select_object_type_param_list">      
      <querytext>
      
    select cols.table_name, cols.column_name
      from user_tab_columns cols, 
           (select upper(t.table_name) as table_name
              from acs_object_types t
                 start with t.object_type = :object_type
               connect by prior t.supertype = t.object_type) t
     where cols.column_name in
              (select args.argument_name
                     from user_arguments args
                    where args.position > 0
                  and args.object_name = upper(:object_name)
                  and args.package_name = upper(:package_name))
       and cols.table_name = t.table_name
    
      </querytext>
</fullquery>

 
<fullquery name="package_instantiate_object.create_object">      
      <querytext>
      
    BEGIN
      :1 := ${package_name}.new([plsql_utility::generate_attribute_parameter_call \
          -prepend ":" \
          -indent [expr [string length $package_name] + 29] \
          $pieces]
      );
    END; 
    
      </querytext>
</fullquery>

 
<partialquery name="package_generate_body.body">      
      <querytext>

create or replace package body ${package_name}
as
[package_insert_default_comment]
  function new ( 
         [plsql_utility::generate_attribute_parameters $attribute_list]
  ) return ${table_name}.${id_column}%TYPE
  is
    v_$id_column ${table_name}.${id_column}%TYPE;
  begin

    v_$id_column := ${supertype_package_name}.new (
                     [plsql_utility::generate_attribute_parameter_call_from_attributes \
                 -prepend "new." \
                 -indent 21 \
                 $supertype_attr_list]
                   );

    insert into ${table_name} 
    ($id_column[plsql_utility::generate_attribute_dml -ignore [list $id_column] $table_name $attribute_list]) 
    values 
    (v_$id_column[plsql_utility::generate_attribute_dml -prepend "new." -ignore [list $id_column] $table_name $attribute_list]);

    return v_$id_column;

  end new;

  procedure del (
    $id_column      in ${table_name}.${id_column}%TYPE
  )
  is 
  begin

    ${supertype_package_name}.del( $package_name.del.$id_column );

  end del;

end ${package_name};
    
      </querytext>
</partialquery>

 
<partialquery name="package_generate_spec.spec">      
      <querytext>

create or replace package $package_name as
[package_insert_default_comment]
  function new (
         [plsql_utility::generate_attribute_parameters [package_create_attribute_list \
         -supertype $supertype \
         -object_name "NEW" \
         -table $table_name \
         -column $id_column \
         $object_type]]
 ) return ${table_name}.${id_column}%TYPE;

  procedure del (
    $id_column      in ${table_name}.${id_column}%TYPE
  );
END ${package_name};
    
      </querytext>
</partialquery>

 
<partialquery name="package_attribute_default.creation_date">      
      <querytext>sysdate</querytext>
</partialquery>

<partialquery name="package_attribute_default.last_modified">      
      <querytext>sysdate</querytext>
</partialquery>

<fullquery name="package_function_p.function_p">      
  <querytext>
    select count(*)
    from user_arguments
    where package_name = upper(:package_name)
      and object_name = upper(:function_name)
      and position = 0
  </querytext>
</fullquery>


<fullquery name="package_exec_plsql.exec_plsql_proc">      
      <querytext>
      
    BEGIN
      ${package_name}.${function_name}([plsql_utility::generate_attribute_parameter_call \
    -prepend ":" \
    -indent [expr [string length $package_name] + 29] \
    $pieces]
      );
    END; 
    
      </querytext>
</fullquery>


<fullquery name="package_exec_plsql.exec_plsql_func">      
      <querytext>
      
    BEGIN
      :1 := ${package_name}.${function_name}([plsql_utility::generate_attribute_parameter_call \
          -prepend ":" \
          -indent [expr [string length $package_name] + 29] \
          $pieces]
      );
    END; 
    
      </querytext>
</fullquery>

 
</queryset>
