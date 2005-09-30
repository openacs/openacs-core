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

foreach optional_param {return_url content export_vars file_ids object_id no_callback_p} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

if {![info exists mime_type]} {
    set mime_type "text/plain"
}
if {![info exists cancel_url]} {
    set cancel_url $return_url
}

# Somehow when the form is submited the party_ids values became
# only one element of a list, this avoid that problem

set recipients [list]
foreach party_id $party_ids {
    if {![empty_string_p $party_id]} {
	lappend recipients [list "<a href=\"[contact::url -party_id $party_id]\">[contact::name -party_id $party_id]</a> 
                             ([cc_email_from_party $party_id])" $party_id]
    }
}

# The element check_uncheck only calls a javascript function
# to check or uncheck all recipients
set form_elements {
    message_id:key
    return_url:text(hidden)
    {message_type:text(hidden) {value "email"}}
    {check_uncheck:text(checkbox),multiple,optional
	{label "Check/Uncheck"}
	{options {{"" 1}}}
	{section "[_ contacts.Recipients]"}
	{html {onclick check_uncheck_boxes(this.checked)}}
    }
    {to:text(checkbox),multiple 
	{label "[_ contacts.Recipients]"} 
	{options  $recipients }
	{html {checked 1}}
    }
}


if { [exists_and_not_null file_ids] } {
    set files [list]
    foreach file $file_ids {
	set file_title [db_string get_file_title { select title from cr_revisions where revision_id = :file} -default "Untitled"]
	lappend files "<a href=\"/file-storage/download/?file_id=$file\">$file_title</a> "
    }
    set files [join $files ", "]

    append form_elements {
        {files_ids:text(inform),optional {label "Associated Files:"} {value $files}}
    }
}



foreach var $export_vars {
    upvar $var var_value

    # We need to split to construct the element with two lappends
    # becasue if we put something like this {value $value} the value
    # of the variable is not interpreted

    set element [list]
    lappend element "${var}:text(hidden)"
    lappend element "value $var_value"
    
    # Adding the element to the form
    lappend form_elements $element
}

set content_list [list $content $mime_type]

append form_elements {
    {subject:text(text),optional
	{label "[_ contacts.Subject]"}
	{html {size 55}}
	{section "[_ contacts.Message]"}
    }
    {content:text(richtext),optional
	{label "[_ contacts.Message]"}
	{html {cols 55 rows 18}}
	{value $content_list}
    }
    {upload_file:file(file),optional
	{label "[_ contacts.Upload_File]"}
    }
}

ad_form -action [ad_conn url] \
    -html {enctype multipart/form-data} \
    -name email \
    -cancel_label "[_ contacts.Cancel]" \
    -cancel_url $cancel_url \
    -edit_buttons {{"Send" send}} \
    -form $form_elements \
    -on_request {
    } -new_request {
    } -edit_request {
    } -on_submit {
	set from [ad_conn user_id]
	set from_addr [cc_email_from_party $from]
	template::multirow create messages message_type to_addr subject content

	# Insert the uploaded file linked under the package_id
	set package_id [ad_conn package_id]
	
	if {![empty_string_p $upload_file] } {
	    set revision_id [content::item::upload_file -package_id $package_id -upload_file $upload_file -parent_id $party_id]
	}

	if {[exists_and_not_null revision_id]} {
	    if {[exists_and_not_null file_ids]} {
		append file_ids " $revision_id"
	    } else {
		set file_ids $revision_id
	    }

	}

	# Send the mail to all parties.
	foreach party_id $to {
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
	    template::multirow append messages $message_type $to_addr [contact::message::interpolate -text $subject -values $values] [contact::message::interpolate -text $content -values $values]

	    # Link the file to all parties
	    if {[exists_and_not_null revision_id]} {
		application_data_link::new -this_object_id $revision_id -target_object_id $party_id
	    }
	}

	

	template::multirow foreach messages {
	    if {[exists_and_not_null file_ids]} {
		
		# If the no_callback_p is set to "t" then no callback will be executed
		if { $no_callback_p } {

		    acs_mail_lite::complex_send \
			-to_addr $to_addr \
			-from_addr "$from_addr" \
			-subject "$subject" \
			-body "$content" \
			-package_id $package_id \
			-file_ids $file_ids \
			-mime_type $mime_type \
			-object_id $object_id \
			-no_callback_p

		} else {

		    acs_mail_lite::complex_send \
			-to_addr $to_addr \
			-from_addr "$from_addr" \
			-subject "$subject" \
			-body "$content" \
			-package_id $package_id \
			-file_ids $file_ids \
			-mime_type $mime_type \
			-object_id $object_id

		}

	    } else {

		# acs_mail_lite does not know about sending the
		# correct mime types....
		if {$mime_type == "text/html"} {


		    if { $no_callback_p } {
			# If the no_callback_p is set to "t" then no callback will be executed			
			acs_mail_lite::complex_send \
			    -to_addr $to_addr \
			    -from_addr "$from_addr" \
			    -subject "$subject" \
			    -body "$content" \
			    -package_id $package_id \
			    -mime_type $mime_type \
			    -object_id $object_id \
			    -no_callback_p

		    } else {

			acs_mail_lite::complex_send \
			    -to_addr $to_addr \
			    -from_addr "$from_addr" \
			    -subject "$subject" \
			    -body "$content" \
			    -package_id $package_id \
			    -mime_type $mime_type \
			    -object_id $object_id

		    }
		    
		} else {
		    if { [exists_and_not_null object_id] } {
			# If the no_callback_p is set to "t" then no callback will be executed
			if { $no_callback_p } {
			    acs_mail_lite::complex_send \
				-to_addr $to_addr \
				-from_addr "$from_addr" \
				-subject "$subject" \
				-body "$content" \
				-package_id $package_id \
				-mime_type "text/html" \
				-object_id $object_id \
				-no_callback_p
			} else {

			    acs_mail_lite::complex_send \
				-to_addr $to_addr \
				-from_addr "$from_addr" \
				-subject "$subject" \
				-body "$content" \
				-package_id $package_id \
				-mime_type "text/html" \
				-object_id $object_id 
			}
		    } else {
			
			if { $no_callback_p } {
			    # If the no_callback_p is set to "t" then no callback will be executed
			    acs_mail_lite::send \
				-to_addr $to_addr \
				-from_addr "$from_addr" \
				-subject "$subject" \
				-body "$content" \
				-package_id $package_id \
				-no_callback_p

			} else {
			    acs_mail_lite::send \
				-to_addr $to_addr \
				-from_addr "$from_addr" \
				-subject "$subject" \
				-body "$content" \
				-package_id $package_id 
			}
			
		    }
		}
	    }
	}

    } -after_submit {
	
	ad_returnredirect $return_url
    }
