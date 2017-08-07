
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Appendix D. Using CVS with an
OpenACS Site}</property>
<property name="doc(title)">Appendix D. Using CVS with an
OpenACS Site</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="i18n-translators" leftLabel="Prev"
		    title="
Part III. For OpenACS Package
Developers"
		    rightLink="acs-plat-dev" rightLabel="Next">
		<div class="appendix">
<div class="titlepage"><div><div><h2 class="title">
<a name="cvs-tips" id="cvs-tips"></a>Appendix D. Using CVS with
an OpenACS Site</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel Aufrecht</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>
<a name="cvs-service-import" id="cvs-service-import"></a><strong>Add the Service to CVS -
OPTIONAL. </strong><a class="indexterm" name="idp140592106625944" id="idp140592106625944"></a>These steps take
an existing OpenACS directory and add it to a <a class="link" href="install-cvs" title="Initialize CVS (OPTIONAL)">CVS
repository</a>.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>Create and set permissions on a subdirectory in the local cvs
repository.</p><pre class="screen">
[root root]# <strong class="userinput"><code>mkdir /cvsroot/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[root root]#<strong class="userinput"><code> chown <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME.$OPENACS_SERVICE_NAME</span></span> /cvsroot/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[root root]#
<span class="action"><span class="action">mkdir /cvsroot/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
chown <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME.$OPENACS_SERVICE_NAME</span></span> /cvsroot/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</span></span>
</pre>
</li><li class="listitem">
<p>Add the repository location to the user environment. On some
systems, you may get better results with .bash_profile instead of
.bashrc.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$<strong class="userinput"><code> emacs .bashrc</code></strong>
</pre><p>Put this string into <code class="computeroutput">/home/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/.bashrc</code>:</p><pre class="programlisting">
export CVSROOT=/cvsroot
</pre><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>exit</code></strong>
logout

[root root]#
</pre>
</li><li class="listitem">
<p>Import all files into cvs. In order to work on files with source
control, the files must be checked out from cvs. So we will import,
move aside, and then check out all of the files. In the cvs import
command, <code class="computeroutput"><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span></code> refers to
the cvs repository to use; it uses the CVSROOT plus this string,
i.e. <code class="computeroutput">/cvsroot/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code>.
"OpenACS" is the vendor tag, and
"oacs-5-9-0-final" is the release tag. These tags will be
useful in upgrading and branching. -m sets the version comment.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cvs import -m "initial install" <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> OpenACS oacs-5-9-0-final</code></strong>
N <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/license.txt
N <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/readme.txt
<span class="emphasis"><em>(many lines omitted)</em></span>
N <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/www/SYSTEM/flush-memoized-statement.tcl

No conflicts created by this import

[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ exit
[root root]#
<span class="action"><span class="action">su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
cvs import -m "initial install" <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> OpenACS oacs-5-9-0-final
exit</span></span>
</pre><p>Move the original directory to a temporary location, and check
out the cvs repository in its place.</p><pre class="screen">
[root root]# <strong class="userinput"><code>mv /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> /var/tmp</code></strong>
[root root]# <strong class="userinput"><code>mkdir /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[root root]# <strong class="userinput"><code>chown <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>.<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd /var/lib/aolserver</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>cvs checkout <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
cvs checkout: Updating <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
U <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/license.txt
<span class="emphasis"><em>(many lines omitted)</em></span>
U <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/www/SYSTEM/dbtest.tcl
U <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/www/SYSTEM/flush-memoized-statement.tcl
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>exit</code></strong>
logout

[root root]#

<span class="action"><span class="action">mv /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> /var/tmp
mkdir /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
chown <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>.<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
cd /var/lib/aolserver
cvs checkout <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
exit</span></span>
</pre>
</li><li class="listitem"><p>If the service starts correctly, come back and remove the
temporary copy of the uploaded files.</p></li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="i18n-translators" leftLabel="Prev" leftTitle="Translator&#39;s Guide"
		    rightLink="acs-plat-dev" rightLabel="Next" rightTitle="Part IV. For
OpenACS Platform Developers"
		    homeLink="index" homeLabel="Home" 
		    upLink="acs-package-dev" upLabel="Up"> 
		