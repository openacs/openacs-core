request create -params {
  user_id -datatype integer -optional
}

if { ! [request is_valid] } { return }

# use a single variable to control what is displayed on the page:
# 1) user_edit    a user edit form
# 2) user_search  user search form
# 3) user_list    results of a user search

# instantiate the user search form.  It may not be displayed but creating it
# allows us to set error messages more easily.

form create user_search -elements {
    user_search -datatype text -html { size 40 } -label "Search Text" -validate {chars {regexp {^\w*$} $value} "invalid search string"}
    submit -datatype text -widget submit -label "Go"
}
set user_search [element get_value user_search user_search]

# the main logic depends on whether the request includes a user ID or not.
if { $user_id ne {} } {

  # the request included a user ID
  set display "user_edit"

} else {

  # handle a missing user ID
  
  if {$user_search eq {}} {

    # no user search string returned.  
    set display "user_search"

    if { [form is_submission user_search] } {

      # the user submitted a blank search form
      element set_error user_search user_search "
        Please specify search criteria."
    }

  } else {
    
    # query for users (obviously not a very scalable query)

    set user_search [string tolower $user_search]
    query get_users users multirow "
        select user_id, first_name, last_name 
        from ad_template_sample_users 
      where lower(first_name) like '%' || :user_search || '%' 
         or lower(last_name) like '%' || :user_search || '%'"
    set user_count [multirow size users]

    if { $user_count == 1 } {

      # if only one found, then set the user_id and proceed
      set user_id [multirow get users 1 user_id]
      set display "user_edit"

    } elseif { $user_count > 1 } {
      
      # multiple users found so display a list of choices
      set display "user_list"

    } else {
      
      # no results so search again
      set display "user_search"
      element set_error user_search user_search "
        No users were found matching your search criteria.<br>
        Please try again."
    }

    # end handling user search
  }

  # end handling an empty user_id query parameter
}

# return without instantiating the edit form if we don't know the user_id yet
if { $display ne "user_edit" } { 

  return 
}

form create user_edit -elements {
  user_id -datatype integer -widget hidden
  first_name -datatype text -widget text -html { size 25 maxlength 20 } \
    -label "First Name"
  last_name -datatype text -widget text -html { size 25 maxlength 20 } \
    -label "Last Name"
  address1 -datatype text -widget text -html { size 45 maxlength 40 } \
    -label "Address 1"
  address2 -datatype text -widget text -html { size 45 maxlength 40 } \
    -label "Address 2"
  city -datatype text -widget text -html { size 45 maxlength 40 } \
    -label "City"
  state -datatype text -widget text -html { size 4 maxlength 2 } \
    -label "State"
}

if { [form is_request user_edit] } {

  if { ! [query get_info info onerow "
              select user_id, first_name, last_name, address1, address2, city, state
              from ad_template_sample_users
              where user_id = :user_id"] } {
    request error invalid_user_id "Invalid User ID"
  }
  
  form set_values user_edit info
}

if { [form is_valid user_edit] } {

  form get_values user_edit first_name last_name address1 address2 city state

  db_dml update_sample_users "update ad_template_sample_users 
    set first_name = :first_name, last_name = :last_name, 
        address1 = :address1, address2 = :address2, city = :city, 
        state = :state
    where user_id = :user_id"

  template::forward multiple
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
