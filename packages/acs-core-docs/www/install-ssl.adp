
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Installing SSL Support for an OpenACS service}</property>
<property name="doc(title)">Installing SSL Support for an OpenACS service</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="maintenance-deploy" leftLabel="Prev"
		    title="
Chapter 6. Production Environments"
		    rightLink="analog-setup" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-ssl" id="install-ssl"></a>Installing SSL Support for an OpenACS
service</h2></div></div></div><p>Debian Users: <code class="computeroutput">apt-get install
openssl</code> before proceeding.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Make sure nsopenssl.so is <a class="link" href="install-nsopenssl" title="Install nsopenssl">installed</a>
for AOLserver.</p></li><li class="listitem">
<p>Uncomment this line from <code class="computeroutput">config.tcl</code>.</p><pre class="programlisting">
#ns_param   nsopenssl       ${bindir}/nsopenssl.so
</pre>
</li><li class="listitem">
<p>
<a name="ssl-certificates" id="ssl-certificates"></a>Prepare a
certificate directory for the service.</p><pre class="screen">
[$OPENACS_SERVICE_NAME etc]$ <strong class="userinput"><code>mkdir /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/certs</code></strong>
[$OPENACS_SERVICE_NAME etc]$ <strong class="userinput"><code>chmod 700 /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/certs</code></strong>
[$OPENACS_SERVICE_NAME etc]$ 
<span class="action"><span class="action">mkdir /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/certs
chmod 700 /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/certs</span></span>
</pre>
</li><li class="listitem">
<p>It takes two files to support an SSL connection. The certificate
is the public half of the key pair - the server sends the
certificate to browser requesting ssl. The key is the private half
of the key pair. In addition, the certificate must be signed by
Certificate Authority or browsers will protest. Each web browser
ships with a built-in list of acceptable Certificate Authorities
(CAs) and their keys. Only a site certificate signed by a known and
approved CA will work smoothly. Any other certificate will cause
browsers to produce some messages or block the site. Unfortunately,
getting a site certificate signed by a CA costs money. In this
section, we&#39;ll generate an unsigned certificate which will work
in most browsers, albeit with pop-up messages.</p><p>Use an OpenSSL perl script to generate a certificate and
key.</p><p>Debian users: use /usr/lib/ssl/misc/CA.pl instead of
/usr/share/ssl/CA</p><p>Mac OS X users: use perl /System/Library/OpenSSL/misc/CA.pl
-newcert instead of /usr/share/ssl/CA</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd /var/lib/aolserver/$OPENACS_SERVICE_NAME/etc/certs</code></strong>
[$OPENACS_SERVICE_NAME certs]$ <strong class="userinput"><code>perl /usr/share/ssl/misc/CA -newcert</code></strong>
Using configuration from /usr/share/ssl/openssl.cnf
Generating a 1024 bit RSA private key
...++++++
.......++++++
writing new private key to 'newreq.pem'
Enter PEM pass phrase:
</pre><p>Enter a pass phrase for the CA certificate. Then, answer the
rest of the questions. At the end you should see this:</p><pre class="screen">
Certificate (and private key) is in newreq.pem
[$OPENACS_SERVICE_NAME certs]$
</pre><p>
<code class="computeroutput">newreq.pem</code> contains our
certificate and private key. The key is protected by a passphrase,
which means that we&#39;ll have to enter the pass phrase each time
the server starts. This is impractical and unnecessary, so we
create an unprotected version of the key. <span class="emphasis"><em>Security implication</em></span>: if anyone gets
access to the file keyfile.pem, they effectively own the key as
much as you do. Mitigation: don&#39;t use this key/cert combo for
anything besides providing ssl for the web site.</p><pre class="screen">
[root misc]# <strong class="userinput"><code>openssl rsa -in newreq.pem -out keyfile.pem</code></strong>
read RSA key
Enter PEM pass phrase:
writing RSA key
[$OPENACS_SERVICE_NAME certs]$ 
</pre><p>To create the certificate file, we take the combined file, copy
it, and strip out the key.</p><pre class="screen">
[$OPENACS_SERVICE_NAME certs]$ <strong class="userinput"><code>cp newreq.pem certfile.pem</code></strong>
[root misc]# <strong class="userinput"><code>emacs certfile.pem</code></strong>
</pre><p>Strip out the section that looks like</p><pre class="programlisting">
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,F3EDE7CA1B404997
S/Sd2MYA0JVmQuIt5bYowXR1KYKDka1d3DUgtoVTiFepIRUrMkZlCli08mWVjE6T
<span class="emphasis"><em>(11 lines omitted)</em></span>
1MU24SHLgdTfDJprEdxZOnxajnbxL420xNVc5RRXlJA8Xxhx/HBKTw==
-----END RSA PRIVATE KEY-----
</pre>
</li><li class="listitem"><p>If you start up using the etc/daemontools/run script, you will
need to edit this script to make sure the ports are bound for SSL.
Details of this are in the run script.</p></li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="maintenance-deploy" leftLabel="Prev" leftTitle="Staged Deployment for Production
Networks"
		    rightLink="analog-setup" rightLabel="Next" rightTitle="Set up Log Analysis Reports"
		    homeLink="index" homeLabel="Home" 
		    upLink="maintenance-web" upLabel="Up"> 
		