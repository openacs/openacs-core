-- The table is filled by after_install and after_upgrade apm callbacks
-- using the iso-639-2.dat file

create table language_639_2_codes (
       iso_639_2            char(3) constraint language_codes_iso_639_2_pk primary key,
       iso_639_1            char(2),
       label                varchar(200)
);

comment on table language_639_2_codes is 'Contains ISO-639-2 language codes and their corresponding ISO-639-1 when it exists.';
