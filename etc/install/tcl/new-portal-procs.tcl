# Procs to support testing OpenACS with Tclwebtest.
#
# Procs for testing the acs-lang (I18N) package
#
# @author Peter Marklund

namespace eval ::twt::new_portal {}
namespace eval ::twt::new_portal::test {}

ad_proc ::twt::new_portal::test::customize_layout {} {
    Test customizing the layout of the MySpace page.
} {
    # Visit the customize layout page
    ::twt::do_request "/dotlrn/configure"

    # Revert to default layout to have a clean starting point
    form find ~n op_revert
    form submit    

    # Remove an element
    link follow ~u {configure-2.*op_hide=1}

    # Move element in different directions
    link follow ~u {configure-2.*op_swap=1.*direction=up}
    link follow ~u {configure-2.*op_swap=1.*direction=down}
    link follow ~u {configure-2.*op_move=1.*direction=right}

    # Move element to different page
    form find ~n op_move_to_page
    form submit

    # Rename a page
    form find ~n op_rename_page
    set test_page_name "__test_page_name"
    field fill $test_page_name ~n pretty_name
    form submit

    # Assert that the test page name is there
    ::twt::assert "page rename was successful" [regexp "$test_page_name" [response body]]

    # Add a page
    form find ~n op_add_page
    form submit

    # Revert back to default layout
    form find ~n op_revert
    form submit    

    # Assert that the test page name is gone
    ::twt::assert "test page name gone after revert" [expr ![regexp "$test_page_name" [response body]]]

    # Assert three pages
    set page_count [regexp -all {<input[^>]+?name="op_rename_page"} [response body]]
    ::twt::assert_equals "customize page has three pages after revert" $page_count "3"
}
