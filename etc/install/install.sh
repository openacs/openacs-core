#!/bin/bash
#
# Read the README file before executing this script.
#
# This script recreates an OpenACS server from scratch by:
#
# - dropping and creating the database
# - Re-checking out the source code from CVS (optional)
# - Doing necessary installation and configuration of OpenACS and
#   .LRN over HTTP that is normally done manually in a browser.
#
# @author Peter Marklund (peter@collaboraid.biz)
# @author Lars Pind (lars@collaboraid.biz)
# @author Joel Aufrecht (joel@aufrecht.org)


######################################################################
#
# Initial setup
#
######################################################################

#---------------------------------------------------------------------
# Uncomment the following line to exit on any failure
#   However, we are not using this because we don't have a way 
#   for postgres database user drop/add to work without failure 
#   regardless of whether the user 
#   already exists or not.
#
#set -e
#---------------------------------------------------------------------


#---------------------------------------------------------------------
# Uncomment following line for debug mode
#set -x
#---------------------------------------------------------------------


#---------------------------------------------------------------------
# Set the script directory to the current dir for convenience
export script_path=$(dirname $(which $0))
cd $script_path


#---------------------------------------------------------------------
# If you don't say ./, it'll search for functions.sh in your path
source ./functions.sh

#---------------------------------------------------------------------
# TODO: create user if necessary
# we should check for the existence of the specified user
#   if the user doesn't exist, 
#     if the user was specified in the command line
#       TODO - Check if the user exists first
#       echo "$0: Creating the user $aolserver_user"
#       useradd -m -g $aolserver_group $aolserver_user -d /home/$server
#     fi
#     interactive prompt to create user or terminate script
#   fi
#
# Meanwhile, however, we're just going to assume that service user
# is the same as servername and that the user exists.  Documented
# in README
#---------------------------------------------------------------------


######################################################################
# 
# Parse command-line arguments
# 
######################################################################

#---------------------------------------------------------------------
# Look for two-part command line arguments
# Also, we need to look for command-line setting for config file
# before we load the config file
config_val_next=0
server_next=0
export config_file="$script_path/install.tcl"
server_overridden="no"
for arg in "$@"
  do
  if [ $config_val_next == "1" ]; then
      export config_file=$arg
      config_val_next=0
  fi
  if [ $server_next == "1" ]; then
      # Overrides server setting in config file
      export server=$arg
      server_next=0
      server_overridden="yes"
  fi
  if [ $arg == "--config-file" ]; then
      config_val_next=1
  fi
  if [ $arg == "--server" ]; then
      server_next=1
  fi
done

# Create a config file with overridden server name if it was
# provided on the command line
export orig_config_file=$config_file
if parameter_true "$server_overridden"; then
    echo "$0: Overriding config server setting with $server"
    create_override_config_file $server $config_file
fi

usage="$0 [OPTIONS]
    --server      Server name.  Overrides config file.
    --config-file Sets up information about the server and database used (see install.tcl.in). Defaults to install.tcl
    --no-checkout Do not checkout new source code
    --oacs-only   Do not install .LRN, only OpenACS
    --no-install  Do not install .LRN or OpenACS. Useful if you only want to recreate the db user and then install manually
    --postgresql  Install on PostgreSQL. Overrides database setting in install config file.
    --interactive Gives you the possibility to exit at certain points during installation
"

# Check that script is executed as root
if [ $(whoami) != "root" ]; then
    echo "$(date): You must execute this script as root; exiting"
    exit -1
fi

# Check that the config file exists
if [ ! -r ${config_file} ]; then
    echo "$(date): Aborting installation. The config file \"$config_file\" does not exist or is not readable."
    exit -1
fi

# Set overridable configuration parameters from config file
do_checkout=`get_config_param do_checkout`
dotlrn=`get_config_param dotlrn`
database=`get_config_param database`
interactive="no"
do_install="yes"
server=`get_config_param server`

