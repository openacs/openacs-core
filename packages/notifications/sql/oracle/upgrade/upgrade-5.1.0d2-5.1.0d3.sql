-- 
-- packages/notifications/sql/oracle/upgrade/upgrade-5.1.0d2-5.1.0d3.sql
-- 
-- @author Stan Kaufman (skaufman@epimetrics.com)
-- @creation-date 2004-07-14
-- @cvs-id $Id$
--
-- see bug http://openacs.org/bugtracker/openacs/bug?bug_number=1973
-- Add the on delete cascade to 
--   request_id column of notification_requests
--   notifcation_id column of notifications
-- based on Peter's upgrade script
-- @author Peter Marklund

alter table notification_requests drop constraint notif_request_id_fk;
alter table notification_requests add constraint notif_request_id_fk
                              foreign key (request_id)
                              references acs_objects (object_id)
                              on delete cascade;

alter table notifications drop constraint notif_notif_id_fk;
alter table notifications add constraint notif_notif_id_fk
                              foreign key (notification_id)
                              references acs_objects (object_id)
                              on delete cascade;
