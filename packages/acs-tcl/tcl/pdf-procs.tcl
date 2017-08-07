# packages/acs-tcl/tcl/pdf-procs.tcl

ad_library {

    Functions for handling Template-documents

    @author Christian Langmann (C_Langmann@gmx.de)
    @creation-date 2005-07-07
}

namespace eval text_templates {}

ad_proc -public text_templates::create_pdf_content {
    {-template_id:required}
    {-set_var_call:required}
} {

    Create the pdf content from a template

    @author Christian Langmann (C_Langmann@gmx.de)
    @creation-date 2005-07-07

    @param template_id The template to use for the preview. It is \
	assumed that the template_id is the same as the revision_id to \
	be used for the template.

    @param set_var_call procedure-name which sets the variables used
								    
    @return the pdf-file-name
} {

    set tmp_filename [ad_tmpnam]
    # create html.file
    set html_content [create_html_content -template_id $template_id -set_var_call $set_var_call]
    set tmp_html_filename "${tmp_filename}.html"
    set fp [open $tmp_html_filename w]
    puts $fp $html_content
    close $fp

    # create pdf-file
    set tmp_pdf_filename "${tmp_filename}.pdf"
    set htmldoc_bin [parameter::get -parameter "HtmlDocBin" -default "/usr/bin/htmldoc"]
    if {[catch {exec $htmldoc_bin --webpage --quiet -t pdf -f $tmp_pdf_filename $tmp_html_filename} err]} {
	ns_log Notice "Error during conversion from html to pdf: $err"
    }
    file delete -- $tmp_html_filename

    if {[file exists $tmp_pdf_filename]} {
	return $tmp_pdf_filename
    } else {
	return ""
    }
}


ad_proc -public text_templates::create_pdf_from_html {
    {-html_content:required}
} {
    The HTML Content is transformed into a PDF file
    
    @param html_content HTML Content that is transformed into PDF
    @return filename of the pdf file
} {
    set tmp_filename [ad_tmpnam]
    set tmp_html_filename "${tmp_filename}.html"
    set fp [open $tmp_html_filename w]
    puts $fp $html_content
    close $fp

    # create pdf-file
    set tmp_pdf_filename "${tmp_filename}.pdf"
    set htmldoc_bin [parameter::get -parameter "HtmlDocBin" -default "/usr/bin/htmldoc"]
    if {[catch {exec $htmldoc_bin --webpage --quiet -t pdf -f $tmp_pdf_filename $tmp_html_filename} err]} {
	ns_log Notice "Error during conversion from html to pdf: $err"
    }
    if {[file exists $tmp_pdf_filename]} {
	return $tmp_pdf_filename
    } else {
	return ""
    }
}

ad_proc -public text_templates::store_final_document {
    {-pdf_file:required}
    {-folder_id:required}
    {-title:required}
    {-description:required}
} {
    The document is stored in the given folder.
    
    @author Christian Langmann (C_Langmann@gmx.de)
    @creation-date 2005-07-07
    @param pdf_file the pdf-file to save
    @param folder_id the folder the document is stored in
    @param title Title or name of the document
    @param description Description of the document
    @return item_id
    
} {
    set file_size [file size $pdf_file]
    set item_id [cr_import_content -title $title -description $description $folder_id $pdf_file $file_size application/pdf $title]
    return $item_id
}

ad_proc -private text_templates::create_html_content {
    {-template_id ""}
    {-set_var_call:required}
    {-filename:required}
} {

    Create the filled out template as html

    @author Christian Langmann (C_Langmann@gmx.de)
    @creation-date 2005-07-07

    @param template_id The template to use for the preview. It is assumed that the template_id is the same as the revision_id to be used for the template.
    @param set_var_call procedure-name which sets the variables used
} {

    {*}$set_var_call
    
    # retrieve template and write to tmpfile
    # set content [content::get_content_value $template_id]
    set file [open $filename]
    fconfigure $file -translation binary
    set content [read $file]

    # parse template and replace placeholders
    eval [template::adp_compile -string $content]
    set final_content $__adp_output

    return $final_content
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
