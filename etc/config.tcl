ns_log notice "nsd.tcl: starting to read config file..."

###################################################################### 
#
# Instance-specific settings 
# These default settings will only work in limited circumstances
# Two servers with default settings cannot run on the same host
#
###################################################################### 

#---------------------------------------------------------------------
# change to 80 and 443 for production use
set httpport                  8000
set httpsport                 8443 

# The hostname and address should be set to actual values.
set hostname                  [ns_info hostname]
set address                   [ns_info address]

set server                    "service0" 
set servername                "New OpenACS Installation - Development"

set serverroot                "/var/lib/aolserver/${server}"

#---------------------------------------------------------------------
# which database do you want? postgres or oracle
set database              postgres 

set db_name               $server

if { $database == "oracle" } {
    set db_password           "mysitepassword"
} else {
    set db_host               localhost
    set db_port               ""
    set db_user               $server
}

#---------------------------------------------------------------------
# if debug is false, all debugging will be turned off
set debug false

set homedir                   /usr/local/aolserver
set bindir                    [file dirname [ns_info nsd]] 

#---------------------------------------------------------------------
# which modules should be loaded?  Missing modules break the server, so
# don't uncomment modules unless they have been installed.

ns_section ns/server/${server}/modules 
ns_param   nssock             ${bindir}/nssock.so 
ns_param   nslog              ${bindir}/nslog.so 
ns_param   nssha1             ${bindir}/nssha1.so 
ns_param   nscache            ${bindir}/nscache.so 
ns_param   nsrewrite          ${bindir}/nsrewrite.so 

#---------------------------------------------------------------------
# nsopenssl will fail unless the cert files are present as specified
# later in this file, so it's disabled by default
#ns_param   nsopenssl          ${bindir}/nsopenssl.so

# Full Text Search
#ns_param   nsfts              ${bindir}/nsfts.so

# PAM authentication
#ns_param   nspam              ${bindir}/nspam.so

# LDAP authentication
#ns_param   nsldap             ${bindir}/nsldap.so

# These modules aren't used in standard OpenACS installs
#ns_param   nsperm             ${bindir}/nsperm.so 
#ns_param   nscgi              ${bindir}/nscgi.so 
#ns_param   nsjava             ${bindir}/libnsjava.so

if { [ns_info version] >= 4 } {
    # Required for AOLserver 4.x
    ns_param   nsdb               ${bindir}/nsdb.so
} else {
    # Required for AOLserver 3.x
    ns_param   libtdom            ${bindir}/libtdom.so
}

#---------------------------------------------------------------------
#
# Rollout email support
#
# These procs help manage differing email behavior on 
# dev/staging/production.
#
#---------------------------------------------------------------------

ns_section ns/server/${server}/acs/acs-rollout-support

# EmailDeliveryMode can be:
#   default:  Email messages are sent in the usual manner.
#   log:      Email messages are written to the server's error log.
#   redirect: Email messages are redirected to the addresses specified 
#             by the EmailRedirectTo parameter.  If this list is absent 
#             or empty, email messages are written to the server's error log.
#   filter:   Email messages are sent to in the usual manner if the 
#             recipient appears in the EmailAllow parameter, otherwise they 
#             are logged.

#ns_param   EmailDeliveryMode redirect
#ns_param   EmailRedirectTo    somenerd@yourdomain.test, othernerd@yourdomain.test
#ns_param   EmailAllow         somenerd@yourdomain.test,othernerd@yourdomain.test

###################################################################### 
#
# End of instance-specific settings 
#
# Nothing below this point need be changed in a default install.
#
###################################################################### 


#---------------------------------------------------------------------
#
# AOLserver's directories. Autoconfigurable. 
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Where are your pages going to live ?
#
set pageroot                  ${serverroot}/www 
set directoryfile             index.tcl,index.adp,index.html,index.htm


#---------------------------------------------------------------------
# Global server parameters 
#---------------------------------------------------------------------

