# upload an item revision from a file

ad_proc -public cr_revision_upload { title item_id path } {

    set revision_id [db_exec_plsql get_revision_id "begin
    :1 := content_revision.new(title     => :title, 
                               item_id   => :item_id, 
                               v_content => null);
     end;"]

    db_dml dml_revision_from_file "update 
                            cr_revisions 
                          set
                            content = empty_blob()
                          where
                            revision_id = :revision_id
                          returning content into :1" -blob_files [list $path]

  return $revision_id
}
