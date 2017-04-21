-- This upgrade adds more mime types and 
-- creates the cr_extension_mime_type_map
--
-- Jeff Davis davis@xarg.net 2003-02-06

create table cr_extension_mime_type_map (
   extension            varchar(200) 
                        constraint cr_mime_type_extension_map_pk
                        primary key,
   mime_type            varchar(200) 
                        constraint cr_mime_ext_map_mime_type_ref
                        references cr_mime_types
); 
create index cr_extension_mime_type_map_idx on cr_extension_mime_type_map(mime_type);

comment on table cr_extension_mime_type_map is '
  a mapping table for extension to mime_type in db version of ns_guesstype data
';

-- Quicky create some tmp tables.
create table tmp_cr_mime_types as select * from cr_mime_types where 0 = 1; 
create table tmp_cr_extension_mime_type_map as select * from cr_extension_mime_type_map where 0 = 1;

-- data from sql/common/mime-type-data.sql

insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Unknown'                  , '*/*'                           , '' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'AutoCAD drawing files'   , 'application/acad'              , 'dwg' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Andrew data stream'      , 'application/andrew-inset'      , 'ez' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'ClarisCAD files'         , 'application/clariscad'         , 'ccad' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Comma separated value'   , 'application/csv'               , 'csv' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'MATRA Prelude drafting'  , 'application/drafting'          , 'drw' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'DXF (AutoCAD)'           , 'application/dxf'               , 'dxf' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Filemaker Pro'           , 'application/filemaker'         , 'fm' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Futuresplash' , 'application/futuresplash'      , 'spl' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'NCSA HDF data format'    , 'application/hdf'               , 'hdf' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'IGES graphics format'    , 'application/iges'              , 'iges' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Mac binhex 4.0'          , 'application/mac-binhex40'      , 'hqx' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Mac Compactpro'          , 'application/mac-compactpro'    , 'cpt' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Microsoft Word'          , 'application/msword'            , 'doc' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Uninterpreted binary'    , 'application/octet-stream'      , 'bin' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'ODA ODIF'                , 'application/oda'               , 'oda' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'PDF'                     , 'application/pdf'               , 'pdf' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'PostScript'              , 'application/postscript'        , 'ps' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Rich Text Format'        , 'application/rtf'               , 'rtf' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Stereolithography'       , 'application/sla'               , 'stl');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'VCard'                   , 'application/vcard'             , 'vcf');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'VDA-FS Surface data'     , 'application/vda'               , 'vda');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'SSOYE Koan Files'        , 'application/vnd.koan'          , 'skp');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'FrameMaker MIF format'   , 'application/vnd.mif'           , 'mif' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Microsoft Access file'   , 'application/vnd.ms-access'     , 'mdb' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Microsoft Excel'         , 'application/vnd.ms-excel'      , 'xls' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Microsoft PowerPoint'    , 'application/vnd.ms-powerpoint' , 'ppt' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Microsoft Project'       , 'application/vnd.ms-project'    , 'mpp' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'WML XML in binary format', 'application/vnd.wap.wmlc'      , 'wmlc');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'WMLScript bytecode'      , 'application/vnd.wap.wmlscriptc', 'wmlsc');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'CorelXARA'               , 'application/vnd.xara'          , 'xar');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'WordPerfect'             , 'application/wordperfect'       , 'wpd');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'WordPerfect 6.0'         , 'application/wordperfect6.0'    , 'w60');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Archive ARJ '            , 'application/x-arj-compressed'  , 'arj');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Authorware'   , 'application/x-authorware-bin'  , 'aab' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Authorware'   , 'application/x-authorware-map'  , 'aam' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Authorware'   , 'application/x-authorware-seg'  , 'aas' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Channel Definition'      , 'application/x-cdf'             , 'cdf' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'VCD'                     , 'application/x-cdlink'          , 'vcd' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Chess PGN file'          , 'application/x-chess-pgn'       , 'pgn');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Archive compres'         , 'application/x-compress'        , 'z');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Archive CPIO'            , 'application/x-cpio'            , 'cpio');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'C-shell script'          , 'application/x-csh'             , 'csh' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Archive Debian Package'  , 'application/x-debian-package'  , 'deb');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Director'     , 'application/x-director'        , 'dxr' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'TeX DVI file'            , 'application/x-dvi'             , 'dvi' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'GNU Tar'                 , 'application/x-gtar'            , 'gtar');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Compressed - gzip'       , 'application/x-gzip'            , 'gz' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'CGI Script'              , 'application/x-httpd-cgi'       , 'cgi');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Adobe Illustrator'       , 'application/x-illustrator'     , 'ai' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Installshield data'      , 'application/x-installshield'   , 'wis');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Java Network Launching Protocol', 'application/x-java-jnlp-file', 'jnlp');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Javascript'              , 'application/x-javascript'      , 'js' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'LaTeX source'            , 'application/x-latex'           , 'latex' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Windows Media Services (wmd)', 'application/x-ms-wmd'      , 'wmd');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Windows Media Services (wmz)', 'application/x-ms-wmz'      , 'wmz');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Unidata netCDF'          , 'application/x-netcdf'          , 'cdf');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Audio Ogg Vorbis'        , 'application/x-ogg'             , 'ogg' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Adobe PageMaker'         , 'application/x-pagemaker'       , 'p65' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Photoshop'               , 'application/x-photoshop'       , 'psd' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Palm Pilot Data'         , 'application/x-pilot'           , 'prc' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Audio Real'              , 'application/x-pn-realmedia'    , 'rp');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Quattro Pro'             , 'application/x-quattro-pro'     , 'wq1');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Archive RAR'             , 'application/x-rar-compressed'  , 'rar');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Session Description Protocol', 'application/sdp'           , 'sdp' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Shockwave'    , 'application/x-shockwave-flash' , 'swf' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'SQL'                     , 'application/x-sql'             , 'sql' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Mac Stuffit compressed'  , 'application/x-stuffit'         , 'sit' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Archive SVR4 cpio'       , 'application/x-sv4cpio'         , 'sv4cpio');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Archive SVR4 crc'        , 'application/x-sv4crc'          , 'sv4crc');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Tar Archive'             , 'application/x-tar'             , 'tar' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'TeX source'              , 'application/x-tex'             , 'tex' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Texinfo (emacs)'         , 'application/x-texinfo'         , 'texinfo' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'troff'                   , 'application/x-troff'           , 'tr' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'troff with MAN macros'   , 'application/x-troff-man'       , 'man' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'troff with ME macros'    , 'application/x-troff-me'        , 'me' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'troff with MS macros'    , 'application/x-troff-ms'        , 'ms' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Archive POSIX Tar'       , 'application/x-ustar'           , 'ustar');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'X509 CA Cert'            , 'application/x-x509-ca-cert'    , 'cacert');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Archive Zip'             , 'application/zip'               , 'zip' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Basic audio (m-law PCM)' , 'audio/basic'                   , 'au' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Audio Midi'              , 'audio/midi'                    , 'midi');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Audio MPEG'              , 'audio/x-mpeg'                  , 'mpga');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Audio MPEG-2'            , 'audio/x-mpeg2'                 , 'mp2a');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Audio Java Media Framework', 'audio/rmf'                   , 'rmf'); 
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Audio Voice'             , 'audio/voice'                   , 'voc' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Audio AIFF'              , 'audio/x-aiff'                  , 'aif' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Audio Mod'               , 'audio/x-mod'                   , 'xm');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'mpeg url (m3u)'          , 'audio/x-mpegurl'               , 'm3u');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Windows Media Services (wma)', 'audio/x-ms-wma'            , 'wma');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Windows Media Services (wmv)', 'audio/x-ms-wmv'            , 'wmv');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Realaudio'               , 'audio/x-pn-realaudio'          , 'ra' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Realaudio Plugin'        , 'audio/x-pn-realaudio-plugin'   , 'rm' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Microsoft WAVE audio'    , 'audio/x-wav'                   , 'wav' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Brookhaven PDB'          , 'chemical/x-pdb'                , 'pdb');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'XMol XYZ'                , 'chemical/x-xyz'                , 'xyz');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'WHIP Web Drawing file'   , 'drawing/x-dwf'                 , 'dwf');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - BMP'             , 'image/bmp'                     , 'bmp' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Fractal Image Format'    , 'image/fif'                     , 'fif');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - Gif'             , 'image/gif'                     , 'gif' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image Exchange Format'   , 'image/ief'                     , 'ief' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - Jpeg'            , 'image/jpeg'                    , 'jpg' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - PNG'             , 'image/png'                     , 'png' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - TIFF'            , 'image/tiff'                    , 'tif' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'WAP wireless bitmap'     , 'image/vnd.wap.wbmp'            , 'wbmp');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - CMU Raster'      , 'image/x-cmu-raster'            , 'ras' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Flexible Image Transport', 'image/x-fits'                  , 'fit' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Freehand'     , 'image/x-freehand'              , 'fh' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'SVG'                     , 'image/xml+svg'                 , 'svg' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - PhotoCD'         , 'image/x-photo-cd'              , 'pcd' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - Mac pict'        , 'image/x-pict'                  , 'pict' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - PNM'             , 'image/x-portable-anymap'       , 'pnm' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - PBM'             , 'image/x-portable-bitmap'       , 'pbm' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - PGM'             , 'image/x-portable-graymap'      , 'pgm' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - Portable Pixmap' , 'image/x-portable-pixmap'       , 'ppm');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Image - RGB'             , 'image/x-rgb'                   , 'rgb');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'X bitmap'                , 'image/x-xbitmap'               , 'xbm' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'X pixmap'                , 'image/x-xpixmap'               , 'xpm' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'X window dump (xwd)'     , 'image/x-xwindowdump'           , 'xwd' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'RFC822 Message'          , 'message/rfc822'                , 'mime');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Computational mesh'      , 'model/mesh'                    , 'mesh');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'SGML Text'               , 'text/sgml'                     , 'sgml');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Cascading style sheet'   , 'text/css'                      , 'css' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'HTML text'               , 'text/html'                     , 'html' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Plain text'              , 'text/plain'                    , 'txt' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Text (flowed)'           , 'text/plain; format=flowed'     , 'text' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Enriched Text'           , 'text/enriched'                 , 'rtx' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Tab separated values'    , 'text/tab-separated-values'     , 'tsv' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'WMLScript'               , 'text/vnd.wap.wmlscript'        , 'wmls');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'WML'                     , 'text/vnd.wap.wml'              , 'wml');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'XML Document'            , 'text/xml'                      , 'xml' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Structured enhanced text', 'text/x-setext'                 , 'etx');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'XSL style sheet'         , 'text/xsl'                      , 'xsl' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Video FLI'               , 'video/fli'                     , 'fli');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Video MPEG'              , 'video/mpeg'                    , 'mpg' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Video MPEG-2'            , 'video/mpeg2'                   , 'mpv2' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Video Quicktime'         , 'video/quicktime'               , 'mov' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Video VDOlive streaming' , 'video/vdo'                     , 'vdo');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Video Vivo'              , 'video/vnd.vivo'                , 'vivo');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Video Microsoft ASF'     , 'video/x-ms-asf'                , 'asf' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Windows Media Services (wm)', 'video/x-ms-wm'              , 'wm');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Windows Media Services (wvx)', 'video/x-ms-wvx'            , 'wvx');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Windows Media Services (wmx)', 'video/x-mx-wmx'            , 'wmx');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Video Microsoft AVI'     , 'video/x-msvideo'               , 'avi' );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Video SGI movie player'  , 'video/x-sgi-movie'             , 'movie'  );
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Conference Cooltalk'     , 'x-conference/x-cooltalk'       , 'ice');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'VRML'                    , 'x-world/x-vrml'                , 'vrml');
insert into tmp_cr_mime_types (label,mime_type,file_extension) values ( 'Xuda'                    , 'xuda/gen-cert'                 , 'xuda');

-- Extension to mime type maps.

-- text/plain for prog langs (maybe we should do application/x-LANG but then you can't look
-- at the code in the browser.
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'c', 'text/plain');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'c++', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'cpp', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'cxx', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'cc', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'h', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'hh', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'h++', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'hxx', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'tcl', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'sql', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'sh', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'csh', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ksh', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'py', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'java', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xql', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'php', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'm4', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pl', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pm', 'text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pod', 'text/plain' );

-- map a few to binary 
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'o','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'so','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'a','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'dll','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'exe','application/octet-stream' );

-- all the rest
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'aab','application/x-authorware-bin' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'aam','application/x-authorware-map' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'aas','application/x-authorware-seg' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ai','application/x-illustrator');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'aif','audio/x-aiff' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'aifc','audio/x-aiff' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'aiff','audio/x-aiff' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ani','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'arj','application/x-arj-compressed' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'asc','text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'asf','video/x-ms-asf' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'asx','video/x-ms-asf' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'au','audio/basic' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'avi','video/x-msvideo' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'bin','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'bmp','image/bmp' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'bqy','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'cacert','application/x-x509-ca-cert' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ccad','application/clariscad' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'cdf','application/x-netcdf' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'cgi','application/x-httpd-cgi' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'class','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'cpio','application/x-cpio' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'cpt','application/mac-compactpro' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'css','text/css' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'csv','application/csv');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'cur','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'dcr','application/x-director' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'deb','application/x-debian-package' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'dhtml','text/html' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'dir','application/x-director' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'dms','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'doc','application/msword' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'dot','application/msword' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'drw','application/drafting' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'dump','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'dvi','application/x-dvi' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'dwf','drawing/x-dwf' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'dwg','application/acad' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'dxf','application/dxf' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'dxr','application/x-director' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'eps','application/postscript' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'etx','text/x-setext' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ez','application/andrew-inset' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'fh4','image/x-freehand' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'fh5','image/x-freehand' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'fh7','image/x-freehand' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'fhc','image/x-freehand' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'fh','image/x-freehand' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'fif','image/fif' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'fit','image/x-fits');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'fli','video/fli' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'fm','application/filemaker');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'gif','image/gif' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'gtar','application/x-gtar' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'gz','application/x-gzip' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'gzip','application/x-gzip' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'hdf','application/hdf');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'hqx','application/mac-binhex40' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'html','text/html' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'htm','text/html' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ice','x-conference/x-cooltalk' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ico','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ief','image/ief' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'iges','application/iges' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'igs','application/iges' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'jnlp','application/x-java-jnlp-file' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'jpeg','image/jpeg' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'jpe','image/jpeg' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'jpg','image/jpeg' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'js','application/x-javascript' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'kar','audio/midi' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'latex','application/x-latex' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'lha','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'lzh','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'm15','audio/x-mod' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'm3u','audio/x-mpegurl' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'm3url','audio/x-mpegurl' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'man','application/x-troff-man' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mdb','application/vnd.ms-access');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'me','application/x-troff-me' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mesh','model/mesh' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mid','audio/midi' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'midi','audio/midi' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mif','application/vnd.mif' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mime','message/rfc822' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'movie','video/x-sgi-movie' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mov','video/quicktime' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mp2','audio/x-mpeg2' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mp2a','audio/x-mpeg2' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mp3','audio/x-mpeg' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mp3a','audio/x-mpeg' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mpeg','video/mpeg' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mpe','video/mpeg' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mpga','audio/x-mpeg' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mpg','video/mpeg' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mpv2','video/mpeg2' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mp2v','video/mpeg2' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mpp','application/vnd.ms-project');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mpc','application/vnd.ms-project');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mpt','application/vnd.ms-project');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mpx','application/vnd.ms-project');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mpw','application/vnd.ms-project');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ms','application/x-troff-ms' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'msh','model/mesh' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'msw','application/msword' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'mtm','audio/x-mod' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'nc','application/x-netcdf' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'oda','application/oda' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ogg','application/x-ogg');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'p65','application/x-pagemaker');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pbm','image/x-portable-bitmap' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pcd','image/x-photo-cd');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pdb','chemical/x-pdb' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pdf','application/pdf' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pgm','image/x-portable-graymap' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pgn','application/x-chess-pgn' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pict','image/x-pict' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'png','image/png' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pnm','image/x-portable-anymap' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ppm','image/x-portable-pixmap' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ppt','application/vnd.ms-powerpoint' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ppz','application/vnd.ms-powerpoint' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pps','application/vnd.ms-powerpoint' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'pot','application/vnd.ms-powerpoint' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'prc','application/x-pilot');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ps','application/postscript' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'psd','application/x-photoshop');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'qt','video/quicktime' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ra','audio/x-pn-realaudio' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ram','audio/x-pn-realaudio' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'rar','application/x-rar-compressed' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ras','image/x-cmu-raster' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'rgb','image/x-rgb' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'rmf', 'audio/rmf');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'rm','audio/x-pn-realaudio-plugin' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'rmm','audio/x-pn-realaudio-plugin' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'roff','application/x-troff' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'rp','application/x-pn-realmedia' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'rpm','audio/x-pn-realaudio-plugin' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'rr','application/x-troff' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'rtf','application/rtf' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'rtx','text/enriched' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 's3m','audio/x-mod' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'sd2','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'sdp','application/sdp' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'sea','application/x-stuffit' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'sgml','text/sgml' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'sgm','text/sgml' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'shtml','text/html' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'silo','model/mesh' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'sit','application/x-stuffit' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'skd','application/vnd.koan' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'skm','application/vnd.koan' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'skp','application/vnd.koan' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'skt','application/vnd.koan' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'snd','audio/basic' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'spl','application/futuresplash' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'stl','application/sla' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'stm','audio/x-mod' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'sv4cpio','application/x-sv4cpio' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'sv4crc','application/x-sv4crc' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'svg','image/xml+svg');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'swf','application/x-shockwave-flash' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 't','application/x-troff' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'tar','application/x-tar' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'tex','application/x-tex' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'texi','application/x-texinfo' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'texinfo','application/x-texinfo' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'text','text/plain; format=flowed');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'tiff','image/tiff' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'tif','image/tiff' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'tr','application/x-troff' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'tsv','text/tab-separated-values' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'txt','text/plain' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ult','audio/x-mod' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'ustar','application/x-ustar' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'uu','application/octet-stream' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'vcd','application/x-cdlink' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'vcf','application/vcard' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'vdo','video/vdo' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'vda','application/vda' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'vivo','video/vnd.vivo' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'viv','video/vnd.vivo' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'voc','audio/voice');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'vrml','x-world/x-vrml' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'vrm','x-world/x-vrml' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wav','audio/x-wav' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wb1','application/x-quattro-pro' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wb2','application/x-quattro-pro' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wb3','application/x-quattro-pro' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wbmp','image/vnd.wap.wbmp' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'web','application/vnd.xara' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wis','application/x-installshield' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wma','audio/x-ms-wma' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wmd','application/x-ms-wmd' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wmlc','application/vnd.wap.wmlc' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wmlsc','application/vnd.wap.wmlscriptc' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wmls','text/vnd.wap.wmlscript' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wml','text/vnd.wap.wml' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wmv','audio/x-ms-wmv' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wm','video/x-ms-wm' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wmx','video/x-mx-wmx' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wmz','application/x-ms-wmz' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wpd','application/wordperfect' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wq1','application/x-quattro-pro' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wrl','x-world/x-vrml' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'wvx','video/x-ms-wvx' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xar','application/vnd.xara' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'w60','application/wordperfect6.0');
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xbm','image/x-xbitmap' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xlc','application/vnd.ms-excel' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xls','application/vnd.ms-excel' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xlm','application/vnd.ms-excel' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xlw','application/vnd.ms-excel' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xm','audio/x-mod' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xml','text/xml' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xpm','image/x-xpixmap' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xsl','text/xsl' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xuda','xuda/gen-cert' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xwd','image/x-xwindowdump' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'xyz','chemical/x-xyz' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'z','application/x-compress' );
insert into tmp_cr_extension_mime_type_map (extension, mime_type) values ( 'zip','application/zip' );

-- Now update the existing data taking care not to mess anything up.

-- Add the mime types that don't already exist.
-- don't add extensions yet since we do that later to prevent
-- duplicates in the 
insert into cr_mime_types 
       select label, mime_type, null
       from tmp_cr_mime_types n 
       where not exists (
             select 1 
             from cr_mime_types o 
             where o.mime_type = n.mime_type);

-- Provide extension for mime types with missing ones and which are
-- not in use for another mime type.
update cr_mime_types set label = (
       select label 
       from tmp_cr_mime_types n
       where n.mime_type = cr_mime_types.mime_type) 
where label is null;

-- Add extensions, verify extension not already used by another mime type.
-- have to do this since we don't want to introduce duplicate
-- extensions since there is still code using the cr_mime_types table to
-- look up mime_type.

update cr_mime_types set file_extension = (
       select file_extension from tmp_cr_mime_types m
       where m.mime_type = cr_mime_types.mime_type 
         and not exists (select * from cr_mime_types c where m.file_extension = c.file_extension))
where file_extension is null;


-- Create a mapping entry for existing mime types.
-- we make sure we only get one mapping per extension just in case
insert into cr_extension_mime_type_map (extension, mime_type) 
select file_extension, min(mime_type) from cr_mime_types 
where file_extension is not null group by file_extension;

-- insert all the rest that are not being used
insert into cr_extension_mime_type_map 
       select extension, mime_type
       from tmp_cr_extension_mime_type_map n
       where not exists (
             select 1 from cr_extension_mime_type_map o
             where o.extension = n.extension );

drop table tmp_cr_mime_types;
drop table tmp_cr_extension_mime_type_map;