ns_section ns/parameters 
ns_param   serverlog          ${serverroot}/log/error.log 
ns_param   home               $homedir 
ns_param   maxkeepalive       0
ns_param   logroll            on
ns_param   maxbackup          5
ns_param   debug              $debug
#ns_param  OutputCharset  utf-8    ;# Default output charset.  When none specified,
                                   # no character encoding of output is performed.
#ns_param  URLCharset     utf-8    ;# Default Charset for Url Encode/Decode.

#---------------------------------------------------------------------
# Thread library (nsthread) parameters 
#---------------------------------------------------------------------

ns_section ns/threads 
ns_param   mutexmeter         true      ;# measure lock contention 
# The per-thread stack size must be a multiple of 8k for AOLServer to run under MacOS X
ns_param   stacksize          [expr 128 * 8192]

# 
# MIME types. 
# 
#  Note: AOLserver already has an exhaustive list of MIME types, but in
#  case something is missing you can add it here. 
#

ns_section ns/mimetypes
ns_param   Default            text/plain
ns_param   NoExtension        text/plain
ns_param   .pcd               image/x-photo-cd
ns_param   .prc               application/x-pilot
ns_param   .xls               application/vnd.ms-excel
ns_param   .doc               application/vnd.ms-word

# 
# Tcl Configuration 
# 
ns_section ns/server/${server}/tcl
ns_param   library            ${serverroot}/tcl
ns_param   autoclose          on 
ns_param   debug              $debug
 

#---------------------------------------------------------------------
# 
# Server-level configuration 
# 
#  There is only one server in AOLserver, but this is helpful when multiple
#  servers share the same configuration file.  This file assumes that only
#  one server is in use so it is set at the top in the "server" Tcl variable
#  Other host-specific values are set up above as Tcl variables, too.
# 
#---------------------------------------------------------------------

ns_section ns/servers 
ns_param   $server            $servername 

# 
# Server parameters 
# 
ns_section ns/server/${server} 
ns_param   directoryfile      $directoryfile
ns_param   pageroot           $pageroot
ns_param   maxconnections     5
ns_param   maxdropped         0
ns_param   maxthreads         5
ns_param   minthreads         5
ns_param   threadtimeout      120
ns_param   globalstats        false    ;# Enable built-in statistics 
ns_param   urlstats           false    ;# Enable URL statistics 
ns_param   maxurlstats        1000     ;# Max number of URL's to do stats on
#ns_param   directoryadp       $pageroot/dirlist.adp ;# Choose one or the other
#ns_param   directoryproc      _ns_dirlist          ;#  ...but not both!
#ns_param   directorylisting   fancy               ;# Can be simple or fancy

#
# Special HTTP pages
#

ns_param   NotFoundResponse   "/global/file-not-found.html"
ns_param   ServerBusyResponse "/global/busy.html"
ns_param   ServerInternalErrorResponse "/global/error.html"

#---------------------------------------------------------------------
# 
# ADP (AOLserver Dynamic Page) configuration 
# 
#---------------------------------------------------------------------

