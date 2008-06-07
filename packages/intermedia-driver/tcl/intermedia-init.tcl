# 

ad_library {
    
    Scheduled proc init for intermedia driver
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2008-04-15
    @cvs-id $Id$
}

ad_schedule_proc -thread t 14400 db_exec_plsql optimize_intermedia_index {begin Ctx_Ddl.Optimize_Index ('swi_index','FAST'); end;}