while [ -n "$1" ] ; do
   case "$1" in
      "--config-file")        
        # We already got this value above so just shift and continue
        shift
      ;;
      "--server")
        # We already got this value above so just shift and continue
        shift
      ;;
      "--no-checkout")
        do_checkout="no"
      ;;
      "--oacs-only")
        dotlrn="no"
      ;;
      "--postgresql")
        database="postgres"
      ;;
      "--interactive")
        interactive="yes"
      ;;
      "--help"|"-h")
        echo "${usage}"
        exit 0
      ;;
      "--no-install")
        do_install="no"
      ;;
      *)
        echo "$(date): option not recognized: ${i}"
        echo "${usage}"
        exit -1
      ;;
   esac

   shift
done

#---------------------------------------------------------------------
#
# set the rest of the config file parameters
#
#---------------------------------------------------------------------

# some of them may vary based on command-line overrides, so we 
# do them after checking the command line

serverroot=`get_config_param serverroot`
use_daemontools=`get_config_param use_daemontools`
svc_bindir=`get_config_param svc_bindir`
svscanroot=`get_config_param svscanroot`
svscan_sourcedir=`get_config_param svscan_sourcedir`
server_url=`get_config_param server_url`
error_log_file=`get_config_param error_log_file`
install_error_file=`get_config_param install_error_file`
tclwebtest_dir=`get_config_param tclwebtest_dir`
stop_server_command=`get_config_param stop_server_command`
start_server_command=`get_config_param start_server_command`
restart_server_command=`get_config_param restart_server_command`
startup_seconds=`get_config_param startup_seconds`
shutdown_seconds=`get_config_param shutdown_seconds`
startup_loop_count=`get_config_param startup_loop_count`
restart_loop_count=`get_config_param restart_loop_count`
shutdown_loop_count=`get_config_param shutdown_loop_count`
dotlrn_demo_data=`get_config_param dotlrn_demo_data`
crawl_links_start_path=`get_config_param crawl_links_start_path`
aolserver_user=`get_config_param aolserver_user`
aolserver_group=`get_config_param aolserver_group`
admin_email=`get_config_param admin_email`
admin_password=`get_config_param admin_password`
aolserver_config_file=`get_config_param aolserver_config_file`
install_xml_file=`get_config_param install_xml_file`
tclwebtest_scripts=`get_config_param tclwebtest_scripts`
do_tclapi_testing=`get_config_param do_tclapi_testing`
report_scp_target=`get_config_param report_scp_target`
server_description=`get_config_param server_description`

# If pre/post checkout scripts have been provided, check that they can
# be executed
pre_checkout_script=`get_config_param pre_checkout_script`
post_checkout_script=`get_config_param post_checkout_script`
if [ -n "$pre_checkout_script" ] && [ ! -x $pre_checkout_script ]; then
    echo "The pre checkout script $pre_checkout_script does not exist or is not executable"
    exit -1
fi
if [ -n "$post_checkout_script" ] && [ ! -x $post_checkout_script ]; then
    echo "The post checkout script $post_checkout_script does not exist or is not executable"
    exit -1
fi

# Log some important parameters for the installation
echo "$(date): Starting installation with config_file $orig_config_file. Using serverroot=$serverroot, server_url=$server_url, do_checkout=$do_checkout, do_install=${do_install}, dotlrn=$dotlrn, and database=$database., use_daemontools=$use_daemontools"

if parameter_true $use_daemontools; then
    echo "$(date): Daemontools settings: svscanroot=$svscanroot svscan_sourcedir=$svscan_sourcedir"
fi

# Give the user a chance to abort
prompt_continue $interactive

######################################################################
#
# stop the server
#
######################################################################

echo "$(date): Taking down $serverroot"

if parameter_true $use_daemontools; then
    echo "$(date): supervise status is: $($svc_bindir/svstat ${svscanroot})"
    command="$svc_bindir/svc -d ${svscanroot}"
    echo "$(date): Issuing command $command"
    $command
    echo "$(date): supervise status is: $($svc_bindir/svstat ${svscanroot})"
else
    # non-daemontools stop
    echo "$(date): Issuing command $stop_server_command"
    $stop_server_command
