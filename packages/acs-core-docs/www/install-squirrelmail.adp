
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install Squirrelmail for use as a webmail system for
OpenACS}</property>
<property name="doc(title)">Install Squirrelmail for use as a webmail system for
OpenACS</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="install-php" leftLabel="Prev"
		    title="
Appendix B. Install additional supporting
software"
		    rightLink="install-pam-radius" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-squirrelmail" id="install-squirrelmail"></a>Install
Squirrelmail for use as a webmail system for OpenACS</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="mailto:openacs\@sussdorff.de" target="_top">Malte Sussdorff</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>This section is work in progress. It will detail how you can
install Squirrelmail as a webmail frontend for OpenACS, thereby
neglecting the need to have a separate webmail package within
OpenACS</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]# <strong class="userinput"><code>cd www</code></strong>
[$OPENACS_SERVICE_NAME www]# <strong class="userinput"><code>wget http://cesnet.dl.sourceforge.net/sourceforge/squirrelmail/squirrelmail-1.4.4.tar.gz</code></strong>
[$OPENACS_SERVICE_NAME www]# <strong class="userinput"><code>tar xfz squirrelmail-1.4.4.tar.gz</code></strong>
[$OPENACS_SERVICE_NAME www]# <strong class="userinput"><code>mv squirrelmail-1.4.4 mail</code></strong>
[$OPENACS_SERVICE_NAME www]# <strong class="userinput"><code>cd mail/config</code></strong>
[$OPENACS_SERVICE_NAME www]# <strong class="userinput"><code>./conf.pl</code></strong>
</pre><p>Now you are about to configure Squirrelmail. The configuration
heavily depends on your setup, so no instructions are given
here.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="install-php" leftLabel="Prev" leftTitle="Install PHP for use in AOLserver"
		    rightLink="install-pam-radius" rightLabel="Next" rightTitle="Install PAM Radius for use as
external authentication"
		    homeLink="index" homeLabel="Home" 
		    upLink="install-more-software" upLabel="Up"> 
		