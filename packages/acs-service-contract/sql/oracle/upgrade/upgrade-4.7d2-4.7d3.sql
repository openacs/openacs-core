--
-- @author Simon Carstensen (simon@collaboraid.biz)
-- @creation_date 2003-09-10
--
-- $Id$

-- add column impl_pretty_name
alter table acs_sc_impls add impl_pretty_name varchar2(200);

update acs_sc_impls set impl_pretty_name = impl_name;

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

   procedure delete (
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
       v_impl_pretty_name       varchar(4000);
   begin
       v_impl_id := acs_object.new (object_type => 'acs_sc_implementation');

        if impl_pretty_name is null then
            v_impl_pretty_name := impl_name;
        else
            v_impl_pretty_name := impl_pretty_name;
        end if;

       insert into acs_sc_impls (
	      impl_id,
	      impl_name,
              impl_pretty_name,
	      impl_owner_name,
	      impl_contract_name
       ) values (
	      v_impl_id,
	      impl_name,
              v_impl_pretty_name,
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

   procedure delete (
       impl_contract_name	acs_sc_impls.impl_contract_name%TYPE,
       impl_name		acs_sc_impls.impl_name%TYPE
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

create or replace view valid_uninstalled_bindings as
    select c.contract_id, c.contract_name, i.impl_id, i.impl_name, i.impl_owner_name, i.impl_pretty_name
    from acs_sc_contracts c, acs_sc_impls i
    where c.contract_name = i.impl_contract_name
    and not exists (select 1
		    from acs_sc_bindings b
		    where b.contract_id = c.contract_id
		    and b.impl_id = i.impl_id)
    and not exists (select 1
		    from acs_sc_operations o
		    where o.contract_id = c.contract_id
		    and not exists (select 1
				    from acs_sc_impl_aliases a
				    where a.impl_contract_name = c.contract_name
				    and a.impl_id = i.impl_id
				    and a.impl_operation_name = o.operation_name));



create or replace view invalid_uninstalled_bindings as
    select c.contract_id, c.contract_name, i.impl_id, i.impl_name, i.impl_owner_name, i.impl_pretty_name
    from acs_sc_contracts c, acs_sc_impls i
    where c.contract_name = i.impl_contract_name
    and not exists (select 1
		    from acs_sc_bindings b
		    where b.contract_id = c.contract_id
		    and b.impl_id = i.impl_id)
    and exists (select 1
	        from acs_sc_operations o
		where o.contract_id = c.contract_id
		and not exists (select 1
			        from acs_sc_impl_aliases a
				where a.impl_contract_name = c.contract_name
				and a.impl_id = i.impl_id
				and a.impl_operation_name = o.operation_name));


create or replace view orphan_implementations as
    select i.impl_id, i.impl_name, i.impl_contract_name, i.impl_owner_name, i.impl_pretty_name
    from acs_sc_impls i
    where not exists (select 1
		      from acs_sc_bindings b
		      where b.impl_id = i.impl_id)
    and not exists (select 1
		    from acs_sc_contracts c
		    where c.contract_name = i.impl_contract_name);
