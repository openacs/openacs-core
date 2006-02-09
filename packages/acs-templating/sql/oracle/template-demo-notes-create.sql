--
-- packages/notes/sql/notes-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-10-22
-- @cvs-id $Id$
--

begin
  acs_object_type.create_type (
    supertype => 'acs_object',
    object_type => 'template_demo_note',
    pretty_name => 'Template Demo Note',
    pretty_plural => 'Template Demo Notes',
    table_name => 'template_demo_notes',
    id_column => 'template_demo_note_id',
	name_method => 'template_demo_note.name'
  );
end;
/
show errors;

declare
  attr_id acs_attributes.attribute_id%TYPE;
begin
  attr_id := acs_attribute.create_attribute (
    object_type => 'template_demo_note',
    attribute_name => 'title',
    pretty_name => 'Title',
    pretty_plural => 'Titles',
    datatype => 'string'
  );

  attr_id := acs_attribute.create_attribute (
    object_type => 'template_demo_note',
    attribute_name => 'body',
    pretty_name => 'Body',
    pretty_plural => 'Bodies',
    datatype => 'string'
  );

  attr_id := acs_attribute.create_attribute (
    object_type => 'template_demo_note',
    attribute_name => 'color',
    pretty_name => 'Color',
    pretty_plural => 'Colors',
    datatype => 'string'
  );
end;
/
show errors;

create table template_demo_notes (
    template_demo_note_id    integer 
                             references acs_objects(object_id) 
                             primary key,
    title                    varchar(255) 
                             not null,
    body                     varchar(4000),
    color                    varchar(100)
);

create or replace package template_demo_note
as
    function new (
        template_demo_note_id  in template_demo_notes.template_demo_note_id%TYPE default null,
	title                  in template_demo_notes.title%TYPE,
	body                   in template_demo_notes.body%TYPE,
        color                  in template_demo_notes.color%TYPE,

	object_type         in acs_object_types.object_type%TYPE
			       default 'template_demo_note',
	creation_date       in acs_objects.creation_date%TYPE
                               default sysdate,
        creation_user       in acs_objects.creation_user%TYPE
                               default null,
        creation_ip         in acs_objects.creation_ip%TYPE default null,
        context_id          in acs_objects.context_id%TYPE default null
    ) return template_demo_notes.template_demo_note_id%TYPE;

    procedure del (
         template_demo_note_id      in template_demo_notes.template_demo_note_id%TYPE
    );

	function name (
		template_demo_note_id	   in template_demo_notes.template_demo_note_id%TYPE
	) return template_demo_notes.title%TYPE;
end template_demo_note;
/
show errors

create or replace package body template_demo_note
as
    function new (
        template_demo_note_id             in template_demo_notes.template_demo_note_id%TYPE default null,
        title               in template_demo_notes.title%TYPE,
        body                in template_demo_notes.body%TYPE,
        color                  in template_demo_notes.color%TYPE,

        object_type         in acs_object_types.object_type%TYPE
			       default 'template_demo_note',
        creation_date       in acs_objects.creation_date%TYPE
                                default sysdate,
        creation_user       in acs_objects.creation_user%TYPE
                                default null,
        creation_ip         in acs_objects.creation_ip%TYPE default null,
        context_id          in acs_objects.context_id%TYPE default null
    ) return template_demo_notes.template_demo_note_id%TYPE
    is
        v_template_demo_note_id integer;
     begin
        v_template_demo_note_id := acs_object.new (
            object_id => template_demo_note_id,
            object_type => object_type,
            creation_date => creation_date,
            creation_user => creation_user,
            creation_ip => creation_ip,
            context_id => context_id
         );

         insert into template_demo_notes
          (template_demo_note_id, title, body, color)
         values
          (v_template_demo_note_id, title, body, color);

         acs_permission.grant_permission(
           object_id => v_template_demo_note_id,
           grantee_id => creation_user,
           privilege => 'admin'
         );

         return v_template_demo_note_id;
     end new;

     procedure del (
         template_demo_note_id      in template_demo_notes.template_demo_note_id%TYPE
     )
     is
     begin
		 delete from acs_permissions
		 where object_id = template_demo_note.del.template_demo_note_id;
         
         delete from template_demo_notes
         where template_demo_note_id = template_demo_note.del.template_demo_note_id;

         acs_object.del(template_demo_note_id);
     end del;

	 function name (
		template_demo_note_id	in template_demo_notes.template_demo_note_id%TYPE
	 ) return template_demo_notes.title%TYPE
	 is
		v_template_demo_note_name		template_demo_notes.title%TYPE;
	 begin
		select title into v_template_demo_note_name
			from template_demo_notes
			where template_demo_note_id = name.template_demo_note_id;

		return v_template_demo_note_name;
	 end name;
end template_demo_note;
/
show errors;
