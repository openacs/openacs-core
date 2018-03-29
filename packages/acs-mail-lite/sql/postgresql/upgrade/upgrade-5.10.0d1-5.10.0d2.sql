-- acs-mail-lite/sql/postgresql/upgrade/upgrade-5.9.1b3-5.9.1b4.sql
--
-- Add Incoming Mail Processing
--
create sequence acs_mail_lite_in_id_seq;

-- New tables

-- table tracking incoming email
create table acs_mail_lite_from_external (
       aml_email_id         integer primary key 
                            not null 
                            DEFAULT nextval ('acs_mail_lite_id_seq'), 
       -- Priority for processing incoming email in queue.
       -- Lower number processed first.
       priority             integer,
       -- using varchar instead of text for indexing
       -- to and from email are defined according to headers. 
       -- See table acs_mail_lite_ie_headers
       to_email_addrs       varchar(1000),
       from_email_addrs     text,
       subject              text,
       -- see acs_mail_lite_send_msg_id_map.msg_id
       msg_id               bigint,
       -- used by prioritization calculations
       -- For IMAP4 this is size defined by rfc822
       size_chars           numeric,
       -- time email received from server in seconds since tcl epoch
       received_cs          bigint,
       -- Answers question: 
       -- Has all ACS Mail Lite processes finished for this email?
       -- Processes like parsing email, bounced email, input validation
       processed_p      boolean,
       -- Answers question: 
       -- Have all callbacks related to this email finished processing?
       -- Upon release, delete  all components of aml_email_id also from
       -- tables acs_mail_lite_ie_headers, acs_mail_lite_ie_body_parts, and
       -- acs_mail_lite_ie_files.
       -- Release essentially means its available to be deleted.
       release_p boolean
);

create index acs_mail_lite_from_external_aml_email_id_idx 
       on acs_mail_lite_from_external (aml_email_id);
create index acs_mail_lite_from_external_processed_p_idx 
       on acs_mail_lite_from_external (processed_p);
create index acs_mail_lite_from_external_release_p_idx 
       on acs_mail_lite_from_external (release_p);



-- Some services are offered between sessions of importing incoming email.
-- A unique ID provided by 
-- acs_mail_lite_email_uid_id_map.uid_ext 
-- is designed to
-- support UIDs for each email that are consistent between import sessions
-- from external source, such as specified by IMAP4 rfc3501 
-- https://tools.ietf.org/html/rfc3501
-- It is also expected that each mailbox.host, mailbox and user are
-- consistent for duration of the service.
-- And yet, experience knows that sometimes email servers change
-- and UIDs for an email change with it.
-- Users switching email servers of an email account using a IMAP4 client 
-- might hassle with moving email, but
-- in the process they generally know what is happening. They don't re-read
-- all the email. 
-- We want to avoid this server re-reading and processing email 
-- that has already been processed, when the UID of emails change.
-- The Questions become:

-- What scenarios might we run into?
-- Another  user resetting flags.
-- A server migration or restore with some conflicting UIDs.

-- Can we recognize a change in server?
-- If so, can we signal ACS Mail Lite to ignore existing email 
-- in a new environment?
-- Also, we should have a manual override to not ignore or ignore
-- in case of false positive and false negative triggers.

-- Can we recognize if another user accesses the same email account
-- and arbitrarily selects some prior messages to unread?
-- Yes. The purpose of acs_mail_lite_email_uid_id_map is to act as a log 
-- of prior processed messages.
-- If total new messages is a significant percentage of all messages
-- and service has been working for a week or more,
-- use statistics to generate a reasonable trigger.
-- Weekly produce a revised distribution curve of weekly counts of incoming.
-- If percentile is over 200%.. ie twice the weekly maximum..
-- Also, test, for example, if new message count is less than
-- prior total, there's more of a chance that they are new messages;
-- Maybe check for one or two duplicates.
-- If new message count is over the total prior message count, flag a problem.
-- rfc3501 2.3.1.1.  ..A client can only assume.. at the time
--        that it obtains the next unique identifier value.. that
--        messages arriving after that time will have a UID greater
--        than or equal to that value...


-- Can we recognize a change in server?
-- rfc3501 does not specify a unqiue server id
-- It specifies a unique id for a mailbox: UIDVALIDITY
-- UIDVALIDITY is optional, quite useful.
-- Rfc3501 specifies a unique id for each email: UID.
-- We can assign each email a more unique reference:
-- mailbox.host + mailbox.name + UIDVALIDITY (of mailbox) + UID.
-- We are more specific so that we detect more subtle cases of 
-- server change, where checks by UID and UIDVALIDITY may not.


