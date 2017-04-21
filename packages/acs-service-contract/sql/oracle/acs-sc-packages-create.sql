-- $Id$

create or replace package acs_sc_contract
as

   function new (
       contract_name	in acs_sc_contracts.contract_name%TYPE,
       contract_desc	in acs_sc_contracts.contract_desc%TYPE
   ) return acs_sc_contracts.contract_id%TYPE;

   function get_id (
       contract_name	in acs_sc_contracts.contract_name%TYPE
   ) return acs_sc_contracts.contract_id%TYPE;

   function get_name (
       contract_id	in acs_sc_contracts.contract_id%TYPE
   ) return acs_sc_contracts.contract_name%TYPE;

   procedure del (
       contract_name	in acs_sc_contracts.contract_name%TYPE default null,
       contract_id	in acs_sc_contracts.contract_id%TYPE default null
   );
end acs_sc_contract;
/
show errors

create or replace package acs_sc_operation
as

   function new (
       contract_name		in acs_sc_contracts.contract_name%TYPE,
       operation_name		in acs_sc_operations.operation_name%TYPE,
       operation_desc		in acs_sc_operations.operation_desc%TYPE,
       operation_iscachable_p   in acs_sc_operations.operation_iscachable_p%TYPE,
       operation_nargs		in acs_sc_operations.operation_nargs%TYPE,
       operation_inputtype	in acs_sc_msg_types.msg_type_name%TYPE,
       operation_outputtype	in acs_sc_msg_types.msg_type_name%TYPE
   ) return acs_sc_operations.operation_id%TYPE;

   function get_id (
       contract_name		acs_sc_contracts.contract_name%TYPE,
       operation_name		acs_sc_operations.operation_name%TYPE
   ) return acs_sc_operations.operation_id%TYPE;


   procedure del (
       operation_id		acs_sc_operations.operation_id%TYPE default null,
       operation_name		acs_sc_operations.operation_name%TYPE default null,
       contract_name		acs_sc_contracts.contract_name%TYPE default null
   );

end acs_sc_operation;
/
show errors

