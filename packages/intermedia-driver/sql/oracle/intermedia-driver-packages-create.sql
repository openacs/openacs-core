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
  procedure register_event (p_object_id	search_observer_queue.object_id%TYPE,
  	    		    p_event	search_observer_queue.event%TYPE);

  procedure logger (p_logmessage varchar);

  function im_convert(
  	query in varchar2 default null
  	) return varchar2;

end site_wide_search;
/
show errors

create or replace package body site_wide_search
as
  procedure register_event (p_object_id	search_observer_queue.object_id%TYPE,
  	    		    p_event	search_observer_queue.event%TYPE) is
  begin
    insert into search_observer_queue
      (object_id, event)
    values
      (p_object_id, p_event);
  end register_event;

  procedure logger (p_logmessage varchar) is
  begin 
    insert into sws_log_messages (logmessage) values (p_logmessage);
  end logger;

  -- Query to take free text user entered query and frob it into something
  -- that will make interMedia happy. Provided by Oracle.
  function im_convert(
  	query in varchar2 default null
  	) return varchar2
  is
    i   number :=0;
    len number :=0;
    char varchar2(1);
    minusString varchar2(256);
    plusString varchar2(256); 
    mainString varchar2(256);
    mainAboutString varchar2(500);
    finalString varchar2(500);
    hasMain number :=0;
    hasPlus number :=0;
    hasMinus number :=0;
    token varchar2(256);
    tokenStart number :=1;
    tokenFinish number :=0;
    inPhrase number :=0;
    inPlus number :=0;
    inWord number :=0;
    inMinus number :=0;
    completePhrase number :=0;
    completeWord number :=0;
    code number :=0;  
  begin
    
    len := length(query);
  
  -- we iterate over the string to find special web operators
    for i in 1..len loop
      char := substr(query,i,1);
      if(char = '"') then
        if(inPhrase = 0) then
          inPhrase := 1;
  	tokenStart := i;
        else
          inPhrase := 0;
          completePhrase := 1;
  	tokenFinish := i-1;
        end if;
      elsif(char = ' ') then
        if(inPhrase = 0) then
          completeWord := 1;
          tokenFinish := i-1;
        end if;
      elsif(char = '+') then
        inPlus := 1;
        tokenStart := i+1;
      elsif((char = '-') and (i = tokenStart)) then
        inMinus :=1;
        tokenStart := i+1;
      end if;
  
      if(completeWord=1) then
        token := '{ '||substr(query,tokenStart,tokenFinish-tokenStart+1)||' }';      
        if(inPlus=1) then
          plusString := plusString||','||token||'*10';
  	hasPlus :=1;	
        elsif(inMinus=1) then
          minusString := minusString||'OR '||token||' ';
  	hasMinus :=1;
        else
          mainString := mainString||' NEAR '||token;
  	mainAboutString := mainAboutString||' '||token; 
  	hasMain :=1;
        end if;
        tokenStart  :=i+1;
        tokenFinish :=0;
        inPlus := 0;
        inMinus :=0;
      end if;
      completePhrase := 0;
      completeWord :=0;
    end loop;
  
    -- find the last token
    token := '{ '||substr(query,tokenStart,len-tokenStart+1)||' }';
    if(inPlus=1) then
      plusString := plusString||','||token||'*10';
      hasPlus :=1;	
    elsif(inMinus=1) then
      minusString := minusString||'OR '||token||' ';
      hasMinus :=1;
    else
      mainString := mainString||' NEAR '||token;
      mainAboutString := mainAboutString||' '||token; 
      hasMain :=1;
    end if;
  
    
    mainString := substr(mainString,6,length(mainString)-5);
    mainAboutString := replace(mainAboutString,'{',' ');
    mainAboutString := replace(mainAboutString,'}',' ');
    mainAboutString := replace(mainAboutString,')',' ');	
    mainAboutString := replace(mainAboutString,'(',' ');
    plusString := substr(plusString,2,length(plusString)-1);
    minusString := substr(minusString,4,length(minusString)-4);
  
    -- we find the components present and then process them based on the specific combinations
    code := hasMain*4+hasPlus*2+hasMinus;
    if(code = 7) then
      finalString := '('||plusString||','||mainString||'*2.0,about('||mainAboutString||')*0.5) NOT ('||minusString||')';
    elsif (code = 6) then  
      finalString := plusString||','||mainString||'*2.0'||',about('||mainAboutString||')*0.5';
    elsif (code = 5) then  
      finalString := '('||mainString||',about('||mainAboutString||')) NOT ('||minusString||')';
    elsif (code = 4) then  
      finalString := mainString;
      finalString := replace(finalString,'*1,',NULL); 
      finalString := '('||finalString||')*2.0,about('||mainAboutString||')';
    elsif (code = 3) then  
      finalString := '('||plusString||') NOT ('||minusString||')';
    elsif (code = 2) then  
      finalString := plusString;
    elsif (code = 1) then  
      -- not is a binary operator for intermedia text
      finalString := 'totallyImpossibleString'||' NOT ('||minusString||')';
    elsif (code = 0) then  
      finalString := '';
    end if;
  
    return finalString;
  end;
  
end site_wide_search;
/
show errors
--------------------------------------------------------
-- The user_datastore proc which is called on every change of the datastore.

create or replace procedure sws_user_datastore_proc ( p_rid in rowid, p_tlob in out nocopy clob )
is
   v_object_id          site_wide_index.object_id%type;
begin
   site_wide_search.logger ('entered sws_user_datastore_proc');

   select indexed_content 
     into p_tlob
     from site_wide_index swi, acs_objects ao
   where swi.object_id = ao.object_id
      and p_rid = swi.rowid;

   site_wide_search.logger ('in sws_user_datastore_proc with type ' || v_object_id);

end;
/
show errors;


exit;