fi

# Wait in a finite loop for the server to come down
x=0
while test "$x" -lt $shutdown_loop_count ; do

    pid=`grep_for_pid "nsd.*${serverroot}/etc/config.tcl"`
    if [ "$pid" == "" ]; then
	echo "$(date): Server is down"
	break
    fi
    echo "$(date): Process IDs of running servers: $pid"
    echo "$(date): Waiting $shutdown_seconds seconds for server to shut down."
    sleep $shutdown_seconds
    x=`expr "$x" + 1`
done

# Verify that the server is down, and abort if not  
pid=$(grep_for_pid "nsd.*${serverroot}/etc/config.tcl")
if ! [ "$pid" == "" ]; then
    echo "$(date): Cannot stop the server. You must shut down the server first."
    exit -1
fi

######################################################################
#
# Recreate the database user and database
#
######################################################################

echo "$(date): Recreating database user and database."
if [ $database == "postgres" ]; then

    # Postgres
    pg_bindir=`get_config_param pg_bindir`
    pg_port=`get_config_param pg_port`
    pg_db_user=`get_config_param pg_db_user`
    db_name=`get_config_param db_name`
    su  `get_config_param pg_db_admin` -c "export LD_LIBRARY_PATH=${pg_bindir}/../lib; ${pg_bindir}/dropuser -p $pg_port $pg_db_user"
    # dropdb may be redundant becasue dropping the user should drop the db, 
    # but only if our assumption that db_user owns db_name is true
    su  `get_config_param pg_db_admin` -c "export LD_LIBRARY_PATH=${pg_bindir}/../lib; ${pg_bindir}/dropdb -p $pg_port $db_name"

    su  `get_config_param pg_db_admin` -c "export LD_LIBRARY_PATH=${pg_bindir}/../lib; ${pg_bindir}/createuser -d -a -p $pg_port $pg_db_user"
    su  `get_config_param pg_db_admin` -c "export LD_LIBRARY_PATH=${pg_bindir}/../lib; ${pg_bindir}/createdb -E UNICODE -p $pg_port $db_name"

    # createlang was part of this command but is not necessary 
    # (and causes an error) for newer installs
    # ${pg_bindir}/createlang -p $pg_port plpgsql $db_name";

else

    #Oracle
    # Need to su to login shell for sqlplus to be in path. Should maybe make ORA_HOME
    # a config param instead.
    su - oracle -c "cd ${script_path}/oracle; config_file=$config_file ./recreate-user.sh";
fi


######################################################################
#
# Check out new files
# 
# If we are doing checkout, checkout files and modify checked out files,
# including /etc/config.tcl and /etc/daemontools/run
#
######################################################################

