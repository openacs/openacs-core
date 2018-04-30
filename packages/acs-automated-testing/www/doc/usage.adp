
<property name="context">{/doc/acs-automated-testing {ACS Automated Testing}} {Usage}</property>
<property name="doc(title)">Usage</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="install" leftLabel="Prev"
			title=""
			rightLink="requirements" rightLabel="Next">
		    <div class="sect1" lang="en">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="usage" id="usage"></a>Usage</h2></div></div></div><div class="authorblurb">
<p>by <a href="mailto:joel\@aufrecht.org" target="_top">Joel
Aufrecht</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>Here&#39;s the entire chain of code used to set up
auto-rebuilding servers on test.openacs.org</p><div class="itemizedlist"><ul type="disc">
<li>
<p>The master server shows the status of all other servers. For
test.openacs.org, it listens on port 80.</p><div class="orderedlist"><ol type="1">
<li><p>The acs-automated-testing parameter <tt class="computeroutput">IsInstallReportServer</tt> is set to 1</p></li><li><p>The acs-automated-testing parameter <tt class="computeroutput">XMLReportDir</tt> is set to <tt class="computeroutput">/var/log/openacs-install</tt>. This is arbitrary -
it just needs to be somewhere all the servers can write to.</p></li>
</ol></div>
</li><li>
<p>For each server that will be monitored:</p><div class="orderedlist"><ol type="1">
<li><p>Suppose the first test server is <span class="replaceable"><span class="replaceable">service1</span></span>. Set
up a dedicated user and <a href="http://openacs.org/doc/openacs-5-0-0/openacs.html#install-with-script" target="_top">automated install script</a>.</p></li><li>
<p>To run automated testing automatically each time the server is
rebuilt, add this to /home/service1/install/install.tcl:</p><pre class="programlisting">
set do_tclapi_testing "yes"</pre>
</li><li>
<p>Get the results of the automated tests dumped where the master
server can see them - in this example, the same directory as above,
<tt class="computeroutput">/var/log/openacs-install</tt>, by adding
this to install.tcl (requires 5.1):</p><pre class="programlisting">
set install_xml_file          "/var/lib/aolserver/service0/packages/acs-core-docs/www/files/install-autotest.xml"</pre><p>This will copy in the file <tt class="computeroutput">install-autotest.xml</tt>:</p><pre class="programlisting">&lt;?xml version="1.0"?&gt;

&lt;!-- This is an install.xml which can be used to configure servers for reporting their automated test results.  Requires acs-automated-testing 5.1.0b2 or better --&gt;

&lt;application name="acs-automated-testing" pretty-name="Automated Testing" home="http://openacs.org/"&gt;

  &lt;actions&gt;

    &lt;set-parameter package="acs-automated-testing" name="XMLReportDir" value="/var/log/openacs-install"/&gt;
  &lt;/actions&gt;

&lt;/application&gt;
</pre><p>which will, during install, configure that parameter in
acs-automated-testing on the monitored server.</p>
</li>
</ol></div>
</li><li>
<p>To enable the 'rebuild server' link, edit the file
/usr/local/bin/rebuild-server.sh:</p><pre class="programlisting">#!/bin/sh
# script to trigger a server rebuild

# hard-coding the valid server names here for some minimal security
case $1 in
    service1) ;;
    service2) ;;
    *)
        echo "Usage: $0 servername"
        exit;;
esac

sudo /home/$1/install/install.sh 2&gt;&amp;1</pre><p>and allow the <tt class="computeroutput">master</tt> user to
execute this file as root (this is a limitation of the automatic
install script, which must be root). In <tt class="computeroutput">/etc/sudoers</tt>, include a line:</p><pre class="programlisting">
master ALL = NOPASSWD: /usr/local/bin/rebuild-server.sh</pre>
</li>
</ul></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="install" leftLabel="Prev" leftTitle="Installation"
			rightLink="requirements" rightLabel="Next" rightTitle="Requirements"
			homeLink="index" homeLabel="Home" 
			upLink="index" upLabel="Up"> 
		    