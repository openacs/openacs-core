#######################################################################
#
# Things you will probably want to inspect and change
#
#######################################################################


#---------------------------------------------------------------------
# the name of your service (site).
# It will be used as the name of directories, the name of database
# users and/or tablespaces, etc.

set server                    "service0"

#---------------------------------------------------------------------
# Server root directory. This is where all of the files for your server 
# will live.

set serverroot                "/web/${server}"

#---------------------------------------------------------------------
# The host name (DNS) the server will be listening on
set server_host               yourserver.test

#---------------------------------------------------------------------
# The IP address the server will be listening on
set server_ip                 127.0.0.1

#---------------------------------------------------------------------
# The port number the server will be listening on
set server_port               8000

#---------------------------------------------------------------------
# The URL where your server will be accessible. 
# This is used by the installation scripts to complete the installation.
# Don't forget to include the port number above
set server_url                "http://${server_ip}:${server_port}"

#---------------------------------------------------------------------
# OS user and group that AOLserver runs as. We recommend that you
# create a new user for your server.
# If you do not want to do that, change the user name below
set aolserver_user            "nsadmin"
set aolserver_group           "web"

#---------------------------------------------------------------------
# OpenACS configuration
set admin_email               "admin@yourserver.test"
set admin_username            "admin"
set admin_first_names         "Admin"
set admin_last_name           "User"
set admin_password            "1"
set system_name               "An OpenACS Development Server"
set publisher_name            "An OpenACS Developer"

#---------------------------------------------------------------------
# Should we automatically grab the OpenACS code from CVS?
# If not, you must have already unpacked a tar-ball in the server root
# directory specified above

set do_checkout               "yes"

#---------------------------------------------------------------------
# Which branch or symbolic tag should we use for the checkout
# For example, say "HEAD" to get the latest code, oacs-5-0-0 to get
# the 5.0.0 release.

set oacs_branch               "HEAD"

#---------------------------------------------------------------------
# Choose which database you will use - Say 'oracle' or 'postgres'

set database                  "postgres"


#----------------------------------------------------------------------
# Database configuration - PostgreSQL
#----------------------------------------------------------------------

#---------------------------------------------------------------------
# Name of the user to use when connecting to the database
set pg_db_user                "postgres"

#---------------------------------------------------------------------
# Name of the PostgreSQL database. Will be created.
set db_name                   ${server}

#---------------------------------------------------------------------
# The host running PostgreSQL
set pg_host                   localhost

#---------------------------------------------------------------------
# The port PostgreSQL is running on. Default PostgreSQL port is 5432.
set pg_port                   5432

#---------------------------------------------------------------------
# The home directory of your PostgreSQL server. Type 'which psql' to find this.
set pg_bindir                 "/usr/local/pgsql/bin"


#----------------------------------------------------------------------
# Database configuration - Oracle
#----------------------------------------------------------------------

# The name of the Oracle user and tablespace. Will get created.
set db_name                   ${server}

# Password for the Oracle user
set oracle_password           ${db_name}

# The system user account and password. We need this to create the tablespace and user above.
set system_user               "system"
set system_user_password      "manager"



#######################################################################
#
# Things you don't want to change if you're doing a standard install
#
#######################################################################

# Path to AOLserver config.tcl file to use. If you don't specify any file here, we will use the default config file.
set aolserver_config_file ""

# The path to the server's error log file, so we can look for errors during installation
set error_log_file "${serverroot}/log/error.log"

# TCLWebTest home directory
set tclwebtest_dir "/usr/local/tclwebtest"

# AOLserver's home directory
set aolserver_home "/usr/local/aolserver"


#----------------------------------------------------------------------
# Settings for starting and stopping the server
#----------------------------------------------------------------------

# The default server control parameters use daemontools
set use_daemontools "true"

# Do 'which svc' to find where the svc binary is installed
set svc_bindir "/usr/local/bin"

# This is the directory which daemontools scans for services to supervies. 
# Normally it's /service, though there has been talk about moving it to /var/lib/svacan.
# Do not use trailing slash.
set svscanroot "/service/${server}"

# This is the directory under your server's root dir which we should link to from the 
# svscanroot directory.
set svscan_sourcedir "$serverroot/etc/daemontools"

# alternate server startup commands
# enable these commands to run without daemontools
set start_server_command "exec /usr/local/aolserver/bin/nsd-postgres -it $serverroot/etc/config.tcl -u $aolserver_user -g $aolserver_group"
set stop_server_command "killall nsd"
set restart_server_command "${stop_server_command}; ${start_server_command}"

# Estimated number of seconds from the startup command is executed until the server is actually up
set startup_seconds 20
# Estimated number of seconds from the shutdown command is executed until the server is actually down
set shutdown_seconds 10



#----------------------------------------------------------------------
# OpenACS configuration options
#----------------------------------------------------------------------

# More OpenACS configuration options
set system_owner_email "$admin_email"
set admin_owner_email "$admin_email"
set host_administrator_email "$admin_email"
set outgoing_sender_email "$admin_email"
set new_registrations_email "$admin_email"



#----------------------------------------------------------------------
# Checking out code from CVS
#----------------------------------------------------------------------

# To use for example for moving away (saving) certain files under serverroot (see README)
set pre_checkout_script ""

# To use for example for moving back certain (saved) files under serverroot (see README)
set post_checkout_script "" 



#----------------------------------------------------------------------
# Install log and email alerting
#----------------------------------------------------------------------

# The keyword output by the install script to indicate
# that an email alert should be sent
set alert_keyword "INSTALLATION ALERT"
set send_alert_script "send-alert"
set install_output_file "${serverroot}/log/install-output.html"

# Where all errors in the log file during installation are collected
set install_error_file "${serverroot}/log/install-log-errors"



#----------------------------------------------------------------------
# Installing .LRN
#----------------------------------------------------------------------

# dotLRN configuration
# should we install dotlrn?
set dotlrn "no"

# Which tag should we checkout from?
set dotlrn_branch "HEAD"

# Should basic demo setup of departments, classes, users, etc. be done?
set dotlrn_demo_data "no"
set dotlrn_users_data_file "users-data.csv"
set demo_users_password "guest"

# Should links be crawled to search for broken pages? This doesn't quite work!
set crawl_links "no"
