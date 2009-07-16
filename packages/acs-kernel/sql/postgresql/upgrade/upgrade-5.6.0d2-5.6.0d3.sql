create function inline_0 ()
returns integer as '
begin

 perform acs_attribute__create_attribute (
   ''acs_object'',
   ''modifying_user'',
   ''integer'',
   ''Modifying User'',
   null,
   null,
   null,
   null,
   1,
   1,
   null,
   ''type_specific'',
   ''f''
   );

  perform acs_attribute__create_attribute (
        ''user'',
        ''username'',
        ''string'',
        ''#acs-kernel.Username#'',
        ''#acs-kernel.Usernames#'',
        null,
        null,
        null,
	0,
	1,
        null,
        ''type_specific'',
        ''f''
      );

  perform acs_attribute__create_attribute (
        ''user'',
        ''screen_name'',
        ''string'',
        ''#acs-kernel.Screen_Name#'',
        ''#acs-kernel.Screen_Names#'',
        null,
        null,
        null,
	0,
	1,
        null,
        ''type_specific'',
        ''f''
      );

  return 0;

end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();
