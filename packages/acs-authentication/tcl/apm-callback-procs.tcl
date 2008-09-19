ad_library {
    Installation procs for authentication, account management, and password management,

    @author Lars Pind (lars@collaobraid.biz)
    @creation-date 2003-05-13
    @cvs-id $Id$
}

namespace eval auth {}
namespace eval auth::authentication {}
namespace eval auth::password {}
namespace eval auth::registration {}
namespace eval auth::get_doc {}
namespace eval auth::process_doc {}
namespace eval auth::user_info {}
namespace eval auth::search {}

ad_proc -private auth::package_install {} {} {

    db_transaction {
        # Create service contracts
        auth::authentication::create_contract
        auth::password::create_contract
        auth::registration::create_contract
        auth::get_doc::create_contract
        auth::process_doc::create_contract
        auth::user_info::create_contract
        auth::search::create_contract

        # Register local authentication implementations and update the local authority
        auth::local::install

        # Register HTTP method for GetDocument
        auth::sync::get_doc::http::register_impl

        # Register local file system method for GetDocument
        auth::sync::get_doc::file::register_impl

        # Register IMS Enterprise 1.1 ProcessDocument implementation
        auth::sync::process_doc::ims::register_impl
    }
}

ad_proc -private auth::package_uninstall {} {} {

    db_transaction {

        # Unregister IMS Enterprise 1.1 ProcessDocument implementation
        auth::sync::process_doc::ims::unregister_impl

        # Unregister HTTP method for GetDocument
        auth::sync::get_doc::http::unregister_impl

        # Unregister local file system method for GetDocument
        auth::sync::get_doc::file::unregister_impl

        # Unregister local authentication implementations and update the local authority
        auth::local::uninstall

        # Delete service contracts
        auth::authentication::delete_contract
        auth::password::delete_contract
        auth::registration::delete_contract
        auth::get_doc::delete_contract
        auth::process_doc::delete_contract
        auth::user_info::delete_contract
        auth::search::delete_contract
    }
}

ad_proc -private auth::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    After upgrade callback.
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            5.0a1 5.0a2 {
                db_transaction {

                    # Delete and recreate contract
                    auth::process_doc::delete_contract
                    auth::process_doc::create_contract

                    # The old implementation is still there, but now it's unbound

                    # We change the name of the old implementation, so we can recreate it, but don't break foreign key references to it
                    set old_impl_id [acs_sc::impl::get_id -name "IMS_Enterprise_v_1p1" -owner "acs-authentication"]
                    db_dml update { 
                        update acs_sc_impls 
                        set   impl_name = 'IMS_Enterprise_v_1p1_old' 
                        where impl_id = :old_impl_id
                    }
                    db_dml update { 
                        update acs_sc_impl_aliases
                        set impl_name = 'IMS_Enterprise_v_1p1_old' 
                        where impl_id = :old_impl_id
                    }

                    # Create the new implementation
                    set new_impl_id [auth::sync::process_doc::ims::register_impl]

                    # Update authorities that used to use the old impl to use the new impl
                    db_dml update_authorities {
                        update auth_authorities
                        set    process_doc_impl_id = :new_impl_id
                        where  process_doc_impl_id = :old_impl_id
                    }

                    # Delete the old implementation
                    acs_sc::impl::delete -contract_name "auth_sync_process" -impl_name "IMS_Enterprise_v_1p1_old"
                }
            }
            5.1.1 5.1.2d1 {
                db_transaction {

		    # this is a direct update to the SC tables, we should expect a new
		    # API for handling updates on SC, but since there's no one yet,
		    # we'll do this way now .... (roc)

		    set sc_change [list {auth_authentication.Authenticate.InputType} {auth_password.ChangePassword.InputType} {auth_password.ResetPassword.InputType}]
		    set element_msg_type_name integer

		    foreach msg_type_name $sc_change {
			set msg_type_id [db_string get_msg_type_id { select msg_type_id from acs_sc_msg_types where msg_type_name = :msg_type_name }]
			set element_pos [db_string get_pos { select max(element_pos) from acs_sc_msg_type_elements where msg_type_id = :msg_type_id }]
			incr element_pos

			acs_sc::msg_type::element::new \
			    -msg_type_name $msg_type_name \
			    -element_name authority_id \
			    -element_msg_type_name $element_msg_type_name \
			    -element_msg_type_isset_p f \
			    -element_pos $element_pos
	
		    }

		}
	    }
            5.1.5 5.2.0a1 {
                db_transaction {

		    # I will add support to MergeUser operation 
		    # this is a direct update to the SC tables, 
		    # we should expect a new API for handling updates on SC, 
		    # but since there's no one yet, we'll do it 
		    # in this way. (quio@galileo.edu)
		    ns_log notice "acs_authentication: Starting Upgrade (adding merge support)"
		    acs_sc::contract::operation::new \
			-contract_name "auth_authentication" \
			-operation "MergeUser" \
			-input { from_user_id:integer to_user_id:integer authority_id:integer } \
			-output {} \
			-description "Merges two accounts given the user_id of each one"

 		    acs_sc::impl::alias::new \
 			-contract_name "auth_authentication" \
 			-impl_name "local" \
 			-operation "MergeUser" \
 			-alias "auth::local::authentication::MergeUser" \
		     
  		    ns_log notice "acs_authentication: Finishing Upgrade (adding merge support)"

		}
	    }
            5.5.0d1 5.5.0d2 {
                auth::search::create_contract
            }

	}
}