if parameter_true $do_checkout || [ $do_checkout == "up" ] ; then

    # The pre_checkout script can move away any files or changes
    # to the source tree that we want to keep (for example an
    # edited AOLserver config file, see README)
    if [ -n "$pre_checkout_script" ]; then
        source $pre_checkout_script
    fi  

    #-----------------------------------------------------------------
    # Remove supervise link if it exists
    if parameter_true $use_daemontools; then
        # Make sure any existing supervise directory is a symlink
	if [ -e $svscanroot ]; then
	    if ! [ -L $svscanroot ]; then
		echo "You have a supervise directory $svscanroot which is not a symlink and we curently don't support that."
		exit -1    
	    fi
	    rm ${svscanroot}
        fi
        if [ -r "$svscan_sourcedir" ]; then
            $svc_bindir/svc -dx $svscan_sourcedir
            echo "$(date): supervise status is: $($svc_bindir/svstat ${svscanroot})"
        fi
    fi

    pid=`grep_for_pid "nsd.*$serverroot"`

    if ! [ "$pid" == "" ]; then
        echo "The server is still running. You must shut down the server first."
        echo "Process IDs of running servers: $pid"
        exit
    fi
	
    if [ $do_checkout == "up" ] ; then
        echo "$(date): Doing cvs update"
        chmod +x updateserver.sh
        ./updateserver.sh $serverroot
    else
        echo "$(date): Checking out OpenACS"
        chmod +x checkout.sh
        config_file=$config_file dotlrn=$dotlrn ./checkout.sh
    fi

    #-----------------------------------------------------------------
    # The post_checkout script can copy back any files (AOLServer config files,
    # log files etc.) under the new source tree, and apply any patches
    # that should be applied (see README).
    if [ -n "$post_checkout_script" ]; then
        source $post_checkout_script
    fi  
    
    #-----------------------------------------------------------------
    # If we are using daemontools, set up the supervise directory if needed
    if parameter_true $use_daemontools && ! [ -e $svscanroot ]; then
        # Create a daemontools directory
	# prevent it from autostarting when linked
        if [ ! -d $svscan_sourcedir ]; then
            echo "$(date): ABORTING: Failed to create daemontools symlink $svscan_sourcedir"
            exit -1
        fi
	echo "$(date): Linking $svscan_sourcedir from $svscanroot"
	touch $svscan_sourcedir/down
	ln -s $svscan_sourcedir $svscanroot 

        # allow svscan to start
        echo "$(date): Waiting for 10 seconds for svscan to find the new link."
        sleep 10
        echo "$(date): supervise status is: $($svc_bindir/svstat ${svscanroot})"	
        echo "$(date): daemontools errors: : $(ps -auxw | grep readproctitle)"
        # Check if svgroup is present, and if so, use it
	if which svgroup &> /dev/null; then
	    echo "$(date): Giving group $aolserver_group control over the server: svgroup web ${svscanroot}"
	    svgroup $aolserver_group ${svscanroot}
	fi
    fi

    #-----------------------------------------------------------------
    # Modify the config file
    if [ -z "$aolserver_config_file" ]; then
        # No AOLserver config file specified - we are using the standard etc/config.tcl file.
        # We need to update it with settings in install.tcl since certain parameters 
        # (such as serverroot) are duplicated between the two files.
        echo "$(date): Editing AOLserver config file with parameter settings in install.tcl"
        ./config-replace.sh $config_file
        chmod +x $svscan_sourcedir/run
    else
        # Copy specified config file to the right path
        echo "$(date): Copying custom AOLserver config file $aolserver_config_file"
        cp $aolserver_config_file $serverroot/etc/config.tcl
    fi 

    #-----------------------------------------------------------------
    # Edit the run script
    echo "$(date): Editing run script at $svscan_sourcedir/run"
    ./run-create.sh $config_file
    chmod +x $svscan_sourcedir/run

    #-----------------------------------------------------------------
    # Make sure we always have sensible ownership and permissions in the whole source tree
    echo "$(date): Setting permissions and ownership for files under ${serverroot}"
    chown -R ${aolserver_user}.${aolserver_group} ${serverroot}
    chmod -R go+rwX ${serverroot}
else
    echo "$(date): Proceeding without checkout.  This assumes that you have a full working site already set up at ${serverroot}, including correctly configured ${serverroot}/etc/config.tcl and ${svscan_sourcedir}"

fi

#
# Done with checkout
#

######################################################################
#
# Start the server
#
######################################################################

echo "$(date): Bringing $serverroot back up"

if parameter_true $use_daemontools; then
    echo "$(date): supervise status is: $($svc_bindir/svstat ${svscanroot})"
    if [ -f $svscanroot/down ]; then
        echo "$(date): removing down file"
	rm $svscanroot/down
    fi
    command="$svc_bindir/svc -u $svscanroot"
    echo "$(date): Issuing command $command"
    $command
    echo "$(date): supervise status is: $($svc_bindir/svstat ${svscanroot})"	
else
    # non-daemontools command
    echo "$(date): Issuing command $start_server_command"
    $start_server_command
fi

# Wait in a finite loop for the server to become responsive
# but first wait just a few seconds, since this startup is usually very quick
sleep 4

# prep for the test
wget_test=${server_url}/SYSTEM/success
if [ -f ${script_path}/success ]; then
    rm ${script_path}/success
