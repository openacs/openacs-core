<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!-- packages/acs-templating/tcl/file-procs.xql -->
<!-- @author Malte Sussdorff (sussdorff@sussdorff.de) -->
<!-- @creation-date 2005-06-21 -->
<!-- @arch-tag: 46e3f4fa-527d-4cf1-b351-474189a46615 -->
<!-- @cvs-id $Id$ -->

<queryset>
  <fullquery name="template::util::file::generate_filename.get_parties_existing_filenames">
  <querytext>
    select name
      from cr_items
     where parent_id = :party_id
  </querytext>
</fullquery>

</queryset>