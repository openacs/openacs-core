
<property name="context">{/doc/acs-core-docs {Documentation}} {Chapter 8. Backup and
Recovery}</property>
<property name="doc(title)">Chapter 8. Backup and
Recovery</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="install-next-nightly-vacuum" leftLabel="Prev"
		    title="
Part II. Administrator's Guide"
		    rightLink="install-next-backups" rightLabel="Next">
		<div class="chapter">
<div class="titlepage"><div><div><h2 class="title">
<a name="backup-recovery" id="backup-recovery"></a>Chapter 8. Backup and
Recovery</h2></div></div></div><div class="toc">
<p><b>Table of Contents</b></p><dl class="toc">
<dt><span class="sect1"><a href="install-next-backups">Backup
Strategy</a></span></dt><dt><span class="sect1"><a href="snapshot-backup">Manual
backup and recovery</a></span></dt><dt><span class="sect1"><a href="automated-backup">Automated
Backup</a></span></dt><dt><span class="sect1"><a href="backups-with-cvs">Using CVS
for backup-recovery</a></span></dt>
</dl>
</div><div class="authorblurb">
<div class="cvstag">($&zwnj;Id: recovery.xml,v 1.17 2010/12/11 23:36:32
ryang Exp $)</div><p>By <a class="ulink" href="mailto:dhogaza\@pacifier.com" target="_top">Don Baccus</a> with additions by <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel Aufrecht</a>
</p><p>We will cover some basic backup and recovery strategies. These
are intended to be robust but simple enough to set up. For a large
scale production site you would probably need to create your own
backup strategies (in particular full dumps from oracle, while easy
to set up, are far from the best solution).</p><p>There are three basic things which need to be backed up, the
database data, the server source tree, and the
acs-content-repository (which is in the server source tree).</p><div class="figure">
<a name="idp140216744771408" id="idp140216744771408"></a><p class="title"><b>Figure 8.1. Backup and
Recovery Strategy</b></p><div class="figure-contents"><div class="mediaobject" align="center"><img src="images/backup.png" align="middle" alt="Backup and Recovery Strategy"></div></div>
</div><p><br class="figure-break"></p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="install-next-nightly-vacuum" leftLabel="Prev" leftTitle="Vacuum Postgres nightly"
		    rightLink="install-next-backups" rightLabel="Next" rightTitle="Backup Strategy"
		    homeLink="index" homeLabel="Home" 
		    upLink="acs-admin" upLabel="Up"> 
		