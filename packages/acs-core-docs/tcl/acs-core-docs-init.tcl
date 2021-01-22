
#ad_register_proc GET /doc/*.html core_docs_html_redirector

ad_register_filter -priority 1000 postauth GET  /doc/*.html core_docs_html_redirector

#ns_register_fastpath GET /doc/*.html
