ad_library {

    Community routines (dealing with users, parties, etc.).

    @author Jon Salz (jsalz@arsdigita.com)
    @date 11 Aug 2000
    @cvs-id $Id$

}

ad_proc -private cc_lookup_screen_name_user { screen_name } {
    return [db_string user_select {
	select user_id from cc_users where upper(screen_name) = upper(:screen_name)
    } -default ""]
}

ad_proc cc_screen_name_user { screen_name } {

    Returns the user ID for a particular screen name, or an empty string
    if none exists.

} {
    return [util_memoize [list cc_lookup_screen_name_user $screen_name]]
}

ad_proc -private cc_lookup_email_user { email } {
    return [db_string user_select {
	select user_id from cc_users where upper(email) = upper(:email)
    } -default ""]
}

ad_proc -public cc_email_from_party { party_id } {
    @return The email address of the indicated party.
} {
    return [db_string email_from_party {
	select email from parties where party_id = :party_id
    } -default 0]
}

ad_proc cc_email_user { email } {

    Returns the user ID for a particular email address, or an empty string
    if none exists.

} {
    return [util_memoize [list cc_lookup_email_user $email]]
}

ad_proc -private cc_lookup_name_group { name } {
    return [db_string group_select {
	select group_id from groups where group_name = :name
    } -default ""]
}

ad_proc cc_name_to_group { name } {

    Returns the group ID for a particular name, or an empty string
    if none exists.

} {
    return [util_memoize [list cc_lookup_name_group $name]]
}

ad_proc ad_user_new {email first_names last_name password password_question password_answer  {url ""} {email_verified_p "t"} {member_state "approved"} {user_id ""} } {
    
    Creates a new user in the system.  The user_id can be specified as an argument to enable double click protection.
    If this procedure succeeds, returns the new user_id.  Otherwise, returns 0.
} {
    if { [empty_string_p $user_id] } {
	set user_id [db_nextval acs_object_id_seq]
    }

    if { [empty_string_p $password_question] } {
	set password_question [db_null]
    }

    if { [empty_string_p $password_answer] } {
	set password_answer [db_null]
    }

    if { [empty_string_p url] } {
	set url [db_null]
    }
    
    set peeraddr [ad_conn peeraddr]
    set salt [sec_random_token]
    set hashed_password [ns_sha1 "$password$salt"]
    
    db_transaction {

	db_exec_plsql user_insert {
	begin
	    :1 := acs.add_user(user_id => :user_id,
			 email => :email,
			 url => :url,
			 first_names => :first_names,
			 last_name => :last_name,
			 password => :hashed_password,
	                 salt => :salt,
	                 password_question => :password_question,
	                 password_answer => :password_answer,
	                 creation_ip => :peeraddr,
	                 email_verified_p => :email_verified_p,
	                 member_state => :member_state);
	    end;
	} 

    } on_error {
	# we got an error.  log it and signal failure.
	ns_log Error "Problem creating a new user: $errmsg"
	return 0
    }
    # success.
    return $user_id
}

