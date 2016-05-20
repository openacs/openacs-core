ad_page_contract {

    Edit and write the CSS file

    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2007-09-29
    @cvs-id $Id$
} {
    {file_location}
    {css_location}
    {return_url:localurl "/"}
} -properties {
} -validate {
} -errors {
}

ds_require_permission [ad_conn package_id] "admin"

if {[file exists $file_location] && [file extension $file_location] eq ".css"} {

    ad_form -name css-edit -export {file_location css_location} -form {
	{css_path:text(inform)}
	{revision_html:text(inform)}
	{css_content:text(textarea)
	    {html {rows 40 cols 80}}
	}
	{css_description:text(text),optional }
    } -on_request {
	
	set package_id [ad_conn package_id]
	set css_path "<a href='[ns_quotehtml $css_location]'>$css_location</a>"
	set fp [open $file_location "r"]
	set css_content ""
	while { [gets $fp line] >= 0 } {
	    append css_content "$line \n"
	}
	close $fp

	set item_id [content::item::get_id_by_name -name $file_location -parent_id $package_id]
	set revision_html ""
	if {$item_id ne ""} {
	    append revision_html "<ol>"
	    db_foreach revision {select revision_id, publish_date, description
		from cr_revisions where item_id = :item_id order by publish_date desc
	    } {
		if { [content::revision::is_live -revision_id $revision_id] == "t" } {
		    set make_live "<strong>that's live!</strong>"
		} else {
		    set return_url_2 [ad_return_url]
		    set href [export_vars -base css-make-live -url {revision_id return_url_2 file_location}]
		    set make_live [subst {<a href="[ns_quotehtml $href]">make live!</a>}]
		}
		set return_url ""
		append revision_html [subst {
		    <li><a href="/o/$revision_id">$publish_date</a>
		    \[$make_live\]: [string range $description 0 50]</li>
		}]
	    }
	    append revision_html "</ol>"
	    file stat $file_location file_stat_arr
	    # mcordova: ugly things until I figure out how to do that in a
	    # better way...
	    set item_id [content::item::get_id_by_name -name $file_location -parent_id $package_id]
	    ns_log Notice " * * * the file $file_location (cr_item_id: $item_id) has that modif time: \[$file_stat_arr(mtime)\]"
	    #todo compare file mtime with live revision time
	    ## if they are not the same date, show user a warning
	    # recommening to make a new revision...
	} else {
	    append revision_html "<em>no revisions yet</em>"
	}
    } -on_submit {

	set package_id [ad_conn package_id]

	# Create new item if necessary
	set item_id [content::item::get_id_by_name -name $file_location -parent_id $package_id]
	if {$item_id eq ""} {

	    # Get the old version to initialize the item with
	    set fp [open "$file_location" "r"]
	    set old_css_content [read $fp]
	    close $fp

	    set item_id [content::item::new -name $file_location \
			     -parent_id $package_id \
			     -title "$css_location" \
			     -description "First revision" \
			     -text $old_css_content]
	}

	
	# Write the new content to the file
	if {[file exists $file_location] && [file extension $file_location] eq ".css"} {
	    set fp [open "${file_location}" "w"]
	    puts $fp "$css_content"
	    close $fp
	}

	# Store the new revision in the CR
	content::revision::new -item_id $item_id -title $css_location -description $css_description -is_live "t" -content $css_content

    } -after_submit {
	ad_returnredirect $return_url
    } -cancel_url $return_url
} else {
    ad_returnredirect $return_url
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
