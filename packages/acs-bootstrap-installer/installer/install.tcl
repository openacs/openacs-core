##############
#
# Get configuration parameters
#
#############

install_page_contract [install_mandatory_params] [install_optional_params]

# Default all system emails to the administrators email
foreach var_name {system_owner admin_owner host_administrator outgoing_sender new_registrations} {
    if { [set $var_name] eq "" } {
        set $var_name $email
    }
}

##############
#
# System setting validation
#
#############

if {$password ne $password_confirmation  } {
    install_return 200 "Passwords Don't Match" [subst {
The passwords you've entered don't match. 
[install_back_button_widget]
    }]
    return
}

##############
#
# Install data model
#
#############

ns_write [install_header 200 ""]

if { ![install_good_data_model_p] } {
    install_do_data_model_install
} else {
    ns_write "Kernel data model already installed."
    # If kernel is installed it probably means this page has already been requested,
    # let's exit
    return
}

##############
#
# Install packages
#
#############

install_do_packages_install

if { $username eq "" } {
    set username $email
}

if { ![db_string user_exists {
    select count(*) from parties where email = lower(:email)
}] } {

  db_transaction {
    
    # Can't use auth::create_user
    # Operation GetParameters is not implemented in 'local' implementation of contract 'auth_registration'
    # set user_id [auth::create_user \
    # 		     -email $email \
    # 		     -first_names $first_names \
    # 		     -last_name $last_name \
    # 		     -password $password \
    # 		     -email_verified_p "t" \
    # 		     -username $username ]
    

    # Can't use auth::create_local_account, account does not work
    # array set user [list email $email first_names $first_names \
    # 			last_name $last_name password $password email_verified_p "t"]
    # array set creation_info [auth::create_local_account \
    # 				 -authority_id [auth::authority::local] \
    # 				 -username $username \
    # 				 -array user]
    # if {$creation_info(creation_status) eq "ok"} {
    #   set user_id $creation_info(user_id)
    # }

    # .. so use the low level helper
    set user_id [auth::create_local_account_helper \
    		     $email \
    		     $first_names \
    		     $last_name \
    		     $password \
    		     "" \
    		     "" \
    		     "" \
    		     "t" \
    		     "approved" \
    		     "" \
    		     $username ]

    if { !$user_id } {

	install_return 200 "Unable to Create Administrator" [subst {
Unable to create the site-wide administrator:
<blockquote><pre>[ns_quotehtml $::errorInfo]</pre></blockquote>
[install_back_button_widget]            
}
        return
    }

    # stub util_memoize_flush...
    rename util_memoize_flush util_memoize_flush_saved
    proc util_memoize_flush {args} {}
    permission::grant -party_id $user_id -object_id [acs_lookup_magic_object security_context_root] -privilege "admin"
    # nuke stub 
    rename util_memoize_flush {}
    rename util_memoize_flush_saved util_memoize_flush
  }
  ad_conn -set user_id $user_id
}

# Now process the application bundle if an install.xml file was found.

if { [file exists "$::acs::rootdir/install.xml"] } {
    set output [apm::process_install_xml "/install.xml" {}]
    ns_write "<p>[join $output "</p><p>"]</p>"
}


##############
#
# Load message catalogs
#
#############


# Doing this before restart so that keys are available in init files on startup
ns_write "<p>Loading message catalogs..."
lang::catalog::import -initialize
ns_write "  <p>Done.<p>"

##############
#
# Secret tokens
#
#############

ns_write "<p>Generating secret tokens..."
populate_secret_tokens_db
ns_write "  <p>Done.<p>"

##############
#
# System settings
#
#############

set kernel_id [db_string acs_kernel_id_get {
    select package_id from apm_packages
    where package_key = 'acs-kernel'
}]

foreach { var param } {
    system_url SystemURL
    system_name SystemName
    publisher_name PublisherName
    system_owner SystemOwner
    admin_owner AdminOwner
    host_administrator HostAdministrator
    outgoing_sender OutgoingSender
} {
    parameter::set_value -parameter $param -value [set $var] -package_id $kernel_id
}

# set the Main Site RestrictToSSL parameter

set main_site_id [subsite::main_site_id]

parameter::set_value -parameter RestrictToSSL -package_id  $main_site_id -value "acs-admin/*" 
parameter::set_value -parameter NewRegistrationEmailAddress -package_id $main_site_id -value $new_registrations 

# We're done - kill the server (will restart if server is setup properly)
ad_schedule_proc -thread t -once t 1 ns_shutdown

set post_installation_message \
    [parameter::get_from_package_key -package_key acs-bootstrap-installer \
     -parameter post_installation_message \
     -default ""]

ns_write "<b>Installation finished</b>

<p> The server has been shut down. Normally, it should come back up by itself after a minute or so. </p>

<p> If not, please check your server error log, or contact your system administrator. </p>"

if { $post_installation_message ne "" } {
    ns_write $post_installation_message
} else {
    ns_write "
<p> When the server is back up you can visit <a href=\"/acs-admin/\">the site-wide administration pages</a> </p>"
}

ns_write [install_footer]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
