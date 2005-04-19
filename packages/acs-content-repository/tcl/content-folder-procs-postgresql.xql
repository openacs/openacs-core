<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->

<queryset>
  
  <rdbms>
    <type>postgresql</type>
    <version>7.3</version>
  </rdbms>
  
  <fullquery name="content::folder::get_folder_from_package_not_cached.get_folder_id">
    <querytext>
        select folder_id from cr_folders where package_id=:package_id
        order by folder_id desc limit 1
    </querytext>
  </fullquery>

</queryset>
