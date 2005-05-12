-- Add a few common mime types
insert into cr_mime_types (label,mime_type,file_extension) select 'Audio - WAV','audio/wav', 'wav' from dual where not exists (select 1 from cr_mime_types where mime_type = 'audio/wav');
insert into cr_mime_types (label,mime_type,file_extension) select 'Audio - MPEG','audio/mpeg', 'mpeg' from dual where not exists (select 1 from cr_mime_types where mime_type = 'audio/mpeg');
insert into cr_mime_types (label, mime_type, file_extension) select 'Audio - MP3','audio/mp3', 'mp3' from dual where not exists (select 1 from cr_mime_types where mime_type = 'audio/mp3');
insert into cr_mime_types (label,mime_type,file_extension) select 'Image - Progressive JPEG','image/pjpeg', 'pjpeg' from dual where not exists (select 1 from cr_mime_types where mime_type = 'image/pjpeg');
