ad_library {
    Procedures in the folder namespace related to content folders.

    @author Peter Marklund
    @cvs-id $Id$
}

namespace eval folder {}

ad_proc -public folder::delete {
    {-folder_id:required}
} {
    Delete a content folder. If the folder
    to delete has children content items referencing it
    via acs_objects.context_id then this proc will fail.

    @author Peter Marklund
} {
    db_exec_plsql delete_folder {}
}
