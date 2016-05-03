-- Common mime types (administered from admin pages)
--
-- see http://www.isi.edu/in-notes/iana/assignments/media-types/
-- also http://www.utoronto.ca/webdocs/HTMLdocs/Book/Book-3ed/appb/mimetype.html
--
-- data assembly Jeff Davis davis@xarg.net 

-- Here are Mime types + text description + cannonical extension
--
-- mapping of extension to mime type done later.

insert into cr_mime_types (label,mime_type,file_extension) values ( 'Unkown'                  , '*/*'                           , '' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'AutoCAD drawing files'   , 'application/acad'              , 'dwg' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Andrew data stream'      , 'application/andrew-inset'      , 'ez' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'ClarisCAD files'         , 'application/clariscad'         , 'ccad' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - Comma separated value', 'application/csv'           , 'csv' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'MATRA Prelude drafting'  , 'application/drafting'          , 'drw' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'DXF (AutoCAD)'           , 'application/dxf'               , 'dxf' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Filemaker Pro'           , 'application/filemaker'         , 'fm' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Futuresplash' , 'application/futuresplash'      , 'spl' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'NCSA HDF data format'    , 'application/hdf'               , 'hdf' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - IGES graphics format', 'application/iges'          , 'iges' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Mac binhex 4.0'          , 'application/mac-binhex40'      , 'hqx' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Mac Compactpro'          , 'application/mac-compactpro'    , 'cpt' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Microsoft Word'          , 'application/msword'            , 'doc' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Uninterpreted binary'    , 'application/octet-stream'      , 'bin' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'ODA ODIF'                , 'application/oda'               , 'oda' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'PDF'                     , 'application/pdf'               , 'pdf' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'PostScript'              , 'application/postscript'        , 'ps' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'RTF - Rich Text Format'  , 'application/rtf'               , 'rtf' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Stereolithography'       , 'application/sla'               , 'stl');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'VCard'                   , 'application/vcard'             , 'vcf');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'VDA-FS Surface data'     , 'application/vda'               , 'vda');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'SSOYE Koan Files'        , 'application/vnd.koan'          , 'skp');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'FrameMaker MIF format'   , 'application/vnd.mif'           , 'mif' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Microsoft Access file'   , 'application/vnd.ms-access'     , 'mdb' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Microsoft Excel'         , 'application/vnd.ms-excel'      , 'xls' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Microsoft PowerPoint'    , 'application/vnd.ms-powerpoint' , 'ppt' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Microsoft Project'       , 'application/vnd.ms-project'    , 'mpp' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'WML XML in binary format', 'application/vnd.wap.wmlc'      , 'wmlc');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'WMLScript bytecode'      , 'application/vnd.wap.wmlscriptc', 'wmlsc');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'CorelXARA'               , 'application/vnd.xara'          , 'xar');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'WordPerfect'             , 'application/wordperfect'       , 'wpd');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'WordPerfect 6.0'         , 'application/wordperfect6.0'    , 'w60');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive ARJ '            , 'application/x-arj-compressed'  , 'arj');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Authorware'   , 'application/x-authorware-bin'  , 'aab' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Authorware'   , 'application/x-authorware-map'  , 'aam' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Authorware'   , 'application/x-authorware-seg'  , 'aas' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Channel Definition'      , 'application/x-cdf'             , 'cdf' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'VCD'                     , 'application/x-cdlink'          , 'vcd' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Chess PGN file'          , 'application/x-chess-pgn'       , 'pgn');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive compres'         , 'application/x-compress'        , 'z');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive CPIO'            , 'application/x-cpio'            , 'cpio');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'C-shell script'          , 'application/x-csh'             , 'csh' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive Debian Package'  , 'application/x-debian-package'  , 'deb');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Director'     , 'application/x-director'        , 'dxr' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'TeX DVI file'            , 'application/x-dvi'             , 'dvi' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive GNU Tar'         , 'application/x-gtar'            , 'gtar');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive gzip compressed' , 'application/gzip'              , 'gz' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'CGI Script'              , 'application/x-httpd-cgi'       , 'cgi');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Adobe Illustrator'       , 'application/x-illustrator'     , 'ai' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Installshield data'      , 'application/x-installshield'   , 'wis');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Java Network Launching Protocol', 'application/x-java-jnlp-file', 'jnlp');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Javascript'              , 'application/javascript'        , 'js' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'LaTeX source'            , 'application/x-latex'           , 'latex' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Windows Media Services (wmd)', 'application/x-ms-wmd'      , 'wmd');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Windows Media Services (wmz)', 'application/x-ms-wmz'      , 'wmz');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Unidata netCDF'          , 'application/x-netcdf'          , 'cdf');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio Ogg Vorbis'        , 'application/x-ogg'             , 'ogg' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Adobe PageMaker'         , 'application/x-pagemaker'       , 'p65' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Photoshop'               , 'application/x-photoshop'       , 'psd' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Palm Pilot Data'         , 'application/x-pilot'           , 'prc' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio Real'              , 'application/x-pn-realmedia'    , 'rp');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Quattro Pro'             , 'application/x-quattro-pro'     , 'wq1');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive RAR'             , 'application/x-rar-compressed'  , 'rar');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Session Description Protocol', 'application/sdp'           , 'sdp' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Macromedia Shockwave'    , 'application/vnd.adobe.flash-movie', 'swf' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'SQL'                     , 'application/x-sql'             , 'sql' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive Mac Stuffit compressed'  , 'application/x-stuffit' , 'sit' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive SVR4 cpio'       , 'application/x-sv4cpio'         , 'sv4cpio');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive SVR4 crc'        , 'application/x-sv4crc'          , 'sv4crc');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive Tar'             , 'application/x-tar'             , 'tar' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - TeX source'         , 'application/x-tex'           , 'tex' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - Texinfo (emacs)'    , 'application/x-texinfo'       , 'texinfo' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - troff'              , 'application/x-troff'         , 'tr' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - troff with MAN macros', 'application/x-troff-man'   , 'man' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - troff with ME macros', 'application/x-troff-me'     , 'me' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - troff with MS macros', 'application/x-troff-ms'     , 'ms' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive POSIX Tar'       , 'application/x-ustar'           , 'ustar');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'X509 CA Cert'            , 'application/x-x509-ca-cert'    , 'cacert');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Archive Zip'             , 'application/zip'               , 'zip' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Basic audio (m-law PCM)' , 'audio/basic'                   , 'au' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio Midi'              , 'audio/midi'                    , 'midi');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio MPEG'              , 'audio/x-mpeg'                  , 'mp3');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio MPEG-2'            , 'audio/x-mpeg2'                 , 'mp2a');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio Java Media Framework', 'audio/rmf'                   , 'rmf'); 
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio Voice'             , 'audio/voice'                   , 'voc' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio AIFF'              , 'audio/x-aiff'                  , 'aif' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio Mod'               , 'audio/x-mod'                   , 'xm');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio mpeg url (m3u)'    , 'audio/x-mpegurl'               , 'm3u');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio Windows Media Services (wma)', 'audio/x-ms-wma'      , 'wma');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio Windows Media Services (wmv)', 'audio/x-ms-wmv'      , 'wmv');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio Realaudio'         , 'audio/x-pn-realaudio'          , 'ra' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio Realaudio Plugin'  , 'audio/x-pn-realaudio-plugin'   , 'rm' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Audio Microsoft WAVE'    , 'audio/x-wav'                   , 'wav' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Chemical Brookhaven PDB' , 'chemical/x-pdb'                , 'pdb');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Chemical XMol XYZ'       , 'chemical/x-xyz'                , 'xyz');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'WHIP Web Drawing file'   , 'drawing/x-dwf'                 , 'dwf');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - BMP'             , 'image/bmp'                     , 'bmp' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - Fractal Image Format', 'image/fif'                 , 'fif');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - Gif'             , 'image/gif'                     , 'gif' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - Image Exchange Format' , 'image/ief'               , 'ief' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - Jpeg'            , 'image/jpeg'                    , 'jpg' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - PNG'             , 'image/png'                     , 'png' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - TIFF'            , 'image/tiff'                    , 'tif' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - WAP wireless bitmap'     , 'image/vnd.wap.wbmp'    , 'wbmp');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - CMU Raster'      , 'image/x-cmu-raster'            , 'ras' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - Flexible Image Transport', 'image/x-fits'          , 'fit' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - Macromedia Freehand'     , 'image/x-freehand'      , 'fh' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - SVG'             , 'image/svg+xml'                 , 'svg' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - PhotoCD'         , 'image/x-photo-cd'              , 'pcd' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - Mac pict'        , 'image/x-pict'                  , 'pict' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - PNM'             , 'image/x-portable-anymap'       , 'pnm' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - PBM'             , 'image/x-portable-bitmap'       , 'pbm' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - PGM'             , 'image/x-portable-graymap'      , 'pgm' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - Portable Pixmap' , 'image/x-portable-pixmap'       , 'ppm');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - RGB'             , 'image/x-rgb'                   , 'rgb');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - X bitmap'        , 'image/x-xbitmap'               , 'xbm' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - X pixmap'        , 'image/x-xpixmap'               , 'xpm' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Image - X window dump (xwd)' , 'image/x-xwindowdump'       , 'xwd' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'RFC822 Message'          , 'message/rfc822'                , 'mime');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Computational mesh'      , 'model/mesh'                    , 'mesh');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - SGML Text'        , 'text/sgml'                     , 'sgml');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - CSS'              , 'text/css'                      , 'css' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - HTML'             , 'text/html'                     , 'html' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - Plain text'       , 'text/plain'                    , 'txt' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - Plain text (flowed)' , 'text/plain; format=flowed'  , 'text' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - Enriched Text'    , 'text/enriched'                 , 'rtx' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - Tab separated values'    , 'text/tab-separated-values'     , 'tsv' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - WMLScript'        , 'text/vnd.wap.wmlscript'        , 'wmls');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - WML'              , 'text/vnd.wap.wml'              , 'wml');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - XML Document'     , 'text/xml'                      , 'xml' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - Structured enhanced text', 'text/x-setext'          , 'etx');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Text - XSL'              , 'text/xsl'                      , 'xsl' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Video FLI'               , 'video/fli'                     , 'fli');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Video MPEG'              , 'video/mpeg'                    , 'mpg' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Video MPEG-2'            , 'video/mpeg2'                   , 'mpv2' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Video Quicktime'         , 'video/quicktime'               , 'mov' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Video VDOlive streaming' , 'video/vdo'                     , 'vdo');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Video Vivo'              , 'video/vnd.vivo'                , 'vivo');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Video Microsoft ASF'     , 'video/x-ms-asf'                , 'asf' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Video Windows Media Services (wm)', 'video/x-ms-wm'        , 'wm');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Video Windows Media Services (wvx)', 'video/x-ms-wvx'      , 'wvx');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Video Windows Media Services (wmx)', 'video/x-mx-wmx'      , 'wmx');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Video Microsoft AVI'     , 'video/x-msvideo'               , 'avi' );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Video SGI movie player'  , 'video/x-sgi-movie'             , 'movie'  );
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Conference Cooltalk'     , 'x-conference/x-cooltalk'       , 'ice');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'VRML'                    , 'x-world/x-vrml'                , 'vrml');
insert into cr_mime_types (label,mime_type,file_extension) values ( 'Xuda'                    , 'xuda/gen-cert'                 , 'xuda');
insert into cr_mime_types (label,mime_type,file_extension) values ('Enhanced text'            , 'text/enhanced'                 , 'etxt');
insert into cr_mime_types (label,mime_type,file_extension) values ('Fixed-width text'         , 'text/fixed-width'              , 'ftxt');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Spreadsheet'   , 'application/vnd.sun.xml.calc'  , 'sxc');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Spreadsheet Template', 'application/vnd.sun.xml.calc.template', 'stc');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Draw', 'application/vnd.sun.xml.draw'            , 'sxd');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Draw Template' , 'application/vnd.sun.xml.draw.template', 'std');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Impress'       , 'application/vnd.sun.xml.impress', 'sxi');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Impress Template', 'application/vnd.sun.xml.impress.template', 'sti');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Math'          , 'application/vnd.sun.xml.math'   , 'sxm');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Writer'        , 'application/vnd.sun.xml.writer' , 'sxw');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Writer Global', 'application/vnd.sun.xml.writer.global', 'sxg');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Writer Template', 'application/vnd.sun.xml.writer.template', 'stw');
insert into cr_mime_types (label,mime_type,file_extension) values ('Audio - WAV'              , 'audio/wav'                      , 'wav');
insert into cr_mime_types (label,mime_type,file_extension) values ('Audio - MPEG'             , 'audio/mpeg'                     , 'mpeg');
insert into cr_mime_types (label,mime_type,file_extension) values ('Audio - MP3'              ,'audio/mp3'                       , 'mp3');
insert into cr_mime_types (label,mime_type,file_extension) values ('Image - Progressive JPEG' ,'image/pjpeg'                     , 'pjpeg');
insert into cr_mime_types (label,mime_type,file_extension) values ('SPPS data file'           ,'application/x-spss-savefile'     , 'sav');
insert into cr_mime_types (label,mime_type,file_extension) values ('SPPS data file'           ,'application/x-spss-outputfile'   , 'spo');
insert into cr_mime_types (label,mime_type,file_extension) values ('Video MP4'                , 'video/mp4'                      , 'mp4');
insert into cr_mime_types (label,mime_type,file_extension) values ('XPInstall'                , 'application/x-xpinstall'        , 'xpi'); 

