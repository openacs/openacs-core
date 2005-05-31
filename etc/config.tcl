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
set httpport                  80
set httpsport                 443 

# If setting port below 1024 with AOLServer 4, read daemontools/run

# The hostname and address should be set to actual values.
set hostname                  rand.rocs.biz
set address                   132.229.155.35

# Note: If port is privileged (usually < 1024), OpenACS must be
# started by root, and, in AOLserver 4, the run script have a 
# '-b address' flag which matches the address given above

set server                    "simulation" 
set servername                "New OpenACS Installation - Development"

set serverroot                "/var/www/${server}"

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

#nsrewrite is not used by any standard OpenACS code
#ns_param   nsrewrite          ${bindir}/nsrewrite.so 

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
#ns_param   mailhost           localhost 

# Unicode by default:
# see http://dqd.com/~mayoff/encoding-doc.html
ns_param   HackContentType    1     
ns_param   DefaultCharset     utf-8
ns_param   HttpOpenCharset    utf-8
ns_param   OutputCharset      utf-8
ns_param   URLCharset         utf-8

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
ns_param   maxinput           [expr 20 * 1024 * 1024] ;# Maximum File Size for uploads in bytes
ns_param   recvwait           [expr 5 * 60] ;# Maximum request time in minutes

#---------------------------------------------------------------------
#
# OpenSSL for Aolserver 3.3 and 4
#
#---------------------------------------------------------------------

if { [ns_info version] < 4} {

    #---------------------------------------------------------------------
    # OpenSSL for Aolserver 3.3
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
    ns_param ServerSessionCache        true
    ns_param ServerSessionCacheID      1
    ns_param ServerSessionCacheSize    512
    ns_param ServerSessionCacheTimeout 300
    ns_param ServerPeerVerify          false
    ns_param ServerPeerVerifyDepth     3
    ns_param ServerCADir               ca
    ns_param ServerCAFile              ca.pem
    ns_param ServerTrace               false
    
    # For listening and accepting SSL connections via Tcl/C API:
    ns_param SockServerCertFile              certfile.pem
    ns_param SockServerKeyFile               keyfile.pem
    ns_param SockServerProtocols             "SSLv2, SSLv3, TLSv1"
    ns_param SockServerCipherSuite           "ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP"
    ns_param SockServerSessionCache          true
    ns_param SockServerSessionCacheID        2
    ns_param SockServerSessionCacheSize      512
    ns_param SockServerSessionCacheTimeout   300
    ns_param SockServerPeerVerify            false
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
    ns_param SockClientPeerVerify            false
    ns_param SockServerPeerVerifyDepth       3
    ns_param SockClientCADir                 ca
    ns_param SockClientCAFile                ca.pem
    ns_param SockClientTrace                 false
    
    # OpenSSL library support:
    #ns_param RandomFile          /some/file
    ns_param SeedBytes            1024
} else {

    #---------------------------------------------------------------------
    # OpenSSL for Aolserver 4
    #---------------------------------------------------------------------
    
    ns_section "ns/server/${server}/module/nsopenssl"

    # We explicitly tell the server which SSL contexts to use as defaults when an
    # SSL context is not specified for a particular client or server SSL
    # connection. Driver connections do not use defaults; they must be explicitly
    # specificied in the driver section. The Tcl API will use the defaults as there
    # is currently no provision to specify which SSL context to use for a
    # particular connection via an ns_openssl Tcl command.

    # Note this portion of the configuration is not perfect, and you
    # will get errors in the your error.log. However, it does
    # work. Fixes welcome.

    # ---------------------------------------------------------
    # this is used by acs-tcl/tcl/security-procs.tcl to get the 
    # https port.
    # ---------------------------------------------------------
    ns_param ServerPort                $httpsport
    
    ns_section "ns/server/${server}/module/nsopenssl/sslcontexts"
    ns_param users        "SSL context used for regular user access"
    # ns_param admins       "SSL context used for administrator access"
    ns_param client       "SSL context used for outgoing script socket connections"

    ns_section "ns/server/${server}/module/nsopenssl/defaults"
    ns_param server               users
    ns_param client               client
    
    ns_section "ns/server/${server}/module/nsopenssl/sslcontext/users"
    ns_param Role                  server
    ns_param ModuleDir             ${serverroot}/etc/certs
    ns_param CertFile              certfile.pem 
    ns_param KeyFile               keyfile.pem
    #ns_param CADir                 ca-client/dir
    #ns_param CAFile                ca-client/ca-client.crt
    ns_param Protocols             "SSLv3, TLSv1" 
    ns_param CipherSuite           "ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP" 
    ns_param PeerVerify            false
    ns_param PeerVerifyDepth       3
    ns_param Trace                 false
    
    #ns_section "ns/server/${server}/module/nsopenssl/sslcontext/admins"
    #ns_param Role                  server
    #ns_param ModuleDir             /path/to/dir
    #ns_param CertFile              server/server.crt 
    #ns_param KeyFile               server/server.key 
    #ns_param CADir                 ca-client/dir 
    #ns_param CAFile                ca-client/ca-client.crt
    #ns_param Protocols             "All"
    #ns_param CipherSuite           "ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP" 
    #ns_param PeerVerify            false
    #ns_param PeerVerifyDepth       3
    #ns_param Trace                 false
    
    ns_section "ns/server/${server}/module/nsopenssl/sslcontext/client"
    ns_param Role                  client
    ns_param ModuleDir             ${serverroot}/etc/certs
    ns_param CertFile              certfile.pem
    ns_param KeyFile               keyfile.pem 
    #ns_param CADir                 ${serverroot}/etc/certs
    #ns_param CAFile                certfile.pem
    ns_param Protocols             "SSLv2, SSLv3, TLSv1" 
    ns_param CipherSuite           "ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP" 
    ns_param PeerVerify            false
    ns_param PeerVerifyDepth       3
    ns_param Trace                 false
    
    # SSL drivers. Each driver defines a port to listen on and an explitictly named
    # SSL context to associate with it. Note that you can now have multiple driver
    # connections within a single virtual server, which can be tied to different
    # SSL contexts. Isn't that cool?
    
    ns_section "ns/server/${server}/module/nsopenssl/ssldrivers"
    ns_param users         "Driver for regular user access"
    ns_param admins        "Driver for administrator access"
    
    ns_section "ns/server/${server}/module/nsopenssl/ssldriver/users"
    ns_param sslcontext            users
    # ns_param port                  $httpsport_users
    ns_param port                  $httpsport
    ns_param hostname              $hostname
    ns_param address               $address
    
    ns_section "ns/server/${server}/module/nsopenssl/ssldriver/admins"
    ns_param sslcontext            admins
    # ns_param port                  $httpsport_admins
    ns_param port                  $httpsport
    ns_param hostname              $hostname
    ns_param address               $address

}


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

