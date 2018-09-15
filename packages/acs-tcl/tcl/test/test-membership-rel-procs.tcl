ad_library {
    
    Test Cases of Membership rel procs
    
    @author Cesar Hernandez (cesarhj@galileo.edu)
    @creation-date 2006-07-31
    @cvs-id $Id$
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        acs_user::get
        membership_rel::approve
        membership_rel::ban
        membership_rel::delete
        membership_rel::reject
        membership_rel::unapprove
        membership_rel::change_state
    } \
    ad_proc_change_state_member  {

    Test the proc change_state

} {
    aa_run_with_teardown -rollback -test_code {
        
        #we get a user_id as party_id
        set user_id [db_nextval acs_object_id_seq]

	#Create the user
        set user_info [acs::test::user::create -user_id $user_id]
	set rel_id [db_string get_rel_id "select max(rel_id) from acs_rels where object_id_two = :user_id" -default 0]

 	#Try to change his state to approved
	aa_log "We change the state to approved"
 	membership_rel::approve -rel_id $rel_id 
        acs_user::get -user_id $user_id -array user
	
 	#Verifying if the state was changed
 	aa_equals "Changed State to aprroved" \
 	    $user(member_state) "approved"


	#Try to change his state to banned
	aa_log "We change the state to banned"
	membership_rel::ban -rel_id $rel_id 
	acs_user::get -user_id $user_id -array user
	
        #Verifying if the state was changed 
	aa_equals "Changed State to banned" \
	    $user(member_state) "banned"


	#Try to change his state to rejected
	aa_log "We change the state to rejected"
	membership_rel::reject -rel_id $rel_id
	acs_user::get -user_id $user_id -array user
	
	#Verifying if the state was changed
	aa_equals "Changed State to rejected" \
	    $user(member_state) "rejected"


	#Try to change his state to unapproved
	aa_log "We change the state to unapproved"
	membership_rel::unapprove -rel_id $rel_id
	acs_user::get -user_id $user_id -array user

	#Verifying if the state was changed
	aa_equals "Changed State to unapproved"  \
	    $user(member_state) "needs approval"

	#Try to change his state to deleted
	aa_log "We change the state to deleted"
        membership_rel::delete -rel_id $rel_id
        acs_user::get -user_id $user_id -array user

	#Verifying if the state was changed
	aa_equals "Changed State to deleted" \
            $user(member_state) "deleted"
    }
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
