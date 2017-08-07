ad_page_contract {
    @author Neophytos Demetriou <k2pts@yahoo.com>
    @creation-date 2001-09-02
} {
    template_demo_note_id:naturalnum,notnull
} -properties {
    context:onevalue
    title:onevalue
    body:onevalue
} -validate {
    valid_note_id -requires template_demo_note_id {
        if {![db_0or1row note_exists {
            select 1 from template_demo_notes
            where template_demo_note_id = :template_demo_note_id
        }]} {
            ad_complain "Invalid note ID"
        }
    }
}


set context [list "One note"]

db_1row note_select {
    select title, body, color
    from template_demo_notes
    where template_demo_note_id = :template_demo_note_id
}

set body [ad_text_to_html -- $body]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
