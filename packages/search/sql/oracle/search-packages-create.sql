--
--  Copyright (C) 2005 MIT
--
--  This file is part of dotLRN.
--
--  dotLRN is free software; you can redistribute it and/or modify it under the
--  terms of the GNU General Public License as published by the Free Software
--  Foundation; either version 2 of the License, or (at your option) any later
--  version.
--
--  dotLRN is distributed in the hope that it will be useful, but WITHOUT ANY
--  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
--  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
--  details.
--

--
-- Create database packages for .LRN site-wide search
--
-- @author <a href="mailto:openacs@dirkgomez.de">Dirk Gomez</a>
-- @version $Id$
-- @creation-date 13-May-2005

-- Partly ported from ACES.

-- The site_wide_search packages holds generally useful
-- PL/SQL procedures and functions.

create or replace package site_wide_search
as
  procedure logger (p_logmessage varchar);
end site_wide_search;
/
show errors

create or replace package body site_wide_search
as
  procedure logger (p_logmessage varchar) is
  begin 
    insert into sws_log_messages (logmessage) values (p_logmessage);
  end logger;
end site_wide_search;
/
show errors

--------------------------------------------------------
-- Forum triggers and procedures

create or replace trigger forums_messages_sws_insert_tr
  after insert on forums_messages for each row
begin
  insert into site_wide_index (object_id, object_name, datastore)
    values  (:new.message_id, :new.subject, 'a');
end;
/
show errors

create or replace trigger forums_messages_sws_update_tr
  after update on forums_messages for each row
begin
  update site_wide_index 
    set object_name=:new.subject,
        datastore='a'
    where object_id = :new.message_id;
end;
/
show errors
    
create or replace trigger forums_messages_sws_delete_tr
  after delete on forums_messages for each row
begin
  delete from site_wide_index
    where object_id = :old.message_id;
end;
/
show errors

create or replace procedure forums_messages_sws_helper (p_tlob in out nocopy clob, p_object_id in varchar)
is
  cursor forums_messages_cursor(v_object_id char) is
  select subject, content, p.first_names || ' ' || p.last_name as
      author_name, parties.email
  from  forums_messages fm, persons p, parties
  where p.person_id = fm.user_id
  and   parties.party_id = p.person_id
  and   fm.message_id = v_object_id;
begin
  for forums_messages_record in forums_messages_cursor(p_object_id) loop
     dbms_lob.writeappend(p_tlob, length('<oneline>'), '<oneline>');
     if forums_messages_record.subject is not null then
        dbms_lob.writeappend(p_tlob, length(forums_messages_record.subject) + 1, forums_messages_record.subject || ' ');
     end if;
     dbms_lob.writeappend(p_tlob, length('</oneline>'), '</oneline>');
     dbms_lob.writeappend(p_tlob, length(forums_messages_record.author_name) + 1, forums_messages_record.author_name || ' ');
     if forums_messages_record.content is not null then
         dbms_lob.append(p_tlob, forums_messages_record.content);
     end if;
  end loop;
end;
/
show errors;

--------------------------------------------------------
-- static-portal triggers and procedures

create or replace trigger static_portal_sws_insert_tr
  after insert on static_portal_content for each row
begin
  insert into site_wide_index (object_id, object_name, datastore)
    values  (:new.content_id, :new.pretty_name, 'a');
end;
/
show errors

create or replace trigger static_portal_sws_update_tr
  after update on static_portal_content for each row
begin
  update site_wide_index 
    set object_name=:new.pretty_name,
        datastore='a'
    where object_id = :new.content_id;
end;
/
show errors
    
create or replace trigger static_portal_sws_delete_tr
  after delete on static_portal_content for each row
begin
  delete from site_wide_index
    where object_id = :old.content_id;
end;
/
show errors

create or replace procedure static_portal_sws_helper (p_tlob in out nocopy clob, p_object_id in varchar)
is
  cursor static_portal_content_cursor(v_object_id char) is
  select pretty_name, body, p.first_names || ' ' || p.last_name as
      author_name, parties.email
  from  static_portal_content fm, persons p, parties, acs_objects ao
  where fm.content_id = ao.object_id
  and   p.person_id = ao.creation_user
  and   parties.party_id = p.person_id
  and   fm.content_id = v_object_id;
