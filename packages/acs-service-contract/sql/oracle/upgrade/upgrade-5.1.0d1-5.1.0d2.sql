update acs_objects
set title = (select msg_type_name
             from acs_sc_msg_types
             where msg_type_id = object_id)
where object_type = 'acs_sc_msg_type';

update acs_objects
set title = (select contract_name
             from acs_sc_contracts
             where contract_id = object_id)
where object_type = 'acs_sc_contract';

update acs_objects
set title = (select operation_name
             from acs_sc_operations
             where operation_id = object_id)
where object_type = 'acs_sc_operation';

update acs_objects
set title = (select impl_pretty_name
             from acs_sc_impls
             where impl_id = object_id)
where object_type = 'acs_sc_implementation';

commit;


create or replace package body acs_sc_msg_type
as

     function new (
        msg_type_name	in acs_sc_msg_types.msg_type_name%TYPE,
	msg_type_spec	in varchar2
     ) return acs_sc_msg_types.msg_type_id%TYPE
     is
	v_msg_type_id   integer;
	v_spec_parse_level integer;
     begin
        v_msg_type_id := acs_object.new(
		      object_type => 'acs_sc_msg_type',
		      title => msg_type_name
		      );		    

        insert into acs_sc_msg_types (
	       msg_type_id,
	       msg_type_name
	       ) values (
	       v_msg_type_id,
	       msg_type_name
	       );

	v_spec_parse_level := acs_sc_msg_type.parse_spec(
			      msg_type_name,
			      msg_type_spec);

	return v_msg_type_id;

     end new;

     procedure del (
         msg_type_id	 in acs_sc_msg_types.msg_type_id%TYPE default null,
	 msg_type_name	 in acs_sc_msg_types.msg_type_name%TYPE default null
     )
     is 
        v_msg_type_id	acs_sc_msg_types.msg_type_id%TYPE;
     begin

	if msg_type_name is not NULL
	then
	   v_msg_type_id := acs_sc_msg_type.get_id(msg_type_name);

	elsif msg_type_id is not NULL
	then
	   v_msg_type_id := msg_type_id;
	
	else
	   raise_application_error(-20000, 'no args supplied to sc_msg_type.delete');

	end if;

	delete from acs_sc_msg_types 
	       where msg_type_id = v_msg_type_id;

     end del;

    function get_id (
        msg_type_name in acs_sc_msg_types.msg_type_name%TYPE
    ) return acs_sc_msg_types.msg_type_id%TYPE

    is 
       v_msg_type_id	acs_sc_msg_types.msg_type_id%TYPE;
    begin

	select msg_type_id into v_msg_type_id
	from acs_sc_msg_types 
	where msg_type_name = get_id.msg_type_name;

	return v_msg_type_id;

    end get_id;


    function get_name (
	msg_type_id   in acs_sc_msg_types.msg_type_id%TYPE
    ) return acs_sc_msg_types.msg_type_name%TYPE
    is	     
       v_msg_type_name	acs_sc_msg_types.msg_type_name%TYPE;
    begin
    
	select msg_type_name into v_msg_type_name
	from acs_sc_msg_types
	where msg_type_id = get_name.msg_type_id;

	return v_msg_type_name;
    end get_name;



    -- string processing in pl/sql is so much fun
    -- i'm sure there is a better way to go about this
    function parse_spec (
	msg_type_name in acs_sc_msg_types.msg_type_name%TYPE,
	msg_type_spec in varchar2
    ) return integer
    is
	v_element_pos	   integer;
	v_str_s_idx        integer; -- spec str pointers
	v_str_e_idx	   integer; 
	v_elem_idx	   integer; -- element str pointer
	v_str_len	   integer;
	v_element          varchar(200);
	v_element_type	   varchar(200);
	v_element_name	   varchar(200);
	v_element_msg_type_name     varchar(200);
	v_element_msg_type_isset_p  char(1);
	v_junk_msg_type_id integer; 
    begin

	-- oracle treats empty strings as nulls
	if msg_type_spec is null
	then		 
	   return 0;
	end if;
		

	v_element_pos := 1;
	v_str_e_idx := 1;

	while TRUE
	loop
	    -- string start check
	    if v_element_pos = 1
	    then
		v_str_s_idx := 1;
	    else	    
		v_str_s_idx := instr(msg_type_spec, ',', v_str_e_idx);	    
		
		if v_str_s_idx > 0 then
		   v_str_s_idx := v_str_s_idx + 1;
		end if;

	    end if;

	    v_str_e_idx := instr(msg_type_spec, ',', v_str_s_idx+1)-1;	

	    -- end of string check
	    if v_str_s_idx > 0 and v_str_e_idx <= 0
	    then
		v_str_e_idx := length(msg_type_spec);
	    end if;

	    -- dbms_output.put_line(v_str_s_idx || ' '|| v_str_e_idx || ' ' || v_element_pos);
	    -- dbms_output.new_line();

	    if v_str_s_idx > 0 
	    then

		v_element := substr(msg_type_spec, 
			            v_str_s_idx,
				    v_str_e_idx+1 - v_str_s_idx);

		v_elem_idx := instr(v_element, ':');

		if v_elem_idx > 0 
 		then
		    v_element_name := trim( substr(v_element, 1, v_elem_idx-1));
		    v_element_type := trim( substr(v_element, v_elem_idx+1));
		    
		    if (instr(v_element_type, '[',1,1) = length(v_element_type)-1) and
		       (instr(v_element_type, ']',1,1) = length(v_element_type))
		    then
			v_element_msg_type_isset_p := 't';
			v_element_msg_type_name := trim(substr(
							v_element_type,
							1,
							length(v_element_type)-2));

			if v_element_msg_type_name = '' 
			then
			    raise_application_error (-20001, 
						    'Wrong Format: Message Type Specification');
		        end if;
		    else
			v_element_msg_type_isset_p := 'f';
			v_element_msg_type_name := v_element_type;

		    end if;

		    v_junk_msg_type_id := acs_sc_msg_type.new_element (
			     msg_type_name =>parse_spec.msg_type_name,
			     element_name  => v_element_name,
			     element_msg_type_name    => v_element_msg_type_name,
			     element_msg_type_isset_p => v_element_msg_type_isset_p,
			     element_pos   => v_element_pos
			     );

		else
		    raise_application_error(-20001,'Wrong Format: Message Type Specification');
		end if;
	    else 
		 -- yippee we're done
		 exit;
	    end if;
	    
	    v_element_pos := v_element_pos + 1;
		
	end loop;
		
	return v_element_pos - 1;
    end parse_spec;

    function new_element (
	msg_type_name	 in acs_sc_msg_types.msg_type_name%TYPE,
	element_name	 in acs_sc_msg_type_elements.element_name%TYPE,
	element_msg_type_name		in acs_sc_msg_types.msg_type_name%TYPE,
	element_msg_type_isset_p	in acs_sc_msg_type_elements.element_msg_type_isset_p%TYPE,
	element_pos			in acs_sc_msg_type_elements.element_pos%TYPE
     ) return acs_sc_msg_types.msg_type_id%TYPE
     is
	v_msg_type_id		integer;
	v_element_msg_type_id	integer;
     begin
	
	v_msg_type_id := acs_sc_msg_type.get_id(msg_type_name);
	
	if v_msg_type_id is null 
	then
	    raise_application_error (-20001, 'Unknown Message Type: ' || msg_type_name);	
	end if;

	v_element_msg_type_id := acs_sc_msg_type.get_id(element_msg_type_name);

	if v_element_msg_type_id is null 
	then
	    raise_application_error (-20001, 'Unknown Message Type: ' || element_msg_type_name);	
	end if;	

	insert into acs_sc_msg_type_elements (
	       msg_type_id,
	       element_name,
	       element_msg_type_id,
	       element_msg_type_isset_p,
	       element_pos
	) values (
	       v_msg_type_id,
	       element_name,	 	
	       v_element_msg_type_id,
	       element_msg_type_isset_p,
	       element_pos
	);
	       
	return v_msg_type_id;

     end new_element;
     
end acs_sc_msg_type;
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
