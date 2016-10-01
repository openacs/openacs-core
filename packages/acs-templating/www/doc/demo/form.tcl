ad_page_contract {
    Demo page
} {
    {user_id:integer,notnull ""}
    {state:word ""}
}

form create add_user -elements {
    user_id -label "User ID" -datatype integer -widget hidden 
    first_name -html { size 30 } -label "First Name" -datatype text
    last_name -html { size 30 } -label "Last Name"  -datatype text
    address1 -html { size 40 } -label "Address 1" -optional  -datatype text
    address2 -html { size 40 } -label "Address 2" -optional  -datatype text
    city -html { size 25 } -label "City" -optional  -datatype text
    state -html { size 3 maxlength 2 } \
	-label "State" -datatype keyword \
	-validate { \
           valid_length {expr {[string length $value] == 2} } { State must be 2 characters in length } \
           valid_range  {expr {$value in {CA HI NV}}}         { Invalid state } \
        }
}

template::add_confirm_handler -event submit -id add_user -message "Are you sure you want to submit?"

# set values

if { [form is_request add_user] } {
    #
    # get a fresh user_id
    #
    set user_id [db_string get_user_id ""]

    element set_properties add_user user_id -value $user_id
}

if { [form is_valid add_user] } {
    
    if {[db_0or1row user_exists {
        select 1 from ad_template_sample_users where user_id = :user_id
    }]} {
        ad_complain 1 "duplicate user_id; looks like somebody tried to hack the form"
        ad_script_abort
    }
    db_dml insert_sample {
        insert into  ad_template_sample_users 
        values ( :user_id, :first_name, :last_name, :address1, :address2, :city, :state)
    } -bind [ns_getform]

    template::forward index.html
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