#####
#
# auth_authentication service contract
#
#####

ad_proc -private auth::authentication::create_contract {} {
    Create service contract for authentication.
} {
    set spec {
        name "auth_authentication"
        description "Authenticate users and retrieve their account status."
        operations {
            Authenticate {
                description {
                    Validate this username/password combination, and return the result.
                    Valid auth_status codes are 'ok', 'no_account', 'bad_password', 'auth_error', 'failed_to_connect'. 
                    The last, 'failed_to_connect', is reserved for communications or implementation errors.
                    auth_message is a human-readable explanation of what went wrong, may contain HTML. 
                    Only checked if auth_status is not ok.
                    Valid account_status codes are 'ok' and 'closed'.
                    account_message may be supplied regardless of account_status, and may contain HTML.
                }
                input {
                    username:string
                    password:string
                    parameters:string,multiple
		    authority_id:integer
                }
                output {
                    auth_status:string
                    auth_message:string
                    account_status:string
                    account_message:string
                }
            }
            MergeUser {
                description {
		    Merges two accounts given the user_id of each one                 
                }
                input {
                    from_user_id:integer
                    to_user_id:integer
		    authority_id:integer
                }
                output {}
            }
            GetParameters {
                description {
                    Get an arraay-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}

ad_proc -private auth::authentication::delete_contract {} {
    Delet service contract for authentication.
} {
    acs_sc::contract::delete -name "auth_authentication"
}

#####
#
# auth_password service contract
#
#####

ad_proc -private auth::password::create_contract {} {
    Create service contract for password management.
} {
    set spec {
        name "auth_password"
        description "Update, reset, and retrieve passwords for authentication."
        operations {
            CanChangePassword {
                description {
                    Return whether the user can change his/her password through this implementation.
                    The value is not supposed to depend on the username and should be cachable.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    changeable_p:boolean
                }
                iscachable_p "t"
            }
            ChangePassword {
                description {
                    Change the user's password. 
                }
                input {
                    username:string
                    old_password:string
                    new_password:string
                    parameters:string,multiple
		    authority_id:integer
                }
                output {
                    password_status:string
                    password_message:string
                }
            }
            CanRetrievePassword {
                description {
                    Return whether the user can retrieve his/her password through this implementation.
                    The value is not supposed to depend on the username and should be cachable.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    retrievable_p:boolean
                }
                iscachable_p "t"
            }
            RetrievePassword {
                description {
                    Retrieve the user's password. The implementation can either return the password, in which case
                    the authentication API will email the password to the user. Or it can email the password
                    itself, in which case it would return the empty string for password.
                }
                input {
                    username:string
                    parameters:string,multiple
                }
                output {
                    password_status:string
                    password_message:string
                    password:string
                }
            }
            CanResetPassword {
                description {
                    Return whether the user can reset his/her password through this implementation.
                    The value is not supposed to depend on the username and should be cachable.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    resettable_p:boolean
                }
                iscachable_p "t"
            }
            ResetPassword {
                description {
                    Reset the user's password to a new, randomly generated value. 
                    The implementation can either return the password, in which case
                    the authentication API will email the password to the user. Or it can email the password
                    itself, in which case it would return the empty string.
                }
                input {
                    username:string
                    parameters:string,multiple
		    authority_id:integer
                }
                output {
                    password_status:string
                    password_message:string
                    password:string
                }
            }
            GetParameters {
                description {
                    Get an arraay-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}

ad_proc -private auth::password::delete_contract {} {
    Delete service contract for password management.
} {
    acs_sc::contract::delete -name "auth_password"
}


#####
#
# auth_registration service contract
#
#####

ad_proc -private auth::registration::create_contract {} {
    Create service contract for account registration.
} {
    set spec {
        name "auth_registration"
        description "Registering accounts for authentication"
        operations {
            GetElements {
                description {
                    Get a list of required and a list of optional fields available when registering accounts through this
                    service contract implementation.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    requiered:string,multiple
                    optional:string,multiple
                }
            }
            Register {
                description {
                    Register a new account. Valid status codes are: 'ok', 'data_error', and 'reg_error', and 'fail'.
                    'data_error' means that the implementation is returning an array-list of element-name, message 
                    with error messages for each individual element. 'reg_error' is any other registration error, 
                    and 'fail' is reserved to communications or implementation errors.
                }
                input {
                    parameters:string,multiple
                    username:string
                    authority_id:integer
                    first_names:string
                    last_name:string
                    screen_name:string
                    email:string
                    url:string
                    password:string
                    secret_question:string
                    secret_answer:string
                }
                output {
                    creation_status:string
                    creation_message:string
                    element_messages:string,multiple
                    account_status:string
                    account_message:string
                }
            }
            GetParameters {
                description {
                    Get an array-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}


ad_proc -private auth::registration::delete_contract {} {
    Delete service contract for account registration.
} {
    acs_sc::contract::delete -name "auth_registration"
}


#####
#
# auth_get_doc service contract
#
#####

ad_proc -private auth::get_doc::create_contract {} {
    Create service contract for account registration.
} {
    set spec {
        name "auth_sync_retrieve"
        description "Retrieve a document, e.g. using HTTP, SMP, FTP, SOAP, etc."
        operations {
            GetDocument {
                description {
                    Retrieves the document. Returns doc_status of 'ok', 'get_error', or 'failed_to_connect'. 
                    If not 'ok', then it should  set doc_message to explain the problem. If 'ok', it must set
                    document to the document retrieved, and set snapshot_p to t if it has retrieved a snapshot document.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    doc_status:string
                    doc_message:string
                    document:string
                    snapshot_p:string
                }
            }
            GetParameters {
                description {
                    Get an array-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}


ad_proc -private auth::get_doc::delete_contract {} {
    Delete service contract for account registration.
} {
    acs_sc::contract::delete -name "auth_sync_retrieve"
}



#####
#
# auth_process_doc service contract
#
#####

ad_proc -private auth::process_doc::create_contract {} {
    Create service contract for account registration.
} {
    set spec {
        name "auth_sync_process"
        description "Process a document containing user information from a remote authentication authority"
        operations {
            ProcessDocument {
                description {
                    Process a user synchronization document.
                }
                input {
                    job_id:integer
                    document:string
                    parameters:string,multiple
                }
            }
            GetAcknowledgementDocument {
                description {
                    Return an acknowledgement document in a format suitable for display on.
                }
                input {
                    job_id:integer
                    document:string
                    parameters:string,multiple
                }
            }
            GetElements {
                description {
                    Get an list of the elements handled by this batch synchronization
                    (first_names, last_name, username, email, etc). These elements will 
                    not be editable by the user, so as not to risk overwriting the user's 
                    changes with a later synchronization.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    elements:string,multiple
                }
            }
            GetParameters {
                description {
                    Get an array-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}


ad_proc -private auth::process_doc::delete_contract {} {
    Delete service contract for account registration.
} {
    acs_sc::contract::delete -name "auth_sync_process"
}




#####
#
# auth_user_info service contract
#
#####

ad_proc -private auth::user_info::create_contract {} {
    Create service contract for account registration.
} {
    set spec {
        name "auth_user_info"
        description "Get information about a user in real-time"
        operations {
            GetUserInfo {
                description {
                    Request information about a user. Returns info_status 'ok', 'no_account', 'info_error', or 'failed_to_connect'. 
                    info_message is a human-readable explanation to the user. 
                }
                input {
                    username:string
                    parameters:string,multiple
                }
                output {
                    info_status:string
                    info_message:string
                    user_info:string,multiple
                }
            }
            GetParameters {
                description {
                    Get an array-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}


ad_proc -private auth::user_info::delete_contract {} {
    Delete service contract for account registration.
} {
    acs_sc::contract::delete -name "auth_user_info"
}


#####
#
# auth_search service contract
#
#####

ad_proc -private auth::search::create_contract {} {
    Create service contract for authority searches.
} {
    set spec {
        name "auth_search"
        description "Search users in given authority"
        operations {
            Search {
                description {
                    Search authority using "search" string. Returns array-list of usernames.
                }
                input {
                    search:string
                    parameters:string,multiple
                }
                output {
                    usernames:string,multiple
                }
            }
            GetParameters {
                description {
                    Get an array-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
	    FormInclude {
		description {
		    File location of an includable search form
		} 
		output {
		    form_include:string
		}
	    }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}


ad_proc -private auth::search::delete_contract {} {
    Delete service contract for authority search.
} {
    acs_sc::contract::delete -name "auth_search"
}
