ad_page_contract {
    Install from local file system
}

# TODO: Maybe set a body onload handler to display a warning message that the page has stopped loading, 
# which it shouldn't.


# TODO: There's some weird issue with this page causing the entire server to stop serving
# pages if you hit reload. The whole point of moving this into a background thread was to 
# let people safely double-click ...

#####
#
# Start installation process
#
#####


set pkg_install_list [ad_get_client_property apm pkg_install_list]

ns_log Notice "Installing: $pkg_install_list"

# We unset the client property so we won't install these packages twice
ad_set_client_property apm pkg_install_list {}

if { ![empty_string_p $pkg_install_list] } {
    util_background_exec -name package-install -pass_vars { pkg_install_list } {

        set sql_files [list]

        foreach pkg_info $pkg_install_list {
            ns_log Notice "Installing $pkg_info"

            set package_key [pkg_info_key $pkg_info]
            set spec_file [pkg_info_spec $pkg_info]
            array set version [apm_read_package_info_file $spec_file]
            set final_version_name $version(name)

            if { [apm_package_version_installed_p $version(package.key) $version(name)] } {
        	# Already installed.

                # Enable this version, in case it's not already enabled
                if { ![apm_package_enabled_p $version(package.key)] } {
                    ns_log Notice "Package $version(package.key) $version(name) is already installed but not enabled, enabling"
                    apm_version_enable -callback apm_dummy_callback [apm_highest_version $version(package.key)]
                } else {
                    ns_log Notice "Package $version(package.key) $version(name) is already installed and enabled, skipping"
                }

        	continue
            }

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
                error "Error installing one of the packages"
            }
        }
    }
}

#####
#
# Display progress bar
#
#####


ReturnHeaders

ns_write {
<html>
<head>
<link rel="stylesheet" type="text/css" href="/resources/acs-subsite/site-master.css" media="all">
</head>
<body>

<div id="body">
  <div id="subsite-name">
    <if @title@ not nil>
      <h1 class="subsite-page-title">Installing packages...</h1>
    </if>
  </div>
  <div id="navbar-body">
    <div id="subnavbar-body">


<table align="center" style="margin-top: 144px; margin-bottom: 144px;">
  <tr>
    <td align="center">
      <p>Installing packages, please wait ...</p>
    </td>
  </tr>
  <tr>
    <td align="center">
      <div style="font-size:16pt;padding:2px; align: center;">
        <span id="progress1" style="background-color: #eeeeee;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id="progress2" style="background-color: #eeeeee;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id="progress3" style="background-color: #eeeeee;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id="progress4" style="background-color: #eeeeee;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id="progress5" style="background-color: #eeeeee;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
      </div>
    </td>
  </tr>
  <tr>
    <td align="center">
      <p style="margin-top: 36px">We will continue automatically when installation is complete.</p>
    </td>
  </tr>
</table>

      <div style="clear: both;"></div>
    </div>
  </div>
</div>


<script language="javascript">
var progressEnd = 5;// set to number of progress <span>'s.
var progressColor = 'blue';// set to progress bar color

var progressAt = progressEnd;
function progress_update() {
    if (progressAt > 0) {
        document.getElementById('progress'+progressAt).style.backgroundColor = '#eeeeee';
    }
    progressAt++;
    if (progressAt > progressEnd) progressAt = 1;
    document.getElementById('progress'+progressAt).style.backgroundColor = progressColor;
}
</script>

}

while { [util_background_running_p -name package-install] } {
    ns_write {<script language="javascript">progress_update();</script>}
    ns_sleep 1
}

#####
#
# Done
#
#####

set success_p [lindex [util_background_get_result -name package-install] 0]

set continue_url [export_vars -base local-install-4 { success_p }]
ns_write "<script language=\"javascript\">window.location='$continue_url';</script>"
ns_conn close