ns_section ns/server/${server}/adp 
ns_param   map                /*.adp    ;# Extensions to parse as ADP's 
#ns_param   map                "/*.html" ;# Any extension can be mapped 
ns_param   enableexpire       false     ;# Set "Expires: now" on all ADP's 
ns_param   enabledebug        $debug    ;# Allow Tclpro debugging with "?debug"
ns_param   defaultparser      fancy

ns_section ns/server/${server}/adp/parsers
ns_param   fancy    ".adp"
 
#---------------------------------------------------------------------
# 
# Socket driver module (HTTP)  -- nssock 
# 
#---------------------------------------------------------------------

ns_section ns/server/${server}/module/nssock
ns_param   timeout            120
ns_param   address            $address
ns_param   hostname           $hostname
ns_param   port               $httpport

#---------------------------------------------------------------------
#
# OpenSSL
#
#---------------------------------------------------------------------

ns_section "ns/server/${server}/module/nsopenssl"

ns_param ModuleDir            ${serverroot}/etc/certs

# NSD-driven connections:
ns_param ServerPort                $httpsport
ns_param ServerHostname            $hostname
ns_param ServerAddress             $address
ns_param ServerCertFile            certfile.pem
ns_param ServerKeyFile             keyfile.pem
ns_param ServerProtocols           "SSLv2, SSLv3, TLSv1"
ns_param ServerCipherSuite         "ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP"
ns_param ServerSessionCache        false
ns_param ServerSessionCacheID      1
ns_param ServerSessionCacheSize    512
ns_param ServerSessionCacheTimeout 300
ns_param ServerPeerVerify          true
ns_param ServerPeerVerifyDepth     3
ns_param ServerCADir               ca
ns_param ServerCAFile              ca.pem
ns_param ServerTrace               false

# For listening and accepting SSL connections via Tcl/C API:
ns_param SockServerCertFile              certfile.pem
ns_param SockServerKeyFile               keyfile.pem
ns_param SockServerProtocols             "SSLv2, SSLv3, TLSv1"
ns_param SockServerCipherSuite           "ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP"
ns_param SockServerSessionCache          false
ns_param SockServerSessionCacheID        2
ns_param SockServerSessionCacheSize      512
ns_param SockServerSessionCacheTimeout   300
ns_param SockServerPeerVerify            true
ns_param SockServerPeerVerifyDepth       3
ns_param SockServerCADir                 internal_ca
ns_param SockServerCAFile                internal_ca.pem
ns_param SockServerTrace                 false

# Outgoing SSL connections
ns_param SockClientCertFile              certfile.pem
ns_param SockClientKeyFile               keyfile.pem
ns_param SockClientProtocols             "SSLv2, SSLv3, TLSv1"
ns_param SockClientCipherSuite           "ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP"
ns_param SockClientSessionCache          false
ns_param SockClientSessionCacheID        3
ns_param SockClientSessionCacheSize      512
ns_param SockClientSessionCacheTimeout   300
ns_param SockClientPeerVerify            true
ns_param SockServerPeerVerifyDepth       3
ns_param SockClientCADir                 ca
ns_param SockClientCAFile                ca.pem
ns_param SockClientTrace                 false

# OpenSSL library support:
#ns_param RandomFile          /some/file
ns_param SeedBytes            1024


#---------------------------------------------------------------------
# 
# Database drivers 
# The database driver is specified here.
# Make sure you have the driver compiled and put it in {aolserverdir}/bin
#
#---------------------------------------------------------------------

ns_section "ns/db/drivers" 
if { $database == "oracle" } {
    ns_param   ora8           ${bindir}/ora8.so
} else {
    ns_param   postgres       ${bindir}/nspostgres.so  ;# Load PostgreSQL driver
}

# 
# Database Pools: This is how AOLserver  ``talks'' to the RDBMS. You need 
# three for OpenACS: main, log, subquery. Make sure to replace ``yourdb'' 
# and ``yourpassword'' with the actual values for your db name and the 
# password for it, if needed.  

# AOLserver can have different pools connecting to different databases 
# and even different different database servers.
# 
ns_section ns/db/pools 
ns_param   pool1              "Pool 1"
ns_param   pool2              "Pool 2"
ns_param   pool3              "Pool 3"

ns_section ns/db/pool/pool1
ns_param   maxidle            1000000000
ns_param   maxopen            1000000000
ns_param   connections        5
ns_param   verbose            $debug
ns_param   extendedtableinfo  true
ns_param   logsqlerrors       $debug
if { $database == "oracle" } {
    ns_param   driver             ora8
    ns_param   datasource         {}
    ns_param   user               $db_name
    ns_param   password           $db_password
} else {
    ns_param   driver             postgres 
    ns_param   datasource         ${db_host}:${db_port}:${db_name}
    ns_param   user               $db_user
    ns_param   password           ""
} 

ns_section ns/db/pool/pool2
ns_param   maxidle            1000000000
ns_param   maxopen            1000000000
ns_param   connections        5
ns_param   verbose            $debug
ns_param   extendedtableinfo  true
ns_param   logsqlerrors       $debug
if { $database == "oracle" } {
    ns_param   driver             ora8
    ns_param   datasource         {}
    ns_param   user               $db_name
    ns_param   password           $db_password
} else {
    ns_param   driver             postgres 
    ns_param   datasource         ${db_host}:${db_port}:${db_name}
    ns_param   user               $db_user
    ns_param   password           ""
} 

ns_section ns/db/pool/pool3
ns_param   maxidle            1000000000
ns_param   maxopen            1000000000
ns_param   connections        5
ns_param   verbose            $debug
ns_param   extendedtableinfo  true
ns_param   logsqlerrors       $debug
if { $database == "oracle" } {
    ns_param   driver             ora8
    ns_param   datasource         {}
    ns_param   user               $db_name
    ns_param   password           $db_password
} else {
    ns_param   driver             postgres 
    ns_param   datasource         ${db_host}:${db_port}:${db_name}
    ns_param   user               $db_user
    ns_param   password           ""
} 

ns_section ns/server/${server}/db
ns_param   pools              "*" 
ns_param   defaultpool        pool1

ns_section ns/server/${server}/redirects
ns_param   404                "global/file-not-found.html"
ns_param   403                "global/forbidden.html"


#---------------------------------------------------------------------
# 
# Access log -- nslog 
# 
#---------------------------------------------------------------------

ns_section ns/server/${server}/module/nslog 
ns_param   debug              false
ns_param   dev                false
ns_param   enablehostnamelookup false
ns_param   file               ${serverroot}/log/${server}.log
ns_param   logcombined        true
ns_param   extendedheaders    COOKIE
#ns_param   logrefer           false
#ns_param   loguseragent       false
ns_param   maxbackup          1000
ns_param   rollday            *
ns_param   rollfmt            %Y-%m-%d-%H:%M
ns_param   rollhour           0
ns_param   rollonsignal       true
ns_param   rolllog            true

#---------------------------------------------------------------------
#
# nsjava - aolserver module that embeds a java virtual machine.  Needed to 
#          support webmail.  See http://nsjava.sourceforge.net for further 
#          details. This may need to be updated for OpenACS4 webmail
#
#---------------------------------------------------------------------

ns_section ns/server/${server}/module/nsjava
ns_param   enablejava         off  ;# Set to on to enable nsjava.
ns_param   verbosejvm         off  ;# Same as command line -debug.
ns_param   loglevel           Notice
ns_param   destroyjvm         off  ;# Destroy jvm on shutdown.
ns_param   disablejitcompiler off  
ns_param   classpath          /usr/local/jdk/jdk118_v1/lib/classes.zip:${bindir}/nsjava.jar:${pageroot}/webmail/java/activation.jar:${pageroot}/webmail/java/mail.jar:${pageroot}/webmail/java 

#---------------------------------------------------------------------
# 
# CGI interface -- nscgi, if you have legacy stuff. Tcl or ADP files inside 
# AOLserver are vastly superior to CGIs. I haven't tested these params but they
# should be right.
# 
#---------------------------------------------------------------------

#ns_section "ns/server/${server}/module/nscgi" 
#       ns_param   map "GET  /cgi-bin/ /web/$server/cgi-bin"
#       ns_param   map "POST /cgi-bin/ /web/$server/cgi-bin" 
#       ns_param   Interps CGIinterps

#ns_section "ns/interps/CGIinterps" 
#       ns_param .pl "/usr/bin/perl"


#---------------------------------------------------------------------
#
# PAM authentication
#
#---------------------------------------------------------------------

ns_section ns/server/${server}/module/nspam
ns_param   PamDomain          "pam_domain"

ns_log notice "nsd.tcl: finished reading config file."