-- For example, when migrating email service and
-- and the new system initially restores the UIVALIDITY and message UID,
-- but references a different state of each email. The cause
-- of such cases are reasonable. For example, restoring 
-- from backup to a new email host or restoring
-- before some batch event changed a bunch of things. So,
-- src_ext = mailbox.host + (user?) + mailbox.name + UIDVALIDITY
-- Leave user out for now..
-- Priority is to have a robust way to ignore 
-- prior messages recognized as 'new' messages.

create table acs_mail_lite_email_uid_id_map (
       -- unqique internal inbound email id
       -- src_ext_id identifies source, but is redundant
       -- for identifying a unique email. 
       aml_email_id  integer not null,
       --uisng varchar instead of text for indexing purposes
       -- Each UID externally defined such as from imap4 server
       uid_ext varchar(3000) not null,
       -- Each external source may apply a different uid.
       -- This is essentially an arbitrary constant frame reference between 
       -- connecting sessions with external server in most scenarios.
       -- For IMAP4v1 rfc3501  2.3.1.1. item 4 ..combination of
       -- mailbox.name, UIDVALIDITY, and UID must refer to a single 
       -- immutable message on that server forever. 
       -- default is: 
       -- ExternalSource parameter mailbox.name  
       -- and UIDVALIDITY with dash as delimiter
       -- where ExternalSource parameter is 
       -- either blank or maybe mailbox.host for example.
       -- external source reference id
       -- see acs_mail_lite_email_src_ext_id_map.aml_src_id
       src_ext_id integer
);

create index acs_mail_lite_email_uid_id_map_uid_ext_idx
	on acs_mail_lite_email_uid_id_map (uid_ext);
create index acs_mail_lite_email_uid_id_map_src_ext_id_idx
	on acs_mail_lite_email_uid_id_map (src_ext_id);

create table acs_mail_lite_email_src_ext_id_map (
       aml_src_id integer not null,
       src_ext varchar(1000) not null
);



-- Packages that are services, such as ACS Mail Lite, do not have a web UI.
-- Scheduled procs cannot read changes in values of package parameters
-- or get updates via web UI connections, or changes in tcl via apm.
-- Choices are updates via nsv variables and database value updates.
-- Choices via database have persistence across server restarts.
-- Defaults are set in acs_mail_lite::sched_parameters
-- These all are used in context of processing incoming email 
-- unless stated otherwise.
-- Most specific flag takes precedence.
-- If an email is flagged high priority by package_id and
-- low priority by subject glob. It is assigned low priority.
-- Order of specificity.
-- medium default package_id party_id subject_id object_id
-- party_id can be group_id or user_id
-- If fast and low flag the same specificity for an email, low is chosen.
create table acs_mail_lite_ui (
       -- scan_replies_est_dur_per_cycle_s_override see www/doc/analysis-notes
       sredpcs_override integer,
       -- Answers question: Reprocess old email?
       reprocess_old_p boolean,
       -- Max number of concurrent threads for high priority processing
       max_concurrent integer,
       -- Any incoming email body part over this size is stored in file 
       -- instead of database.
       max_blob_chars integer,
       -- Minimum threshold for default medium (standard) priority
       mpri_min integer,
       -- Maximum value for default medium (standard) priority
       mpri_max integer,
       --space delimited list of package_ids to process at fast/high priority
       hpri_package_ids text,
       --space delimited list of package_ids to process at low priority
       lpri_package_ids text,
       --space delimited list of party_ids to process at fast/high priority
       hpri_party_ids text,
       --space delimited list of party_ids to process at low priority
       lpri_party_ids text,
       -- a glob for searching subjects to flag for fast/high priority 
       hpri_subject_glob text,
       -- a glob for searching subjects to flag for low priority 
       lpri_subject_glob text,
       --space delimited list of object_ids to process at fast/high priority
       hpri_object_ids text,
       --space delimited list of object_ids to process at low priority
       lpri_object_ids text,
       --filters to reject input as early as possible in processing inbound
       --Each filter is a name value in standard tcl list format
       --where name is a header name
       reject_on_hit text,
       reject_on_miss text
);


