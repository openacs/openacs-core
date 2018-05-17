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

    The HTML fragment should have an h2 header for sectioning.

    @param user_id - the user to display
    @see callback::user::workspace::impl::acs-subsite
} -

ad_proc -public -callback user::workspace -impl acs-subsite {
        -user_id
} {
    Generate a table showing the application group membership
} {
    set themed_template [template::themed_template /packages/acs-subsite/lib/user-subsites]
    return [template::adp_include $themed_template [list user_id $user_id]]
}

ad_proc -public -callback user::registration {
    -package_id
} {
    used to verify if there is another registration process.
    The implementation must return the url of the registration page.
} -

ad_proc -callback subsite::get_extra_headers {
} {
    @return any further header stuff that needs to be added
    @see subsite::page_plugin
} -

ad_proc -callback subsite::header_onload {
} {
    @return any JavaScript function that needs to be loaded
    the callback implementation should simply do:
    return {your_function(params);}
    @see subsite::page_plugin
} -

ad_proc -callback subsite::page_plugin {
} {
    Execute package-specific code on every page. Callbacks of this type
    typically call template::head::* functions to add application specific
    code (CSS and JavaScript) to every page (e.g. like e.g. the cookie-consent-plugin).
    This callback is a generalization of the callbacks "subsite::get_extra_headers"
    and "subsite::header_onload".
} -


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
