insert into cr_mime_types(label, mime_type, file_extension)
select 'Microsoft Office Word macro enabled', 'application/vnd.ms-word.document.macroenabled.12', 'docm' from dual
where not exists (select 1 from cr_mime_types where mime_type = 'application/vnd.ms-word.document.macroenabled.12');

insert into cr_mime_types(label, mime_type, file_extension)
select 'Microsoft Office Word Template macro enabled', 'application/vnd.ms-word.template.macroenabled.12', 'dotm' from dual
where not exists (select 1 from cr_mime_types where mime_type = 'application/vnd.ms-word.template.macroenabled.12');

insert into cr_mime_types(label, mime_type, file_extension)
select 'Microsoft Office Excel macro enabled', 'application/vnd.ms-excel.sheet.macroenabled.12', 'xlsm' from dual
where not exists (select 1 from cr_mime_types where mime_type = 'application/vnd.ms-excel.sheet.macroenabled.12');

insert into cr_mime_types(label, mime_type, file_extension)
select 'Microsoft Office Excel Template macro enabled', 'application/vnd.ms-excel.template.macroenabled.12', 'xltm' from dual
where not exists (select 1 from cr_mime_types where mime_type = 'application/vnd.ms-excel.template.macroenabled.12');

insert into cr_mime_types(label, mime_type, file_extension)
select 'Microsoft Office Excel Addin macro enabled', 'application/vnd.ms-excel.addin.macroenabled.12', 'xlam' from dual
where not exists (select 1 from cr_mime_types where mime_type = 'application/vnd.ms-excel.addin.macroenabled.12');

insert into cr_mime_types(label, mime_type, file_extension)
select 'Microsoft Office Excel Sheet binary macro enabled', 'application/vnd.ms-excel.sheet.binary.macroenabled.12', 'xlsb' from dual
where not exists (select 1 from cr_mime_types where mime_type = 'application/vnd.ms-excel.sheet.binary.macroenabled.12');

insert into cr_mime_types(label, mime_type, file_extension)
select 'Microsoft Office PowerPoint Addin macro enabled', 'application/vnd.ms-powerpoint.addin.macroenabled.12', 'ppam' from dual
where not exists (select 1 from cr_mime_types where mime_type = 'application/vnd.ms-powerpoint.addin.macroenabled.12');

insert into cr_mime_types(label, mime_type, file_extension)
select 'Microsoft Office PowerPoint Presentation macro enabled', 'application/vnd.ms-powerpoint.presentation.macroenabled.12', 'pptm' from dual
where not exists (select 1 from cr_mime_types where mime_type = 'application/vnd.ms-powerpoint.presentation.macroenabled.12');

insert into cr_mime_types(label, mime_type, file_extension)
select 'Microsoft Office PowerPoint Template macro enabled', 'application/vnd.ms-powerpoint.template.macroenabled.12', 'potm' from dual
where not exists (select 1 from cr_mime_types where mime_type = 'application/vnd.ms-powerpoint.template.macroenabled.12');

insert into cr_mime_types(label, mime_type, file_extension)
select 'Microsoft Office PowerPoint Slideshow macro enabled', 'application/vnd.ms-powerpoint.slideshow.macroenabled.12', 'ppsm' from dual
where not exists (select 1 from cr_mime_types where mime_type = 'application/vnd.ms-powerpoint.slideshow.macroenabled.12');
