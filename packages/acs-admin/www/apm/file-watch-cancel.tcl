ad_page_contract {
    Stops watching a particular file or all files if
    no file is specified.
   
    @param watch_file The file to stop watching.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    {watch_file ""}
    {return_url ""}
}
apm_file_watch_cancel $watch_file

ad_returnredirect $return_url
