
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install PAM Radius for use as external
authentication}</property>
<property name="doc(title)">Install PAM Radius for use as external
authentication</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="install-squirrelmail" leftLabel="Prev"
		    title="
Appendix B. Install additional supporting
software"
		    rightLink="install-ldap-radius" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-pam-radius" id="install-pam-radius"></a>Install PAM Radius for use as external
authentication</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="mailto:openacs\@sussdorff.de" target="_top">Malte Sussdorff</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>This step by step guide is derived from the installation
instructions which you can find at <span class="replaceable"><span class="replaceable">yourdomain.com</span></span>/doc/acs-authentication/ext-auth-pam-install.html.
It is build upon PAM 0.77 (tested) and does not work on RedHat
Linux Enterprise 3 (using PAM 0.75). It makes use of the ns_pam
module written by Mat Kovach. The instructions given in here do
work with PAM LDAP accordingly and differences will be shown at the
end of the file.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<a name="install-ns_pam" id="install-ns_pam"></a><p>
<strong>Install ns_pam. </strong>Download and
install ns_pam</p><pre class="screen">
[root aolserver]# <strong class="userinput"><code>cd /usr/local/src/aolserver/</code></strong>
          [root aolserver]# <strong class="userinput"><code>wget http://braindamage.alal.com/software/ns_pam-0.1.tar.gz</code></strong>
          [root aolserver]# <strong class="userinput"><code>tar xvfz ns_pam-0.1.tar.gz</code></strong>
          [root aolserver]# <strong class="userinput"><code>cd ns_pam-0.1</code></strong>
          [root ns_pam-0.1]# <strong class="userinput"><code>make install INST=/usr/local/aolserver</code></strong>
          [root ns_pam-0.1]#
<span class="action"><span class="action">cd /usr/local/src/aolserver/
wget http://braindamage.alal.com/software/ns_pam-0.1.tar.gz
tar xvfz ns_pam-0.1.tar.gz
cd ns_pam-0.1
make install INST=/usr/local/aolserver
</span></span>
</pre>
</li><li class="listitem">
<a name="configure-ns_pam" id="configure-ns_pam"></a><p>
<strong>Configure ns_pam. </strong>Configure
AOLserver for ns_pam</p><p>To enable ns_pam in AOLServer you will first have to edit your
config.tcl file and enable the loading of the ns_pam module and
configure the aolservers pam configuration file.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Change <span class="emphasis"><em>config.tcl</em></span>. Remove
the <span class="emphasis"><em>#</em></span> in front of
<code class="computeroutput">ns_param nspam
${bindir}/nspam.so</code> to enable the loading of the ns_pam
module.</p></li><li class="listitem"><p>Change <span class="emphasis"><em>config.tcl</em></span>.
Replace <code class="computeroutput">pam_domain</code> in the
section <code class="computeroutput">ns/server/${server}/module/nspam</code> with
<strong class="userinput"><code>aolserver</code></strong>
</p></li><li class="listitem">
<p>Create <span class="emphasis"><em>/etc/pam.d/aolserver</em></span>.</p><pre class="screen">
              [root ns_pam]#<strong class="userinput"><code>cp /var/lib/aolserver/<span class="replaceable"><span class="replaceable">service0</span></span>/packages/acs-core-docs/www/files/pam-aolserver.txt /etc/pam.d/aolserver</code></strong>
</pre>
</li>
</ul></div>
</li><li class="listitem">
<a name="configure-pam-radius" id="configure-pam-radius"></a><p>
<strong>Configure PAM Radius. </strong>Configure and
install PAM Radius</p><p>You have to make sure that pam_radius v.1.3.16 or higher is
installed, otherwise you will have to install it.</p><pre class="screen">
[root ns_pam]# <strong class="userinput"><code>cd /usr/local/src/</code></strong>
          [root src]# <strong class="userinput"><code>wget ftp://ftp.freeradius.org/pub/radius/pam_radius-1.3.16.tar</code></strong>
          [root src]# <strong class="userinput"><code>tar xvf pam_radius-1.3.16</code></strong>
          [root src]# <strong class="userinput"><code>cd pam_radius</code></strong>
          [root pam_radius]# <strong class="userinput"><code>make</code></strong>
          [root pam_radius]# <strong class="userinput"><code>cp pam_radius_auth.so /lib/security/</code></strong>
          [root pam_radius]#
<span class="action"><span class="action">cd /usr/local/src
wget ftp://ftp.freeradius.org/pub/radius/pam_radius-1.3.16.tar
tar xvf pam_radius-1.3.16
cd pam_radius
make
cp pam_radius_auth.so /lib/security/
</span></span>
</pre><p>Next you have to add the configuration lines to your Radius
configuration file (/etc/rddb/server). For AOLserver to be able to
access this information you have to change the access rights to
this file as well.</p><pre class="screen">
[root pam_radius]# <strong class="userinput"><code>echo "radius.<span class="replaceable"><span class="replaceable">yourdomain.com</span></span>:1645 <span class="replaceable"><span class="replaceable">your_radius_password</span></span> &gt;&gt;/etc/rddb/server</code></strong>
          [root src]# <strong class="userinput"><code>chown <span class="replaceable"><span class="replaceable">service0</span></span>:web /etc/rddb/server</code></strong>
</pre>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="install-squirrelmail" leftLabel="Prev" leftTitle="Install Squirrelmail for use as a
webmail system for OpenACS"
		    rightLink="install-ldap-radius" rightLabel="Next" rightTitle="Install LDAP for use as external
authentication"
		    homeLink="index" homeLabel="Home" 
		    upLink="install-more-software" upLabel="Up"> 
		