
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Initialize CVS (OPTIONAL)}</property>
<property name="doc(title)">Initialize CVS (OPTIONAL)</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="openacs-unpack" leftLabel="Prev"
		    title="
Appendix B. Install additional supporting
software"
		    rightLink="psgml-for-emacs" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-cvs" id="install-cvs"></a>Initialize CVS (OPTIONAL)</h2></div></div></div><a class="indexterm" name="idp140592107194328" id="idp140592107194328"></a><p>CVS is a source control system. Create and initialize a
directory for a local cvs repository.</p><pre class="screen">
[root tmp]# <strong class="userinput"><code>mkdir /cvsroot</code></strong>
[root tmp]#<strong class="userinput"><code> cvs -d /cvsroot init</code></strong>
[root tmp]#
<span class="action"><span class="action">mkdir /cvsroot
cvs -d /cvsroot init</span></span>
</pre>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="openacs-unpack" leftLabel="Prev" leftTitle="Unpack the OpenACS tarball"
		    rightLink="psgml-for-emacs" rightLabel="Next" rightTitle="Add PSGML commands to emacs init file
(OPTIONAL)"
		    homeLink="index" homeLabel="Home" 
		    upLink="install-more-software" upLabel="Up"> 
		