-- $Id$

begin

   acs_object_type.create_type (
        supertype => 'acs_object',
        object_type => 'acs_sc_msg_type',
	pretty_name => 'ACS SC Message Type',
        pretty_plural => 'ACS SC Message Types',
        table_name => 'acs_sc_msg_types',
        id_column => 'msg_type_id'
    );

end;
/
show errors

create table acs_sc_msg_types (
    msg_type_id		     integer
			     constraint acs_sc_msg_type_id_fk
			     references acs_objects(object_id)
			     on delete cascade
			     constraint acs_sc_msg_type_pk
			     primary key,
    msg_type_name	     varchar2(100)
			     constraint acs_sc_msg_type_name_un
			     unique
);


create table acs_sc_msg_type_elements (
    msg_type_id		     integer
			     constraint acs_sc_msg_type_el_mtype_id_fk
			     references acs_sc_msg_types(msg_type_id)
			     on delete cascade,
    element_name	     varchar2(100),
    element_msg_type_id	     integer
			     constraint acs_sc_msg_type_el_emti_id_fk
			     references acs_sc_msg_types(msg_type_id),
    element_msg_type_isset_p char(1) constraint acs_msg_type_el_set_p_ck
			     check (element_msg_type_isset_p in ('t', 'f')),
    element_pos		     integer
);

create or replace package acs_sc_msg_type
as

    function new (
        msg_type_name	 in acs_sc_msg_types.msg_type_name%TYPE,
	msg_type_spec	 in varchar2
     ) return acs_sc_msg_types.msg_type_id%TYPE;

    procedure del (
        msg_type_id	 in acs_sc_msg_types.msg_type_id%TYPE default null,
	msg_type_name	 in acs_sc_msg_types.msg_type_name%TYPE default null
    );

    function get_id (
        msg_type_name	 in acs_sc_msg_types.msg_type_name%TYPE
    ) return acs_sc_msg_types.msg_type_id%TYPE;


    function get_name (
	msg_type_id	 in acs_sc_msg_types.msg_type_id%TYPE
    ) return acs_sc_msg_types.msg_type_name%TYPE;

    -- ask nd about name
    function parse_spec (
	msg_type_name	 in acs_sc_msg_types.msg_type_name%TYPE,
	msg_type_spec	 in varchar2
    ) return integer;

    function new_element (
	msg_type_name	 in acs_sc_msg_types.msg_type_name%TYPE,
	element_name	 in acs_sc_msg_type_elements.element_name%TYPE,
	element_msg_type_name		in acs_sc_msg_types.msg_type_name%TYPE,
	element_msg_type_isset_p	in acs_sc_msg_type_elements.element_msg_type_isset_p%TYPE,
	element_pos			in acs_sc_msg_type_elements.element_pos%TYPE
     ) return acs_sc_msg_types.msg_type_id%TYPE;

end acs_sc_msg_type;
/
show errors


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


--
-- Primitive Message Types
--
declare
    v_msg_type_id	acs_sc_msg_types.msg_type_id%TYPE;
begin
    v_msg_type_id := acs_sc_msg_type.new('integer','');
    v_msg_type_id := acs_sc_msg_type.new('string','');
    v_msg_type_id := acs_sc_msg_type.new('boolean','');
    v_msg_type_id := acs_sc_msg_type.new('timestamp','');
    v_msg_type_id := acs_sc_msg_type.new('uri','');
    v_msg_type_id := acs_sc_msg_type.new('version','');
    v_msg_type_id := acs_sc_msg_type.new('float','');
    v_msg_type_id := acs_sc_msg_type.new('bytearray','');
end;
/
show errors

