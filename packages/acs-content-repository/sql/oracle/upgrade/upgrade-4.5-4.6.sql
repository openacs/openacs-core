-- Upgrade script
--
-- @author vinod@kurup.com
-- @created 2002-10-06

-- add mime_types

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Binary', 'application/octet-stream', 'bin' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/octet-stream');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Microsoft Word', 'application/msword', 'doc' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/msword');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Microsoft Excel', 'application/msexcel', 'xls' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/msexcel');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Microsoft PowerPoint', 'application/powerpoint', 'ppt' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/powerpoint');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Microsoft Project', 'application/msproject', 'mpp' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/msproject');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'PostScript', 'application/postscript', 'ps' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/postscript');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Adobe Illustrator', 'application/x-illustrator', 'ai' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/x-illustrator');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Adobe PageMaker', 'application/x-pagemaker', 'p65' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/x-pagemaker');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Filemaker Pro', 'application/filemaker', 'fm' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/filemaker');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Image Pict', 'image/x-pict', 'pic' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'image/x-pict');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Photoshop', 'application/x-photoshop', 'psd' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/x-photoshop');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Acrobat', 'application/pdf', 'pdf' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/pdf');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Video Quicktime', 'video/quicktime', 'mov' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'video/quicktime');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Video MPEG', 'video/mpeg', 'mpg' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'video/mpeg');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Audio AIFF',  'audio/aiff', 'aif' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'audio/aiff');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Audio Basic', 'audio/basic',      'au' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'audio/basic');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Audio Voice', 'audio/voice',      'voc' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'audio/voice');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Audio Wave', 'audio/wave', 'wav' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'audio/wave');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Archive Zip', 'application/zip', 'zip' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/zip');

insert into cr_mime_types(label, mime_type, file_extension) 
  select 'Archive Tar', 'application/z-tar', 'tar' from dual 
  where not exists (select 1 from cr_mime_types 
                    where mime_type = 'application/z-tar');

 

