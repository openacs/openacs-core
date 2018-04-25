
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Add PSGML commands to emacs init file (OPTIONAL)}</property>
<property name="doc(title)">Add PSGML commands to emacs init file (OPTIONAL)</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="install-cvs" leftLabel="Prev"
			title="Appendix B. Install
additional supporting software"
			rightLink="install-daemontools" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="psgml-for-emacs" id="psgml-for-emacs"></a>Add PSGML commands to emacs init file
(OPTIONAL)</h2></div></div></div><p>
<a class="indexterm" name="idp140682186507336" id="idp140682186507336"></a> If you plan to write or edit any
documentation with emacs, install a customized emacs configuration
file with DocBook commands in the skeleton directory, so it will be
used for all new users. The file also fixes the backspace -&gt;
help mis-mapping that often occurs in terminals.</p><pre class="screen">[root tmp]# <strong class="userinput"><code>cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/emacs.txt /etc/skel/.emacs</code></strong>
cp: overwrite `/etc/skel/.emacs'? <strong class="userinput"><code>y</code></strong>
[root tmp]# </pre><p>Debian users:</p><pre class="screen"><span class="action">apt-get install psgml</span></pre><p>Note: The new nxml mode for emacs, when used in combination with
psgml, provides a pretty good set of functionality that makes
DocBook editing much less painless. In particular, nxml does syntax
testing in real-time so that you can see syntax errors immediately
instead of in the output of the xsltproc hours or days later. For
Debian, <code class="computeroutput">apt-get install
nxml</code>.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="install-cvs" leftLabel="Prev" leftTitle="Initialize CVS (OPTIONAL)"
			rightLink="install-daemontools" rightLabel="Next" rightTitle="Install Daemontools (OPTIONAL)"
			homeLink="index" homeLabel="Home" 
			upLink="install-more-software" upLabel="Up"> 
		    