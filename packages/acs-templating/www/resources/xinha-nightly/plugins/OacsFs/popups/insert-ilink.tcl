ad_page_contract {
  @author Guenter Ernst guenter.ernst@wu-wien.ac.at, 
  @author Gustaf Neumann neumann@wu-wien.ac.at
  @creation-date 13.07.2004
  @cvs-id $Id$
} {
  {fs_package_id:integer,optional}
  {folder_id:integer,optional}
  {file_types *}
}
 
set selector_type "file"
set file_selector_link [export_vars -base file-selector \
			    {fs_package_id folder_id selector_type file_types}]
set fs_found 1

#set user_id [ad_verify_and_get_user_id]
#permission::require_permission -party_id $user_id -object_id $fs_package_id \
#    -privilege "admin"

ad_return_template
