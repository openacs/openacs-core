ad_library {
    
    Initialize rollout email support.  See also rollout-email-procs.tcl.  

    Parameter settings summary:

    ns_section ns/server/${server}/acs/acs-rollout-support

    #EmailDeliveryMode can be:
    #  default:  Email messages are sent in the usual manner.
    #  log:      Email messages are written to the server's error log.
    #  redirect: Email messages are redirected to the addresses specified
    #      by the EmailRedirectTo parameter.  If this list is absent or
    #      empty, email messages are written to the server's error log.
    #  filter:   Email messages are sent to in the usual manner if the
    #      recipient appears in the EmailAllow parameter, otherwise they are
    #      logged.
    ns_param EmailDeliveryMode redirect
    ns_param EmailRedirectTo somenerd@yourdomain.com,othernerd@yourdomain.com
    #ns_param EmailAllow somenerd@yourdomain.com,othernerd@yourdomain.com

    @author Andrew Grumet <aegrumet@alum.mit.edu>
    @date 30 July 2002

}

switch [ns_config ns/server/[ns_info server]/acs/acs-rollout-support EmailDeliveryMode] {

    log {

	if { [ro::email::rename_ns_sendmail] } {

	    ns_log Notice "rollout-email-init.tcl: renaming ro::email::sendmail_log to ns_sendmail.  Email messages will be written to the error log instead of getting sent."

	    rename ro::email::sendmail_log ns_sendmail

	}

    }

    redirect {

	if { [ro::email::rename_ns_sendmail] } {

	    ns_log Notice "rollout-email-init.tcl: renaming ro::email::sendmail_redirect to ns_sendmail.  Email messages will be redirected to addresses specified by the EmailRedirectTo parameter of acs/acs-rollout-support ('[ns_config ns/server/[ns_info server]/acs/acs-rollout-support EmailRedirectTo]') or else logged if that parameter is not set ."

	    rename ro::email::sendmail_redirect ns_sendmail

	}

    }

    filter {

	if { [ro::email::rename_ns_sendmail] } {

	    ns_log Notice "rollout-email-init.tcl: renaming ro::email::sendmail_filter to ns_sendmail.  Email messages will be logged unless this recipient's address is listed in the EmailAllow parameter of acs/acs-rollout-support ('[ns_config ns/server/[ns_info server]/acs/acs-rollout-support EmailAllow]') ."

	    rename ro::email::sendmail_filter ns_sendmail

	}
    }
}