begin
  for static_portal_content_record in static_portal_content_cursor(p_object_id) loop
     dbms_lob.writeappend(p_tlob, length('<oneline>'), '<oneline>');
     if static_portal_content_record.pretty_name is not null then
        dbms_lob.writeappend(p_tlob, length(static_portal_content_record.pretty_name) + 1, static_portal_content_record.pretty_name || ' ');
     end if;
     dbms_lob.writeappend(p_tlob, length('</oneline>'), '</oneline>');
     dbms_lob.writeappend(p_tlob, length(static_portal_content_record.author_name) + 1, static_portal_content_record.author_name || ' ');
     if static_portal_content_record.body is not null then
         dbms_lob.append(p_tlob, static_portal_content_record.body);
     end if;
  end loop;
end;
/
show errors;

--------------------------------------------------------
-- ACS-events triggers and procedures
-- I think only calendar makes use of the acs-events tables.

create or replace trigger acs_events_sws_insert_tr
  after insert on acs_events for each row
begin
  insert into site_wide_index (object_id, object_name, datastore)
    values  (:new.event_id, :new.name, 'a');
end;
/
show errors

create or replace trigger acs_events_sws_update_tr
  after update on acs_events for each row
begin
  update site_wide_index 
    set object_name=:new.name,
        datastore='a'
    where object_id = :new.event_id;
end;
/
show errors
    
create or replace trigger acs_events_sws_delete_tr
  after delete on acs_events for each row
begin
  delete from site_wide_index
    where object_id = :old.event_id;
end;
/
show errors

create or replace procedure acs_events_sws_helper (p_tlob in out nocopy clob, p_object_id in varchar)
is
  cursor acs_events_cursor(v_object_id char) is
    select name, description, p.first_names || ' ' || p.last_name as
        author_name, parties.email
    from  acs_events ae, acs_objects ao, persons p, parties
    where p.person_id = ao.creation_user
    and   ao.object_id = v_object_id
    and   parties.party_id = p.person_id
    and   ae.event_id = v_object_id;
begin
  for acs_events_record in acs_events_cursor(p_object_id) loop
     dbms_lob.writeappend(p_tlob, length('<oneline>'), '<oneline>');
     if acs_events_record.name is not null then
        dbms_lob.writeappend(p_tlob, length(acs_events_record.name) + 1, acs_events_record.name || ' ');
     end if;
     dbms_lob.writeappend(p_tlob, length('</oneline>'), '</oneline>');
     dbms_lob.writeappend(p_tlob, length(acs_events_record.author_name) + 1, acs_events_record.author_name || ' ');
     if acs_events_record.description is not null then
         dbms_lob.writeappend(p_tlob, length(acs_events_record.description) + 1, acs_events_record.description || ' ');
     end if;
  end loop;
end;
/
show errors;

--------------------------------------------------------
-- FAQ triggers and procedures

create or replace trigger faq_q_and_as_sws_insert_tr
  after insert on faq_q_and_as for each row
begin
  insert into site_wide_index (object_id, object_name, datastore)
    values  (:new.entry_id, :new.question, 'a');
end;
/
show errors

create or replace trigger faq_q_and_as_sws_update_tr
  after update on faq_q_and_as for each row
begin
  update site_wide_index 
    set object_name=:new.question,
        datastore='a'
    where object_id = :new.entry_id;
end;
/
show errors
    
create or replace trigger faq_q_and_as_sws_delete_tr
  after delete on faq_q_and_as for each row
begin
  delete from site_wide_index
    where object_id = :old.entry_id;
end;
/
show errors

create or replace procedure faq_q_and_as_sws_helper (p_tlob in out nocopy clob, p_object_id in varchar)
is
  cursor faq_q_and_as_cursor(v_object_id char) is
  select question, answer, p.first_names || ' ' || p.last_name as
      author_name, parties.email
  from  faq_q_and_as ae, acs_objects ao, persons p, parties
  where p.person_id = ao.creation_user
  and   ao.object_id = v_object_id
  and   parties.party_id = p.person_id
  and   ae.entry_id = v_object_id;
