
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Staged Deployment for Production Networks}</property>
<property name="doc(title)">Staged Deployment for Production Networks</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="high-avail" leftLabel="Prev"
			title="Chapter 6. Production
Environments"
			rightLink="install-ssl" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="maintenance-deploy" id="maintenance-deploy"></a>Staged Deployment for Production
Networks</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red"><span class="cvstag">($&zwnj;Id:
maintenance.xml,v 1.32 2018/03/27 11:18:00 hectorr Exp
$)</span></span></p><p>By <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel Aufrecht</a>
</p>
&lt;/authorblurb&gt;
<p>This section describes two minimal-risk methods for deploying
changes on a production network. The important characteristics of a
safe change deployment include: (THIS SECTION IN DEVELOPMENT)</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Control: You know for sure that the change you are making is the
change that you intend to make and is the change that you
tested.</p></li><li class="listitem"><p>Rollback: If anything goes wrong, you can return to the previous
working configuration safely and quickly.</p></li>
</ul></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140682193078776" id="idp140682193078776"></a>Method 1: Deployment with CVS</h3></div></div></div><p>With this method, we control the files on a site via CVS. This
example uses one developmental server (service0-dev) and one
production server (service0). Depending on your needs, you can also
have a staging server for extensive testing before you go live. The
only way files should move between the server instances is via
cvs.</p><p>To set up a developmental installation, first set up either your
developmental installation or your production installation, and
follow the instructions for committing your files to CVS. We&#39;ll
assume in this example that you set up the production server
(service0). To set up the developmental instance, you then follow
the install guide again, this time creating a new user
(service0-dev) that you&#39;ll use for the new installation. To get
the files for service0-dev, you check them out from cvs (check out
service0).</p><pre class="programlisting">
su - service0-dev
co -d /cvsroot service0
mv service0 /var/lib/aolserver/service0-dev
ln -s /home/service0-dev/web /var/lib/aolserver/service0-dev
emacs web/etc/config.tcl
emacs web/etc/daemontools/run
</pre><p>In the config.tcl file, you&#39;ll probably want to pay
attention the rollout support section. That will ensure that email
on your developmental server will not be sent out to the general
world.</p><p>Also, instead of going through the OpenACS online installer,
you&#39;ll actually load live data into your production server.</p><p>You can even automate the process of getting live data from your
production server. Copy something like this to
/home/service0-dev/bin and put it in service0-dev&#39;s crontab to
run once a night. You&#39;ll need to make sure the database backups
are set up in service0's crontab, and that if the servers are
on different physical machines, that the database backup is copied
to the developmental machine once per night.</p><pre class="programlisting">
/usr/local/bin/svc -d /service/service0-dev
/bin/sleep 60
# this deletes the dev database!
/usr/local/pgsql/bin/dropdb service0-dev
/usr/local/pgsql/bin/createdb -E UNICODE service0-dev
# this is not necessary from Postgres 7.4 on
/usr/local/pgsql/bin/psql -f /var/lib/aolserver/service0-dev/packages/acs-kernel/sql/postgresql/postgresql.sql service0
mv /var/lib/aolserver/service0/database-backup/service0-nightly-backup.dmp.gz /var/lib/aolserver/service0-dev/database-backup/service0-nightly-backup-old.dmp.gz
/bin/gunzip /var/lib/aolserver/service0-dev/database-backup/service0-nightly-backup.dmp.gz
/usr/bin/perl -pi -e "s/^\\connect service0$/\\connect service0-dev/" /var/lib/aolserver/service0-dev/database-backup/service0-nightly-backup.dmp
/usr/local/pgsql/bin/psql service0-dev &lt; /var/lib/aolserver/service0-dev/database-backup/service0-nightly-backup.dmp
/usr/local/bin/svc -u /service/service0-dev
/bin/gzip /var/lib/aolserver/service0-dev/database-backup/service0-nightly-backup-old.dmp
</pre><p>Your developmental server will always have data about a day
old.</p><p>To make changes on service0-dev:</p><pre class="programlisting">
1) change the file on service0-dev as desired
2) test the new file
3) commit the file: 
if the file is /var/lib/aolserver/service0-dev/www/index.adp, do: 

