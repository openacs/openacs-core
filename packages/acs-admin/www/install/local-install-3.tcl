ad_page_contract {
    Install from local file system
}


#####
#
# Start progress bar
#
#####

# TODO: We should execute this in a background-thread, so that
# we don't risk running two installation processes at the same time (double-click, or two users)

# TODO: Maybe set a body onload handler to display a warning message that the page has stopped loading, 
# which it shouldn't. If people hit reload, we should preferably just re-display the progress bar
# and continue waiting.


ReturnHeaders

ns_write "
<html>
<head>
<link rel=\"stylesheet\" type=\"text/css\" href=\"/resources/acs-subsite/site-master.css\" media=\"all\">
</head>
<body>

<div id=\"body\">
  <div id=\"subsite-name\">
    <if @title@ not nil>
      <h1 class=\"subsite-page-title\">Installing packages...</h1>
    </if>
  </div>
  <div id=\"navbar-body\">
    <div id=\"subnavbar-body\">


<table align=\"center\" style=\"margin-top: 144px; margin-bottom: 144px;\">
  <tr>
    <td align=\"center\">
      <p>Installing packages, please wait ...</p>
    </td>
  </tr>
  <tr>
    <td align=\"center\">
      <div style=\"font-size:16pt;padding:2px; align: center;\">
        <span id=\"progress1\" style=\"background-color: #eeeeee;\">&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id=\"progress2\" style=\"background-color: #eeeeee;\">&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id=\"progress3\" style=\"background-color: #eeeeee;\">&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id=\"progress4\" style=\"background-color: #eeeeee;\">&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id=\"progress5\" style=\"background-color: #eeeeee;\">&nbsp;&nbsp;&nbsp;&nbsp;</span>
      </div>
    </td>
  </tr>
  <tr>
    <td align=\"center\">
      <p style=\"margin-top: 36px\">We will continue automatically when installation is complete.</p>
    </td>
  </tr>
</table>


      <div style=\"clear: both;\"></div>
    </div>
  </div>
</div>


<script language=\"javascript\">
var progressEnd = 5;// set to number of progress <span>'s.
var progressColor = 'blue';// set to progress bar color
var progressInterval = 1000;// set to time between updates (milli-seconds)

var progressAt = progressEnd;
var progressTimer;
function progress_update() {
    if (progressAt > 0) {
        document.getElementById('progress'+progressAt).style.backgroundColor = '#eeeeee';
    }
    progressAt++;
    if (progressAt > progressEnd) progressAt = 1;
    document.getElementById('progress'+progressAt).style.backgroundColor = progressColor;
    progressTimer = setTimeout('progress_update()',progressInterval);
}
function progress_stop() {
    clearTimeout(progressTimer);
    progress_clear();
}
progress_update();// start progress bar
</script>

"



#####
#
# Install packages
#
#####


set pkg_install_list [ad_get_client_property apm pkg_install_list]

set sql_file_list [list]


foreach pkg_info $pkg_install_list {

    set package_key [pkg_info_key $pkg_info]
    array set version [apm_read_package_info_file [pkg_info_spec $pkg_info]]
    set final_version_name $version(name)

    # Determine if we are upgrading or installing.
    if { [apm_package_upgrade_p $package_key $final_version_name] == 1} {
	ns_log Debug "Upgrading package [string totitle $version(package-name)] to $final_version_name."
	set upgrade_p 1
	set initial_version_name [db_string apm_package_upgrade_from {
	    select version_name from apm_package_versions
	    where package_key = :package_key
	    and version_id = apm_package__highest_version(:package_key)
	} -default ""]
    } else {
	set upgrade_p 0
	set initial_version_name ""
    }

    # Find out which script is appropriate to be run.
    set data_model_in_package 0
    set table_rows ""
    set data_model_files [concat \
                             [apm_data_model_scripts_find \
                                 -upgrade_from_version_name $initial_version_name \
                                 -upgrade_to_version_name $final_version_name \
                                 $package_key] \
                             [apm_ctl_files_find $package_key]]

    set sql_file_list [concat $sql_file_list $data_model_files]
}




set sql_files $sql_file_list

set error_p 0

set installed_count 0
foreach pkg_info $pkg_install_list {
    set spec_file [pkg_info_spec $pkg_info]
    if { [catch {
	array set version [apm_read_package_info_file $spec_file]
    } errmsg] } {
	ns_write "<li> Unable to install the [pkg_info_key $pkg_info] package because its specification
	file is invalid: <blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
	continue
    }

    if {[apm_package_version_installed_p $version(package.key) $version(name)] } {
	# Already installed.
	continue
    }

    set package_key $version(package.key)
    set version_files $version(files)

    set data_model_files [list]
    # Find the correct data model files for this package.
    foreach file $sql_files {
	if {![string compare [lindex $file 2] $package_key]} {
	    # Pass on the file path and its type.
	    lappend data_model_files $file
	}
    }

    # Install the packages.
    set version_id [apm_package_install \
                        -enable \
                        -install_path "[acs_root_dir]/packages" \
                        -load_data_model \
                        -data_model_files $data_model_files \
                        $spec_file]
    
    if { $version_id == 0 } {
        # Installation of the package failed and we shouldn't continue with installation
        # as there might be packages depending on the failed package. Ideally we should
        # probably check for such dependencies and continue if there are none.
        set error_p 1
        break
    }
    
    incr installed_count
}


#####
#
# Done
#
#####

set continue_url [export_vars -base local-install-4 { error_p }]
ns_write "<script language=\"javascript\">window.location='$continue_url';</script>"
ns_conn close