begin
  for faq_q_and_as_record in faq_q_and_as_cursor(p_object_id) loop
     dbms_lob.writeappend(p_tlob, length('<oneline>'), '<oneline>');
     if faq_q_and_as_record.question is not null then
        dbms_lob.writeappend(p_tlob, length(faq_q_and_as_record.question) + 1, faq_q_and_as_record.question || ' ');
     end if;
     dbms_lob.writeappend(p_tlob, length('</oneline>'), '</oneline>');
     dbms_lob.writeappend(p_tlob, length(faq_q_and_as_record.author_name) + 1, faq_q_and_as_record.author_name || ' ');
     if faq_q_and_as_record.answer is not null then
         dbms_lob.writeappend(p_tlob, length(faq_q_and_as_record.answer) + 1, faq_q_and_as_record.answer || ' ');
     end if;
  end loop;
end;
/
show errors;

--------------------------------------------------------
-- Survey Procs

create or replace trigger surveys_sws_insert_tr
  after insert on surveys for each row
begin
  insert into site_wide_index (object_id, object_name, datastore)
    values  (:new.survey_id, :new.name, 'a');
end;
/
show errors

create or replace trigger surveys_sws_update_tr
  after update on surveys for each row
begin
  update site_wide_index 
    set object_name=:new.name,
        datastore='a'
    where object_id = :new.survey_id;
end;
/
show errors

    
create or replace trigger surveys_sws_delete_tr
  after delete on surveys for each row
begin
  delete from site_wide_index
    where object_id = :old.survey_id;
end;
/
show errors

create or replace procedure surveys_sws_helper (p_tlob in out nocopy clob, p_object_id in varchar)
is

  cursor surveys_cursor(v_object_id char) is
    select name, description, p.first_names || ' ' || p.last_name as
        author_name, parties.email
    from  surveys sv, persons p, parties, acs_objects ao
    where sv.survey_id = ao.object_id
    and   p.person_id = ao.creation_user
    and   parties.party_id = p.person_id
    and   sv.survey_id = v_object_id;

  cursor survey_sections_cursor(v_survey_id char) is
    select section_id, name, description
    from  survey_sections sv
    where sv.survey_id = v_survey_id;

  cursor survey_questions_cursor(v_section_id char) is
    select question_text
    from  survey_questions
    where section_id = v_section_id;

begin
  for surveys_record in surveys_cursor(p_object_id) loop
     dbms_lob.writeappend(p_tlob, length('<oneline>'), '<oneline>');
     if surveys_record.name is not null then
        dbms_lob.writeappend(p_tlob, length(surveys_record.name) + 1, surveys_record.name || ' ');
     end if;
     dbms_lob.writeappend(p_tlob, length('</oneline>'), '</oneline>');
     dbms_lob.writeappend(p_tlob, length(surveys_record.author_name) + 1, surveys_record.author_name || ' ');
     if surveys_record.description is not null then
         dbms_lob.writeappend(p_tlob, length(surveys_record.description) + 1, surveys_record.description || ' ');
     end if;

    for survey_sections_record in survey_sections_cursor(p_object_id) loop
       dbms_lob.writeappend(p_tlob, length('<section_name>'), '<section_name>');
       if survey_sections_record.name is not null then
          dbms_lob.writeappend(p_tlob, length(survey_sections_record.name) + 1, survey_sections_record.name || ' ');
       end if;
       dbms_lob.writeappend(p_tlob, length('</section_name>'), '</section_name>');
       if survey_sections_record.description is not null then
           dbms_lob.append(p_tlob, survey_sections_record.description);
       end if;

      for survey_questions_record in survey_questions_cursor(survey_sections_record.section_id) loop
         dbms_lob.writeappend(p_tlob, length('<question_text>'), '<question_text>');
         if survey_questions_record.question_text is not null then
            dbms_lob.append(p_tlob, survey_questions_record.question_text);
         end if;
         dbms_lob.writeappend(p_tlob, length('</question_text>'), '</question_text>');
      end loop;

    end loop;

  end loop;
