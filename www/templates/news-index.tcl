# /packages/editthispage/templates/news-index.tcl

ad_page_contract {
    @author Luke Pond (dlpond@pobox.com)
    @creation-date 2001-08-30

    This is an example of using extended attributes in an ETP template.

    Displays all news items for which the release date is in 
    the past and the archive date is in the future.

    If "archive_p=t" is in the url, displays all news items for
    which the release date is in the past.

} {
    {archive_p "f"}
} -properties {
    pa:onerow
    content_pages:multirow
}

if { $archive_p == "f" } {
    set where "sysdate() between to_date(attributes.release_date, 'YYYY-MM-DD') and to_date(attributes.archive_date, 'YYYY-MM-DD')"
} else {
    set where "sysdate() >= to_date(attributes.archive_date, 'YYYY-MM-DD')"
}

set orderby "to_date(attributes.release_date, 'YYYY-MM-DD') desc"

etp::get_page_attributes
etp::get_content_items -where $where -orderby $orderby release_date archive_date
