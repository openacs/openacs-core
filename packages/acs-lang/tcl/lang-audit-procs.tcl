#/packages/acs-lang/tcl/lang-message-procs.tcl
ad_library {

    Auditing of lang_messages

    @creation-date 15 October 2000
    @author Peter Marklund (peter@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval lang::audit {

    ad_proc -public changed_message { 
        old_message
        package_key
        message_key
        locale
    } {
      Save a message that is overwritten.
      @author Peter Marklund
    } {
        # Save the old message in the audit table
        set overwrite_user [ad_conn user_id]
        db_dml lang_message_audit {
          insert into lang_messages_audit (package_key, message_key, locale, message, overwrite_user) 
            values (:package_key, :message_key, :locale, empty_clob(), :overwrite_user) 
          returning message into :1
        } -clobs [list $old_message]
    }    

    ad_proc -public created_message { 
        package_key
        message_key
        locale
    } {
      Keep track of who added a translation and when
      @author Peter Marklund
    } {
        set user_id [ad_conn user_id]
        db_dml lang_message_audit_create {
            insert into lang_messages_created (package_key, message_key, locale, creation_user)
               values (:package_key, :message_key, :locale, :user_id)
        }
    }    
}
