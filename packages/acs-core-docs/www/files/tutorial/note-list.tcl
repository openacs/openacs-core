template::list::create \
    -name notes \
    -multirow notes \
    -actions { "Add a Note" note-edit} \
    -elements {
	edit {
	    link_url_col edit_url
	    display_template {
		<img src="/resources/acs-subsite/Edit16.gif" width="16" height="16" border="0">
	    }
	    sub_class narrow
	}
	title {
	    label "Title"
	}
	delete {
	    link_url_col delete_url 
	    display_template {
		<img src="/resources/acs-subsite/Delete16.gif" width="16" height="16" border="0">
	    }
	    sub_class narrow
	}
    }

db_multirow \
    -extend {
	edit_url
	delete_url
    } notes notes_select {
	select ci.item_id,
	       n.title
        from   cr_items ci,
               mfp_notesx n
        where  n.revision_id = ci.live_revision
    } {
	set edit_url [export_vars -base "note-edit" {item_id}]
	set delete_url [export_vars -base "note-delete" {item_id}]
    }
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