cd /var/lib/aolserver/service0-dev/www
cvs diff index.adp (this is optional; it&#39;s just a
reality check)
the lines starting &gt; will be added and the lines
starting &lt; will be removed, when you commit
if that looks okay, commit with: 
cvs -m "changing text on front page for February conference" index.adp
the stuff in -m "service0" is a comment visible only from within cvs commands
</pre><p>To make these changes take place on service0:</p><pre class="programlisting">
4) update the file on production:
cd /var/lib/aolserver/service0/www
cvs up -Pd index.adp</pre><p>If you make changes that require changes to the database, test
them out first on service0-dev, using either -create.sql or upgrade
scripts. Once you&#39;ve tested them, you then update and run the
upgrade scripts from the package manager.</p><p>The production site can run "HEAD" from cvs.</p><p>The drawback to using HEAD as the live code is that you cannot
commit new work on the development server without erasing the
definition of 'working production code.' So a better method
is to use a tag. This guarantees that, at any time in the future,
you can retrieve exactly the same set of code. This is useful for
both of the characteristics of safe change deployment. For control,
you can use tags to define a body of code, test that code, and then
know that what you are deploying is exactly that code. For
rollback, you can use return to the last working tag if the new tag
(or new, untagged changes) cause problems. .... example of using
tags to follow ...</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140682193079128" id="idp140682193079128"></a>Method 2: A/B Deployment</h3></div></div></div><p>The approach taken in this section is to always create a new
service with the desired changes, running in parallel with the
existing site. This guarantees control, at least at the final step
of the process: you know what changes you are about to make because
you can see them directly. It does not, by itself, guarantee the
entire control chain. You need additional measures to make sure
that the change you are making is exactly and completely the change
you intended to make and tested previously, and nothing more. Those
additional measures typically take the form of source control tags
and system version numbers. The parallel-server approach also
guarantees rollback because the original working service is not
touched; it is merely set aside.</p><p>This approach can has limitations. If the database or file
system regularly receiving new data, you must interrupt this
function or risk losing data in the shuffle. It also requires extra
steps if the database will be affected.</p><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140682193094056" id="idp140682193094056"></a>Simple A/B Deployment: Database is not
changed</h4></div></div></div><div class="figure">
<a name="idp140682193094792" id="idp140682193094792"></a><p class="title"><strong>Figure 6.2. Simple A/B
Deployment - Step 1</strong></p><div class="figure-contents"><div class="mediaobject" align="center"><img src="images/simple-deploy-1.png" align="middle" alt="Simple A/B Deployment - Step 1"></div></div>
</div><br class="figure-break"><div class="figure">
<a name="idp140682193097912" id="idp140682193097912"></a><p class="title"><strong>Figure 6.3. Simple A/B
Deployment - Step 2</strong></p><div class="figure-contents"><div class="mediaobject" align="center"><img src="images/simple-deploy-2.png" align="middle" alt="Simple A/B Deployment - Step 2"></div></div>
</div><br class="figure-break"><div class="figure">
<a name="idp140682193100872" id="idp140682193100872"></a><p class="title"><strong>Figure 6.4. Simple A/B
Deployment - Step 3</strong></p><div class="figure-contents"><div class="mediaobject" align="center"><img src="images/simple-deploy-3.png" align="middle" alt="Simple A/B Deployment - Step 3"></div></div>
</div><br class="figure-break">
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140682193103864" id="idp140682193103864"></a>Complex A/B Deployment: Database is
changed</h4></div></div></div><div class="figure">
<a name="idp140682193104504" id="idp140682193104504"></a><p class="title"><strong>Figure 6.5. Complex A/B
Deployment - Step 1</strong></p><div class="figure-contents"><div class="mediaobject" align="center"><img src="images/complex-deploy-1.png" align="middle" alt="Complex A/B Deployment - Step 1"></div></div>
</div><br class="figure-break"><div class="figure">
<a name="idp140682193107560" id="idp140682193107560"></a><p class="title"><strong>Figure 6.6. Complex A/B
Deployment - Step 2</strong></p><div class="figure-contents"><div class="mediaobject" align="center"><img src="images/complex-deploy-2.png" align="middle" alt="Complex A/B Deployment - Step 2"></div></div>
</div><br class="figure-break"><div class="figure">
<a name="idp140682193110440" id="idp140682193110440"></a><p class="title"><strong>Figure 6.7. Complex A/B
Deployment - Step 3</strong></p><div class="figure-contents"><div class="mediaobject" align="center"><img src="images/complex-deploy-3.png" align="middle" alt="Complex A/B Deployment - Step 3"></div></div>
</div><br class="figure-break">
</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="high-avail" leftLabel="Prev" leftTitle="High Availability/High Performance
Configurations"
			rightLink="install-ssl" rightLabel="Next" rightTitle="Installing SSL Support for an OpenACS
service"
			homeLink="index" homeLabel="Home" 
			upLink="maintenance-web" upLabel="Up"> 
		    