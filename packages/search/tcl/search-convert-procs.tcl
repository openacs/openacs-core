ad_library {
    Binaries conversion procedures for the search package.
    Thanks to Carsten Clasohm for suggesting the converter programs.

    @author Dirk Gomez <openacs@dirkgomez.de>
    @creation-date 2005-06-25
    @cvs-id $Id$
}


namespace eval search {}
namespace eval search::convert {}

ad_proc -public search::convert::binary_to_text {
    {-filename:required}
    {-mime_type:required}
} {
    Converts the binary file to text and returns this as a string.
    (Carsten Clasohm provided the converters.)

    @author Dirk Gomez <openacs@dirkgomez.de>
    @creation-date 2005-06-25
} {

    if {[file size $filename] == 0} {
        #
        # Some conversion programs choke on empty content
        #
        return ""
    }

    ad_try {

        switch -glob $mime_type {
            application/msword -
            application/vnd.ms-word {
                return [exec -- catdoc $filename]
            }
            application/msexcel -
            application/vnd.ms-excel {
                return [exec -ignorestderr -- xls2csv $filename]
            }
            application/mspowerpoint -
            application/vnd.ms-powerpoint {
                return [exec -- catppt $filename]
            }
            application/pdf {
                if {![util::file_content_check -type pdf -file $filename]} {
                    ns_log warning "search: $filename ($mime_type) is not a pdf file; skip indexing"
                    return ""
                } else {
                    return [exec -- pdftotext $filename -]
                }
            }
            application/vnd.oasis.opendocument.text -
            application/vnd.oasis.opendocument.text-template -
            application/vnd.oasis.opendocument.text-web -
            application/vnd.oasis.opendocument.text-master -
            application/vnd.oasis.opendocument.presentation -
            application/vnd.oasis.opendocument.presentation-template -
            application/vnd.oasis.opendocument.spreadsheet -
            application/vnd.oasis.opendocument.spreadsheet-template {
                if {![util::file_content_check -type zip -file $filename]} {
                    ns_log warning "search: $filename ($mime_type) is not a zip file; skip indexing"
                    return ""
                } else {
                    #
                    # Extract the markup...
                    #
                    set xml [exec -- [util::which unzip] -p $filename content.xml]
                    #
                    # ... and clean it up so that only the plain text remains.
                    #
                    return [string trim [ns_striphtml $xml]]
                }
            }
            application/vnd.openxmlformats-officedocument.* {
                #
                # File claims to be a MS Office Open XML Format
                #
                # Similar to ODF, these files are in fact a zip archive
                # containing a directory structure that describes the
                # document. The text content we are looking for is located
                # in a specific path for every document type, but the
                # principle is always the same: unzip the xml location
                # from the archive and return it stripped of any markup.
                #

                switch $mime_type {
                    application/vnd.openxmlformats-officedocument.presentationml.presentation {
                        #
                        # PowerPoint .pptx
                        #
                        set xml_path ppt/slides/*.xml
                    }
                    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet {
                        #
                        # Excel .xlsx
                        #
                        set xml_path xl/sharedStrings.xml
                    }
                    application/vnd.openxmlformats-officedocument.wordprocessingml.document {
                        #
                        # Word .docx
                        #
                        set xml_path word/document.xml
                    }
                    default {
                        #
                        # We do not support this file, exit.
                        #
                        return ""
                    }
                }

                #
                # First check that we can unzip the file
                #
                if {![util::file_content_check -type zip -file $filename]} {
                    ns_log warning "search: $filename ($mime_type) is not a zip file; skip indexing"
                    return ""
                }

                #
                # Extract the markup...
                #
                set xml [exec -- [util::which unzip] -p $filename $xml_path]
                #
                # ... and clean it up so that only the plain text remains.
                #
                return [string trim [ns_striphtml $xml]]
            }
            text/html {
                #
                # Reading the whole content into memory is not necessarily
                # the best when dealing with huge files. However, for
                # html-files this is probably ok.
                #
                return [ns_striphtml [template::util::read_file $filename]]
            }
            text/plain {
                #
                # Don't trust blindly the extension and try to use the
                # unix "file" command to get more info.
                #
                set file_command [::util::which file]
                if {$file_command ne ""} {
                    set result [exec -ignorestderr $file_command --mime-type $filename]
                    set mime_type [lindex $result 1]
                    #
                    # Maybe, we are too restrictve by the following test,
                    # but let us be conservative first.
                    #
                    if {$mime_type ne "text/plain"} {
                        #
                        # The available file is not what it preteneds to
                        # be. We could try further to extract content, but
                        # we give simply up here.
                        #
                        ns_log notice "search-convert: not a plain text file $result"
                        return ""
                    }
                }
                #
                # Reading the whole content into memory is not necessarily
                # the best when dealing with huge files. However, for
                # txt-files this is probably ok.
                #
                return [template::util::read_file $filename]
            }

            default {
                # If there's nothing implemented for a particular mime type
                # we'll just index filename and pathname
                return ""
            }
        }

    } on error {errorMsg} {
        ns_log error "SEARCH: conversion failed - cannot extract text from $filename ($mime_type): $errorMsg"
        return ""
    }

}



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