fi
x=0

while test "$x" -lt $startup_loop_count ; do

    # check for static file
    echo "$(date): attempting: wget --tries=1 $wget_test"
    wget --tries=1 $wget_test
    if [ -r ${script_path}/success ] && [ $(cat ${script_path}/success) = "success" ]; then
	echo "$(date): Server is up"
	break
    fi
    echo "$(date): Waiting for $startup_seconds seconds for server to respond."
    sleep $startup_seconds
    x=`expr "$x" + 1`
done

if parameter_true $do_install; then
  # Save the time we started installation
  installation_start_time=$(date +%s)
    
  if [ $dotlrn == "yes" ]; then
    # Make sure the dotlrn/install.xml file is at the server root
    cp $serverroot/packages/dotlrn/install.xml $serverroot
  elif [ -n "$install_xml_file" ]; then
      # Copy specified install.xml file
      cp ${install_xml_file} $serverroot
  fi

  #-------------------------------------------------------------------
  # Install OpenACS
  echo "$(date): Starting installation of OpenACS."
  # TODO: this should be a parameter in install.tcl
  export TCLLIBPATH="$TCLLIBPATH /usr/local/tclwebtest"

  ${tclwebtest_dir}/tclwebtest -config_file $config_file openacs-install.test
  

  #-------------------------------------------------------------------
  # Restart the server
  echo "$(date): Restarting $serverroot"
  if parameter_true $use_daemontools; then
      echo "$(date): Daemontools should restart the server automatically"
  else
      echo "$(date): Issuing command $start_server_command"
      $start_server_command
  fi

  # Peter: it seems nsunix will trigger a restart of the server after we request
  # the SYSTEM/dbtest page, so give the server some extra time here to potentially restart
  # again before we proceed
  sleep 30

  # we check for dbtest instead of success here because dbtest is a more thorough test
  # we would have used dbtest before but it doesn't work on postgresql before openacs
  # install
  wget_test=${server_url}/SYSTEM/dbtest
  if [ -f ${script_path}/dbtest ]; then
      rm ${script_path}/dbtest
  fi
  # Wait in a finite loop for the server to become responsive
  x=0
  while test "$x" -lt $restart_loop_count ; do
      # check for database responsiveness
      wget_test=${server_url}/SYSTEM/dbtest
      echo "$(date): trying to retrieve $wget_test"
      wget --tries=1 $wget_test
      if [ -r ${script_path}/dbtest ] && [ $(cat ${script_path}/dbtest) = "success" ]; then
	  echo "$(date): Server is up"
	  break
      fi
      echo "$(date): Waiting for $startup_seconds seconds for server to respond."
      sleep $startup_seconds
      x=`expr "$x" + 1`
  done

  #-------------------------------------------------------------------
  # Do .LRN demo data setup
  if parameter_true "$dotlrn_demo_data"; then
      echo "$(date): Starting basic setup of .LRN."
      cp tcl/eval-command.tcl $serverroot/www/eval-command.tcl
      ${tclwebtest_dir}/tclwebtest -config_file $config_file dotlrn-basic-setup.test
      rm $serverroot/www/eval-command.tcl
  fi
      
  #---------------------------------------------------------------
  # Search for broken pages
  if [ -n "$crawl_links_start_path" ]; then
      echo "$(date): Starting to crawl links to search for broken pages. Start path is $crawl_links_start_path"
      ${tclwebtest_dir}/tclwebtest -config_file $config_file crawl-links.test
  fi

  #-------------------------------------------------------------------
  # Run any additional tclwebtest scripts
  if [ -n "$tclwebtest_scripts" ]; then
      echo "$(date): Running additional tclwebtest scripts"

      for tclwebtest_script_path in $tclwebtest_scripts
      do
        echo "$(date): Running tclwebtest script $tclwebtest_script_path"
        ${tclwebtest_dir}/tclwebtest -config_file $config_file $tclwebtest_script_path
      done
  fi  

  #-------------------------------------------------------------------
  # Check errors in the log file
  # We do this before the Tcl API tests as these tend to generate errors intentionally
  if [ -r ${error_log_file} ]; then
      seconds_since_installation_start=$(expr $(date +%s) - $installation_start_time)
      minutes_since_installation_start=$(expr $seconds_since_installation_start / 60 + 1)

      ./aolserver-errors.pl -${minutes_since_installation_start}m ${error_log_file} > ${install_error_file}
      error_line_count=$(wc -l $install_error_file | awk '{print $1}')
      if expr $error_line_count \> 1 &> /dev/null; then
         alert_keyword=`get_config_param alert_keyword`
         echo "$(date): ${alert_keyword} - There are error messages in the log file, they are stored in $install_error_file"
      fi
  else
      echo "$(date): Log file ${error_log_file} not readable - cannot check for errors"
  fi

  #-------------------------------------------------------------------
  # Run the Tcl API tests
  if parameter_true $do_tclapi_testing; then
      echo "$(date): Running tclwebtest tests"
      ${tclwebtest_dir}/tclwebtest -config_file $config_file tcl-api-test.test

  fi

  #-------------------------------------------------------------------
  # Vacuum analyze for PG
  if [ $database == "postgres" ]; then
      pg_bindir=`get_config_param pg_bindir`
      db_name=`get_config_param db_name`
      echo "$(date): Beginning 'vacuum analyze'."
      su  `get_config_param pg_db_user` -c "export LD_LIBRARY_PATH=${pg_bindir}/../lib; ${pg_bindir}/vacuumdb -p $pg_port -z $db_name"
  fi

  #-------------------------------------------------------------------
  # Warn about errors in the HTML returned from the server
  ./warn-if-installation-errors.sh `get_config_param install_output_file`

  ######################################################################
  #
  # Generate an XML report
  #
  ######################################################################

  xmlreportfile=$script_path/$HOSTNAME-$server-installreport.xml
  echo "<service name=\"$server\">" > $xmlreportfile
  echo "  <info type=\"description\">$server_description</info>" >> $xmlreportfile
  echo "  <info type=\"os\">$(uname -a)</info>" >> $xmlreportfile
  echo "  <info type=\"dbtype\">$database</info>" >> $xmlreportfile
  if [ $database == "postgres" ]; then
      # Postgres
      echo "  <info type=\"dbversion\">$(${pg_bindir}/psql --version)</info>"  >> $xmlreportfile
  fi
  
  #TODO: Oracle version number

  echo "  <info type=\"webserver\">$(/usr/local/aolserver/bin/nsd -V)</info>"  >> $xmlreportfile
  echo "  <info type=\"url\">$server_url</info>" >> $xmlreportfile
  echo "  <info type=\"hostname\">$HOSTNAME</info>" >> $xmlreportfile
  echo "  <info type=\"openacs-cvs-flag\">$(get_config_param oacs_branch)</info>" >> $xmlreportfile
  echo "  <info type=\"sitename\">$(get_config_param system_name)</info>" >> $xmlreportfile
  echo "  <info type=\"adminemail\">$admin_email</info>" >> $xmlreportfile
  echo "  <info type=\"adminpassword\">$admin_password</info>" >> $xmlreportfile
  echo "  <info type=\"install-begin-epoch\">$installation_start_time</info>" >> $xmlreportfile
  echo "  <info type=\"install-end-epoch\">$(date +%s)</info>" >> $xmlreportfile
  echo "  <info type=\"install-end-timestamp\">$(date)</info>" >> $xmlreportfile
  echo "  <info type=\"script_path\">$script_path</info>" >> $xmlreportfile
  echo "</service>"  >> $xmlreportfile

  # Report the time at which we were done
  echo "$(date): Finished (re)installing $serverroot.
######################################################################
  New site URL: $server_url
admin email   : $admin_email
admin password: $admin_password
######################################################################"

  if [ -n "$report_scp_target" ]; then
      echo "$(date): Copying xml report to $report_scp_target"
      scp $xmlreportfile $report_scp_target
  fi
fi
