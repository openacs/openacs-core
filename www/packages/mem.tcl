set keys {
      cm 
      site_nodes 
      apm_reload 
      doc_adptags 
      bootstrap_fatal_error 
      proc_source_file 
      clickthrough_cache 
      rp_directory_listing_p 
      OACS_FULLQUERIES 
      apm_enabled_package 
      vc_summary_cache 
      chat 
      rand 
      NSXML 
      payment_gateway_return_codes 
      static_pages 
      browser_state 
      template_header_preamble 
      apm_library_mtime 
      aa_test 
      ad_procs 
      ad_page_contract_filters 
      api_proc_doc 
      clickthrough_mutex 
      template_extension 
      rp_registered_procs 
      rp_properties 
      apm_version_properties 
      ad_known_database_types 
      ad_robot_useragent_cache 
      locale 
      tabstrip_tab 
      __template_cache_timeout 
      __template_query_persistent_timeout 
      CR_LOCATIONS 
      api_library_doc 
      acs_installer 
      ad_after_server_initialization 
      . 
      proc_doc 
      vc_status_cache 
      __template_config 
      __template_query_persistent_cache 
      ad_page_contract_mutex 
      qd_pg_packages 
      site_node_urls 
      rp_extension_handlers 
      apm_reload_watch 
      aa_file_wide_stubs 
      vc_log_cache 
      ds_properties 
      ad_page_contract_filter_rules 
      acs_mail 
      acs_properties 
      chat_room 
      __template_cache_value 
      s 
      rp_filters 
      apm_properties 
      ad_database_type 
      db_available_pools 
      ad_database_version 
}

foreach key $keys { 
    append out "[format "%4d %8d %s"  [nsv_array size $key] [string bytelength [nsv_array get $key]] $key]\n"
}

#append out "[nsv_array get site_node_urls]\n"
#append out "[nsv_array names api_proc_doc]\n"
#append out "[nsv_array get api_proc_doc]\n"
append out "[string equal postgresql [db_type]] [db_type]\n"
ns_return 200 text/plain $out
