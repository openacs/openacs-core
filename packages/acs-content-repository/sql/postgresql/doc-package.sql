----------------------------------------
-- Return function headers for packages
---------------------------------------

-- create or replace package doc
-- is
-- 
--   function get_proc_header (
--     proc_name    in varchar2,
--     package_name in varchar2
--   ) return varchar2;
-- 
--   function get_package_header (
--     package_name in varchar2
--   ) return varchar2;
-- 
-- end doc;

-- show errors

-- create or replace package body doc
-- function get_proc_header
create function doc__get_proc_header (varchar,varchar)
returns varchar as '
declare
  proc_name              alias for $1;  
  package_name           alias for $2;  
  v_line                 integer;       
  v_result               varchar(4000); 
  v_text                 varchar(4000); 
  v_started              varchar(1);    
  v_newline              varchar(10)    
  ';                                    
                                        
  cursor                 v_package_cur  
  select                 line,          
  where                  lower(name)    
  and                    type           
  order                  by             
                                        
begin
  
    v_result := '''';
    v_started := ''f'';

    open v_package_cur;
    loop
      fetch v_package_cur into v_line, v_text; 
      exit when v_package_cur%NOTFOUND;
      
      -- Look for the function header
      if v_started = ''f'' then
        if lower(v_text) like ''%function%'' || lower(proc_name) || ''%'' then
          v_started := ''t'';
        elsif lower(v_text) like ''%procedure%'' || lower(proc_name) || ''%'' then
          v_started := ''t'';
        end if;
      end if;
    
      -- Process the header
      if v_started = ''t'' then
        v_result := v_result || v_text;
        if v_text like ''%;%'' then
          close v_package_cur;
          return v_result;
        end if;
      end if;
    end loop;

    -- Return unfinished result
    return v_result;     
   
end;' language 'plpgsql';


-- function get_package_header
create function doc__get_package_header (varchar)
returns varchar as '
declare
  package_name           alias for $1;  
  v_line                 integer;       
  v_result               varchar(4000); 
  v_text                 varchar(4000); 
  v_started              varchar(1);    
  v_newline              varchar(10)    
  ';                                    
                                        
  cursor                 v_package_cur  
  select                 line,          
  where                  lower(name)    
  and                    type           
  order                  by             
                                        
begin
  
    v_result := '''';
    v_started := ''f'';

    open v_package_cur;
    loop
      fetch v_package_cur into v_line, v_text; 
      exit when v_package_cur%NOTFOUND;
      
      -- Look for the function header
      if v_started = ''f'' then
        if v_text like ''--%'' then
          v_started := ''t'';
        end if;
      end if;
    
      -- Process the header
      if v_started = ''t'' then

        if v_text not like ''--%'' then
          close v_package_cur;
          return v_result;
        end if;
        
        v_result := v_result || v_text;
      end if;
    end loop;

    -- Return unfinished result
    return v_result;     

   
end;' language 'plpgsql';



-- show errors
         
      

        
