# /packages/editthispage/templates/article-index.tcl

ad_page_contract {
    @author Luke Pond (dlpond@pobox.com)
    @creation-date 2001-06-01

    This is an interface for a list of Frequently Asked Questions.
    We assume you want to see all the questions on a single page,
    so there are no links to pages that display individual questions.

    This template uses no extended page attributes.  The question
    is stored in the page title, and the answer is stored in the content
    field.
} {
} -properties {
    pa:onerow
    content_pages:multirow
}

etp::get_page_attributes
etp::get_content_items content
