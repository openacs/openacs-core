# Procs to support testing OpenACS with Tclwebtest.
#
# For testing forums package.
#
# @author Peter Marklund

namespace eval ::twt::forums {}

ad_proc ::twt::forums::add_default_forums { server_url } {
    Adds a general forum to each class. Goes via the class admin pages.
} {
    foreach admin_url [::twt::class::get_admin_urls $server_url "[::twt::dotlrn::current_term_pretty_name]"] {

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

    # Loop over all classes
    foreach forum_url [::twt::class::get_urls] {
        # Create thread

        # Enter thread

        # Post question

        # Post answers
    }
}
