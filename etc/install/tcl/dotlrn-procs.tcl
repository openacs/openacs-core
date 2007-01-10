# Procs to support testing OpenACS with Tclwebtest.
#
# Procs related to creating a basic .LRN class and communities setup.
# Membership of the classes is handled by procs in class-procs.tcl.
# 
# @author Peter Marklund

namespace eval ::twt::dotlrn {}
namespace eval ::twt::dotlrn::test {}

ad_proc ::twt::dotlrn::add_term { server_url term_name start_month start_year end_month end_year } {

    ::twt::do_request "/dotlrn/admin/term-new"
    form find ~n add_term
    field find ~n "term_name"

    field fill "$term_name"
    # Start date
    ::twt::multiple_select_value start_date.month $start_month
    ::twt::multiple_select_value start_date.day "1"
    field find ~n "start_date.year"
    field fill $start_year
    # End date
    ::twt::multiple_select_value end_date.month $end_month
    ::twt::multiple_select_value end_date.day "1"
    field find ~n "end_date.year"
    field fill $end_year
    form submit
}

ad_proc ::twt::dotlrn::setup_terms { server_url } {

    add_term $server_url "Spring" "1" "2004" "7" "2004"
    add_term $server_url "Fall" "9" "2004" "1" "2005"    
    add_term $server_url "Spring" "1" "2005" "7" "2005"
}

ad_proc ::twt::dotlrn::current_term_pretty_name {} {
    return "Spring 2004"
}

ad_proc ::twt::dotlrn::current_term_id {} {
    ::twt::do_request [class_admin_url]

    form find ~n term_form
    field find ~n term_id
    # Term pretty names are not I18N so this will work in different locales
    field select [current_term_pretty_name]
    array set term_select_field [field current]
    set term_id $term_select_field(value)

    return $term_id
}

ad_proc ::twt::dotlrn::class_admin_url {
    {-term_id "-1"}
} {
   return "/dotlrn/admin/term?term_id=$term_id" 
}

ad_proc ::twt::dotlrn::add_department { server_url pretty_name description external_url } {

    ::twt::do_request "/dotlrn/admin/department-new"
    form find ~n add_department
    field find ~n "pretty_name"
    field fill $pretty_name
    field find ~n "description"
    field fill $description 
    field find ~n "external_url"
    field fill $external_url

    form submit
}

ad_proc ::twt::dotlrn::setup_departments { server_url } {

    add_department $server_url "Mathematics" \
	                       "The Faculty of Mathematics consists of the Department of Applied Mathematics & Theoretical Physics (DAMTP) and the Department of Pure Mathematics & Mathematical Statistics (DPMMS). The  Statistical Laboratory is a sub-department of the DPMMS. Also located within the University of Cambridge is the Isaac Newton Institute for Mathematical Sciences." \
			       "http://www.maths.cam.ac.uk/"

    add_department $server_url "Computer Science" \
	                       "The Computer Laboratory is the Computer Science department of the University of Cambridge. The University Computing Service has a separate set of web pages." \
			       "http://www.cl.cam.ac.uk/"

    add_department $server_url "Architecture" \
	                       "Because of the great diversity of offerings in the College of Environmental Design and in the Department of Architecture in areas such as building environments, practice of design, design methods, structures and construction, history, social and cultural factors in design, and design itself, it is possible to obtain either a very broad and general foundation or to concentrate in one or several areas." \
	                       "http://arch.ced.berkeley.edu/"

    add_department $server_url "Business Administration" \
                               "The department offers a range of courses in Business Administration, Finance, and Law" \
                               "http://mitsloan.mit.edu/"
}

ad_proc ::twt::dotlrn::add_subject { server_url department_pretty_name pretty_name description } {

    ::twt::do_request "/dotlrn/admin/class-new"

    form find ~n add_class
    field find ~n "form:id"
    # Department pretty names are not I18N so this will work in different locales    
    field select "$department_pretty_name"
    field find ~n "pretty_name"
    field fill $pretty_name
    field find ~n "description"
    field fill $description

    form submit
}

