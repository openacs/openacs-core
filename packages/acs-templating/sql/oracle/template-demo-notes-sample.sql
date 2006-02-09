declare
    security_context_root acs_objects.object_id%TYPE;
    default_context       acs_objects.object_id%TYPE;
    registered_users      acs_objects.object_id%TYPE;
    unregistered_visitor  acs_objects.object_id%TYPE;
    owning_party          acs_objects.object_id%TYPE;
    context               acs_objects.object_id%TYPE;
    dummy_var             acs_objects.object_id%TYPE;
begin
    security_context_root := acs.magic_object_id('security_context_root');
    default_context       := acs.magic_object_id('default_context');
    registered_users      := acs.magic_object_id('registered_users');
    unregistered_visitor  := acs.magic_object_id('unregistered_visitor');

    context := default_context;
    owning_party := unregistered_visitor;

    dummy_var := template_demo_note.new
	(
		NULL,
		'title01',
		'body01',
		'red',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title02',
		'body02',
		'blue',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title03',
		'body03',
		'green',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title04',
		'body04',
		'orange',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title05',
		'body05',
		'purple',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title06',
		'body06',
		'red',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title07',
		'body07',
		'blue',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title08',
		'body08',
		'green',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title09',
		'body09',
		'orange',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title10',
		'body10',
		'purple',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title11',
		'body11',
		'red',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title12',
		'body12',
		'blue',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title13',
		'body13',
		'green',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title14',
		'body14',
		'orange',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title15',
		'body15',
		'purple',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title16',
		'body16',
		'red',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title17',
		'body17',
		'blue',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title18',
		'body18',
		'green',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title19',
		'body19',
		'orange',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

    dummy_var := template_demo_note.new
	(
		NULL,
		'title20',
		'body20',
		'purple',

		'template_demo_note',
		sysdate,
		owning_party,
		NULL,
		context
	);

--    return context;
end;
/
show errors;

