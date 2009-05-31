
declare
  attr_id integer;
begin

 attr_id := acs_attribute.create_attribute (
        object_type => 'user',
        attribute_name => 'bio',
        datatype => 'string',
        pretty_name => '#acs-kernel.Bio#',
        pretty_plural => '#acs-kernel.Bios#',
	min_n_values => 0,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'user',
        attribute_name => 'username',
        datatype => 'string',
        pretty_name => '#acs-kernel.Username#',
        pretty_plural => '#acs-kernel.Usernames#',
	min_n_values => 0,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'user',
        attribute_name => 'screen_name',
        datatype => 'string',
        pretty_name => '#acs-kernel.Screen_Name#',
        pretty_plural => '#acs-kernel.Screen_Names#',
	min_n_values => 0,
	max_n_values => 1
      );

end;
/
show errors;
