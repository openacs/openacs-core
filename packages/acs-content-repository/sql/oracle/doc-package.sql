----------------------------------------
-- Return function headers for packages
---------------------------------------

create or replace package doc
is

  function get_proc_header (
    proc_name    in varchar2,
    package_name in varchar2
  ) return varchar2;

  function get_package_header (
    package_name in varchar2
  ) return varchar2;

end doc;
/
show errors

create or replace package body doc
is

  function get_proc_header (
    proc_name    in varchar2,
    package_name in varchar2
  ) return varchar2
  is
    v_line    integer;
    v_result  varchar2(4000);
    v_text    varchar2(4000);
    v_started varchar2(1);
    v_newline varchar2(10) := '
';

    cursor v_package_cur is
      select line, text from user_source 
      where lower(name) = lower(package_name)
      and type = 'PACKAGE'
      order by line;

  begin
  
    v_result := '';
    v_started := 'f';

    open v_package_cur;
    loop
      fetch v_package_cur into v_line, v_text; 
      exit when v_package_cur%NOTFOUND;
      
      -- Look for the function header
      if v_started = 'f' then
        if lower(v_text) like '%function%' || lower(proc_name) || '%' then
          v_started := 't';
        elsif lower(v_text) like '%procedure%' || lower(proc_name) || '%' then
          v_started := 't';
        end if;
      end if;
    
      -- Process the header
      if v_started = 't' then
        v_result := v_result || v_text;
        if v_text like '%;%' then
          close v_package_cur;
          return v_result;
        end if;
      end if;
    end loop;
    close v_package_cur;

    -- Return unfinished result
    return v_result;     
  end get_proc_header;

  function get_package_header (
    package_name in varchar2
  ) return varchar2
  is
    v_line    integer;
    v_result  varchar2(4000);
    v_text    varchar2(4000);
    v_started varchar2(1);
    v_newline varchar2(10) := '
';

    cursor v_package_cur is
      select line, text from user_source 
      where lower(name) = lower(package_name)
      and type = 'PACKAGE'
      order by line;

  begin
  
    v_result := '';
    v_started := 'f';

    open v_package_cur;
    loop
      fetch v_package_cur into v_line, v_text; 
      exit when v_package_cur%NOTFOUND;
      
      -- Look for the function header
      if v_started = 'f' then
        if v_text like '--%' then
          v_started := 't';
        end if;
      end if;
    
      -- Process the header
      if v_started = 't' then

        if v_text not like '--%' then
          close v_package_cur;
          return v_result;
        end if;
        
        v_result := v_result || v_text;
      end if;
    end loop;
    close v_package_cur;

    -- Return unfinished result
    return v_result;     

  end get_package_header;

end doc;
/
show errors
         
      

        
