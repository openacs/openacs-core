ad_library {
    
    Test Cases of Membership rel procs
    
    @author Cesar Hernandez (cesarhj@galileo.edu)
    @creation-date 2006-07-31
    @arch-tag: 92464550-0231-4D33-8885-595623B00DB6
    @cvs-id $Id$
}

aa_register_case -cats {api smoke} ad_proc_change_state_member  {

    Test the proc change_state

} {
    #we get a user_id as party_id
    set user_id [db_nextval acs_object_id_seq]
    aa_run_with_teardown -rollback -test_code {
	#Create the user
        array set user_info [twt::user::create -user_id $user_id]
	set rel_id [db_string get_rel_id "select max(rel_id) from acs_rels where object_id_two = :user_id" -default 0]

 	#Try to change his state to approved
	aa_log "We change the state to approved"
 	membership_rel::approve -rel_id $rel_id 
        acs_user::get -user_id $user_id -array user
	
 	#Verifying if the state was changed
 	aa_true "Changed State to aprroved" \
 	    [string equal $user(member_state) "approved"]


	#Try to change his state to banned
	aa_log "We change the state to banned"
	membership_rel::ban -rel_id $rel_id 
	acs_user::get -user_id $user_id -array user
	
        #Verifying if the state was changed 
	aa_true "Changed State to banned" \
	    [string equal $user(member_state) "banned"]


	#Try to change his state to rejected
	aa_log "We change the state to rejected"
	membership_rel::reject -rel_id $rel_id
	acs_user::get -user_id $user_id -array user
	
	#Verifying if the state was changed
	aa_true "Changed State to rejected" \
	    [string equal $user(member_state) "rejected"]


	#Try to change his state to unapproved
	aa_log "We change the state to unapproved"
	membership_rel::unapprove -rel_id $rel_id
	acs_user::get -user_id $user_id -array user

	#Verifying if the state was changed
	aa_true "Changed State to unapproved" \
	    [string equal $user(member_state) "needs approval"]

	#Try to change his state to deleted
	aa_log "We change the state to deleted"
        membership_rel::delete -rel_id $rel_id
        acs_user::get -user_id $user_id -array user

	#Verifying if the state was changed
	aa_true "Changed State to deleted" \
            [string equal $user(member_state) "deleted"]


    }
}