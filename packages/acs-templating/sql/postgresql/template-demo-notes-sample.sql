create function template__make_sample_data() returns integer
as
'
declare
    security_context_root integer;
    a_sitewide_admin integer;
    acs_templating_package_id int4;
begin
    -- try to find a sitewide admin by finding a user 
    -- with admin perm on the security context root object

    security_context_root := acs__magic_object_id(''security_context_root'');

    select 
        p.grantee_id into a_sitewide_admin
    from
        acs_permissions p
    where
        p.object_id = security_context_root
      and
        p.privilege = ''admin''
    limit 1;

    -- now, we want the object id of the acs templating package instance

    select
        p.package_id into acs_templating_package_id
    from
	apm_packages p
    where
        p.package_key = ''acs-templating'';

    perform template_demo_note__new
	(
		NULL,
		''title01'',
		''body01'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title02'',
		''body02'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title03'',
		''body03'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title04'',
		''body04'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title05'',
		''body05'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title06'',
		''body06'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title07'',
		''body07'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title08'',
		''body08'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title09'',
		''body09'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title10'',
		''body10'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title11'',
		''body11'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title12'',
		''body12'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title13'',
		''body13'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title14'',
		''body14'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title15'',
		''body15'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title16'',
		''body16'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title17'',
		''body17'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title18'',
		''body18'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title1'',
		''body1'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title19'',
		''body19'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    perform template_demo_note__new
	(
		NULL,
		''title20'',
		''body20'',
		''template_demo_note'',

		now(),
		a_sitewide_admin,
		NULL,
		acs_templating_package_id
	);

    return a_sitewide_admin;
end;
'
language 'plpgsql';

-- select template__make_sample_data();

drop function template__make_sample_data();

