ad_page_contract {
    Build package repository.

    @cvs-id $Id$
    @author Lars Pind (lars@collaboraid.biz)
}

# TODO: Build repository in temp dir, then rename

#----------------------------------------------------------------------
# Configuration Settings
#----------------------------------------------------------------------

set cvs_command "cvs"
set cvs_root ":pserver:anonymous@cvs.openacs.org:/cvsroot"

set work_dir "[acs_root_dir]/repository-builder/"

set repository_dir "[acs_root_dir]/www/repository/"
set repository_url "http://openacs.org/repository/"

set channel_index_template "/packages/acs-admin/www/apm/repository-channel-index"
set index_template "/packages/acs-admin/www/apm/repository-index"

# this shouldn't be necessary because I removed the openacs-5-0-compat tags
# from these packages
#set exclude_package_list { cms cms-news-demo glossary site-wide-search spam library }
set exclude_package_list {}
set head_channel "5-3"

# Set this to 1 to only checkout sample packages -- useful for debugging and testing
set debug_p 0

#----------------------------------------------------------------------
# Prepare output
#----------------------------------------------------------------------

ReturnHeaders
ns_write [ad_header "Building repository"]
ns_write "<h1>Building Package Repository</h1><hr>"
ns_write <ul>

#----------------------------------------------------------------------
# Find available channels
#----------------------------------------------------------------------

# Prepare work dir
file mkdir $work_dir

cd $work_dir

catch { exec $cvs_command -d $cvs_root -z3 co openacs-4/readme.txt }
catch { exec $cvs_command -d $cvs_root -z3 log -h openacs-4/readme.txt } output

set lines [split $output \n]
for { set i 0 } { $i < [llength $lines] } { incr i } {
    if { [string equal [string trim [lindex $lines $i]] "symbolic names:"] } {
        incr i
        break
    }
}

array set channel_tag [list]
array set channel_bugfix_version [list]

for { } { $i < [llength $lines] } { incr i } {
    # Tag lines have the form   tag: cvs-version
    #     openacs-5-0-0-final: 1.25.2.5

    if { ![regexp {^\s+([^:]+):\s+([0-9.]+)} [lindex $lines $i] match tag_name version_name] } {
        break
    }
    
    # Look for tags named 'openacs-x-y-compat'
    if { [regexp {^openacs-([1-9][0-9]*-[0-9]+)-compat$} $tag_name match oacs_version] } {
        
        set major_version [lindex [split $oacs_version "-"] 0]
        set minor_version [lindex [split $oacs_version "-"] 1]

        if { $major_version >= 5 } {
            set channel "${major_version}-${minor_version}"

            ns_write "<li>Found channel $channel using tag $tag_name\n"

            set channel_tag($channel) $tag_name
        }
    }
}

set channel_tag($head_channel) HEAD


ns_write "<li>Channels are: [array get channel_tag]</ul>\n"


#----------------------------------------------------------------------
# Read all package .info files, building manifest file
#----------------------------------------------------------------------

# Wipe and re-create the working directory
file delete -force $work_dir
file mkdir ${work_dir}
cd $work_dir
    
