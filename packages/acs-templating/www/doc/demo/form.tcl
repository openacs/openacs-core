form create add_user -elements {
  user_id -label "User ID" -datatype integer -widget hidden
  first_name -html { size 30 } -label "First Name" -datatype text
  last_name -html { size 30 } -label "Last Name"  -datatype text
  address1 -html { size 40 } -label "Address 1" -optional  -datatype text
  address2 -html { size 40 } -label "Address 2" -optional  -datatype text
  city -html { size 25 } -label "City" -optional  -datatype text
  state -html { size 3 maxlength 2 } \
    -label "State" -datatype keyword \
    -validate { {expr [string length $value] == 2 } \
              { State must be 2 characters in length } }
	} \
-html { onSubmit "return confirm('Are you sure you want to submit?');" }

# set values

if { [form is_request add_user] } {

  set query "select ad_template_sample_users_seq.nextval from dual"
  template::query get_user_id user_id onevalue $query

  element set_properties add_user user_id -value $user_id
}

if { [form is_valid add_user] } {

  
  db_dml insert_sample -bind [ns_getform] "
    insert into 
      ad_template_sample_users 
    values (
      :user_id, :first_name, :last_name, :address1, :address2, :city, :state
    )"

  template::forward index.html
}
