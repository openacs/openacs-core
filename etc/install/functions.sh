# Access config parameters in the TCL file through this function

get_config_param () {
    echo "source $source_config_file; puts [set $1]" | tclsh
}

create_override_config_file () {
    server=$1
    config_file=$2

    override_config_file=/tmp/config-$server-$$.tcl
    # Only write the source_config_file if this hasn't already been done
    if [ ! -a $override_config_file ]; then
      echo "set server $server" > $override_config_file
      cat $config_file | egrep -v '^[[:space:]]*set[[:space:]]+server[[:space:]]+' >> $override_config_file
      export source_config_file=$override_config_file
else  
      export source_config_file=$config_file    
    fi
}

# present an interactive continue prompt.  
# Quit the script if user chooses no.
prompt_continue () {

    interactive=$1
    
    if [ "$interactive" == "yes" ]; then
        echo "Continue? (y/n)"
        read continue
        if [ "$continue" == "n" ]; then
            echo "$0: exiting on users request"
            exit
        fi
    fi
}


# convert y, Y, t, and T to true and other values to false
parameter_true () {
    case "$1" in
      [yY]*|[tT]*)
                    true
                    ;;
      *)
                    false
                    ;;
    esac
}