-- Open Documents MIME types
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.text', 'odt', 'OpenDocument Text');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.text-template', 'ott', 'OpenDocument Text Template');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.text-web', 'oth', 'HTML Document Template');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.text-master', 'odm', 'OpenDocument Master Document');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.graphics', 'odg', 'OpenDocument Drawing');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.graphics-template', 'otg', 'OpenDocument Drawing Template');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.presentation', 'odp', 'OpenDocument Presentation');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.presentation-template', 'otp', 'OpenDocument Presentation Template');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.spreadsheet', 'ods', 'OpenDocument Spreadsheet');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.spreadsheet-template', 'ots', 'OpenDocument Spreadsheet Template');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.chart', 'odc', 'OpenDocument Chart');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.formula', 'odf', 'OpenDocument Formula');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.database', 'odb', 'OpenDocument Database');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.oasis.opendocument.image', 'odi', 'OpenDocument Image');

-- Open XML formats for MS-Office
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx', 'Microsoft Office Excel');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.openxmlformats-officedocument.spreadsheetml.template', 'xltx', 'Microsoft Office Excel Template');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.openxmlformats-officedocument.presentationml.presentation', 'pptx', 'Microsoft Office PowerPoint Presentation');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.openxmlformats-officedocument.presentationml.slideshow', 'ppsx', 'Microsoft Office PowerPoint Slideshow');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.openxmlformats-officedocument.presentationml.template', 'potx', 'Microsoft Office PowerPoint Template');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx', 'Microsoft Office Word');
insert into cr_mime_types (mime_type, file_extension, label) values ('application/vnd.openxmlformats-officedocument.wordprocessingml.template', 'dotx', 'Microsoft Office Word Template');

