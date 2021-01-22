
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install PHP for use in AOLserver}</property>
<property name="doc(title)">Install PHP for use in AOLserver</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="install-tclwebtest" leftLabel="Prev"
		    title="
Appendix B. Install additional supporting
software"
		    rightLink="install-squirrelmail" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-php" id="install-php"></a>Install PHP for use in AOLserver</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="mailto:openacs\@sussdorff.de" target="_top">Malte Sussdorff</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>To be able to use PHP software with AOLserver (and OpenACS), you
have to install PHP with AOLserver support. Get the latest version
from <a class="ulink" href="http://www.php.net" target="_top">www.php.net</a>. For convenience we get version 4.3.4 from a
mirror</p><pre class="screen">
[root root]# <strong class="userinput"><code>cd /usr/local/src</code></strong>
[root src]# <strong class="userinput"><code>wget http://de3.php.net/distributions/php-4.3.4.tar.gz</code></strong>
[root src]# <strong class="userinput"><code>tar xfz php-4.3.4.tar.gz</code></strong>
[root src]# <strong class="userinput"><code>cd php-4.3.4</code></strong>
[root php-4.3.4]# <strong class="userinput"><code>cd php-4.3.4</code></strong>
[root php-4.3.4]# <strong class="userinput"><code> ./configure --with-aolserver=/usr/local/aolserver/ --with-pgsql=/usr/local/pgsql --without-mysql</code></strong>
[root php-4.3.4]# <strong class="userinput"><code>make install</code></strong>
</pre><p>Once installed you can enable this by configuring your config
file. Make sure your config file supports php (it should have a php
section with it). Furthermore add <strong class="userinput"><code>index.php</code></strong> as the last element to
your <code class="computeroutput">directoryfile</code>
directive.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="install-tclwebtest" leftLabel="Prev" leftTitle="Install tclwebtest."
		    rightLink="install-squirrelmail" rightLabel="Next" rightTitle="Install Squirrelmail for use as a
webmail system for OpenACS"
		    homeLink="index" homeLabel="Home" 
		    upLink="install-more-software" upLabel="Up"> 
		