ad_proc ::twt::dotlrn::setup_subjects { server_url } {

    # Mathematics Department
    add_subject $server_url "Mathematics" "Differential Geometry" " An introduction to differential geometry with applications to general relativity. Metrics, Lie bracket, connections, geodesics, tensors, intrinsic and extrinsic curvature are studied on abstractly defined manifolds using coordinate charts. Curves and surfaces in three dimensions are studied as important special cases. Gauss-Bonnet theorem for surfaces and selected introductory topics in special and general relativity are also studied. 18.100 is required, 18.101 is strongly recommended, and 18.901 would be helpful."

    # Computer Science department
    add_subject $server_url "Computer Science" "Peer to Peer Computing" "The term peer-to-peer (P2P) refers to a class of systems and applications that employ distributed resources to perform a critical function in a decentralized manner..."

    add_subject $server_url "Computer Science" "Advanced Topics in Programming Languages" "This course focuses on bioinformatics applications, high-performance computing, and the application of high-performance computing to bioinformatics applications."

    add_subject $server_url "Computer Science" "Computer and Network Security" "This class serves as an introduction to information systems security and covers security issues at an undergraduate level"

    # Architecture Department
    add_subject $server_url "Architecture" "Architecture and Culture" "Selected examples of architecture and interior design are used as case studies to illustrate the presence of ideas in built matter. A range of projects are analysed and discussed in terms of the conceptual qualities that underpin the physical manifestations of architecture and interior design."

    # Business Administration Department
    add_subject $server_url "Business Administration" "Economic Analysis for Business Decisions" " Introduces students to principles of microeconomic analysis used in managerial decision making. Topics include demand analysis, cost and production functions, the behavior of competitive and non-competitive markets, sources and uses of market power, and game theory and competitive strategy, with applications to various business and public policy decisions. Antitrust policy and other government regulations are also discussed. 15.010 restricted to first-year Sloan masters students. 15.011 primarily for non-Sloan School students."

    add_subject $server_url "Business Administration" "Organizational Psychology & Sociology" "Organizations are changing rapidly. To deal with these changes requires new skills and attitudes on the part of managers. The goal of the OPS course is to make you aware of this challenge and equip you to better meet it. In short, the purpose is to acquaint you with some of psychological and sociological phenomena that regularly occur in organizations - the less visible forces that influence employee and managerial behavior.  The aim is to increase your understanding of these forces -- in yourself and in others -- so that as they become more visible, they become manageable (more or less) and hence subject to analysis and choice."

    add_subject $server_url "Business Administration" "Advanced Corporate Finance" "The primary objective of the advanced corporate finance course is to conduct an in-depth analysis of special topics of interest to corporate finance managers.  Our attempt will be to obtain a detailed understanding of the motives and reasons that lead to certain corporate decisions specifically in relation to the following issues: Mergers and Acquisitions, Corporate Restructurings, Corporate Bankruptcy, Corporate Governance"
}

ad_proc ::twt::dotlrn::get_class_add_urls { server_url } {

    return [::twt::get_url_list "/dotlrn/admin/classes" "class-instance-new"]
}

ad_proc ::twt::dotlrn::setup_classes { server_url } {

    setup_classes_for_term $server_url "[::twt::dotlrn::current_term_pretty_name]"
    setup_classes_for_term $server_url "Spring 2004"
}

ad_proc ::twt::dotlrn::setup_classes_for_term { server_url term_name } {

    foreach link [get_class_add_urls $server_url] {

        ::twt::do_request $link
        form find ~n "add_class_instance"
        field find
        # Term pretty names are not I18N so this will work in different locales
        field select $term_name
        field find ~n pretty_name
        array set name_field [field current]
        set pretty_name $name_field(value)
        field fill "$pretty_name $term_name"
        form submit
    }
}

