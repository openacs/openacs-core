ad_page_contract {
    Will redirect you to aolserver.com if documentation can be found
    @cvs-id $Id$
} {
    tcl_proc
} -properties {
    title:onevalue
    context_bar:onevalue
    tcl_proc:onevalue
}

###############################################
# This is a big hack.
# It will work for now, I'll fix it on Monday
# (If the online AOL docs change this page won't work)
# If we want to download copy of docs something like this might be ok
#  Of course not in this form
# Otherwize, should query page with index and search for tcl_proc in it
#  with a regexp.
#
#
# Also note docs not formed well:  
# ns_returnredirect can't be found, 
# it is under ns_return
# the same way ns_db insert is under ns_db
#
###############################################
# START Perl Script Output:
###
set tcl_api_page(env) tapi-ch3.htm#155774
set tcl_api_page(ns_adp_abort) tapi-ch4.htm#145894
set tcl_api_page(ns_adp_argc) tapi-ch5.htm#205037
set tcl_api_page(ns_adp_argv) tapi-ch6.htm#205045
set tcl_api_page(ns_adp_bind_args) tapi-ch7.htm#205053
set tcl_api_page(ns_adp_break) tapi-ch8.htm#200736
set tcl_api_page(ns_adp_debug) tapi-ch9.htm#222048
set tcl_api_page(ns_adp_dir) tapi-c10.htm#146426
set tcl_api_page(ns_adp_dump) tapi-c11.htm#222437
set tcl_api_page(ns_adp_eval) tapi-c12.htm#222438
set tcl_api_page(ns_adp_exception) tapi-c13.htm#222439
set tcl_api_page(ns_adp_include) tapi-c14.htm#146692
set tcl_api_page(ns_adp_parse) tapi-c15.htm#145624
set tcl_api_page(ns_adp_puts) tapi-c16.htm#222875
set tcl_api_page(ns_adp_registertag) tapi-c17.htm#221672
set tcl_api_page(ns_adp_return) tapi-c18.htm#296668
set tcl_api_page(ns_adp_stream) tapi-c19.htm#223254
set tcl_api_page(ns_adp_tell) tapi-c20.htm#287015
set tcl_api_page(ns_adp_trunc) tapi-c21.htm#287024
set tcl_api_page(ns_atclose) tapi-c22.htm#179148
set tcl_api_page(ns_atexit) tapi-c23.htm#225714
set tcl_api_page(ns_atshutdown) tapi-c24.htm#75924
set tcl_api_page(ns_atsignal) tapi-c25.htm#87327
set tcl_api_page(ns_cache_flush) tapi-c26.htm#236562
set tcl_api_page(ns_cache_names) tapi-c27.htm#236563
set tcl_api_page(ns_cache_size) tapi-c28.htm#236564
set tcl_api_page(ns_cache_stats) tapi-c29.htm#236565
set tcl_api_page(ns_checkurl) tapi-c30.htm#226180
set tcl_api_page(ns_chmod) tapi-c31.htm#207399
set tcl_api_page(ns_cond) tapi-c32.htm#226592
set tcl_api_page(ns_config) tapi-c33.htm#3184
set tcl_api_page(ns_configsection) tapi-c34.htm#227106
set tcl_api_page(ns_configsections) tapi-c35.htm#227107
set tcl_api_page(ns_conn) tapi-c36.htm#3206
set tcl_api_page(ns_conncptofp) tapi-c37.htm#228287
set tcl_api_page(ns_connsendfp) tapi-c38.htm#227925
set tcl_api_page(ns_cp) tapi-c39.htm#58696
set tcl_api_page(ns_cpfp) tapi-c40.htm#80619
set tcl_api_page(ns_cport) tapi-c41.htm#228736
set tcl_api_page(ns_critsec) tapi-c42.htm#80760
set tcl_api_page(ns_crypt) tapi-c43.htm#3386
set tcl_api_page(ns_db) tapi-c44.htm#67537
set tcl_api_page(ns_dbconfigpath) tapi-c45.htm#67905
set tcl_api_page(ns_dberror) tapi-c46.htm#67914
set tcl_api_page(ns_dbformvalue) tapi-c47.htm#77098
set tcl_api_page(ns_dbformvalueput) tapi-c48.htm#77112
set tcl_api_page(ns_dbquotename) tapi-c49.htm#77217
set tcl_api_page(ns_dbquotevalue) tapi-c50.htm#77226
set tcl_api_page(ns_deleterow) tapi-c51.htm#77349
set tcl_api_page(ns_eval) tapi-c52.htm#26310
set tcl_api_page(ns_event) tapi-c53.htm#80907
set tcl_api_page(ns_ext) tapi-c54.htm#82709
set tcl_api_page(ns_findrowbyid) tapi-c55.htm#77814
set tcl_api_page(ns_fmttime) tapi-c56.htm#179545
set tcl_api_page(ns_ftruncate) tapi-c57.htm#174989
set tcl_api_page(ns_getcsv) tapi-c58.htm#199439
set tcl_api_page(ns_getform) tapi-c59.htm#190694
set tcl_api_page(ns_get_multipart_formdata) tapi-c60.htm#148702
set tcl_api_page(ns_geturl) tapi-c61.htm#31659
set tcl_api_page(ns_gifsize) tapi-c62.htm#190984
set tcl_api_page(ns_gmtime) tapi-c63.htm#302169
set tcl_api_page(ns_guesstype) tapi-c64.htm#3596
set tcl_api_page(ns_hostbyaddr) tapi-c65.htm#81032
set tcl_api_page(ns_hrefs) tapi-c66.htm#3758
set tcl_api_page(ns_httpget) tapi-c67.htm#68227
set tcl_api_page(ns_httpopen) tapi-c68.htm#107131
set tcl_api_page(ns_httptime) tapi-c69.htm#147715
set tcl_api_page(ns_info) tapi-c70.htm#31528
set tcl_api_page(ns_insertrow) tapi-c71.htm#167015
set tcl_api_page(ns_jpegsize) tapi-c72.htm#216570
set tcl_api_page(ns_kill) tapi-c73.htm#229131
set tcl_api_page(ns_library) tapi-c74.htm#81247
set tcl_api_page(ns_link) tapi-c75.htm#175248
set tcl_api_page(ns_localsqltimestamp) tapi-c76.htm#77999
set tcl_api_page(ns_localtime) tapi-c77.htm#3844
set tcl_api_page(ns_log) tapi-c78.htm#32344
set tcl_api_page(ns_logroll) tapi-c79.htm#229429
set tcl_api_page(ns_markfordelete) tapi-c80.htm#229698
set tcl_api_page(ns_menu) tapi-c81.htm#300772
set tcl_api_page(ns_mkdir) tapi-c82.htm#59915
set tcl_api_page(ns_mktemp) tapi-c83.htm#81346
set tcl_api_page(ns_modlog) tapi-c84.htm#229969
set tcl_api_page(ns_modlogcontrol) tapi-c85.htm#229970
set tcl_api_page(ns_modulepath) tapi-c86.htm#230273
set tcl_api_page(ns_mutex) tapi-c87.htm#81432
set tcl_api_page(ns_normalizepath) tapi-c88.htm#65259
set tcl_api_page(ns_param) tapi-c89.htm#227552
set tcl_api_page(ns_parseheader) tapi-c90.htm#230562
set tcl_api_page(ns_parsehttptime) tapi-c91.htm#163542
set tcl_api_page(ns_parsequery) tapi-c92.htm#230777
set tcl_api_page(ns_passwordcheck) tapi-c93.htm#297155
set tcl_api_page(ns_perm) tapi-c94.htm#79412
set tcl_api_page(ns_permpasswd) tapi-c95.htm#296291
set tcl_api_page(ns_pooldescription) tapi-c96.htm#147140
set tcl_api_page(ns_queryexists) tapi-c97.htm#191284
set tcl_api_page(ns_queryget) tapi-c98.htm#191488
set tcl_api_page(ns_querygetall) tapi-c99.htm#235507
set tcl_api_page(ns_quotehtml) tapi-100.htm#3909
set tcl_api_page(ns_rand) tapi-101.htm#235740
set tcl_api_page(ns_register_adptag) tapi-102.htm#173981
set tcl_api_page(ns_register_filter) tapi-103.htm#148224
set tcl_api_page(ns_register_proc) tapi-104.htm#3937
set tcl_api_page(ns_register_trace) tapi-105.htm#81668
set tcl_api_page(ns_rename) tapi-106.htm#206851
set tcl_api_page(ns_requestauthorize) tapi-107.htm#86251
set tcl_api_page(ns_respond) tapi-108.htm#162338
set tcl_api_page(ns_return) tapi-109.htm#3987
set tcl_api_page(ns_rmdir) tapi-110.htm#61094
set tcl_api_page(ns_rollfile) tapi-111.htm#235966
set tcl_api_page(ns_rwlock) tapi-112.htm#200308
set tcl_api_page(ns_schedule_daily) tapi-113.htm#81743
set tcl_api_page(ns_schedule_proc) tapi-114.htm#81770
set tcl_api_page(ns_schedule_weekly) tapi-115.htm#81782
set tcl_api_page(ns_section) tapi-116.htm#227793
set tcl_api_page(ns_sema) tapi-117.htm#81850
set tcl_api_page(ns_sendmail) tapi-118.htm#48166
set tcl_api_page(ns_server) tapi-119.htm#193657
set tcl_api_page(ns_set) tapi-120.htm#197598
set tcl_api_page(ns_setexpires) tapi-121.htm#147921
set tcl_api_page(ns_set_precision) tapi-122.htm#198594
set tcl_api_page(ns_share) tapi-123.htm#147998
set tcl_api_page(ns_shutdown) tapi-124.htm#147915
set tcl_api_page(ns_sleep) tapi-125.htm#32708
set tcl_api_page(ns_sockaccept) tapi-126.htm#82156
set tcl_api_page(ns_sockblocking) tapi-127.htm#232740
set tcl_api_page(ns_sockcallback) tapi-128.htm#82176
set tcl_api_page(ns_sockcheck) tapi-129.htm#82223
set tcl_api_page(ns_socketpair) tapi-130.htm#175441
set tcl_api_page(ns_socklisten) tapi-131.htm#233605
set tcl_api_page(ns_socklistencallback) tapi-132.htm#232820
set tcl_api_page(ns_socknonblocking) tapi-133.htm#232894
set tcl_api_page(ns_socknread) tapi-134.htm#232969
set tcl_api_page(ns_sockopen) tapi-135.htm#82248
set tcl_api_page(ns_sockselect) tapi-136.htm#82277
set tcl_api_page(ns_striphtml) tapi-137.htm#32426
set tcl_api_page(ns_symlink) tapi-138.htm#175518
set tcl_api_page(ns_thread) tapi-139.htm#82563
set tcl_api_page(ns_time) tapi-140.htm#148150
set tcl_api_page(ns_tmpnam) tapi-141.htm#63417
set tcl_api_page(ns_truncate) tapi-142.htm#175579
set tcl_api_page(ns_unlink) tapi-143.htm#62276
set tcl_api_page(ns_unregister_proc) tapi-144.htm#64118
set tcl_api_page(ns_unschedule_proc) tapi-145.htm#82663
set tcl_api_page(ns_url2file) tapi-146.htm#4268
set tcl_api_page(ns_urldecode) tapi-147.htm#32587
set tcl_api_page(ns_urlencode) tapi-148.htm#32604
set tcl_api_page(ns_uudecode) tapi-149.htm#225620
set tcl_api_page(ns_uuencode) tapi-150.htm#225621
set tcl_api_page(ns_write) tapi-151.htm#32524
set tcl_api_page(ns_writecontent) tapi-152.htm#33391
set tcl_api_page(ns_writefp) tapi-153.htm#198728

##
# END Perl Script Output
#########################

set tcl_api_root "http://www.aolserver.com/docs/tcldev/"

set tcl_proc [lindex $tcl_proc 0] 

if [info exists tcl_api_page($tcl_proc)] {
    ad_returnredirect "$tcl_api_root$tcl_api_page($tcl_proc)"
    return
} else {
    set title "Tcl API Procedure Search for: \"$tcl_proc\""
    set context_bar [ad_context_bar "TCL API Search: $tcl_proc"]
}

