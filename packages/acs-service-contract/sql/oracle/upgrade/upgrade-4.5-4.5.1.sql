-- packages/acs-service-contract/sql/oracle/upgrade/upgrade-4.5-4.5.1.sql
--
-- @author Vinod Kurup (vinod@kurup.com)
-- @creation_date 2002-08-14
--
-- $Id$

-- UPGRADE ISSUE 1
-- PG version has 2 packages acs_sc_impl and acs_sc_impl_alias
-- For consistency, we're making it the same in Oracle
-- Oracle function acs_sc_impl.new_alias -> acs_sc_impl_alias.new
--                 acs_sc_impl.delete_alias -> acs_sc_impl_alias.delete
-- Old functions deprecated, but still work.

create or replace package acs_sc_impl_alias
as
   function new (
       impl_contract_name	acs_sc_contracts.contract_name%TYPE,
       impl_name			acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE,
       impl_alias			acs_sc_impl_aliases.impl_alias%TYPE,
       impl_pl				acs_sc_impl_aliases.impl_pl%TYPE
   ) return acs_sc_impl_aliases.impl_id%TYPE;

   function delete (
       impl_contract_name	acs_sc_contracts.contract_name%TYPE,
       impl_name			acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE;

end acs_sc_impl_alias;
/
show error

-- now the new package bodies

create or replace package body acs_sc_impl
as

   function new (
       impl_contract_name	acs_sc_impls.impl_contract_name%TYPE,
       impl_name			acs_sc_impls.impl_name%TYPE,
       impl_owner_name		acs_sc_impls.impl_owner_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE
   is
       v_impl_id			acs_sc_impls.impl_id%TYPE;
   begin
       v_impl_id := acs_object.new (object_type => 'acs_sc_implementation');

       insert into acs_sc_impls (
	      impl_id,
	      impl_name,	
	      impl_owner_name,
	      impl_contract_name
       ) values (
	      v_impl_id,
	      impl_name,
	      impl_owner_name,
	      impl_contract_name
       );

       return v_impl_id;
   end new;

   function get_id (
       impl_contract_name	acs_sc_impls.impl_contract_name%TYPE,
       impl_name			acs_sc_impls.impl_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE
   as
       v_impl_id			acs_sc_impls.impl_id%TYPE;
   begin

       select impl_id into v_impl_id
       from acs_sc_impls
       where impl_name = get_id.impl_name
       and impl_contract_name = get_id.impl_contract_name;

       return v_impl_id;

   end get_id;


   function get_name (
       impl_id				acs_sc_impls.impl_id%TYPE
   ) return acs_sc_impls.impl_name%TYPE
   as
       v_impl_name			acs_sc_impls.impl_name%TYPE;
   begin

       select impl_name into v_impl_name
       from acs_sc_impls
       where impl_id = get_name.impl_id;

       return v_impl_name;

   end get_name;

   procedure delete (
       impl_contract_name	acs_sc_impls.impl_contract_name%TYPE,
       impl_name			acs_sc_impls.impl_name%TYPE
   )
   as
   begin
       delete from acs_sc_impls
       where impl_contract_name = acs_sc_impl.delete.impl_contract_name
       and impl_name = acs_sc_impl.delete.impl_name;   	
   end delete;


   /* next 2 functions are deprecated. */

  function new_alias (
       impl_contract_name	acs_sc_contracts.contract_name%TYPE,
       impl_name			acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE,
       impl_alias			acs_sc_impl_aliases.impl_alias%TYPE,
       impl_pl				acs_sc_impl_aliases.impl_pl%TYPE
   ) return acs_sc_impl_aliases.impl_id%TYPE
   is
       v_impl_id			acs_sc_impls.impl_id%TYPE;
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
       impl_name			acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE
   is
       v_impl_id			acs_sc_impls.impl_id%TYPE;
   begin
	-- FUNCTION DEPRECATED. USE acs_sc_impl_alias.delete
	dbms_output.put_line('acs_sc_impl.delete_alias DEPRECATED. Use acs_sc_impl_alias.delete');

	v_impl_id := acs_sc_impl_alias.delete(
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

   function delete (
       impl_contract_name	acs_sc_contracts.contract_name%TYPE,
       impl_name			acs_sc_impls.impl_name%TYPE,
       impl_operation_name	acs_sc_operations.operation_name%TYPE
   ) return acs_sc_impls.impl_id%TYPE
   is
       v_impl_id		acs_sc_impls.impl_id%TYPE;
   begin
       v_impl_id := acs_sc_impl.get_id(impl_contract_name,impl_name);

       delete from acs_sc_impl_aliases
       where impl_contract_name = acs_sc_impl_alias.delete.impl_contract_name
       and impl_name = acs_sc_impl_alias.delete.impl_name
       and impl_operation_name = acs_sc_impl_alias.delete.impl_operation_name;

       return v_impl_id;

   end delete;

end acs_sc_impl_alias;
/
show errors

-- UPGRADE ISSUE 2
-- acs_sc_binding.exists_p was broken on Oracle if you
-- tested a binding for which the implementation was installed, but the
-- contract wasn't.

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
					' failed.');
       end if;

       insert into acs_sc_bindings (
	      contract_id,
	      impl_id
       ) values (
	      v_contract_id,
	      v_impl_id
       );

   end new;

   procedure delete(
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
   end delete;

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

