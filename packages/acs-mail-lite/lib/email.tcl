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

foreach optional_param {return_url content export_vars file_ids object_id} {
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

if {![info exists no_callback_p]} {
    set no_callback_p f
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
set recipients_num [llength $recipients]
if { $recipients_num <= 1 } {
    set form_elements {
	message_id:key
	return_url:text(hidden)
	no_callback_p:text(hidden)
	title:text(hidden),optional
	{message_type:text(hidden) {value "email"}}
	{to:text(checkbox),multiple 
	    {label "[_ contacts.Recipients]"} 
	    {options  $recipients }
	    {html {checked 1}}
	    {section "[_ contacts.Recipients]"}
	}
	{cc:text(text),optional
	    {label "CC:"} 
	    {html {size 56}}
	    {help_text "[_ contacts.cc_help]"}
	}
    }
} else {
    set form_elements {
	message_id:key
	return_url:text(hidden)
	no_callback_p:text(hidden)
	title:text(hidden),optional
	{message_type:text(hidden) {value "email"}}
	{check_uncheck:text(checkbox),multiple,optional
	    {label "[_ contacts.check_uncheck]"}
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
}


if { [exists_and_not_null file_ids] } {
    set files [list]
    foreach file $file_ids {
	set file_title [db_string get_file_title { select title from cr_revisions where revision_id = :file} -default "Untitled"]
	lappend files "<a href=\"/tracking/download/$file_title?version_id=$file\">$file_title</a> "
    }
    set files [join $files ", "]

    append form_elements {
        {files_ids:text(inform),optional {label "[_ contacts.Associated_files]"} {value $files}}
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
    {content_body:text(richtext),optional
	{label "[_ contacts.Message]"}
	{html {cols 55 rows 18}}
	{value $content_list}
    }
    {upload_file:file(file),optional
	{label "[_ contacts.Upload_File]"}
    }
}

if { ![exists_and_not_null action] } {
    set action [ad_conn url]
}

ad_form -action $action \
    -html {enctype multipart/form-data} \
    -name email \
    -cancel_label "[_ contacts.Cancel]" \
    -cancel_url $cancel_url \
    -edit_buttons {{"Send" send}} \
    -form $form_elements \
    -on_request {
    } -new_request {
	if {[exists_and_not_null folder_id]} {
            callback contacts::email_subject -folder_id $folder_id
        }
        if {[exists_and_not_null item_id]} {
            contact::message::get -item_id $item_id -array message_info
            set subject $message_info(description)
            set content_body [ad_html_text_convert \
                             -to "text/plain" \
                             -from $message_info(content_format) \
                             -- $message_info(content) \
			     ]
            set title $message_info(title)
        }
        if {[exists_and_not_null signature_id]} {
            set signature [contact::signature::get -signature_id $signature_id]
            if { [exists_and_not_null signature] } {
		append content_body "{<br><br> $signature } text/html"
            }
        }
    } -edit_request {
    } -on_submit {
	# List to store know wich emails recieved the message
	set recipients_addr [list]

	set from [ad_conn user_id]
	set from_addr [cc_email_from_party $from]

	# Remove all spaces in cc
	regsub -all " " $cc "" cc

	set cc_list [split $cc ";"]

	template::multirow create messages message_type to_addr subject content_body

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
	    lappend recipients_addr $to_addr

	    if {[empty_string_p $to_addr]} {
                # We are going to check if this party_id has an employer and if this
                # employer has an email
                set employer_id [relation::get_object_two -object_id_one $party_id \
                                     -rel_type "contact_rels_employment"]
                if { ![empty_string_p $employer_id] } {
                    # Get the employer email adress
                    set to_addr [contact::email -party_id $employer_id]
                    if {[empty_string_p $to_addr]} {
                        ad_return_error [_ contacts.Error] [_ contacts.lt_there_was_an_error_processing_this_request]
                        break
                    }
                } else {
                    ad_return_error [_ contacts.Error] [_ contacts.lt_there_was_an_error_processing_this_request]
                    break
                }
            }
	    set values [list]
	    foreach element [list first_names last_name name date] {
		lappend values [list "{$element}" [set $element]]
	    }
	    template::multirow append messages $message_type $to_addr [contact::message::interpolate -text $subject -values $values] [contact::message::interpolate -text $content_body -values $values]

	    # Link the file to all parties
	    if {[exists_and_not_null revision_id]} {
		application_data_link::new -this_object_id $revision_id -target_object_id $party_id
	    }
	}

	# Send the email to all CC in cc_list
	foreach email_addr $cc_list {
	    set name $email_addr
	    set first_names [split $email_addr "@"]
	    set last_name $first_names
	    set date [lc_time_fmt [dt_sysdate] "%q"]
	    set to $name
	    set to_addr $email_addr
	    lappend recipients_addr $to_addr

	    set values [list]
	    foreach element [list first_names last_name name date] {
		lappend values [list "{$element}" [set $element]]
	    }
	    template::multirow append messages $message_type $to_addr [contact::message::interpolate -text $subject -values $values] [contact::message::interpolate -text $content_body -values $values]

	}

	template::multirow foreach messages {
	    if {[exists_and_not_null file_ids]} {
		# If the no_callback_p is set to "t" then no callback will be executed
		if { $no_callback_p } {

		    acs_mail_lite::complex_send \
			-to_addr $to_addr \
			-from_addr "$from_addr" \
			-subject "$subject" \
			-body "$content_body" \
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
			-body "$content_body" \
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
			    -body "$content_body" \
			    -package_id $package_id \
			    -mime_type $mime_type \
			    -object_id $object_id \
			    -no_callback_p

		    } else {

			acs_mail_lite::complex_send \
			    -to_addr $to_addr \
			    -from_addr "$from_addr" \
			    -subject "$subject" \
			    -body "$content_body" \
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
				-body "$content_body" \
				-package_id $package_id \
				-mime_type "text/html" \
				-object_id $object_id \
				-no_callback_p
			} else {

			    acs_mail_lite::complex_send \
				-to_addr $to_addr \
				-from_addr "$from_addr" \
				-subject "$subject" \
				-body "$content_body" \
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
				-body "$content_body" \
				-package_id $package_id \
				-no_callback_p

			} else {
			    acs_mail_lite::send \
				-to_addr $to_addr \
				-from_addr "$from_addr" \
				-subject "$subject" \
				-body "$content_body" \
				-package_id $package_id 
			}
			
		    }
		}
	    }

	    contact::message::log \
                -message_type "email" \
                -sender_id $from \
                -recipient_id $party_id \
                -title $title \
                -description $subject \
                -content $content_body \
                -content_format "text/plain"
	    
            lappend recipients "<a href=\"[contact::url -party_id $party_id]\">$to</a>"
	    
	}

	set recipients [join $recipients_addr ", "]
        util_user_message -html -message "[_ contacts.Your_message_was_sent_to_-recipients-]"

    } -after_submit {
	
	ad_returnredirect $return_url
    }
