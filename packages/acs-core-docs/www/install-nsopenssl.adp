
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install nsopenssl}</property>
<property name="doc(title)">Install nsopenssl</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="install-full-text-search-tsearch2" leftLabel="Prev"
			title="Appendix B. Install
additional supporting software"
			rightLink="install-tclwebtest" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-nsopenssl" id="install-nsopenssl"></a>Install nsopenssl</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel Aufrecht</a> and
<a class="ulink" href="mailto:openacs\@sussdorff.de" target="_top">Malte Sussdorff</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><p>This AOLserver module is required if you want people to connect
to your site via https. These commands compile nsopenssl and
install it, along with a Tcl helper script to handle https
connections. You will also need ssl certificates. Because those
should be different for each server service, you won&#39;t need
<a class="link" href="install-ssl">those
instructions</a> until later.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-nsopenssl-aolserver3" id="install-nsopenssl-aolserver3"></a>Install on AOLserver3</h3></div></div></div><p>You will need the <a class="link" href="aolserver">unpacked Aolserver
tarball</a> in <code class="computeroutput">/usr/local/src/aolserver</code> and the <a class="link" href="individual-programs">nsopenssl
tarball</a> in <code class="computeroutput">/tmp</code>.</p><p>Red Hat 9 note: see <a class="ulink" href="http://openacs.org/forums/message-view?message_id=92882" target="_top">this thread</a> for details on compiling nsopenssl.)</p><pre class="screen">[root bin]#<strong class="userinput"><code> cd /usr/local/src/aolserver</code></strong>
[root aolserver]# <strong class="userinput"><code>wget --passive http://www.scottg.net/download/nsopenssl-2.1.tar.gz</code></strong>
[root aolserver]# <strong class="userinput"><code>tar xzf nsopenssl-2.1.tar.gz </code></strong>
[root aolserver]# <strong class="userinput"><code>cd nsopenssl-2.1</code></strong>
[root nsopenssl-2.1]# <strong class="userinput"><code>make OPENSSL=/usr/local/ssl</code></strong>
gcc -I/usr/local/ssl/include -I../aolserver/include -D_REENTRANT=1 -DNDEBUG=1 -g -fPIC -Wall -Wno-unused -mcpu=i686 -DHAVE_CMMSG=1 -DUSE_FIONREAD=1 -DHAVE_COND_EINTR=1   -c -o nsopenssl.o nsopenssl.c
<span class="emphasis"><em>(many lines omitted)</em></span>
gcc -shared -nostartfiles -o nsopenssl.so nsopenssl.o config.o init.o ssl.o thread.o tclcmds.o -L/usr/local/ssl/lib -lssl -lcrypto
[root nsopenssl-2.1]# <strong class="userinput"><code>cp nsopenssl.so /usr/local/aolserver/bin</code></strong>
[root nsopenssl-2.1]# <strong class="userinput"><code>cp https.tcl /usr/local/aolserver/modules/tcl/</code></strong>
[root nsopenssl-2.1]#
<span class="action">cd /usr/local/src/aolserver
wget --passive http://www.scottg.net/download/nsopenssl-2.1.tar.gz
tar xzf nsopenssl-2.1.tar.gz 
cd nsopenssl-2.1 
make OPENSSL=/usr/local/ssl 
cp nsopenssl.so /usr/local/aolserver/bin 
cp https.tcl /usr/local/aolserver/modules/tcl/</span>
</pre><p>For Debian (<a class="ulink" href="http://openacs.org/forums/message-view?message_id=93854" target="_top">more information</a>):</p><pre class="screen"><span class="action">apt-get install libssl-dev
cd /usr/local/src/aolserver
tar xzf /tmp/nsopenssl-2.1.tar.gz
cd nsopenssl-2.1
make OPENSSL=/usr/lib/ssl
cp nsopenssl.so /usr/local/aolserver/bin
cp https.tcl /usr/local/aolserver/modules/tcl/</span></pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-nsopenssl-aolserver4" id="install-nsopenssl-aolserver4"></a>Install on AOLserver4</h3></div></div></div><p>You will need the AOLserver4 source in <code class="computeroutput">/usr/local/src/aolserver/aolserver</code> and
OpenSSL installed in <code class="computeroutput">/usr/local/ssl</code> (or at least symlinked
there). The use of <code class="computeroutput">INST=/point/to/aolserver</code> is being replaced
with <code class="computeroutput">AOLSERVER=/point/to/aolserver</code>. We are
including both here, because while this module still requires INST,
if one just uses AOLSERVER, the default value would be used and
could intefere with another existing installation.</p><p>FreeBSD note: build nsopenssl with <strong class="userinput"><code>gmake install OPENSSL=/usr/local/openssl
AOLSERVER=/usr/local/aolserver4r10</code></strong>
</p><pre class="screen">[root bin]#<strong class="userinput"><code> cd /usr/local/src/aolserver</code></strong>
[root aolserver]# <strong class="userinput"><code>cvs -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver login</code></strong>
[root aolserver]# <strong class="userinput"><code>cvs -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver co nsopenssl</code></strong>
[root aolserver]# <strong class="userinput"><code>cd nsopenssl</code></strong>
[root nsopenssl]# <strong class="userinput"><code>make OPENSSL=/usr/local/ssl</code></strong>
gcc -I/usr/local/ssl/include (many items omitted)  -c -o sslcontext.o sslcontext.c
<span class="emphasis"><em>(many lines omitted)</em></span>
[root nsopenssl-2.1]# <strong class="userinput"><code>make install OPENSSL=/usr/local/ssl AOLSERVER=/usr/local/aolserver4r10 INST=/usr/local/aolserver4r10</code></strong>
[root nsopenssl-2.1]#
<span class="action">cd /usr/local/src/aolserver
cvs -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver login
cvs -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver co nsopenssl
cd nsopenssl
make OPENSSL=/usr/local/ssl 
make install OPENSSL=/usr/local/ssl AOLSERVER=/usr/local/aolserver AOLSERVER=/usr/local/aolserver4r10</span>
</pre><p>If you have problems starting your server with nsopenssl.so due
to missing libssl.so.0.9.7 (or lower), you have to create
symlinks</p><pre class="screen">
[root nsopenssl]# <strong class="userinput"><code>cd /usr/local/aolserver/lib</code></strong>
[root lib]# <strong class="userinput"><code>ln -s /usr/local/ssl/lib/libssl.so.0.9.7 libssl.so.0.9.7</code></strong>
[root lib]# <strong class="userinput"><code>ln -s /usr/local/ssl/lib/libcrypto.so.0.9.7 libcrypto.so.0.9.7</code></strong>
[root lib]#
<span class="action">cd /usr/local/aolserver/lib
ln -s /usr/local/ssl/lib/libssl.so.0.9.7 libssl.so.0.9.7
ln -s /usr/local/ssl/lib/libcrypto.so.0.9.7 libcrypto.so.0.9.7
</span>
</pre><p>SSL support must be enabled separately in each OpenACS server
(<a class="xref" href="install-ssl">Generate
ssl certificates</a>.</p><p>If your ports for SSL are privileged (below 1024), you will have
to start AOLserver with prebinds for both your HTTP and your HTTPS
port (usually by adding <code class="computeroutput">-b <em class="replaceable"><code>your_ip:your_http_port</code></em>,<em class="replaceable"><code>your_ip:your_https_port</code></em>
</code> to
the nsd call. If you are using daemontools, this can be changed in
your <code class="computeroutput">etc/daemontools/run
file</code>).</p><p>To enable SSL support in your server, make sure your
etc/config.tcl file has a section on "OpenSSL 3 with
AOLserver4". If that section is not present, try looking at
the README file in <code class="computeroutput">/usr/local/src/aolserver/nsopenssl</code>.</p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="install-full-text-search-tsearch2" leftLabel="Prev" leftTitle="Install Full Text Search using
Tsearch2"
			rightLink="install-tclwebtest" rightLabel="Next" rightTitle="Install tclwebtest."
			homeLink="index" homeLabel="Home" 
			upLink="install-more-software" upLabel="Up"> 
		    