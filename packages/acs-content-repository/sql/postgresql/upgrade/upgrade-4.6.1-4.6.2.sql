-- Adds indexes for RI checking
--
create index cr_cont_mimetypmap_mimetyp_idx ON cr_content_mime_type_map(mime_type); --  cr_mime_types.mime_type
create index cr_folder_typ_map_cont_typ_idx ON cr_folder_type_map(content_type); --  acs_object_types.object_type
create index cr_folders_package_id_idx ON cr_folders(package_id); --  apm_packages.package_id
create index cr_item_keyword_map_kw_id_idx ON cr_item_keyword_map(keyword_id); --  cr_keywords.keyword_id
create index cr_item_rels_rel_obj_id_idx ON cr_item_rels(related_object_id); --  acs_objects.object_id
create index cr_keywords_parent_id_idx ON cr_keywords(parent_id); --  cr_keywords.keyword_id
create index cr_revisions_lob_idx ON cr_revisions(lob); --  lobs.lob_id
create index cr_revisions_item_id_idx ON cr_revisions(item_id); --  cr_items.item_id
create index cr_type_children_chld_type_idx ON cr_type_children(child_type); --  acs_object_types.object_type
create index cr_type_relations_tgt_typ_idx ON cr_type_relations(target_type); --  acs_object_types.object_type
