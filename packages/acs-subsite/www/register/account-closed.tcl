ad_page_contract {
    Inform the user that his/her account is closed
    
    @cvs-id $Id$
} {
    {message:html ""}
}

set page_title [ad_convert_to_text -html_p t -- $message]
set context [list [_ "acs-kernel.common_Register"]]

