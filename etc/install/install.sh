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

# If any command fails - exit
# not using this because we don't have a way for postgres database user drop/add to work without
# failure regardless of whether the user already exists or not.
#set -e
# Uncomment following line for debug mode
#set -x

# Set the script directory to the current dir for convenience
script_path=$(dirname $(which $0))
cd $script_path

# If you don't say ./, it'll search for functions.sh in your path
source ./functions.sh

# TODO: create user if necessary
# we should check for the existence of the specified user
#   if the user doesn't exist, 
#     if the user was specified in the command line
#       TODO - Check if the user exists first
#       echo "$0: Creating the user $aolserver_user at $(date)"
#       useradd -m -g $aolserver_group $aolserver_user -d /home/$server
#     fi
#     interactive prompt to create user or terminate script
#   fi
#
# Meanwhile, however, we're just going to assume that service user
# is the same as servername and that the user exists.  Documented
# in README

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
    echo "$0: You must execute this script as root; exiting"
    exit -1
fi

# Check that the config file exists
if [ ! -r ${config_file} ]; then
    echo "$0: Aborting installation. The config file \"$config_file\" does not exist or is not readable."
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
        echo "$0: option not recognized: ${i}"
        echo "${usage}"
        exit 1
      ;;
   esac

   shift
done

# set the rest of the config file parameters
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
restart_seconds=$(expr $startup_seconds + $shutdown_seconds)
dotlrn_demo_data=`get_config_param dotlrn_demo_data`
crawl_links=`get_config_param crawl_links`
aolserver_user=`get_config_param aolserver_user`
aolserver_group=`get_config_param aolserver_group`
admin_email=`get_config_param admin_email`
admin_password=`get_config_param admin_password`
aolserver_config_file=`get_config_param aolserver_config_file`
install_xml_file=`get_config_param install_xml_file`

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
echo "$0: Starting installation with config_file $orig_config_file. Using serverroot=$serverroot, server_url=$server_url, do_checkout=$do_checkout, do_install=${do_install}, dotlrn=$dotlrn, and database=$database., use_daemontools=$use_daemontools"

if parameter_true $use_daemontools; then
    echo "$0: Daemontools settings: svscanroot=$svscanroot svscan_sourcedir=$svscan_sourcedir"
fi

# Give the user a chance to abort
prompt_continue $interactive

# stop the server
echo "$0: Taking down $serverroot at $(date)"

if parameter_true $use_daemontools; then
    $svc_bindir/svc -d ${svscanroot}
else
    # non-daemontools stop
    $stop_server_command
fi

# Wait for the server to come down
# TODO - instead of waiting, do a real check wherever we currently sleep
echo "$0: Waiting $shutdown_seconds seconds for server to shut down at $(date)"
sleep $shutdown_seconds

# Check that it's been shut down
pid=`grep_for_pid "nsd.*$serverroot"`
if ! [ "$pid" == "" ]; then
    echo "The server is still running. You must shut down the server first."
    echo "Process IDs of running servers: $pid"
    exit
fi
	
# Recreate the database user and database
echo "$0: Recreating database user and database at $(date)"
if [ $database == "postgres" ]; then

    # Postgres
    pg_bindir=`get_config_param pg_bindir`
    pg_port=`get_config_param pg_port`
    db_name=`get_config_param db_name`
    su  `get_config_param pg_db_admin` -c "export LD_LIBRARY_PATH=${pg_bindir}/../lib; ${pg_bindir}/dropuser -p $pg_port $db_name"
    su  `get_config_param pg_db_admin` -c "export LD_LIBRARY_PATH=${pg_bindir}/../lib; ${pg_bindir}/createuser -d -a -p $pg_port $db_name"

    # dropdb may be redundant becasue dropping the user should drop the db, 
    # but only if our assumption that db_user owns db_name is true
    su  `get_config_param pg_db_admin` -c "export LD_LIBRARY_PATH=${pg_bindir}/../lib; ${pg_bindir}/dropdb -p $pg_port $db_name"
    su  `get_config_param pg_db_admin` -c "export LD_LIBRARY_PATH=${pg_bindir}/../lib; ${pg_bindir}/createdb -p $pg_port $db_name"

    # createlang was part of this command but is not necessary 
    # (and causes an error) for newer installs
    # ${pg_bindir}/createlang -p $pg_port plpgsql $db_name";

else

    #Oracle
    # Need to su to login shell for sqlplus to be in path. Should maybe make ORA_HOME
    # a config param instead.
    su - oracle -c "cd ${script_path}/oracle; config_file=$config_file ./recreate-user.sh";
fi

