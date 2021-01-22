
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Basic Steps}</property>
<property name="doc(title)">Basic Steps</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="install-overview" leftLabel="Prev"
		    title="
Chapter 2. Installation Overview"
		    rightLink="individual-programs" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-steps" id="install-steps"></a>Basic Steps</h2></div></div></div><p>Most of the documentation in this section is kept as a
reference. More up-to-date documentation is in the <a class="ulink" href="http://openacs.org/xowiki/openacs-system-install" target="_top">install sections in the Wiki</a>.</p><p>The basic steps for installing OpenACS are:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Install an OS and supporting software (see <a class="xref" href="unix-installation" title="Install a Unix-like system and supporting software">Install a
Unix-like OS</a> or <a class="xref" href="install-redhat" title="Appendix A. Install Red Hat 8/9">Appendix A,
<em>Install Red Hat 8/9</em>
</a> for more details). See the
<a class="xref" href="individual-programs" title="Table 2.2. Version Compatibility Matrix">Table 2.2,
&ldquo;Version Compatibility
Matrix&rdquo;</a>.</p></li><li class="listitem"><p>Install a database (see <a class="xref" href="oracle" title="Install Oracle 8.1.7">the section called
&ldquo;Install Oracle 8.1.7&rdquo;</a> or
<a class="xref" href="postgres" title="Install PostgreSQL">Install PostgreSQL</a>).</p></li><li class="listitem"><p>Install AOLserver (<a class="xref" href="aolserver4" title="Install AOLserver 4">Install AOLserver 4</a>) .</p></li><li class="listitem"><p>Create a unique database and system user. Install the OpenACS
tarball, start and AOLserver instance, and use the OpenACS web
pages to complete installation (see <a class="xref" href="openacs" title="Install OpenACS 5.9.0">Install OpenACS
5.9.0</a>).</p></li>
</ol></div><p>Specific instructions are available for Mac OS X and Windows2000
(see <a class="xref" href="mac-installation" title="OpenACS Installation Guide for Mac OS X">the section called
&ldquo;OpenACS Installation Guide for Mac OS
X&rdquo;</a> or <a class="xref" href="win2k-installation" title="OpenACS Installation Guide for Windows">the section called
&ldquo;OpenACS Installation Guide for
Windows&rdquo;</a>).</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-rpms" id="install-rpms"></a>Binaries and other shortcuts</h3></div></div></div><p>You can try out OpenACS using some binary installers. In
general, they are not yet supported by the community, so they are
mostly for evaluation purposes. <a class="ulink" href="http://openacs.org/faq/one-faq?faq_id=130897#130917" target="_top">Installing OpenACS</a>
</p><p>You can see a list of <a class="ulink" href="http://openacs.org/projects/openacs/installer" target="_top">current installers</a>.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>The packaged version of PostgreSQL in Debian, Red Hat, and
FreeBSD ports works fine.</p></li><li class="listitem"><p>Once AOLserver and a database are installed, a bash script
<a class="link" href="openacs" title="Installation Option 1: Use automated script">automates the OpenACS
checkout and installation</a>.</p></li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-requirements" id="install-requirements"></a>System Requirements</h3></div></div></div><p>You will need a PC (or equivalent) with at least these minimum
specifications:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>128MB RAM (much more if you want Oracle)</p></li><li class="listitem"><p>1GB free space on your hard drive (much more if you want
Oracle)</p></li><li class="listitem"><p>A Unix-like operating system with Tcl, tDOM, and a mail
transport agent like sendmail or qmail. (see <a class="xref" href="individual-programs" title="Prerequisite Software">the
section called &ldquo;Prerequisite
Software&rdquo;</a>)</p></li>
</ul></div><p>All of the software mentioned is open-source and available
without direct costs, except for Oracle. You can obtain a free copy
of Oracle for development purposes. This is described in the
<a class="xref" href="oracle" title="Acquire Oracle">Acquire Oracle</a> section.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="how-to-use" id="how-to-use"></a>How to
use this guide</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<code class="computeroutput">This</code> is text you will see on
screen, such as a <code class="computeroutput"><span class="guibutton"><span class="guibutton">
<u><span class="accel">B</span></u>utton</span></span></code> or <code class="computeroutput"><span class="guilabel"><span class="guilabel"><u><span class="accel">link</span></u></span></span></code> in a radio button list
or menu.</p></li><li class="listitem"><p><strong class="userinput"><code>This is text that you will
type.</code></strong></p></li><li class="listitem">
<p>This is text from a program or file which you may need to
examine or edit:</p><pre class="programlisting">
if {$database eq "oracle"} {
          set db_password        "mysitepassword"
}
</pre>
</li><li class="listitem">
<p>This is text that you will <code class="computeroutput">see</code> and <strong class="userinput"><code>type</code></strong> in a command shell,
including <span class="replaceable"><span class="replaceable">text
you may have to change</span></span>. It is followed by a list of
just the commands, which you can copy and paste. The command prompt
varies by system; in the examples we use the form<code class="computeroutput">[$OPENACS_SERVICE_NAME aolserver]$</code>, where
<code class="computeroutput">$OPENACS_SERVICE_NAME</code> is the
current user and <code class="computeroutput">aolserver</code> is
the current directory. The root prompt is shown ending in # and all
other prompts in $.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - $OPENACS_SERVICE_NAME</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>svc -d /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>dropdb <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
DROP DATABASE
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>createdb <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
CREATE DATABASE
<span class="action"><span class="action">su - $OPENACS_SERVICE_NAME
svc -d /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
dropdb <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
createdb <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</span></span>
</pre><p>
<a name="cut-and-paste-name-var" id="cut-and-paste-name-var"></a><strong>Setting a global shell
variable for cut and paste. </strong>In order to cut
and paste the instructions into your shell, you must set the
environment variable $OPENACS_SERVICE_NAME. In order to set it
globally so that it works for any new users or special service
users you may create, edit the file <code class="computeroutput">/etc/profile</code> ( <code class="computeroutput">/etc/share/skel/dot.profile</code> for FreeBSD)
and add this line:</p><pre class="programlisting">
export OPENACS_SERVICE_NAME=<span class="replaceable"><span class="replaceable">service0</span></span>
</pre>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140592102795240" id="idp140592102795240"></a>Paths and Users</h3></div></div></div><div class="table">
<a name="idp140592102795880" id="idp140592102795880"></a><p class="title"><strong>Table 2.1. Default
directories for a standard install</strong></p><div class="table-contents"><table class="table" summary="Default directories for a standard install" cellspacing="0" width="100%" border="1">
<colgroup>
<col><col>
</colgroup><tbody>
<tr>
<td>Fully qualified domain name of your server</td><td><span class="replaceable"><span class="replaceable">yourserver.test</span></span></td>
</tr><tr>
<td>name of administrative access account</td><td>remadmin</td>
</tr><tr>
<td>OpenACS service</td><td>
<a class="indexterm" name="idp140592102800488" id="idp140592102800488"></a><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> (set to service0
in default install)</td>
</tr><tr>
<td>OpenACS service account</td><td><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span></td>
</tr><tr>
<td>OpenACS database name</td><td><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span></td>
</tr><tr>
<td>Root of OpenACS service file tree (SERVERROOT)</td><td><span class="replaceable"><span class="replaceable">/var/lib/aolserver/$OPENACS_SERVICE_NAME</span></span></td>
</tr><tr>
<td>Location of source code tarballs for new software</td><td>/var/tmp</td>
</tr><tr>
<td>The OpenACS tarball contains some files which are useful while
setting up other software. Those files are located at:</td><td>/var/tmp/openacs-5.9.0/packages/acs-core-docs/www/files</td>
</tr><tr>
<td>Database backup directory</td><td><span class="replaceable"><span class="replaceable">/var/lib/aolserver/$OPENACS_SERVICE_NAME/database-backup</span></span></td>
</tr><tr>
<td>Service config files</td><td><span class="replaceable"><span class="replaceable">/var/lib/aolserver/$OPENACS_SERVICE_NAME/etc</span></span></td>
</tr><tr>
<td>Service log files</td><td><span class="replaceable"><span class="replaceable">/var/lib/aolserver/$OPENACS_SERVICE_NAME/log</span></span></td>
</tr><tr>
<td>Compile directory</td><td>/usr/local/src</td>
</tr><tr>
<td>PostgreSQL directory</td><td>/usr/local/pgsql</td>
</tr><tr>
<td>AOLserver directory</td><td>/usr/local/aolserver</td>
</tr>
</tbody>
</table></div>
</div><br class="table-break"><p>None of these locations are set in stone - they&#39;re simply
the values that we&#39;ve chosen. The values that you&#39;ll
probably want to change, such as service name, are <span class="replaceable"><span class="replaceable">marked like
this</span></span>. The other values we recommend you leave
unchanged unless you have a reason to change them.</p><div class="note" style="margin-left: 0.5in; margin-right: 0.5in;">
<h3 class="title">Note</h3><p>Some of the paths and user accounts have been changed from those
recommended in previous versions of this document to improve
security and maintainability. See <a class="ulink" href="http://openacs.org/forums/message-view?message_id=82934" target="_top">this thread</a> for discussion.</p>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-stuck" id="install-stuck"></a>Getting Help during installation</h3></div></div></div><p>We&#39;ll do our best to assure that following our instructions
will get you to the promised land. If something goes wrong,
don&#39;t panic. There are plenty of ways to get help. Here are
some tips:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Keep track of the commands you are run and record their output.
I like to do my installations in a shell inside of emacs
(<code class="computeroutput">M-x shell</code>) so that I can save
the output if needed. An alternative would be to use the
<code class="computeroutput">script</code> command.</p></li><li class="listitem"><p>We&#39;ll point out where the error logs for the various pieces
of software are. Output from those logs will help us help you.
Don&#39;t worry if you feel overwhelmed by all the information in
the error logs. Over time, you&#39;ll find that they make more and
more sense. Soon, you&#39;ll actually look forward to errors so
that you can run to the log and diagnose the problem.</p></li><li class="listitem"><p>Search the <a class="ulink" href="http://openacs.org/forums/" target="_top">forums at openacs.org</a> - you&#39;ll often find
many people who have struggled through the same spot that
you&#39;re in.</p></li><li class="listitem"><p>The bottom of each page has a link to OpenACS.org, where you can
post comments and read other users comments about the contents of
the page.</p></li><li class="listitem"><p>Ask questions at the irc channel on <a class="ulink" href="http://freenode.net" target="_top">freenode.net</a> (#openacs).
They&#39;re knowledgeable and quite friendly if you can keep them
on topic.</p></li><li class="listitem"><p>Post a question on the <a class="ulink" href="http://openacs.org/forums/" target="_top">forums</a>. Make sure
you&#39;ve done a search first. When you do post, be sure to
include your setup information (OS, etc) as well as the exact
commands that are failing with the accompanying error. If
there&#39;s a SQL error in the Tcl error or in the log, post that
too.</p></li><li class="listitem"><p>If you find errors in this document or if you have ideas about
making it better, please post them in our <a class="ulink" href="http://openacs.org/bugtracker/openacs/" target="_top">BugTracker</a>.</p></li>
</ul></div><div class="cvstag">($&zwnj;Id: overview.xml,v 1.29.2.2 2016/06/23
08:32:46 gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="install-overview" leftLabel="Prev" leftTitle="
Chapter 2. Installation Overview"
		    rightLink="individual-programs" rightLabel="Next" rightTitle="Prerequisite Software"
		    homeLink="index" homeLabel="Home" 
		    upLink="install-overview" upLabel="Up"> 
		