-- Extension to mime type maps.

-- text/plain for prog langs (maybe we should do application/x-LANG but then you can't look
-- at the code in the browser.
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'c', 'text/plain');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'c++', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'cpp', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'cxx', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'cc', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'h', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'hh', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'h++', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'hxx', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'tcl', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'sql', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'sh', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'csh', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ksh', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'py', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'java', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xql', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'php', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'm4', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pl', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pm', 'text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pod', 'text/plain' );

-- map a few to binary 
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'o','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'so','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'a','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'dll','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'exe','application/octet-stream' );

-- all the rest
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'aab','application/x-authorware-bin' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'aam','application/x-authorware-map' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'aas','application/x-authorware-seg' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ai','application/x-illustrator');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'aif','audio/x-aiff' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'aifc','audio/x-aiff' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'aiff','audio/x-aiff' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ani','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'arj','application/x-arj-compressed' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'asc','text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'asf','video/x-ms-asf' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'asx','video/x-ms-asf' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'au','audio/basic' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'avi','video/x-msvideo' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'bin','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'bmp','image/bmp' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'bqy','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'cacert','application/x-x509-ca-cert' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ccad','application/clariscad' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'cdf','application/x-netcdf' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'cgi','application/x-httpd-cgi' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'class','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'cpio','application/x-cpio' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'cpt','application/mac-compactpro' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'css','text/css' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'csv','application/csv');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'cur','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'dcr','application/x-director' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'deb','application/x-debian-package' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'dhtml','text/html' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'dir','application/x-director' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'dms','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'doc','application/msword' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'dot','application/msword' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'drw','application/drafting' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'dump','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'dvi','application/x-dvi' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'dwf','drawing/x-dwf' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'dwg','application/acad' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'dxf','application/dxf' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'dxr','application/x-director' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'eps','application/postscript' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'etx','text/x-setext' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ez','application/andrew-inset' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'fh4','image/x-freehand' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'fh5','image/x-freehand' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'fh7','image/x-freehand' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'fhc','image/x-freehand' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'fh','image/x-freehand' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'fif','image/fif' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'fit','image/x-fits');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'fli','video/fli' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'fm','application/filemaker');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'gif','image/gif' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'gtar','application/x-gtar' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'gz','application/gzip' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'gzip','application/gzip' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'hdf','application/hdf');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'hqx','application/mac-binhex40' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'html','text/html' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'htm','text/html' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ice','x-conference/x-cooltalk' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ico','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ief','image/ief' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'iges','application/iges' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'igs','application/iges' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'jnlp','application/x-java-jnlp-file' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'jpeg','image/jpeg' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'jpe','image/jpeg' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'jpg','image/jpeg' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'js','application/javascript' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'kar','audio/midi' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'latex','application/x-latex' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'lha','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'lzh','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'm15','audio/x-mod' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'm3u','audio/x-mpegurl' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'm3url','audio/x-mpegurl' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'man','application/x-troff-man' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mdb','application/vnd.ms-access');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'me','application/x-troff-me' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mesh','model/mesh' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mid','audio/midi' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'midi','audio/midi' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mif','application/vnd.mif' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mime','message/rfc822' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'movie','video/x-sgi-movie' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mov','video/quicktime' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mp2','audio/x-mpeg2' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mp2a','audio/x-mpeg2' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mp3','audio/x-mpeg' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mp3a','audio/x-mpeg' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mpeg','video/mpeg' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mpe','video/mpeg' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mpga','audio/x-mpeg' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mpg','video/mpeg' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mpv2','video/mpeg2' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mp2v','video/mpeg2' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mpp','application/vnd.ms-project');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mpc','application/vnd.ms-project');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mpt','application/vnd.ms-project');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mpx','application/vnd.ms-project');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mpw','application/vnd.ms-project');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ms','application/x-troff-ms' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'msh','model/mesh' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'msw','application/msword' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'mtm','audio/x-mod' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'nc','application/x-netcdf' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'oda','application/oda' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ogg','application/x-ogg');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'p65','application/x-pagemaker');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pbm','image/x-portable-bitmap' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pcd','image/x-photo-cd');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pdb','chemical/x-pdb' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pdf','application/pdf' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pgm','image/x-portable-graymap' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pgn','application/x-chess-pgn' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pict','image/x-pict' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'png','image/png' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pnm','image/x-portable-anymap' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ppm','image/x-portable-pixmap' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ppt','application/vnd.ms-powerpoint' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ppz','application/vnd.ms-powerpoint' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pps','application/vnd.ms-powerpoint' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'pot','application/vnd.ms-powerpoint' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'prc','application/x-pilot');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ps','application/postscript' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'psd','application/x-photoshop');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'qt','video/quicktime' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ra','audio/x-pn-realaudio' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ram','audio/x-pn-realaudio' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'rar','application/x-rar-compressed' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ras','image/x-cmu-raster' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'rgb','image/x-rgb' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'rmf', 'audio/rmf');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'rm','audio/x-pn-realaudio-plugin' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'rmm','audio/x-pn-realaudio-plugin' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'roff','application/x-troff' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'rp','application/x-pn-realmedia' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'rpm','audio/x-pn-realaudio-plugin' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'rr','application/x-troff' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'rtf','application/rtf' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'rtx','text/enriched' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 's3m','audio/x-mod' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'sd2','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'sdp','application/sdp' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'sea','application/x-stuffit' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'sgml','text/sgml' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'sgm','text/sgml' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'shtml','text/html' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'silo','model/mesh' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'sit','application/x-stuffit' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'skd','application/vnd.koan' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'skm','application/vnd.koan' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'skp','application/vnd.koan' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'skt','application/vnd.koan' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'snd','audio/basic' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'spl','application/futuresplash' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'stl','application/sla' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'stm','audio/x-mod' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'sv4cpio','application/x-sv4cpio' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'sv4crc','application/x-sv4crc' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'svg','image/svg+xml');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'swf','application/vnd.adobe.flash-movie' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 't','application/x-troff' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'tar','application/x-tar' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'tex','application/x-tex' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'texi','application/x-texinfo' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'texinfo','application/x-texinfo' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'text','text/plain; format=flowed');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'tiff','image/tiff' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'tif','image/tiff' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'tr','application/x-troff' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'tsv','text/tab-separated-values' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'txt','text/plain' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ult','audio/x-mod' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'ustar','application/x-ustar' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'uu','application/octet-stream' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'vcd','application/x-cdlink' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'vcf','application/vcard' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'vdo','video/vdo' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'vda','application/vda' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'vivo','video/vnd.vivo' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'viv','video/vnd.vivo' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'voc','audio/voice');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'vrml','x-world/x-vrml' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'vrm','x-world/x-vrml' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wav','audio/x-wav' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wb1','application/x-quattro-pro' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wb2','application/x-quattro-pro' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wb3','application/x-quattro-pro' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wbmp','image/vnd.wap.wbmp' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'web','application/vnd.xara' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wis','application/x-installshield' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wma','audio/x-ms-wma' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wmd','application/x-ms-wmd' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wmlc','application/vnd.wap.wmlc' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wmlsc','application/vnd.wap.wmlscriptc' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wmls','text/vnd.wap.wmlscript' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wml','text/vnd.wap.wml' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wmv','audio/x-ms-wmv' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wm','video/x-ms-wm' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wmx','video/x-mx-wmx' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wmz','application/x-ms-wmz' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wpd','application/wordperfect' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wq1','application/x-quattro-pro' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wrl','x-world/x-vrml' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'wvx','video/x-ms-wvx' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xar','application/vnd.xara' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'w60','application/wordperfect6.0');
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xbm','image/x-xbitmap' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xlc','application/vnd.ms-excel' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xls','application/vnd.ms-excel' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xlm','application/vnd.ms-excel' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xlw','application/vnd.ms-excel' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xm','audio/x-mod' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xml','text/xml' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xpm','image/x-xpixmap' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xsl','text/xsl' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xuda','xuda/gen-cert' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xwd','image/x-xwindowdump' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'xyz','chemical/x-xyz' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'z','application/x-compress' );
insert into cr_extension_mime_type_map (extension, mime_type) values ( 'zip','application/zip' );
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxc', 'application/vnd.sun.xml.calc');
insert into cr_extension_mime_type_map (extension, mime_type) values ('stc', 'application/vnd.sun.xml.calc.template');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxd', 'application/vnd.sun.xml.draw');
insert into cr_extension_mime_type_map (extension, mime_type) values ('std', 'application/vnd.sun.xml.draw.template');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxi', 'application/vnd.sun.xml.impress');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sti', 'application/vnd.sun.xml.impress.template');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxm', 'application/vnd.sun.xml.math');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxw', 'application/vnd.sun.xml.writer');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxg', 'application/vnd.sun.xml.writer.global');
insert into cr_extension_mime_type_map (extension, mime_type) values ('stw', 'application/vnd.sun.xml.writer.template');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sav', 'application/x-spss-savefile');
insert into cr_extension_mime_type_map (extension, mime_type) values ('spo', 'application/x-spss-outputfile');
insert into cr_extension_mime_type_map (extension, mime_type) values ('mp4', 'video/mp4');
insert into cr_extension_mime_type_map (extension, mime_type) values ('xpi', 'application/x-xpinstall');

