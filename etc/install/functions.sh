# Access config parameters in the TCL file through this function

get_config_param () {
    echo "source $config_file; puts [set $1]" | tclsh
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
