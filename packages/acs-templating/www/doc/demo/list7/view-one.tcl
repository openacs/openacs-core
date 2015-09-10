ad_page_contract {
    @author Neophytos Demetriou <k2pts@yahoo.com>
    @creation-date 2001-09-02
} {
    note_id:naturalnum,notnull
} -properties {
    context:onevalue
    title:onevalue
    body:onevalue
}

set context [list "One note"]

db_1row note_select {
    select title, body
    from notes
    where note_id = :note_id
}

set body [ad_text_to_html -- $body]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
