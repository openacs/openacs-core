# packages/acs-mail-lite/lib/email.tcl
# Template for email inclusion
# @author Malte Sussdorff (sussdorff@sussdorff.de)
# @creation-date 2005-06-14
# @arch-tag: 48fe00a8-a527-4848-b5de-0f76dfb60291
# @cvs-id $Id$

foreach required_param {party_ids} {
    if {![info exists $required_param]} {
	return -code error "$required_param is a required parameter."
    }
}
foreach optional_param {return_url content} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

foreach party_id $party_ids {
    lappend recipients "<a href=\"[contact::url -party_id $party_id]\">[contact::name -party_id $party_id]</a>"
}
set recipients [join $recipients ", "]

set form_elements {
    message_id:key
    party_ids:text(hidden)
    return_url:text(hidden)
    {message_type:text(hidden) {value "email"}}
    {to:text(inform),optional {label "[_ contacts.Recipients]"} {value $recipients}}
}

append form_elements {
    {subject:text(text),optional
	{label "[_ contacts.Subject]"}
	{html {size 55}}
    }
    {content:text(textarea),optional
	{label "[_ contacts.Message]"}
	{html {cols 55 rows 18}}
    }
    {upload_file:file(file),optional
	{label "[_ contacts.Upload_File]"}
    }
}

ad_form -action message \
    -html {enctype multipart/form-data} \
    -name email \
    -cancel_label "[_ contacts.Cancel]" \
    -cancel_url $return_url \
    -edit_buttons {{"Send" send}} \
    -form $form_elements \
    -on_request {
    } -new_request {
    } -edit_request {
    } -on_submit {
	set from [ad_conn user_id]
	set from_addr [cc_email_from_party $user_id]
	template::multirow create messages message_type to_addr subject content

	# Insert the uploaded file linked under the package_id
	
	set package_id [ad_conn package_id]

	set revision_id [template::util::file::store_for_party -package_id $package_id -upload_file $upload_file -party_id $party_id]

	if {[exists_and_not_null revision_id]} {
	    if {[exists_and_not_null file_ids]} {
		append file_ids ",$revision_id"
	    } else {
		set file_ids $revision_id
	    }

	}

	# Send the mail to all parties.
	foreach party_id $party_ids {
	    set name [contact::name -party_id $party_id]
	    set first_names [lindex $name 0]
	    set last_name [lindex $name 1]
	    set date [lc_time_fmt [dt_sysdate] "%q"]
	    set to $name
	    set to_addr [cc_email_from_party $party_id]
	    if {[empty_string_p $to_addr]} {
		break
	    }
	    set values [list]
	    foreach element [list first_names last_name name date] {
		lappend values [list "{$element}" [set $element]]
	    }
	    template::multirow append messages $message_type $to_addr [contact::util::interpolate -text $subject -values $values] [contact::util::interpolate -text $content -values $values]

	    # Link the file to all parties
	    if {[exists_and_not_null revision_id]} {
		application_data_link::new -this_object_id $revision_id -target_object_id $party_id
	    }
	}

	template::multirow foreach messages {
	    if {[exists_and_not_null file_ids]} {
		acs_mail_lite::complex_send -to_addr $to_addr -from_addr "$from_addr" -subject "$subject" -body "$content" -package_id $package_id -file_ids $file_ids
	    } else {
		acs_mail_lite::send -to_addr $to_addr -from_addr "$from_addr" -subject "$subject" -body "$content" -package_id $package_id
	    }
	}

    } -after_submit {
	
	ad_returnredirect $return_url
    }