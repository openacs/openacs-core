ad_page_contract {
    Finishes updating someone's basic info

    @author Unknown
    @creation-date Unknown
    @cvs-id $Id$
} {
    first_names:trim
    last_name:trim
    email:trim
    {url:trim ""}
    {screen_name:trim ""}
    {bio ""}
    {return_url ""}
    {user_id ""}
}

set current_user_id [ad_verify_and_get_user_id]

if [empty_string_p $user_id] {
    set user_id $current_user_id
}

ad_require_permission $user_id "write"

set exception_text ""
set exception_count 0

if { ![info exists first_names] || [empty_string_p $first_names] } {
    append exception_text "<li>You need to type in a first name\n"
    incr exception_count
}


if { ![info exists last_name] || [empty_string_p $last_name] } {
    append exception_text "<li>You need to type in a last name\n"
    incr exception_count
}


if {[info exists first_names] && [string first "<" $first_names] != -1} {
    incr exception_count
    append exception_text "<li> You can't have a &lt; in your first
    name because it will look like an HTML tag and confuse other users."
}

if {[info exists last_name] && [string first "<" $last_name] != -1} {
    incr exception_count
    append exception_text "<li> You can't have a &lt; in your last
    name because it will look like an HTML tag and confuse other users."
}

if { ![info exists email] || ![util_email_valid_p $email] } {
    incr exception_count
    append exception_text "<li>The email address that you typed
    doesn't look right to us.  Examples of valid email addresses are
    <ul>
    <li>Alice1234@aol.com
    <li>joe_smith@hp.com
    <li>pierre@inria.fr
    </ul>"
}

if { [string equal $url "http://"] } {
    #its just the url hint ignore it.
    set url ""
}

if { ![empty_string_p $url] && ![util_url_valid_p $url] } {
    incr exception_count
    append exception_text "<li>Your URL doesn't really look like a URL."
}

if {![empty_string_p $screen_name]} {
    # screen name was specified.
    set sn_unique_p [db_string screen_name_unique_count "
    select count(*) from users where screen_name = :screen_name and user_id != :user_id"]
    if {$sn_unique_p != 0} {
	append exception_text "<li>The screen name you have selected is already taken.\n"
	incr exception_count
    }
}

if { [string length $bio] >= 4000 } {
    append exception_text "<li> Your biography is too long. Please limit it to 4000 characters"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    ad_script_abort
}

if { [db_string email_unique_count "select count(party_id) from parties where email = lower(:email) and party_id <> :user_id"] > 0 } {
    ad_return_error "$email already in database" "The email address
    \"$email\" is already in the database.  If this is your email address,
    perhaps you're trying to combine two accounts?  If so, please email <a
    href=\"mailto:[ad_system_owner]\">[ad_system_owner]</a> with your
    request."
    ad_script_abort
}

# bio_change_to = 0 -> insert
# bio_change_to = 1 -> don't change
# bio_change_to = 2 -> update
if ![db_0or1row grab_bio "select attr_value as bio_old
    from acs_attribute_values
    where object_id = :user_id
    and attribute_id =
      (select attribute_id
      from acs_attributes
      where object_type = 'person'
      and attribute_name = 'bio')"] {
    # There is no bio yet
    set bio_change_to [empty_string_p $bio]
} else {
    if [string equal $bio $bio_old] {
	set bio_change_to 1
    } else {
	set bio_change_to 2
    }
}

db_transaction {
    db_dml update_parties "update parties
      set email = :email,
      url = :url
      where party_id = :user_id"
    db_dml update_persons "update persons
      set first_names = :first_names,
      last_name = :last_name
      where person_id = :user_id"
    person::name_flush -person_id $user_id
    db_dml update_users "update users
      set screen_name=:screen_name
      where user_id = :user_id"
    if { $bio_change_to == 0 } {
	# perform the insert
	db_dml insert_bio "insert into acs_attribute_values
	(object_id, attribute_id, attr_value)
	values 
	(:user_id, (select attribute_id
          from acs_attributes
          where object_type = 'person'
          and attribute_name = 'bio'), :bio)"
    } elseif { $bio_change_to == 2 } {
	# perform the update
	db_dml update_bio "update acs_attribute_values
	set attr_value = :bio
	where object_id = :user_id
	and attribute_id =
          (select attribute_id
          from acs_attributes
          where object_type = 'person'
          and attribute_name = 'bio')"
    }
} on_error {
    ad_return_error "Ouch!"  "The database choked on our update:
    <blockquote>
    $errmsg
    </blockquote>
    hi richard $bio_change_to 
    "
    return

}

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "/pvt/home"
}


