<master>
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <h1>@title@</h1>
  <p>
    These notes augment nsimap documentation at <a href="https://bitbucket.org/naviserver/nsimap">https://bitbucket.org/naviserver/nsimap</a>.
  </p>
  <p>Get imap from https://github.com/jonabbey/panda-imap</p>
  <h3>Build errors</h3>
  <p>If there are errors building panda-imap mentioning to use -fPIC. See its use in following OS specific examples.
  </p>
  <h3>nsimap.so installed?</h3>
  <p>nsimap.so may not be automatically added to the NAVISERVER install directory after a build.
  </p>
  <p>Copy it to the NaviServer install directory's bin directory:</p>
  <code>cp nsimap.so /usr/local/ns/bin/.</code>
  <p>Replace '/usr/local/ns' with the value given in the build for the flag NAVISERVER=
  </p>
  <h3>Add nsimap section to NaviServer's config.tcl file</h3>
  <p>Instead of copy/pasting the nsimap parameters for the config.tcl file from the web instructions,
    insert this text snip along other module configurations in the config.tcl file:
    <a href="config-nsimap-part.txt">config-nsimap-part.txt</a>
  </p>
 
  <p>In the ${server}/modules section of the config.tcl file near the comment "These modules aren't used in standard OpenACS installs",
    have nsimap loaded by adding this line:
  </p>
  <code>ns_param  nsimap    ${bindir}/nsimap.so
    </code>
  <h3>Tcl quoting mailbox value</h3>
  <p>For parsing to work in 'ns_imap open' avoid wrapping 
    the mailbox value with double quotes. Quote with curly braces only.</p>
  <p>This works:</p>
  <pre>
    set mailbox {{localhost}/mail/INBOX}
    </pre>
  <p>These may not parse as expected:</p>
  <pre>
    set mailbox "{localhost}/mail/INBOX"
    set mailbox "{{localhost}/mail/INBOX}"
  </pre>

  <h2>Notes on installing nsimap on FreeBSD 10.3-STABLE</h2>
  <p>
    Build panda-imap with:
  </p>
  <code>gmake bsf EXTRACFLAGS=-fPIC</code>
  <p>
    Then build nsimap with:
  </p>
  <code>
    gmake NAVISERVER=/usr/local/ns IMAPFLAGS=-I../../panda-imap/c-client/ "IMAPLIBS=../../panda-imap/c-client/c-client.a -L/usr/local/ns/lib -lpam -lgssapi_krb5 -lkrb5"
  </code>
  <p>Note that NaviServer library is referenced in two places in that line,
    in case your local system locates NaviServer's installation directory elsewhere.</p>
  <p>If there are errors during startup related to FD_SETSIZE and nsd crashing, try this to get nsd to not quit unexpectedly during startup:</p>
  <p>In the startup script for nsd, add the following before invoking nsd:</p>
  <pre>
    # aolserver4 recommends descriptors limit (FD_SETSIZE) to be set to 1024, 
    # which is standard for most OS distributions
    # For freebsd systems, uncomment following line:
    ulimit -n 1024
  </pre>
  <p>Note: This does not fix any problem associated with a crash, only makes problem evaporate for low volume traffic sites.</p>
    
  <h2>Notes on installing nsimap on Ubuntu 16.04 LTS</h2>
  <p>Install some development libraries:</p>
  <code>apt-get install libssl-dev libpam-unix2 libpam0g-dev libkrb5-dev</code>
  <p>Build panda-imap with:</p>
  <code>make ldb EXTRACFLAGS=-fPIC</code>
  <p>If your system requires ipv4 only, add the flags:
    <code>IP=4 IP6=4 SSLTYPE=nopwd</code> like this:</p>
  <code>make ldb EXTRACFLAGS=-fPIC IP=4 IP6=4 SSLTYPE=nopwd</code>
  <p>Some of these are defaults, but the defaults weren't recognized on the test system,
    so they had to be explicitly invoked in this case.
  </p>
  <p>
    Then build nsimap with:
  </p>
  <code>
    make NAVISERVER=/usr/local/ns IMAPFLAGS=-I../../panda-imap/c-client "IMAPLIBS=../../panda-imap/c-client/c-client.a -L/usr/local/ns/lib -lpam -lgssapi_krb5 -lkrb5"
  </code>
  <p>Note that NaviServer library is referenced in two places in that line,
    in case your local system locates NaviServer's installation directory elsewhere.</p>
