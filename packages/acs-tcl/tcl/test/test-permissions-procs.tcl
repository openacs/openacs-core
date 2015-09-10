# 

ad_library {
    
    Test for Permission Procedures
    
    @author Cesar Hernandez (cesarhj@galileo.edu)
    @creation-date 2006-07-14
    @arch-tag: 0823E65B-D0B0-417A-AB6F-CA86E0461A8E
    @cvs-id $Id$
}

aa_register_case -cats {api smoke} ad_proc_permission_grant_and_revoke {

    Test for Permission Procedures of grant and revoke.

} {
    #we get an user_id as party_id.
    set user_id [db_nextval acs_object_id_seq]
    aa_run_with_teardown -rollback -test_code {
	#Create the user
	array set user_info [twt::user::create -user_id $user_id]
	#Create and mount new subsite to test the permissions on this instance
	set site_name [ad_generate_random_string]
	set new_package_id [site_node::instantiate_and_mount \
				-node_name $site_name \
				-package_key acs-subsite]
	#Grant privileges of admin,read,write and create, after check
	#this ones, after revoke this ones.
	
	#Grant admin privilege
 	permission::grant -party_id $user_id -object_id $new_package_id -privilege "admin"  
 	#Verifying the admin privilege on the user
        aa_true "testing admin privilige" \
 	    [expr {[permission::permission_p -party_id $user_id -object_id $new_package_id -privilege "admin"] == 1}]
 	#Revoking admin privilege
 	permission::revoke -party_id $user_id -object_id $new_package_id -privilege "admin"
 	aa_true "testing if admin privilige was revoked" \
 	    [expr {[permission::permission_p -party_id $user_id -object_id $new_package_id -privilege "admin"] == 0}]

	#Grant read privilege
	permission::grant -party_id $user_id -object_id $new_package_id -privilege "read"
 	#Verifying  the read privilege on the user
        aa_true "testing read permissions" \
            [expr {[permission::permission_p -party_id $user_id -object_id $new_package_id -privilege "read" ] == 1}]
        #Revoking read privilege
        permission::revoke -party_id $user_id -object_id $new_package_id -privilege "read"
	#We tested with a query because we have problems with inherit
	aa_true "testing if read privilige was revoked" \
	    [expr {[db_string test_read "select 1 from acs_permissions where object_id = :new_package_id and grantee_id = :user_id" -default 0] ==  0}]

        #Grant write privilege
  	permission::grant -party_id $user_id -object_id $new_package_id -privilege "write"
  	#Verifying the write privilege  on the user
  	aa_true "testing write permissions" \
              [expr {[permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "write" ] == 1}]
 	#Revoking write privilege
 	permission::revoke -party_id $user_id -object_id $new_package_id -privilege "write"
 	aa_true "testing if write permissions was revoked" \
 	    [expr {[permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "write" ] == 0}]

  	#Grant create privilege
  	permission::grant -party_id $user_id -object_id $new_package_id -privilege "create"
  	#Verifying the create privelege  on the user
  	aa_true "testing create permissions" \
             [expr {[permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "create" ] == 1}]
 	#Revoking create privilege
         permission::revoke -party_id $user_id -object_id $new_package_id -privilege "create"
         aa_true "testing if create privileges was revoked" \
             [expr {[permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "create" ] == 0}]

 	#Grant delete privilege
 	permission::grant -party_id $user_id -object_id $new_package_id -privilege "delete"
 	#Verifying the delete privilege on the user
 	aa_true "testing delete permissions" \
             [expr {[permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "delete" ] == 1}]
 	#Revoking delete privilege
 	permission::revoke -party_id $user_id -object_id $new_package_id -privilege "delete"
         aa_true "testing if delete permissions was revoked" \
             [expr {[permission::permission_p -party_id $user_id  -object_id  $new_package_id -privilege "delete" ]  == 0}]
    } 
}

aa_register_case -cats {api smoke} ad_proc_permission_permission_p {

    Test for Permission Procedures of permission_p

} {
    #we get an user_id as party_id.
    set user_id [db_nextval acs_object_id_seq]
    aa_run_with_teardown -rollback -test_code {
	#Create the user
	array set user_info [twt::user::create -user_id $user_id]
	#Create and mount new subsite to test the permissions on this
	# instance                                                                                                                                                              
	set site_name [ad_generate_random_string]
	set new_package_id [site_node::instantiate_and_mount \
				-node_name $site_name \
				-package_key acs-subsite]
	#Grant permissions for this user in this object
	permission::grant -party_id $user_id -object_id $new_package_id -privilege "delete"
	aa_true "testing admin permissions" \
	    [expr {[permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "delete" ] == 1}]
	permission::revoke -party_id $user_id -object_id $new_package_id -privilege "delete"

        permission::grant -party_id $user_id -object_id $new_package_id -privilege "create"
	aa_true "testing create permissions" \
	    [expr {[permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "create" ] == 1}]
	permission::revoke -party_id $user_id -object_id $new_package_id -privilege "create"

        permission::grant -party_id $user_id -object_id $new_package_id -privilege "write"
	aa_true "testing write permissions" \
	    [expr {[permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "write" ] == 1}]
        permission::revoke -party_id $user_id -object_id $new_package_id -privilege "write"

        permission::grant -party_id $user_id -object_id $new_package_id -privilege "read"
	aa_true "testing read permissions" \
	    [expr {[db_string test_read "select 1 from acs_permissions where object_id = :new_package_id and grantee_id = :user_id" -default 0] == 1}]
	permission::revoke -party_id $user_id -object_id $new_package_id -privilege "read"

        permission::grant -party_id $user_id -object_id $new_package_id -privilege "admin"
	aa_true "testing delete permissions" \
	    [expr {[permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "admin" ] == 1}]
	permission::revoke -party_id $user_id -object_id $new_package_id -privilege "admin"
    }
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
