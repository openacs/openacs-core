ad_page_contract {
    Download messages from the database.

    @author Peter Marklund
} {
    locale
    package_key
    {return_url "/acs-lang/admin"}
}

if ![parameter::get -parameter BehaveLikeTranslationServerP -default 0] { 
    ad_returnredirect [export_vars -base "admin/download-messages" {locale package_key} ]
}

set page_title "Download"

# Create a temporary directory
set tmp_path [ns_tmpnam]
file mkdir $tmp_path

set system_charset [ad_locale charset $locale]
set file_charset [ad_decode $system_charset "ISO-8859-1" $system_charset utf-8]

set filename "${package_key}.${locale}.${file_charset}.xml"

# Get messages and descriptions for the locale
set messages_list [list]
set descriptions_list [list]
lang::catalog::all_messages_for_package_and_locale $package_key $locale
template::util::multirow_foreach all_messages {
    lappend messages_list @all_messages.message_key@ @all_messages.message@
    lappend descriptions_list @all_messages.message_key@ @all_messages.description@
}

# Put the messages and descriptions in an array so it's easier to access them
array set messages_array $messages_list
array set descriptions_array $descriptions_list

# Sort the keys so that it's easier to manually read and edit the catalog files
set message_key_list [lsort -dictionary [array names messages_array]]


# Write the to a temp directory
set catalog_file_id [open $tmp_path/$filename w]
set file_encoding [ns_encodingforcharset [lang::catalog::default_charset_if_unsupported $file_charset]]
fconfigure $catalog_file_id -encoding $file_encoding

# Open the root node of the document
puts $catalog_file_id "<?xml version=\"1.0\" encoding=\"$file_charset\"?>
<message_catalog package_key=\"$package_key\" package_version=\"[lang::catalog::system_package_version_name $package_key]\" locale=\"$locale\" charset=\"$file_charset\">
"

# Loop over and write the messages to the file
set message_count "0"
foreach message_key $message_key_list {
    puts $catalog_file_id "  <msg key=\"[ad_quotehtml $message_key]\">[ad_quotehtml $messages_array($message_key)]</msg>"
    if { [exists_and_not_null descriptions_array($message_key)] && $locale == "en_US" } {
	puts $catalog_file_id "  <description key=\"[ad_quotehtml $message_key]\">[ad_quotehtml $descriptions_array($message_key)]</description>\n"
    }
    incr message_count
}

# Close the root node and close the file
puts $catalog_file_id "</message_catalog>"

close $catalog_file_id       

ns_returnfile 200 file/xml $tmp_path/$filename