# Procs to support testing OpenACS with Tclwebtest.
#
# For testing forums package.
#
# @author Peter Marklund

namespace eval ::twt::forums {}

ad_proc ::twt::forums::add_default_forums { server_url } {
    Adds a general forum to each class. Goes via the class admin pages.
} {
    foreach admin_url [::twt::class::get_admin_urls $server_url "Fall 2003/2004"] {

        # Admin page of one class
        do_request $admin_url

        # Add forum form
        link follow ~u forum-new

        form find ~n forum
        field fill "This is a general discussion forum where teachers, assistants, and students can come together to discuss the subject of the class or practical matters surrounding exams, assignments, project work etc." ~n charter
        form submit        
    }    
}

ad_proc ::twt::forums::add_postings {} {
    global __server_url

    # Request the start page
    do_request "${__server_url}/register"

}
