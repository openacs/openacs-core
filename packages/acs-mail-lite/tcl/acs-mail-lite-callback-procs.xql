<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!-- packages/acs-mail-lite/tcl/acs-mail-lite-callback-procs.xql -->
<!-- @author Malte Sussdorff (sussdorff@sussdorff.de) -->
<!-- @creation-date 2005-08-03 -->
<!-- @arch-tag: ef7b6a8f-d03c-4502-96ef-7fdd5c2713a4 -->
<!-- @cvs-id $Id$ -->

<queryset>
     <fullquery name="IncomingEmail.record_bounce">
      <querytext>

        update acs_mail_lite_bounce
        set bounce_count = bounce_count + 1
        where user_id = :user_id

      </querytext>
    </fullquery>

    <fullquery name="IncomingEmail.insert_bounce">
      <querytext>

        insert into acs_mail_lite_bounce (user_id, bounce_count)
        values (:user_id, 1)

      </querytext>
    </fullquery>

</queryset>