end;
/
show errors;

create or replace trigger survey_sections_sws_insert_tr
  after insert on survey_sections for each row
begin
  update site_wide_index 
    set datastore='a'
    where object_id = :new.survey_id;
end;
/
show errors

create or replace trigger survey_sections_sws_update_tr
  after update on survey_sections for each row
begin
  update site_wide_index 
    set datastore='a'
    where object_id = :new.survey_id;
end;
/
show errors

    
create or replace trigger survey_sections_sws_delete_tr
  after delete on survey_sections for each row
begin
  update site_wide_index 
    set datastore='a'
    where object_id = :old.survey_id;
end;
/
show errors

create or replace trigger survey_questions_sws_insert_tr
  after insert on survey_questions for each row
begin
  update site_wide_index 
    set datastore='a'
    where object_id in (select survey_id 
          from survey_sections
	    where section_id = :new.section_id);
end;
/
show errors

create or replace trigger survey_questions_sws_update_tr
  after update on survey_questions for each row
begin
  update site_wide_index 
    set datastore='a'
    where object_id in (select survey_id 
          from survey_sections
	    where section_id = :new.section_id);
end;
/
show errors

    
create or replace trigger survey_questions_sws_delete_tr
  after delete on survey_questions for each row
begin
  update site_wide_index 
    set datastore='a'
    where object_id in (select survey_id 
          from survey_sections
	    where section_id = :old.section_id);
end;
/
show errors

--------------------------------------------------------
-- The user_datastore proc which is called on every change of the datastore.

create or replace procedure sws_user_datastore_proc ( p_rid in rowid, p_tlob in out nocopy clob )
is
   v_object_id          site_wide_index.object_id%type;
   v_object_type        acs_objects.object_type%type;
begin
   site_wide_search.logger ('entered sws_user_datastore_proc');
   select swi.object_id, ao.object_type
     into v_object_id, v_object_type
     from site_wide_index swi, acs_objects ao
     where swi.object_id = ao.object_id
        and p_rid = swi.rowid;
   
   -- clean out the clob we're going to stuff
   dbms_lob.trim(p_tlob, 0);

   site_wide_search.logger ('in sws_user_datastore_proc with type ' || v_object_type);
   -- handle different sections
   if v_object_type = 'forums_message' then
      site_wide_search.logger ('calling forums_messages_sws_helper ');
      forums_messages_sws_helper(p_tlob, v_object_id);
   elsif v_object_type = 'cal_item' then
      site_wide_search.logger ('calling acs_events_sws_helper with cal_item');
      acs_events_sws_helper(p_tlob, v_object_id);
   elsif v_object_type = 'faq_q_and_a' then
      site_wide_search.logger ('calling faq_q_and_as_sws_helper with faq_q_and_a');
      faq_q_and_as_sws_helper(p_tlob, v_object_id);
   elsif v_object_type = 'static_portal_content' then
      site_wide_search.logger ('calling static_portal_sws_helper');
      static_portal_sws_helper(p_tlob, v_object_id);
   elsif v_object_type = 'survey' then
      site_wide_search.logger ('calling surveys_sws_helper');
      surveys_sws_helper(p_tlob, v_object_id);
   elsif v_object_type = 'survey_section' then
      site_wide_search.logger ('calling survey_sections_sws_helper');
      survey_sections_sws_helper(p_tlob, v_object_id);
   elsif v_object_type = 'survey_question' then
      site_wide_search.logger ('calling survey_questions_sws_helper');
      survey_questions_sws_helper(p_tlob, v_object_id);
   elsif v_object_type = 'survey_response' then
      site_wide_search.logger ('calling survey_responses_sws_helper');
      survey_responses_sws_helper(p_tlob, v_object_id);
   elsif v_object_type = 'wp_slides' then
        v_object_type := 'foobar';
   end if;
end;
/
show errors;


exit;

