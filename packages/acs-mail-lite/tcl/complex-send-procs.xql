<?xml version="1.0"?>
<queryset>


    <fullquery name="acs_mail_lite::complex_sweeper.get_complex_queued_message">
        <querytext>
            select id
            from acs_mail_lite_complex_queue
            where id=:id and (locking_server = '' or locking_server is NULL)
        </querytext>
    </fullquery>

    <fullquery name="acs_mail_lite::complex_sweeper.lock_queued_message">
        <querytext>
            update acs_mail_lite_complex_queue
               set locking_server = :locking_server
            where id=:id
        </querytext>
    </fullquery> 

    <fullquery name="acs_mail_lite::complex_sweeper.delete_complex_queue_entry">
        <querytext>
            delete from acs_mail_lite_complex_queue
            where id=:id
        </querytext>
    </fullquery>        



</queryset>