foreach channel [lsort -decreasing [array names channel_tag]] {
    ns_write "<h2>Channel $channel using tag $channel_tag($channel)</h2><ul>"

    # Wipe and re-create the checkout directory
    file delete -force "${work_dir}openacs-4"
    
    # Prepare channel directory
    set channel_dir "${work_dir}repository/${channel}/"
    file mkdir $channel_dir

    # Store the list of packages we've seen for this channel, so we don't include the same package twice
    # Seems odd, but we have to do this given the forked packages sitting in /contrib
    set packages [list]
    
    # Checkout from the tag given by channel_tag($channel)
    if { $debug_p } {
        # Smaller list for debugging purposes
        set checkout_list [list \
                               $work_dir $cvs_root openacs-4/packages/acs-core-docs
                           ]
    } else {
        # Full list for real use
        set checkout_list [list \
                               $work_dir $cvs_root openacs-4/packages \
                               $work_dir $cvs_root openacs-4/contrib/packages]
    }
    
    foreach { cur_work_dir cur_cvs_root cur_module } $checkout_list {
        cd $cur_work_dir
        if { $channel_tag($channel) ne "HEAD" } {
            ns_write "<li>Checking out $cur_module from CVS:"
            catch { exec $cvs_command -d $cur_cvs_root -z3 co -r $channel_tag($channel) $cur_module } output
            ns_write " [llength $output] files\n"
        } else {
            ns_write "<li>Checking out $cur_module from CVS:"
            catch { exec $cvs_command -d $cur_cvs_root -z3 co $cur_module } output
            ns_write " [llength $output] files\n"
        }
    }
    cd $work_dir

    set manifest {<manifest>}
    append manifest \n

    template::multirow create packages \
        package_path package_key version pretty_name \
        package_type summary description \
        release_date vendor_url vendor \
        license_url license maturity maturity_text 
    
    foreach packages_dir \
        [list "${work_dir}openacs-4/packages" \
             "${work_dir}openacs-4/contrib/packages"] {

        foreach spec_file [lsort [apm_scan_packages $packages_dir]] {
        
            set package_path [eval file join [lrange [file split $spec_file] 0 end-1]]
            set package_key [lindex [file split $spec_file] end-1]
            set version_id [apm_version_id_from_package_key $package_key]

            if { [lsearch -exact $exclude_package_list $package_key] != -1 } {
                ns_write "Package $package_key is on list of packages to exclude - skipping"
                continue
            }

            if { [array exists version] } {
                array unset version
            }
            if { [info exists version] } {
                unset version
            }

            with_catch errmsg {
                array set version [apm_read_package_info_file $spec_file]
                
                if { [lsearch -exact $packages $version(package.key)] != -1 } {
                    ns_write "<li>Skipping package $package_key, because we already have another version of it"
                } else {
                    lappend packages $version(package.key)
                    
                    append manifest {  } {<package>} \n
                
                    append manifest {    } {<package-key>} [ad_quotehtml $version(package.key)] {</package-key>} \n
                    append manifest {    } {<version>} [ad_quotehtml $version(name)] {</version>} \n
                    append manifest {    } {<pretty-name>} [ad_quotehtml $version(package-name)] {</pretty-name>} \n
                    append manifest {    } {<package-type>} [ad_quotehtml $version(package.type)] {</package-type>} \n
                    append manifest {    } {<summary>} [ad_quotehtml $version(summary)] {</summary>} \n
                    append manifest {    } {<description format="} [ad_quotehtml $version(description.format)] {">} 
                    append manifest [ad_quotehtml $version(description)] {</description>} \n
                    append manifest {    } {<release-date>} [ad_quotehtml $version(release-date)] {</release-date>} \n
                    append manifest {    } {<maturity>} [ad_quotehtml $version(maturity)] {</maturity>} \n
                    append manifest {    } {<license url="} [ad_quotehtml $version(license_url)] {">}
		    append manifest [ad_quotehtml $version(license)] {</license>} \n
                    append manifest {    } {<vendor url="} [ad_quotehtml $version(vendor.url)] {">} 
                    append manifest [ad_quotehtml $version(vendor)] {</vendor>} \n

                    append manifest [apm::package_version::attributes::generate_xml \
                                         -version_id $version_id \
                                         -indentation {    }]

                    template::multirow append packages \
                        $package_path $package_key $version(name) $version(package-name) \
                        $version(package.type) $version(summary) $version(description) \
                        $version(release-date) $version(vendor.url) $version(vendor) \
                        $version(license_url) $version(license) $version(maturity) [apm::package_version::attributes::maturity_int_to_text $version(maturity)]

                    set apm_file "${channel_dir}${version(package.key)}-${version(name)}.apm"

                    ns_write "<li>Building package $package_key for channel $channel\n"
                    
                    set files [apm_get_package_files \
                                   -all_db_types \
                                   -package_key $version(package.key) \
                                   -package_path $package_path]
                    
                    if { [llength $files] == 0 } {
                        ns_write "No files in package"
                    } else {
                        set cmd [list exec [apm_tar_cmd] cf -  2>/dev/null]

                        # The path to the 'packages' directory in the checkout
                        set packages_root_path [eval file join [lrange [file split $spec_file] 0 end-2]]
                        set tmp_filename [ns_tmpnam]
                        lappend cmd  --files-from $tmp_filename -C $packages_root_path

                        set fp [open $tmp_filename w]
                        foreach file $files {
                          puts $fp $package_key/$file
                        }
                        close $fp

                        lappend cmd "|" [apm_gzip_cmd] -c ">" $apm_file
                        #ns_log Notice "Executing: [ad_quotehtml $cmd]"
                        eval $cmd
                    }


                    set apm_url "${repository_url}${channel}/${version(package.key)}-${version(name)}.apm"

                    append manifest {    } {<download-url>} $apm_url {</download-url>} \n
                    foreach elm $version(provides) {
                        append manifest {    } "<provides url=\"[ad_quotehtml [lindex $elm 0]]\" version=\"[ad_quotehtml [lindex $elm 1]]\" />" \n
                    }
                    
                    foreach elm $version(requires) {
                        append manifest {    } "<requires url=\"[ad_quotehtml [lindex $elm 0]]\" version=\"[ad_quotehtml [lindex $elm 1]]\" />" \n
                    }
                    
                    append manifest {  } {</package>} \n
                } 
            } {
                global errorInfo
                ns_write "<li> Error on spec_file $spec_file: [ad_quotehtml $errmsg]<br>[ad_quotehtml $errorInfo]\n"
            }
        }
    }
    append manifest {</manifest>} \n
    
    ns_write "<li>Writing $channel manifest to ${channel_dir}manifest.xml"
    set fw [open "${channel_dir}manifest.xml" w]
    puts $fw $manifest
    close $fw

    ns_write "<li>Writing $channel index page to ${channel_dir}index.html"
    set fw [open "${channel_dir}index.html" w]

    # sort by package name
    set packages [lsort $packages]
    puts $fw [ad_parse_template -params [list channel packages] -- $channel_index_template]
    close $fw

    ns_write "<li> Channel $channel complete.</ul>\n"
    
}

ns_write "<h2>Finishing Repository</h2><ul>"

# Write the index page
ns_write "<li>Writing repository index page to ${work_dir}repository/index.html"
template::multirow create channels name
foreach channel [lsort -decreasing [array names channel_tag]] {
    template::multirow append channels $channel
}
set fw [open "${work_dir}repository/index.html" w]
puts $fw [ad_parse_template -params [list channels] -- $index_template]
close $fw


# Without the trailing slash
set work_repository_dirname "${work_dir}repository"
set repository_dirname [string range $repository_dir 0 end-1]
set repository_bak "[string range $repository_dir 0 end-1].bak"

ns_write "<li>Moving work repository $work_repository_dirname to live repository dir at <a href=\"/repository\/>$repository_dir</a>\n"

if { [file exists $repository_bak] } {
    file delete -force $repository_bak
}
if { [file exists $repository_dirname] } {
    file rename $repository_dirname $repository_bak
}
file rename $work_repository_dirname  $repository_dirname

ns_write "</ul> <h2>DONE</h2>\n"