if { $database == "oracle" } {
    ns_section "ns/db/driver/ora8"
    ns_param  maxStringLogLength -1
    ns_param  LobBufferSize      32768
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
#       ns_param   map "GET  /cgi-bin/ ${serverroot}/cgi-bin"
#       ns_param   map "POST /cgi-bin/ ${serverroot}/cgi-bin" 
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

#---------------------------------------------------------------------
#
# WebDAV Support (optional, requires oacs-dav package to be installed
#
#---------------------------------------------------------------------

ns_section ns/server/${server}/tdav
ns_param propdir ${serverroot}/data/dav/properties
ns_param lockdir ${serverroot}/data/dav/locks
ns_param defaultlocktimeout "300"

ns_section ns/server/${server}/tdav/shares
ns_param share1 "OpenACS"
#ns_param share2 "Share 2 description"

ns_section ns/server/${server}/tdav/share/share1
ns_param uri "/dav/*"
# all WebDAV options
ns_param options "OPTIONS COPY GET PUT MOVE DELETE HEAD MKCOL POST PROPFIND PROPPATCH LOCK UNLOCK"

#ns_section ns/server/${server}/tdav/share/share2
#ns_param uri "/share2/path/*"
# read-only WebDAV options
#ns_param options "OPTIONS COPY GET HEAD MKCOL POST PROPFIND PROPPATCH"

ns_log notice "nsd.tcl: finished reading config file."

