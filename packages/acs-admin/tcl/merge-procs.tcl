ad_library {

    Definitions of procs for the merge process

    @creation-date 15 APR 2005
    @author Enrique Catalan (quio@galileo.edu)
    @cvs-id $Id$

}

ad_proc -callback MergePackageUser {
    -from_user_id:required
    -to_user_id:required
} {
    Merge two accounts
} -

ad_proc -callback MergeShowUserInfo {
    -user_id:required
} {
    Merge two accounts
} -


