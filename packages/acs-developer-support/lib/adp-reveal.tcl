set ds_adp_box_class [ds_adp_box_class]
set ds_adp_file_class [ds_adp_file_class]
set apidoc_path [string range $ds_adp_stub [string length [acs_root_dir]] end].$ds_adp_template_extension
set stub_path [join [split $ds_adp_stub /] " / "]
set ds_adp_output_class [ds_adp_output_class]
