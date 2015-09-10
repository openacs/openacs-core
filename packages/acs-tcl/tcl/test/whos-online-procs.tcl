ad_library {
    Check whos-online procs
    
    @author Juan Pablo Amaya jpamaya@unicauca.edu.co
    @creation-date 2006-08-02
}

aa_register_case -cats {
    smoke production_safe web
} -libraries tclwebtest -procs {
    whos_online::num_users
    whos_online::set_invisible
    whos_online::all_invisible_user_ids
    whos_online::unset_invisible
    whos_online::user_ids
} whos_online__check_online_visibility {
    Check procs related with users online visibility
} {
    
    set user_id [db_nextval acs_object_id_seq]
    
    aa_run_with_teardown -test_code {
	
        #---------------------------------------------------------------------------------------------------
	#Test num_users
        #---------------------------------------------------------------------------------------------------
	
        set logged_users [whos_online::num_users]
        aa_log "Logged users: $logged_users"
	
        # Login user
        array set user_info [twt::user::create -admin -user_id $user_id]
        twt::user::login $user_info(email) $user_info(password)
	
	set logged_users [whos_online::num_users]
	aa_true "New user logged - Users logged: $logged_users" [expr { $logged_users  > 0 } ]
	
        #---------------------------------------------------------------------------------------------------
	#Test set_invisible
        #---------------------------------------------------------------------------------------------------
	
	aa_log "User $user_info(email) is visible"
	
	whos_online::set_invisible $user_id
	
	aa_true "User $user_info(email) is Invisible" [expr {[nsv_exists invisible_users $user_id] == 1 }]
	
        #---------------------------------------------------------------------------------------------------
        #Test all-invisible_user_ids
        #---------------------------------------------------------------------------------------------------

        aa_true "User $user_info(email) with user_id=$user_id is in the invisible list" \
	    [expr {$user_id in [whos_online::all_invisible_user_ids]}]
	
        #---------------------------------------------------------------------------------------------------
	#Test unset_invisible
        #---------------------------------------------------------------------------------------------------
	
	aa_log "User $user_info(email) is invisible"
	
	whos_online::unset_invisible $user_id
	
	aa_false "User $user_info(email) is Visible" \
	    [expr {[whos_online::user_invisible_p $user_id ] == 1 }]
	
        #---------------------------------------------------------------------------------------------------
        #Test user_ids
        #---------------------------------------------------------------------------------------------------
	
	aa_true "User $user_info(email) with user_id=$user_id is in the visible list" \
	    [expr {$user_id in [whos_online::user_ids]}]

	twt::user::logout
	twt::user::delete -user_id $user_id

    } -teardown_code {
	twt::user::delete -user_id $user_id
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
