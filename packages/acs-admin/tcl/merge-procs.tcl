ad_library {

    Definitions for the account merge 

    @creation-date 15 APR 2005
    @author Enrique Catalan (quio@galileo.edu)
    @cvs-id $Id$

}

ad_proc -callback MergePackageUser {
    -from_user_id:required
    -to_user_id:required
} {
    Merge two accounts
} {}