create or replace package acs_sc_impl
as

   function new (
       impl_contract_name	acs_sc_impls.impl_contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE,
       impl_pretty_name		acs_sc_impls.impl_pretty_name%TYPE default null,
       impl_owner_name		acs_sc_impls.impl_owner_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE;

   function get_id (
       impl_contract_name	acs_sc_impls.impl_contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE;

   function get_name (
       impl_id			acs_sc_impls.impl_id%TYPE
   ) return acs_sc_impls.impl_name%TYPE;

   procedure del (
       impl_contract_name	acs_sc_impls.impl_contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE
   );

   /* Next 2 functions are deprecated but left here for backwards compatibility */

   function new_alias (
       impl_contract_name	acs_sc_contracts.contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE,
       impl_alias		acs_sc_impl_aliases.impl_alias%TYPE,
       impl_pl			acs_sc_impl_aliases.impl_pl%TYPE
   ) return acs_sc_impl_aliases.impl_id%TYPE;

   -- fix by Ben from delete_aliases to delete_alias
   function delete_alias (
       impl_contract_name	acs_sc_contracts.contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE;

end acs_sc_impl;
/
show error

create or replace package acs_sc_impl_alias
as
   function new (
       impl_contract_name	acs_sc_contracts.contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE,
       impl_alias		acs_sc_impl_aliases.impl_alias%TYPE,
       impl_pl			acs_sc_impl_aliases.impl_pl%TYPE
   ) return acs_sc_impl_aliases.impl_id%TYPE;

   function del (
       impl_contract_name	acs_sc_contracts.contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE;

end acs_sc_impl_alias;
/
show error

create or replace package acs_sc_binding
as
   procedure new (
       contract_id	acs_sc_operations.contract_id%TYPE default null,
       impl_id		acs_sc_bindings.impl_id%TYPE default null,
       contract_name    acs_sc_contracts.contract_name%TYPE default null,
       impl_name	acs_sc_impls.impl_name%TYPE default null
   );

   procedure del (
       contract_id	acs_sc_contracts.contract_id%TYPE default null,
       contract_name	acs_sc_contracts.contract_name%TYPE default null,
       impl_id		acs_sc_impls.impl_id%TYPE default null,
       impl_name	acs_sc_impls.impl_name%TYPE default null
   );

   function exists_p (
       contract_name		acs_sc_contracts.contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE
   ) return integer;

end acs_sc_binding;
/
show errors

create or replace package body acs_sc_contract
as
   function new (
       contract_name	in acs_sc_contracts.contract_name%TYPE,
       contract_desc	in acs_sc_contracts.contract_desc%TYPE
   ) return acs_sc_contracts.contract_id%TYPE
   is
       v_contract_id	acs_sc_contracts.contract_id%TYPE;
   begin
       v_contract_id := acs_object.new(
		object_type => 'acs_sc_contract',
		title => contract_name
	);

       insert into acs_sc_contracts (
	      contract_id,
	      contract_name,
	      contract_desc
       ) values (
	      v_contract_id,
	      contract_name,
	      contract_desc
       );

       return v_contract_id;

   end new;

   function get_id (
       contract_name	in acs_sc_contracts.contract_name%TYPE
   ) return acs_sc_contracts.contract_id%TYPE
   is
       v_contract_id	acs_sc_contracts.contract_id%TYPE;
   begin
	
       select contract_id into v_contract_id
       from acs_sc_contracts
       where contract_name = get_id.contract_name;

       return v_contract_id;

   end get_id;

   function get_name (
       contract_id	in acs_sc_contracts.contract_id%TYPE
   ) return acs_sc_contracts.contract_name%TYPE
   is
       v_contract_name	acs_sc_contracts.contract_name%TYPE;
   begin

       select contract_name into v_contract_name
       from acs_sc_contracts
       where contract_id = get_name.contract_id;

       return v_contract_name;

   end get_name;

   procedure del (
       contract_name	in acs_sc_contracts.contract_name%TYPE default null,
       contract_id	in acs_sc_contracts.contract_id%TYPE default null
   )
   is
       v_contract_id	acs_sc_contracts.contract_id%TYPE;
   begin

	if contract_name is not NULL
	then
	   v_contract_id := acs_sc_contract.get_id(contract_name);

	elsif contract_id is not NULL
	then
	   v_contract_id := contract_id;
	
	else
	   raise_application_error(-20001, 'Service Contracts: no valid args supplied to delete');
	end if;	


       delete from acs_sc_contracts
              where contract_id = v_contract_id;
       acs_object.del(v_contract_id);

   end del;

end acs_sc_contract;
/
show errors


create or replace package body acs_sc_operation
as

   function new (
       contract_name		in acs_sc_contracts.contract_name%TYPE,
       operation_name		in acs_sc_operations.operation_name%TYPE,
       operation_desc		in acs_sc_operations.operation_desc%TYPE,
       operation_iscachable_p   in acs_sc_operations.operation_iscachable_p%TYPE,
       operation_nargs		in acs_sc_operations.operation_nargs%TYPE,
       operation_inputtype	in acs_sc_msg_types.msg_type_name%TYPE,
       operation_outputtype	in acs_sc_msg_types.msg_type_name%TYPE
   ) return acs_sc_operations.operation_id%TYPE
   is
       v_contract_id		acs_sc_contracts.contract_id%TYPE;
       v_operation_id		acs_sc_operations.operation_id%TYPE;
       v_operation_inputtype_id acs_sc_operations.operation_inputtype_id%TYPE;
       v_operation_outputtype_id acs_sc_operations.operation_outputtype_id%TYPE;
   begin

       v_contract_id := acs_sc_contract.get_id(contract_name);
       v_operation_id := acs_object.new (
		object_type => 'acs_sc_operation',
		title => operation_name
	);
       v_operation_inputtype_id := acs_sc_msg_type.get_id(operation_inputtype);
       v_operation_outputtype_id := acs_sc_msg_type.get_id(operation_outputtype);

       insert into acs_sc_operations (
           contract_id,		
	   operation_id,
	   contract_name,
	   operation_name,
	   operation_desc,
	   operation_iscachable_p,
	   operation_nargs,
	   operation_inputtype_id,
	   operation_outputtype_id
       ) values (
	   v_contract_id,
	   v_operation_id,
	   contract_name,
	   operation_name,
	   operation_desc,
	   operation_iscachable_p,
	   operation_nargs,
	   v_operation_inputtype_id,
	   v_operation_outputtype_id
       );

       return v_operation_id;

   end new;


   function get_id (
       contract_name		acs_sc_contracts.contract_name%TYPE,
       operation_name		acs_sc_operations.operation_name%TYPE
   ) return acs_sc_operations.operation_id%TYPE
   as
       v_operation_id		acs_sc_operations.operation_id%TYPE;
   begin
       select operation_id into v_operation_id
       from acs_sc_operations
       where contract_name = get_id.contract_name
       and operation_name = get_id.operation_name;

       return v_operation_id;
   end get_id;


   procedure del (
       operation_id		acs_sc_operations.operation_id%TYPE default null,
       operation_name		acs_sc_operations.operation_name%TYPE default null,
       contract_name		acs_sc_contracts.contract_name%TYPE default null
   )
   is
       v_operation_id		acs_sc_operations.operation_id%TYPE;
   begin

       if (operation_id is NULL and operation_name is not NULL and contract_name is not NULL)
       then
	  v_operation_id := get_id(contract_name, operation_name);

       elsif operation_id is not NULL
       then
          v_operation_id := operation_id;

       else
          raise_application_error(-20001, 'ACS Contracts: Invalid args to operation delete');
       end if;

       delete from acs_sc_operations
	   where operation_id = v_operation_id;

   end del;

   	   	
end acs_sc_operation;
/
show errors


create or replace package body acs_sc_impl
as

   function new (
       impl_contract_name	acs_sc_impls.impl_contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE,
       impl_pretty_name		acs_sc_impls.impl_pretty_name%TYPE default null,
       impl_owner_name		acs_sc_impls.impl_owner_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE
   is
       v_impl_id		acs_sc_impls.impl_id%TYPE;
   begin
       v_impl_id := acs_object.new (
		object_type => 'acs_sc_implementation',
		title => impl_pretty_name
	);

       insert into acs_sc_impls (
	      impl_id,
	      impl_name,
              impl_pretty_name,
	      impl_owner_name,
	      impl_contract_name
       ) values (
	      v_impl_id,
	      impl_name,
              impl_pretty_name,
	      impl_owner_name,
	      impl_contract_name
       );

       return v_impl_id;
   end new;

   function get_id (
       impl_contract_name	acs_sc_impls.impl_contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE
   as
       v_impl_id		acs_sc_impls.impl_id%TYPE;
   begin

       select impl_id into v_impl_id
       from acs_sc_impls
       where impl_name = get_id.impl_name
       and impl_contract_name = get_id.impl_contract_name;

       return v_impl_id;

   end get_id;


   function get_name (
       impl_id			acs_sc_impls.impl_id%TYPE
   ) return acs_sc_impls.impl_name%TYPE
   as
       v_impl_name		acs_sc_impls.impl_name%TYPE;
   begin

       select impl_name into v_impl_name
       from acs_sc_impls
       where impl_id = get_name.impl_id;

       return v_impl_name;

   end get_name;

   procedure del (
       impl_contract_name	acs_sc_impls.impl_contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE
   )
   as
   begin
       delete from acs_sc_impls
       where impl_contract_name = acs_sc_impl.del.impl_contract_name
       and impl_name = acs_sc_impl.del.impl_name;   	
   end del;


   /* next 2 functions are deprecated. */

  function new_alias (
       impl_contract_name	acs_sc_contracts.contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE,
       impl_alias		acs_sc_impl_aliases.impl_alias%TYPE,
       impl_pl			acs_sc_impl_aliases.impl_pl%TYPE
   ) return acs_sc_impl_aliases.impl_id%TYPE
   is
       v_impl_id		acs_sc_impls.impl_id%TYPE;
   begin
	-- FUNCTION DEPRECATED. USE acs_sc_impl_alias.new
	dbms_output.put_line('acs_sc_impl.new_alias DEPRECATED. Use acs_sc_impl_alias.new');

	v_impl_id := acs_sc_impl_alias.new(
		impl_contract_name,
		impl_name,
		impl_operation_name,
		impl_alias,
		impl_pl
	);

	return v_impl_id;

   end new_alias;

   function delete_alias (
       impl_contract_name	acs_sc_contracts.contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE
   is
       v_impl_id		acs_sc_impls.impl_id%TYPE;
   begin
	-- FUNCTION DEPRECATED. USE acs_sc_impl_alias.delete
	dbms_output.put_line('acs_sc_impl.delete_alias DEPRECATED. Use acs_sc_impl_alias.delete');

	v_impl_id := acs_sc_impl_alias.del(
		impl_contract_name,
		impl_name,
		impl_operation_name
	);

       return v_impl_id;

   end delete_alias;

end acs_sc_impl;
/
show errors

create or replace package body acs_sc_impl_alias
as

  function new (
       impl_contract_name	acs_sc_contracts.contract_name%TYPE,
       impl_name			acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE,
       impl_alias			acs_sc_impl_aliases.impl_alias%TYPE,
       impl_pl				acs_sc_impl_aliases.impl_pl%TYPE
   ) return acs_sc_impl_aliases.impl_id%TYPE
   is
       v_impl_id		acs_sc_impls.impl_id%TYPE;
   begin

       v_impl_id := acs_sc_impl.get_id(impl_contract_name,impl_name);

       insert into acs_sc_impl_aliases (
        impl_id,
		impl_name,
		impl_contract_name,
		impl_operation_name,
		impl_alias,
		impl_pl
       ) values (
        v_impl_id,
		impl_name,
		impl_contract_name,
		impl_operation_name,
		impl_alias,
		impl_pl
       );

       return v_impl_id;

   end new;

   function del (
       impl_contract_name	acs_sc_contracts.contract_name%TYPE,
       impl_name			acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE
   is
       v_impl_id		acs_sc_impls.impl_id%TYPE;
   begin
       v_impl_id := acs_sc_impl.get_id(impl_contract_name,impl_name);

       delete from acs_sc_impl_aliases
       where impl_contract_name = acs_sc_impl_alias.del.impl_contract_name
       and impl_name = acs_sc_impl_alias.del.impl_name
       and impl_operation_name = acs_sc_impl_alias.del.impl_operation_name;

       return v_impl_id;

   end del;

end acs_sc_impl_alias;
/
show errors 

create or replace package body acs_sc_binding
as
   -- you can pick a pair of args, either ids or names to pass in.
   procedure new (
       contract_id	acs_sc_operations.contract_id%TYPE default null,
       impl_id		acs_sc_bindings.impl_id%TYPE default null,
       contract_name    acs_sc_contracts.contract_name%TYPE default null,
       impl_name	acs_sc_impls.impl_name%TYPE default null
   )
   is
       v_contract_name	acs_sc_contracts.contract_name%TYPE;
       v_contract_id    acs_sc_contracts.contract_id%TYPE;
       v_impl_name	acs_sc_impls.impl_name%TYPE;
       v_impl_id	acs_sc_impls.impl_id%TYPE;
       v_count		integer;
   begin

       if impl_id is not null and contract_id is not null
       then

          v_contract_name := acs_sc_contract.get_name(contract_id);
          v_impl_name := acs_sc_impl.get_name(impl_id);
	  v_contract_id := contract_id;
	  v_impl_id := impl_id;

       elsif contract_name is not null and impl_name is not null
       then
          v_contract_id := acs_sc_contract.get_id(contract_name);
          v_impl_id := acs_sc_impl.get_id(contract_name,impl_name);
	  v_impl_name := impl_name;
	  v_contract_name := contract_name;

       else
          raise_application_error(-20001, 'Service Contracts:Invalid args to binding new');
       end if;


       select count(*) into v_count
         from acs_sc_operations
	 where contract_id = new.contract_id
	   and operation_name not in (select impl_operation_name
				      from acs_sc_impl_aliases
				      where impl_contract_name = v_contract_name
				      and impl_id = v_impl_id);

       if v_count > 0
       then
	  raise_application_error(-20001, 'Binding of ' ||
					v_contract_name ||
  					' to '		||
					v_impl_name	||
					' failed since certain operations are not implemented.');
       end if;

       insert into acs_sc_bindings (
	      contract_id,
	      impl_id
       ) values (
	      v_contract_id,
	      v_impl_id
       );

   end new;

   procedure del (
       contract_id	acs_sc_contracts.contract_id%TYPE default null,
       contract_name	acs_sc_contracts.contract_name%TYPE default null,
       impl_id		acs_sc_impls.impl_id%TYPE default null,
       impl_name	acs_sc_impls.impl_name%TYPE default null
   )
   is
       v_contract_id    acs_sc_contracts.contract_id%TYPE;
       v_impl_id	acs_sc_impls.impl_id%TYPE;
   begin

       if impl_id is not null and contract_id is not null
       then
	   v_impl_id := impl_id;
	   v_contract_id := contract_id;

       elsif impl_name is not null and contract_name is not null
       then
	   v_impl_id := acs_sc_impl.get_id(contract_name,impl_name);
	   v_contract_id := acs_sc_contract.get_id(contract_name);
       else
	  raise_application_error(-20001, 'Service contract binding delete invalid args');
       end if;

       delete from acs_sc_bindings
           where  contract_id = v_contract_id
	   and impl_id = v_impl_id;
   end del;

   function exists_p (
       contract_name        acs_sc_contracts.contract_name%TYPE,
       impl_name            acs_sc_impls.impl_name%TYPE
   ) return integer
   is
       v_exists_p       integer;
   begin
       select decode(count(*),0, 0, 1) into v_exists_p
       from acs_sc_bindings
       where contract_id = acs_sc_contract.get_id(contract_name)
       and impl_id = acs_sc_impl.get_id(contract_name,impl_name);
    
       return v_exists_p;
   end exists_p;

end acs_sc_binding;
/
show errors
