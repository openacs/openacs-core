ad_library {
    
    Rollout support email procs.  These procs help manage differing
    email behavior on dev/staging/production.

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

namespace eval ro::email {

    ad_proc -private get_template {} {

	Returns a template for displaying email messages that would
        have been sent in default delivery mode.  It expects the following
        variables to be set in the calling environment:
   	to, from, subject, body.

	Usage pattern:

	set message [ro::email::get_template]
	some_proc [subst $message]

    } { 

	return {
****************************************
To: $to
From: $from
Subject: $subject

$body
****************************************}
    }
	
	
    ad_proc -private sendmail_log {
	to from subject body {extraheaders {}} {bcc {}}
    } {

	Writes email messages to the error log instead of sending them.

	@author Andrew Grumet <aegrumet@alum.mit.edu>
	@date 29 July 2002

    } {

	ns_log Notice "ro::email::sendmail_log:  Logging email instead of sending:
[subst [ro::email::get_template]]"

        return 1
    }

    ad_proc -private sendmail_redirect {
	to from subject body {extraheaders {}} {bcc {}}
    } {

	Redirects email to the addresses listed in the EmailRedirectTo
	parameter.

	@author Andrew Grumet <aegrumet@alum.mit.edu>
	@date 29 July 2002

    } {
	set targets [ns_config ns/server/[ns_info server]/acs/acs-rollout-support EmailRedirectTo]
	if { ![string equal $targets ""] } {
	    set body "The following email would have been sent from \"[ad_parameter SystemName]\", but
was instead redirected to you.

[subst [ro::email::get_template]]
"

            return [_old_ns_sendmail $targets $from $subject $body $extraheaders $bcc]
        } else {
	    return [ro::email::sendmail_log $to $from $subject $body $extraheaders $bcc]
	}
    }


    ad_proc -private sendmail_filter {
	to from subject body {extraheaders {}} {bcc {}}
    } {

	Email messages are sent to in the usual manner if the
	recipient appears in the EmailAllow parameter, otherwise they are
	logged.

	@author Andrew Grumet <aegrumet@alum.mit.edu>
	@date 29 July 2002

    } {
	set allowed [ns_config ns/server/[ns_info server]/acs/acs-rollout-support EmailAllow]

        # make sure we are comparing just the email address portion
        # not a@b.com and a@b.com (Abc Def)
        # note this takes out the name part as a side effect. -jfr
        regexp {([a-zA-Z0-9][^ @]*)@([a-zA-Z0-9_.-]+\.[a-zA-Z]{2,6})} $to match beginning end
        set to_for_comparison "${beginning}@${end}"

	if { [lsearch [split $allowed ,] $to_for_comparison] >= 0 } {

	    return [_old_ns_sendmail $to_for_comparison $from $subject $body $extraheaders $bcc]
	} else {
	    return [ro::email::sendmail_log $to_for_comparison $from $subject $body $extraheaders $bcc]
	}
    }

    ad_proc -private rename_ns_sendmail {} {

        Renames ns_sendmail to _old_ns_sendmail if _old_ns_sendmail
        doesn't already exist.  Returns 1 if successful, 0 otherwise.

        @author Andrew Grumet <aegrumet@alum.mit.edu>
        @date 6 June 2003

    } {
        ns_log Notice "rollout-email-procs.tcl: renaming ns_sendmail to _old_ns_sendmail."
        if { [catch {
            #We have to execute this code in the global namespace
            #because otherwise _old_ns_sendmail will land in ro::email.
            namespace eval :: { rename ns_sendmail _old_ns_sendmail }
        } errMsg] } {
            ns_log Notice "rollout-email-procs.tcl: rename failed!  Error message: '$errMsg'"
            return 0
        }
        return 1
    }
}
