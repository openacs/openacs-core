
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Unpack the OpenACS tarball}</property>
<property name="doc(title)">Unpack the OpenACS tarball</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="install-more-software" leftLabel="Prev"
			title="Appendix B. Install
additional supporting software"
			rightLink="install-cvs" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="openacs-unpack" id="openacs-unpack"></a>Unpack the OpenACS tarball</h2></div></div></div><p>The OpenACS tarball contains sample configuration files for some
of the packages listed below. In order to access those files,
unpack the tarball now.</p><pre class="screen">[root root]# <strong class="userinput"><code>cd /tmp</code></strong>
[root tmp]# <strong class="userinput"><code>tar xzf openacs-5.9.0.tgz</code></strong><span class="action">cd /tmp
tar xzf openacs-5.9.0.tgz</span>
</pre><p>If you are installing from a different method and just need the
configuration files, you can instead get them from CVS:</p><pre class="screen">[root root]# <strong class="userinput"><code>cd /tmp</code></strong>
[root tmp]# <strong class="userinput"><code>cvs -d :pserver:anonymous\@cvs.openacs.org:/cvsroot co openacs-4/packages/acs-core-docs/www/files/</code></strong>
cvs checkout: warning: failed to open /root/.cvspass for reading: No such file or directory
cvs server: Updating openacs-4/packages/acs-core-docs/www/files
U openacs-4/packages/acs-core-docs/www/files/README.TXT
<span class="emphasis"><em>(many lines omitted)</em></span>
U openacs-4/packages/acs-core-docs/www/files/template-ini.ini
U openacs-4/packages/acs-core-docs/www/files/winnsd.txt
[root tmp]# <strong class="userinput"><code>mv openacs-4 openacs-5.9.0</code></strong><span class="action">cd /tmp
cvs -d :pserver:anonymous\@cvs.openacs.org:/cvsroot co openacs-4/packages/acs-core-docs/www/files/
mv openacs-4 openacs-5.0.0a4</span>
</pre>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="install-more-software" leftLabel="Prev" leftTitle="Appendix B. Install
additional supporting software"
			rightLink="install-cvs" rightLabel="Next" rightTitle="Initialize CVS (OPTIONAL)"
			homeLink="index" homeLabel="Home" 
			upLink="install-more-software" upLabel="Up"> 
		    