-- This table has similar requirements to acs_mail_lite_ui
-- proc acs_mail_lite_imap_conn_* needs to be able to update values
-- within scheduled procs without restarting server.
-- Port is ignored. Added because it is a common requirement of connections
-- that might one day be useful here, too.
create table acs_mail_lite_imap_conn (
       -- mailbox.host
       ho text,
       -- you guessed it
       pa text,
       -- port
       po integer,
       --timeout
       ti integer,
       -- user
       us text,
       -- mailbox.name See nsimap documentation for definition
       na text,
       -- space separated list of flags for imap related modifications
       -- ssl means connect via ssl.
       -- novalidatecert means accept a self-signed certificate
       fl text
);


-- Following tables store parsed incoming email for processing by callbacks
-- defined in the rest of OpenACS

-- incoming email headers
-- There should be a size limit per unit time from each source
-- to prevent DDOS attacks and such (at least to the imap system).
-- 
create table acs_mail_lite_ie_headers (
       -- incoming email
       -- only includes headers useful in processing the queue
       -- Such as
       -- size
       -- from
       aml_email_id integer,
       -- header name, one header per row
       -- For all headers together, see acs_mail_lite_ie_parts.c_type=headers
       -- Special case: h_name = struct means
       -- h_value contains entire value returned from ns_imap struct
       -- as a tcl list
       h_name text,
       h_value text
);

create index acs_mail_lite_ie_headers_aml_email_id_idx
	on acs_mail_lite_ie_headers (aml_email_id);

-- incoming email body parts
-- including email file attachments and file content
-- A part may be a filename. The filename data model is added
-- to the parts table to reduce code complexity.
-- An attached or inline file is a kind of part.
create table acs_mail_lite_ie_parts (
       aml_email_id integer,
       section_id integer,
       
       -- In addition to content_type, there is a special case:
       -- headers, which contains all headers for email
       -- content_type = c_type
       c_type text,
       -- If type has a filename, this is original filename.
       filename text,
       -- If c_type is multipart, content is blank. part_id is branched.
       content text,
       -- An alternate filepathname for large blob, or
       -- A local absolute filepath location
       c_filepathname text
);

create index acs_mail_lite_ie_parts_aml_email_id_idx
	on acs_mail_lite_ie_parts (aml_email_id);


-- incoming email parts, name value pairs of
create table acs_mail_lite_ie_part_nv_pairs (
       aml_email_id integer,
       -- Usage is same as acs_mail_lite_ie_parts.section_id
       section_id integer,
       -- name value pair
       p_name text,
       p_value text
);

create index acs_mail_lite_ie_part_nv_pairs_aml_email_id_idx
	on acs_mail_lite_ie_part_nv_pairs (aml_email_id);

create table acs_mail_lite_ie_section_ref_map (
       -- 'Section' refers to usage with 'part' reference in 'ns_imap body'
       -- Email parts can contain multiple parts.
       -- Each multiple part can contain multiple parts.

       -- Section_ref is an absolute reference of a part
       -- including the parts it is contained in, and
       -- delimited by period.
       -- It is defined by:
       --  ns_imap body #s msgno part
       -- And yet, this reference system holds for any email
       -- storage, so is adopted for generic use as well.

       -- Default reference is value of 1.
       -- A two part message has values 1 and 2.
       -- Part 2 of a 3 part email (2/3) has reference '2'
       -- If part 2 is also multiple parts, then
       -- part 1 of part 2 of email has reference '2.1' and so on.

       -- Mapping is constant for each case.
       -- For example, '1.2.2.1' will always point to the same integer.
       -- So do not alter values as they are likely used by
       -- multiple emails.


       section_ref varchar(300),
       section_id integer
);

create index acs_mail_lite_ie_section_ref_map_section_ref_idx
	on acs_mail_lite_ie_section_ref_map (section_ref);
create index acs_mail_lite_ie_section_ref_map_section_id_idx
	on acs_mail_lite_ie_section_ref_map (section_id);

--
create table acs_mail_lite_send_msg_id_map (
       -- a randomized number unique to this table
       -- unique not null
       msg_id        text primary key,
       package_id    integer
                     constraint aml_package_id_fk
                     references apm_packages,
       party_id      integer
                     constraint aml_from_external_party_id_fk
                     references parties (party_id),
       object_id     integer 
                     constraint aml_from_external_obect_id_fk
                     references acs_objects (object_id),
       -- Indicate approximate time when this email is created
       datetime_cs   integer,
       -- other data or parameters to associate with email
       other         text
);

create index acs_mail_lite_send_msg_id_map_msg_id_idx
       on acs_mail_lite_send_msg_id_map (msg_id);