# Check out new files
if parameter_true $do_checkout; then

    # The pre_checkout script can move away any files or changes
    # to the source tree that we want to keep (for example an
    # edited AOLserver config file, see README)
    if [ -n "$pre_checkout_script" ]; then
        source $pre_checkout_script
    fi  

    if parameter_true $use_daemontools; then
    # Remove supervise link if it exists
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
        fi
    fi

    pid=`grep_for_pid "nsd.*$serverroot"`

    if ! [ "$pid" == "" ]; then
        echo "The server is still running. You must shut down the server first."
        echo "Process IDs of running servers: $pid"
        exit
    fi
	
    echo "$0: Checking out OpenACS at $(date)"
    chmod +x checkout.sh
    config_file=$config_file dotlrn=$dotlrn ./checkout.sh

    if [ -z "$aolserver_config_file" ]; then
        # No AOLserver config file specified - we are using the standard etc/config.tcl file.
        # We need to update it with settings in install.tcl since certain parameters 
        # (such as serverroot) are duplicated between the two files.
        ./config-replace.sh $config_file
        chmod +x $serverroot/etc/daemontools/run
    fi 

    # The post_checkout script can copy back any files (AOLServer config files,
    # log files etc.) under the new source tree, and apply any patches
    # that should be applied (see README).
    if [ -n "$post_checkout_script" ]; then
        source $post_checkout_script
    fi  
    
    # If we are using daemontools, set up the supervise directory if needed
    if parameter_true $use_daemontools && ! [ -e $svscanroot ]; then
        # Create a daemontools directory
	# prevent it from autostarting when linked
	echo "$0: Creating daemontools directory"
	touch $svscan_sourcedir/down
	ln -s $svscan_sourcedir $svscanroot
        # allow svscan to start
	echo "$0: Waiting for 10 seconds for svscan to come up at $(date)"
	sleep 10
        # Check if svgroup is present, and if so, use it
	if which svgroup &> /dev/null; then
	    echo "$0: Giving group $aolserver_group control over the server: svgroup web ${svscanroot}"
	    svgroup $aolserver_group ${svscanroot}
	fi
    fi
fi

# Bring up the server again
echo "$0: Bringing the server $serverroot back up at $date with command $command"
if parameter_true $use_daemontools; then
    if [ -f $svscanroot/down ]; then
	rm $svscanroot/down
    fi
    $svc_bindir/svc -u $svscanroot
else
    # non-daemontools command
    $start_server_command
fi

# Give the server some time to come up
echo "$0: Waiting for $startup_seconds seconds for server to come up at $(date)"
sleep $startup_seconds

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

  # Install OpenACS
  echo "$0: Starting installation of OpenACS at $(date)"
  ${tclwebtest_dir}/tclwebtest -config_file $config_file openacs-install.test
  
  # Restart the server
  echo "$0: Restarting server at $(date)"
  
  if parameter_true $use_daemontools; then
      $svc_bindir/svc -t $svscanroot
  else
      $restart_server_command
  fi

  echo "$0: Waiting for $restart_seconds seconds for server to come up at $(date)"
  sleep $restart_seconds

  # Extra wait on first startup
  extra_seconds_wait=300
  echo "$0: Waiting an extra $extra_seconds_wait seconds here as much initialization of OpenACS and message catalog usually happens at this point"
  sleep $extra_seconds_wait

  if parameter_true "$dotlrn_demo_data"; then
      # Do .LRN demo data setup
      echo "$0: Starting basic setup of .LRN at $(date)"
      cp tcl/eval-command.tcl $serverroot/www/eval-command.tcl
      ${tclwebtest_dir}/tclwebtest -config_file $config_file dotlrn-basic-setup.test
      rm $serverroot/www/eval-command.tcl
  fi
      
  if parameter_true $crawl_links; then
      # Search for broken pages
      echo "$0: Starting to crawl links to search for broken pages at $(date)"
      ${tclwebtest_dir}/tclwebtest -config_file $config_file dotlrn-links-check.test
  fi

  # Check errors in the log file
  # We do this before the Tcl API tests as these tend to generate errors intentionally
  if [ -r ${error_log_file} ]; then
      seconds_since_installation_start=$(expr $(date +%s) - $installation_start_time)
      minutes_since_installation_start=$(expr $seconds_since_installation_start / 60 + 1)

      ./aolserver-errors.pl -${minutes_since_installation_start}m ${error_log_file} > ${install_error_file}
      error_line_count=$(wc -l $install_error_file | awk '{print $1}')
      if expr $error_line_count \> 1 &> /dev/null; then
         alert_keyword=`get_config_param alert_keyword`
         echo "$0: ${alert_keyword} - There are error messages in the log file, they are stored in $install_error_file"
      fi
  else
      echo "$0: Log file ${error_log_file} not readable - cannot check for errors"
  fi
  
  # Run the Tcl API tests
  ${tclwebtest_dir}/tclwebtest -config_file $config_file tcl-api-test.test

  if [ $database == "postgres" ]; then
      # Run vacuum analyze
      db_name=`get_config_param db_name`
      echo "$0: Beginning 'vacuum analyze' at $(date)"
      su  `get_config_param pg_db_user` -c "export LD_LIBRARY_PATH=${pg_bindir}/../lib; ${pg_bindir}/vacuumdb -p $pg_port -z $db_name"
  fi
  
  # Report the time at which we were done
  echo "$0: Finished (re)installing $serverroot at $(date).  Access the new site at $server_url with admin username $admin_email and password $admin_password"
  
  # Warn about errors in the HTML returned from the server
  ./warn-if-installation-errors.sh `get_config_param install_output_file`
fi
