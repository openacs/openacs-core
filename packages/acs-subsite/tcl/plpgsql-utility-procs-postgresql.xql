<?xml version="1.0"?>

<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="plpgsql_utility::get_function_args.get_function_args">      
    <querytext>
      select arg_name, arg_default
      from acs_function_args
      where function = upper(:function_name)
      order by arg_seq
    </querytext>
  </fullquery>

</queryset>
