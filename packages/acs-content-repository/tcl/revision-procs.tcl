# upload an item revision from a file

proc cr_revision_upload { title item_id path } {

  set db [ns_db gethandle]

  ns_ora exec_plsql_bind $db "begin
    :revision_id := content_revision.new(title => :title, 
                                         item_id => :item_id, 
                                         v_content => null);
  end;" revision_id

  ns_ora blob_dml_file_bind $db "update cr_revisions set
                                  content = empty_blob()
                                 where
                                  revision_id = :revision_id
                                 returning content into :1" [list 1] $path

  ns_db releasehandle $db

  return $revision_id
}