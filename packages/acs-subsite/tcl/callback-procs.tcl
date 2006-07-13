ad_library {
    Callback definitions 

    @author Jeff Davis <davis@xarg.net>
    @creation-date 2005-03-11
    @cvs-id $Id$
}

ad_proc -public -callback user::workspace {
    -user_id
} {
    used to generate html fragments for display on the /pvt/home page.
    
    The html fragment should have an h2 header for sectioning.
    
    @param user_id - the user to display
    
    @see callback::user::workspace::impl::acs-subsite
} -


ad_proc -public -callback user::workspace -impl acs-subsite {
	-user_id
} {
    Generate a table showing the application group membership 
} {
    return [template::adp_include /packages/acs-subsite/lib/user-subsites [list user_id $user_id]]
}

ad_proc -public -callback user::registration { 
    -package_id 
} {
    used to verify if there is another registration process.
    The implementation must return the url of the registration page.
} - 

ad_proc -callback subsite::get_extra_headers {
} {
    returns any further header stuff that needs to be added
} -

ad_proc -callback subsite::header_onload {
} {
    returns any javascript function that needs to be loaded
    the callback implementation should simply do:
    return {your_function(params);}
} -

