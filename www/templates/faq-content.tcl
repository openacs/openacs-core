# /packages/editthispage/templates/faq-content.tcl

ad_page_contract {
    @author Luke Pond (dlpond@pobox.com)
    @creation-date 2001-07-05

    This page can be used to display a single question from a FAQ.
    However, the faq-index page displays all questions and answers
    without linking to an individual question, so you'll have to 
    come up with some other way to use it (search engine results, perhaps) 
} {
} -properties {
    pa:onerow
}

etp::get_page_attributes