ad_proc ::twt::dotlrn::setup_communities { server_url } {

    add_community $server_url "Tennis Club" "Community for the university tennis club with tournaments and other events, also helps you find people to play with." "open"
    add_community $server_url "Business Alumni Class of 1997" "Alumni community for the Business Administration graduates from the class of 1997." "closed"
    add_community $server_url "Business Administration Program" "Community for all students following the Business Administration Program" "closed"
    add_community $server_url "Star Trek Fan Club" "Community for die-hard fans of Star Trek" "needs approval"
}

ad_proc ::twt::dotlrn::add_community { server_url name description policy } {
    
    ::twt::do_request "/dotlrn/admin/club-new"    

    form find ~n add_club

    field find ~n pretty_name
    field fill $name
    field find ~n description
    field fill $description
    ::twt::multiple_select_value join_policy $policy

    form submit
}

ad_proc ::twt::dotlrn::get_user_admin_url { email } {
    Get the .LRN admin URL for a user. This is awkward. If we could
    lookup the user_id from email this would be much easier.
} {
    ::twt::do_request "/dotlrn/admin/users-search?name=einstein&form%3Aid=user_search"

    link follow ~u {user\?user}

    return [response url]
}

ad_proc ::twt::dotlrn::add_site_wide_admin { server_url } {

    global __admin_last_name

    # Goto users page
    ::twt::do_request "/dotlrn/admin/users?type=pending"

    # Goto the community page for the site-wide admin (assuming he's first in the list)
    link follow ~u {^user\?user}

    # Follow the add to dotlrn link
    link follow ~u "user-new-2"

    # Use defaults (external with full access)
    form find ~a "user-new-2"
    form submit
}

###################
#
# Namespace ::twt::dotlrn::test - no demo data setup, pure testing
#
###################

ad_proc ::twt::dotlrn::test::manage_my_memberships {} {
    Test that user can manage (join/drop) his own class and community memberships.
} {
    # First request some ids from the OpenACS server
    set user_id [::twt::oacs::eval "ad_conn user_id"]
    set class_community_id [::twt::oacs::get_class_to_join $user_id]
    set club_join_community_id [::twt::oacs::get_club_to_join $user_id "open"]
    set club_request_community_id [::twt::oacs::get_club_to_join $user_id "needs approval"]

    # Visit the manage memberships page
    ::twt::do_request "/dotlrn/manage-memberships"

    # Join a class
    set link_pattern "register.*community_id=$class_community_id"
    link follow ~u $link_pattern

    # Assert class join link is gone
    if { [::twt::count_links $link_pattern] > 0 } {
        ::twt::log_alert "Class with community_id $class_community_id was joined but the join link still appears to be present"
    }
    
    # Join a club
    set link_pattern "register.*community_id=$club_join_community_id"
    link follow ~u $link_pattern

    # Assert join club link is gone
    if { [::twt::count_links $link_pattern] > 0 } {
        ::twt::log_alert "Club with community_id $club_join_community_id was joined but the join link still appears to be present"
    }    
    
    # Request membership for a club
    set link_pattern "register.*community_id=$club_request_community_id"
    link follow ~u $link_pattern

    # Assert request membership link is gone
    if { [::twt::count_links $link_pattern] > 0 } {
        ::twt::log_alert "Requested membership for club with community_id $club_request_community_id but the request link still appears to be present"
    }    

    # Drop a class
    set link_pattern deregister
    set deregister_count_before [::twt::count_links $link_pattern]
    link follow ~u $link_pattern
    set deregister_count_after [::twt::count_links $link_pattern]

    # Assert there is now one less class to deregister from
    ::twt::assert_equals \
            "Should be one less class to dergister from after deregistering" \
            $deregister_count_after \
            [expr {$deregister_count_before - 1}]
}
