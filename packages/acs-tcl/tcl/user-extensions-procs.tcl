
ad_library {

    Procs to manage extensions to user data.
    This calls the UserData service contract for allowing packages to be notified 
    of changes in user information.

    @author ben@openforce.net
    @creation-date 2002-01-22
    @cvs-id $Id$

}

namespace eval acs_user_extension {
    
    ad_proc -private dispatch {
        {-op:required}
        {-list_of_args:required}
        {-impl ""}
    } {
    
    	Dispatches (calls the service contract routines) the requested
	method so that the operation gets executed.

    } {
        if {[empty_string_p $impl]} {
            set extensions [list_extensions]
        } else {
            set extensions [list $impl]
        }

        # Loop through the extensions
        foreach extension $extensions {
            acs_sc_call UserData $op $list_of_args $extension
        }
    }

    ad_proc -public list_extensions {} {
        List the extensions (User Data contract)
    } {
        return [db_list select_extensions {}]
    }

    ad_proc -public user_new {
        {-user_id:required}
    } {
        New User
    } {
        dispatch -op UserNew -list_of_args [list $user_id]
    }

    ad_proc -public user_approve {
        {-user_id:required}
    } {
        Approve User
    } {
        dispatch -op UserApprove -list_of_args [list $user_id]
    }

    ad_proc -public user_deapprove {
        {-user_id:required}
    } {
        Deapprove User
    } {
        dispatch -op UserDeapprove -list_of_args [list $user_id]
    }

    ad_proc -public user_modify {
        {-user_id:required}
    } {
        Modify User
    } {
        dispatch -op UserModify -list_of_args [list $user_id]
    }

    ad_proc -public user_delete {
        {-user_id:required}
    } {
        Delete User
    } {
        dispatch -op UserDelete -list_of_args [list $user_id]
    }

}

