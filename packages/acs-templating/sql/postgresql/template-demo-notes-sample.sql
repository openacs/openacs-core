

CREATE function template__make_sample_data(
) 
RETURNS integer AS $$
DECLARE
    security_context_root int4;
    default_context int4;
    registered_users int4;
    unregistered_visitor int4;
    owning_party int4;
    context int4;
BEGIN
    security_context_root := acs__magic_object_id('security_context_root');
    default_context       := acs__magic_object_id('default_context');
    registered_users      := acs__magic_object_id('registered_users');
    unregistered_visitor  := acs__magic_object_id('unregistered_visitor');

    context := default_context;
    owning_party := unregistered_visitor;

    perform template_demo_note__new
	(
		NULL,
		'title01',
		'body01',
		'red',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title02',
		'body02',
		'blue',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title03',
		'body03',
		'green',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title04',
		'body04',
		'orange',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title05',
		'body05',
		'purple',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title06',
		'body06',
		'red',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title07',
		'body07',
		'blue',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title08',
		'body08',
		'green',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title09',
		'body09',
		'orange',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title10',
		'body10',
		'purple',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title11',
		'body11',
		'red',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title12',
		'body12',
		'blue',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title13',
		'body13',
		'green',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title14',
		'body14',
		'orange',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title15',
		'body15',
		'purple',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title16',
		'body16',
		'red',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title17',
		'body17',
		'blue',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title18',
		'body18',
		'green',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title19',
		'body19',
		'orange',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    perform template_demo_note__new
	(
		NULL,
		'title20',
		'body20',
		'purple',

		'template_demo_note',
		now(),
		owning_party,
		NULL,
		context
	);

    return context;
END;

$$ LANGUAGE plpgsql;

select template__make_sample_data();

drop function template__make_sample_data();

