ad_page_contract {
    Inform the user that his/her account is closed
    
    @cvs-id $Id$
} {
    {message:allhtml ""}
}

set page_title [ad_convert_to_text -html_p t -- $message]
set context [list $page_title]

