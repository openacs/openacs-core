-- template-demo-notes
-- drop script
-- Vinod Kurup, vkurup@massmed.org
--

-- neophytosd

--drop functions
drop function template_demo_note__new (integer,varchar,varchar,varchar,varchar,timestamptz,integer,varchar,integer);
drop function template_demo_note__del(integer);
drop function template_demo_note__name (integer);

--drop permissions
delete from acs_permissions where object_id in (select template_demo_note_id from template_demo_notes);

--drop objects


--
-- procedure inline_0/0
--
CREATE OR REPLACE FUNCTION inline_0(

) RETURNS integer AS $$
DECLARE
	object_rec		record;
BEGIN
	for object_rec in select object_id from acs_objects where object_type='template_demo_note'
	loop
		perform acs_object__delete( object_rec.object_id );
	end loop;

	return 0;
END;
$$ LANGUAGE plpgsql;

select inline_0();
drop function inline_0();

--drop table
drop table template_demo_notes;

--drop attributes
select acs_attribute__drop_attribute (
	   'template_demo_note',
	   'TITLE'
	);

select acs_attribute__drop_attribute (
	   'template_demo_note',
	   'BODY'
	);


--drop type
select acs_object_type__drop_type(
	   'template_demo_note',
	   't'
	);