-- Open Documents MIME types
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.text', 'odt');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.text-template', 'ott');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.text-web', 'oth');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.text-master', 'odm');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.graphics', 'odg');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.graphics-template', 'otg');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.presentation', 'odp');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.presentation-template', 'otp');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.spreadsheet', 'ods');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.spreadsheet-template', 'ots');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.chart', 'odc');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.formula', 'odf');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.database', 'odb');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.oasis.opendocument.image', 'odi');

-- Open XML formats for MS-Office
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.openxmlformats-officedocument.spreadsheetml.template', 'xltx');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.openxmlformats-officedocument.presentationml.presentation', 'pptx');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.openxmlformats-officedocument.presentationml.slideshow', 'ppsx');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.openxmlformats-officedocument.presentationml.template', 'potx');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx');
insert into cr_extension_mime_type_map (mime_type, extension) values ('application/vnd.openxmlformats-officedocument.wordprocessingml.template', 'dotx');


insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Office Word macro enabled', 'application/vnd.ms-word.document.macroenabled.12', 'docm' from dual;
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Office Word Template macro enabled', 'application/vnd.ms-word.template.macroenabled.12', 'dotm' from dual;
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Office Excel macro enabled', 'application/vnd.ms-excel.sheet.macroenabled.12', 'xlsm' from dual;
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Office Excel Template macro enabled', 'application/vnd.ms-excel.template.macroenabled.12', 'xltm' from dual;
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Office Excel Addin macro enabled', 'application/vnd.ms-excel.addin.macroenabled.12', 'xlam' from dual;
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Office Excel Sheet binary macro enabled', 'application/vnd.ms-excel.sheet.binary.macroenabled.12', 'xlsb' from dual;
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Office PowerPoint Addin macro enabled', 'application/vnd.ms-powerpoint.addin.macroenabled.12', 'ppam' from dual;
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Office PowerPoint Presentation macro enabled', 'application/vnd.ms-powerpoint.presentation.macroenabled.12', 'pptm' from dual;
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Office PowerPoint Template macro enabled', 'application/vnd.ms-powerpoint.template.macroenabled.12', 'potm' from dual;
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Office PowerPoint Slideshow macro enabled', 'application/vnd.ms-powerpoint.slideshow.macroenabled.12', 'ppsm' from dual;



--  Here are some less common mime types and extensions not defined here.
--
--  tsp       | application/dsptype
--  pfr       | application/font-tdpfr
--  imd       | application/immedia
--  mbd       | application/mbedlet
--  pps       | application/pps
--  prt       | application/pro_eng
--  smi       | application/smil
--  smil      | application/smil
--  sol       | application/solids
--  step      | application/step
--  stp       | application/step
--  vmd       | application/vocaltec-media-desc
--  vmf       | application/vocaltec-media-file
--  bcpio     | application/x-bcpio
--  chat      | application/x-chat
--  ipx       | application/x-ipix
--  ips       | application/x-ipscript
--  src       | application/x-wais-source
--  wsrc      | application/x-wais-source
--  vox       | audio/voxware
--  rmf       | audio/x-rmf
--  svh       | image/svh
--  ivr       | i-world/i-vrml
--  hdml      | text/x-hdml
