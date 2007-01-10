# Procs to support testing OpenACS with Tclwebtest.
#
# .LRN Class procs.
#
# @author Peter Marklund

namespace eval ::twt::class {}
namespace eval ::twt::class::test {}

ad_proc ::twt::class::get_admin_urls { } {
    Returns a list with the fully qualified URLs of the admin pages of
    all .LRN classes.
} {
    set term_id [::twt::dotlrn::current_term_id]
    set page_url [::twt::dotlrn::class_admin_url -term_id $term_id]

    set url_pattern {/dotlrn/classes/.*/one-community-admin$}

    return [::twt::get_url_list $page_url $url_pattern]
}

ad_proc ::twt::class::get_urls { } {
    Returns a list with the fully qualified URLs of the home pages of
    all .LRN classes.
} {
    # The trick we use here is that we know that class urls are the admin
    # URLs minus "one-community-admin"
    set url_list [list]
    set admin_url_list [get_admin_urls]

    foreach admin_url $admin_url_list {
        regexp {^(.*)one-community-admin$} $admin_url match class_url
        lappend url_list $class_url
    }

    return $url_list
}

ad_proc ::twt::class::engineering_p { class_url } {

    return [regexp {dotlrn/classes/(computer-science|mathematics)} $class_url match]
}

ad_proc ::twt::class::follow_members_link {} {

    link follow ~u {members$}    
}

ad_proc ::twt::class::get_professor { class_url } {

    # TODO: find the professor of the class
    class::follow_members_link

    # This is fragile...
    # TODO regexping on HTML code is too fragile
    # write special pages that export such data instead

    return [user::get_random_users professor 1]
}

ad_proc ::twt::class::setup_memberships { server_url } {

    foreach admin_url [get_admin_urls] {

        # Admin page for the class
        ::twt::do_request "$admin_url"

        # Member management for the class
        follow_members_link
    
        # Add all students
        add_members [::twt::user::get_users student] dotlrn_student_rel

        # Add a random professor
        add_member [::twt::user::get_random_users professor 1] dotlrn_instructor_rel

        # Add two staff in random roles (one of Teaching Assistant, Course Admin, or Course Assistant)
        set admin_users [::twt::user::get_random_users staff 2]
        set admin_rels [list dotlrn_ta_rel dotlrn_cadmin_rel dotlrn_ca_rel]
        set admin_counter 0
        for { set admin_counter 0 } \
            { [expr {$admin_counter < 2 && $admin_counter < [llength $admin_users]}] } \
            { incr admin_counter } {

            set admin_rel [::twt::get_random_items_from_list $admin_rels 1]
            add_member [lindex $admin_users $admin_counter] $admin_rel
        }
    }
}

ad_proc ::twt::class::add_members { email_list rel_type } {
    foreach email $email_list {
        add_member $email $rel_type
    }
}

ad_proc ::twt::class::add_member { email rel_type } {

    if { $email eq "" } {
        return
    }

    # Search for the student to add
    form find ~a member-add
    field find ~n search_text
    field fill $email
    form submit

    # Pick the user (there should be only one)
    link follow ~u member-add-2

    # pick relationship type to class (role)
    form find ~a "member-add-3"
    ::twt::multiple_select_value rel_type $rel_type
    form submit
}

ad_proc ::twt::class::setup_subgroups { server_url } {

    foreach admin_url [get_admin_urls] {

        foreach {name description policy} [subcommunity_properties_list] {

            # Admin page of one class
            ::twt::do_request $admin_url

            # Add subcommunity form
            link follow ~u subcommunity-new

            form find ~n add_subcomm
            field fill $name ~n pretty_name
            field fill $description ~n description
            ::twt::multiple_select_value join_policy $policy
            form submit
        }
    }    
}

ad_proc ::twt::class::subcommunity_properties_list {} {

    set property_list [list]

    foreach letter {A B} {
        set pretty_name "Project Group $letter"
        lappend property_list $pretty_name
        lappend property_list "Workspace for people working in $pretty_name"
        # Other possible values: open, closed
        lappend property_list "needs approval"    
    }

    return $property_list
}

ad_proc ::twt::class::add_member_applets { server_url } {

    foreach admin_url [get_admin_urls] {

        # Only add the members applet to computing classes so that we can
        # demo adding it to other classes manually
        if { [regexp -nocase {comput} $admin_url match] } {

            # Admin page of the class
            ::twt::do_request $admin_url
        
            # Manage Applets
            link follow ~u {applets$}

            # Add the Members Info applet
            link follow ~u {applet-add.*applet_key=dotlrn_members}
        }
    }
}

###################
#
# Namespace ::twt::class::test - no demo data setup, pure testing
#
###################

ad_proc ::twt::class::test::manage_memberships {} {
    Test removing users and changing their roles in a class
    using the class_url/members page.

    @author Peter Marklund
} {
    
}