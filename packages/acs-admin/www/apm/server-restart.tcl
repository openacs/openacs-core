ad_page_contract {

    Kill (restart) the server.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 27:th of March 2003
    @cvs-id $Id$
}

set page_title "Restart Server"

set context [list [list "." "Package Manager"] $page_title]


# We do this as a schedule proc, so the server will have time to serve the page

ad_schedule_proc -thread t -once t 1 exit
