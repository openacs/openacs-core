# packages/notes/www/add-edit.tcl
ad_page_contract {

  @author Don Baccus (dhogaza@pacifier.com)
  @creation-date 2000-10-23
  @cvs-id $Id$

  Example script that allows for the creation or editing of a simple note
  object type, using ad_form and package Tcl API tools.

} -query {
    note_id:naturalnum,notnull,optional
} -properties {
    context:onevalue
    page_title:onevalue
}

# When using ad_form to generate or edit acs_objects, the object type's
# key column must be specified in ad_page_contract as is done above,
# and defined with the type "key" in ad_form.  This enables the use of
# the various request and submission code blocks.

set package_id [ad_conn package_id]

ad_form -form {

    # The "note" object type's key

    id:key

    # "title" is of type text and will use a "text" widget.

    {title:text \
        {label Title}
        {html {size 20}}
    }

    # "body" is of type text and will use a "textarea" widget.

    {body:text(textarea) \
        {label Body}
        {html {rows 10 cols 40}}
    }

    {vitamins:text(checkbox) 
        {label "Vitamins"}
        {options {
            {Lettuce lettuce}
            {"&nbsp;Tomato" tomato}
            {"&nbsp;&nbsp;Pickle" pickle}
            {"&nbsp;&nbsp;&nbsp;Sprouts" sprouts}
        }}
    }

    {action:text(select)
        {label Action}
        {options {
            { "&nbsp;&nbsp;&nbsp;&nbsp;aaa" a }
            { "&nbsp;&nbsp;bbb" b }
            { "<c>" c }
        }}
    }

} -new_request {

    # By convention packages only allow a user to create new objects if the user has
    # the "create" privilege on the package instance itself.

    permission::require_permission -object_id $package_id -privilege create

    # Customize the page title to reflect the fact that this form is used to
    # create a new note.

    set page_title "New Note"

} -edit_request {

    permission::require_permission -object_id $note_id -privilege write

    # Customize the page title to reflect the fact that this form is used to
    # edit an existing note.

    set page_title "Edit Note"

    # Fill the form with the values from the note we're editing.

    db_1row note_select {}

} -on_validation_error {

    # There was an error in the form, let the page title reflect this.

    set page_title "Error in submission"

} -new_data {

    # Create a new note.

    # Generate the new object automatically from the data set in the form.  Standard
    # acs_object attributes like creation_user are set automatically.

    package_instantiate_object -var_list [list [list context_id $package_id]] \
        -form_id add-edit \
        note

} -edit_data {

    # Currently we need to update our object manually ...

    set modifying_user [ad_conn user_id]
    set modifying_ip [ad_conn peeraddr]

    db_transaction {
        db_dml object_update {}
        db_dml note_update {}
    }

} -after_submit {

    # We've successfully processed the submission, send the user back to the index page.

    ad_returnredirect "./"

    # ad_returnredirect returns after redirecting the user, so abort the script rather
    # than fall through to the display code.  Failure to abort the script will burden
    # your server with needless template processing, though the user won't notice due to
    # having been redirected.

    ad_script_abort

}

# The following is only executed if we did not process a valid submission, in other
# words on the initial "new" or "edit" form request or after a submission which
# contained errors.  Add the page title to the breadcrumb context bar.

set context [list $page_title]

# Display the form, blank if we're processing a "new" request, filled with data if we're
# processing an "edit" request or a submitted form that contains errors.

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
