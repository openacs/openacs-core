
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install tclwebtest.}</property>
<property name="doc(title)">Install tclwebtest.</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="install-nsopenssl" leftLabel="Prev"
			title="Appendix B. Install
additional supporting software"
			rightLink="install-php" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-tclwebtest" id="install-tclwebtest"></a>Install tclwebtest.</h2></div></div></div><p>Download the <a class="link" href="individual-programs">tclwebtest source</a>,
unpack it, and put it an appropriate place. (tclwebtest 1.0 will be
required for auto-tests in OpenACS 5.1. When it exists, the cvs
command here will be replaced with
http://prdownloads.sourceforge.net/tclwebtest/tclwebtest-0.3.tar.gz?download.)
As root:</p><pre class="screen"><span class="action">cd /tmp
cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/tclwebtest co tclwebtest
#wget http://umn.dl.sourceforge.net/sourceforge/tclwebtest/tclwebtest-1.0.tar.gz
#tar xvzf tclwebtest-1-0.tar.gz
mv tclwebtest-0.3 /usr/local/
ln -s /usr/local/tclwebtest-0.3 /usr/local/tclwebtest
ln -s /usr/local/tclwebtest/tclwebtest /usr/local/bin
</span></pre>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="install-nsopenssl" leftLabel="Prev" leftTitle="Install nsopenssl"
			rightLink="install-php" rightLabel="Next" rightTitle="Install PHP for use in AOLserver"
			homeLink="index" homeLabel="Home" 
			upLink="install-more-software" upLabel="Up"> 
		    