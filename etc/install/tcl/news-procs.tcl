# Procs to support testing OpenACS with Tclwebtest.
#
# Procs related to the news application.
#
# @author Peter Marklund

namespace eval ::twt::news {}

ad_proc ::twt::news::add_item_to_classes { server_url } {

    set news_item_list [get_items]

    set class_counter 0
    foreach admin_url [::twt::class::get_admin_urls] {

        # We want the professor of the class to post the news item
        # TODO
        #set email [::twt::class::get_professor $admin_url]
        #user::login $email [::twt::user::get_password $email]

        # Admin page of the class
        ::twt::do_request $admin_url

        # News item add
        link follow ~u {news/+item-create}

        set news_item [lindex [::twt::get_random_items_from_list $news_item_list 1] 0]

        form find ~a preview
        set publish_title [lindex $news_item 0]
        set publish_body [lindex $news_item 1]
        field fill $publish_title ~n publish_title
        field fill $publish_body ~n publish_body
        field check ~n permanent_p
        form submit

        # confirm
        form find ~a {item-create-3}

        form submit
        
        incr class_counter
    }

    # Re-login the site-wide admin
    #login_site_wide_admin
}

ad_proc ::twt::news::get_items {} {

    set news_item_list [list]

    lappend news_item_list {{The exam is postponed by one week} {The final exam previously planned for the 20:th of December will be on the 3:d of January instead - the calendar has been updated}}
    
    lappend news_item_list {{Recommended Reading for friday workshop} {For the friday workshop reading up on chapter three of the course materials is strongly recommended. See you on friday!}}

    lappend news_item_list {{Class Assistants Needed} {We need more people to assist with the seminar on tuesday - let me know if you are interested!}}

    lappend news_item_list {{Changed Schedule} {We have decided to adjust the schedule slightly by moving section 6 and 8 of the of the text book to be treated in december.}}

    lappend news_item_list {{Deadline for assignment II on thursday} {We need to have the homework assignments handed in for review no later than this thursday}}

    lappend news_item_list {{Project Group Meeting} {We will hold an extra project group meeting on next wednesday to plan and discuss the various topics that have been suggested.}}

    return $news_item_list
}
