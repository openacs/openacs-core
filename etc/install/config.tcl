# TCLWebTest configuration
set tclwebtest_dir "/usr/local/tclwebtest"


set server "service0"

# Choose database - oracle or postgres
set database "postgres"

# Oracle configuration
set oracle_user "${server}"
set oracle_password "${oracle_user}"
set system_user "system"
set system_user_password "manager"

# PostgreSQL configuration
# system account for postgres
set pg_db_user "postgres"
set pg_db_name ${server}
set pg_host localhost
set pg_port 5432
set pg_bindir "/usr/local/pgsql/bin"

# AOLServer configuration
set serverroot "/var/lib/aolserver/${server}"
set svscanroot "/var/lib/svscan"
set server_url "http://localhost:8000"
set error_log_file "${serverroot}/log/error.log"
set start_server_command "svc -u ${svscanroot}/$server"
set stop_server_command "svc -d ${svscanroot}/$server"
set restart_server_command "svc -t ${svscanroot}/$server"
# Time from invocation of startup command until the server is actually up
set startup_seconds 20
# Time from invocation of shutdown command until the server is actually down
set shutdown_seconds 10

# OpenACS configuration
set admin_email "postmaster@localhost"
set admin_first_names "Admin"
set admin_last_name "User"
set admin_password "1"
set admin_password_question "Hello - is there anybody out there?"
set admin_password_answer "1853"
set system_name "OpenACS Test System"
set publisher_name "Yourname"
set system_owner_email "$admin_email"
set admin_owner_email "$admin_email"
set host_administrator_email "$admin_email"
set outgoing_sender_email "$admin_email"
set new_registrations_email "$admin_email"

# Set to yes to not install full ref-timezones and save time during
# datamodel install. Set to no for production servers.
set use_timesaver_files "no"

# dotLRN configuration
# should we install dotlrn?
set dotlrn "no"

# Should basic demo setup of departments, classes, users, etc. be done?
set dotlrn_demo_data "no"
set dotlrn_users_data_file "users-data.csv"
set demo_users_password "guest"
# Should links be crawled to search for broken pages?
set crawl_links "no"

# CVS variables
set oacs_branch "HEAD"
set dotlrn_branch "HEAD"
set do_checkout "yes"
# To use if you have your AOLServer config file under server_root (see README)
# Only executes if checkout is done
set pre_checkout_script ""
# To use if you have your AOLServer config file under server_root (see README)
# Only executes if checkout is done
set post_checkout_script "" 

# The keyword outputed by the install script to indicate
# that an email alert should be sent
set alert_keyword "INSTALLATION ALERT"
set send_alert_script "send-alert"
set openacs_output_file "${serverroot}/log/install-openacs-data-model-output.html"
set openacs_packages_output_file "${serverroot}/log/install-openacs-packages-install-output.html"
set apm_output_file "${serverroot}/log/install-apm-packages-output.html"
