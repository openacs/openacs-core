
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install Oracle 8.1.7}</property>
<property name="doc(title)">Install Oracle 8.1.7</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="unix-installation" leftLabel="Prev"
		    title="
Chapter 3. Complete Installation"
		    rightLink="postgres" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="oracle" id="oracle"></a>Install Oracle 8.1.7</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="mailto:vinod\@kurup.com" target="_top">Vinod Kurup</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>If you are installing PostGreSQL instead of Oracle, skip this
section.</p><p>OpenACS 5.9.0 will install with Oracle 9i but has not been
extensively tested so may still have bugs or tuning issues. See
<a class="ulink" href="http://www.piskorski.com/docs/oracle.html" target="_top">Andrew Piskorski&#39;s Oracle 9i notes</a> for
guidance.</p><p>This installation guide attempts to present all of the
information necessary to complete an OpenACS installation. We try
hard to make all of the steps possible in one pass, rather than
having a step which amounts to "go away and develop a profound
understanding of software X and then come back and, in 99% of all
cases, type these two lines." The exception to our rule is
Oracle production systems. This page describes a set of steps to
get a working Oracle development server, but it is <span class="strong"><strong>unsuitable for production systems</strong></span>.
If you will be using OpenACS on Oracle in a production environment,
you will experience many problems unless you develop a basic
understanding of Oracle which is outside the scope of this
document. T</p><p>This document assumes that you&#39;ll be installing Oracle on
the same box as AOLserver. For more details on a remote Oracle
installation, see Daryl Biberdorf&#39;s <a class="ulink" href="http://openacs.org/new-file-storage/one-file?file_id=273" target="_top">document</a>.</p><p>Useful links to find help on how to set up Oracle under Linux
are:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="ulink" href="https://www.dizwell.com/wordpress/technical-articles/oracle/" target="_top">Dizwell - on Oracle on Linux</a></p></li><li class="listitem"><p><a class="ulink" href="http://puschitz.com/" target="_top">Werner Puschitz - Oracle on Red Hat Linux</a></p></li><li class="listitem"><p><a class="ulink" href="http://www.suse.com/us/business/certifications/certified_software/oracle/" target="_top">SuSE/Oracle Support matrix</a></p></li>
</ul></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-oracle-getit" id="install-oracle-getit"></a>Acquire Oracle</h3></div></div></div><p>Production Oracle systems should run on certified platforms.
Follow the <a class="ulink" href="http://metalink.oracle.com/metalink/plsql/ml2_documents.showDocument?p_database_id=NOT&amp;p_id=223718.1" target="_top">metalink note 223718.1</a>to find certified
platforms. If you don&#39;t have metalink access, take a look at
the Oracle on Linux FAQ: <a class="ulink" href="http://www.orafaq.com/wiki/Linux_FAQ" target="_top">Which Linux
Distributions Are Directly Supported By Oracle?</a>. In summary,
free and inexpensive Linux distributions are not certified.</p><p>You can download the Oracle software from the <a class="ulink" href="https://www.oracle.com/downloads/index.html" target="_top">Oracle Downloads</a> page.</p><p>Each Oracle release comes with extensive and usually quite
well-written documentation. Your first step should be to thoroughly
read the release notes for your operating system and your Oracle
version. Find the docs here:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="ulink" href="http://www.oracle.com/technetwork/documentation/oracle8i-085806.html" target="_top">Oracle 8i Release Documentation</a></p></li><li class="listitem"><p><a class="ulink" href="https://docs.oracle.com/cd/B10501_01/server.920/a96531/ch4_doc.htm" target="_top">Oracle 9i Release Documentation</a></p></li><li class="listitem"><p><a class="ulink" href="https://docs.oracle.com/cd/B19306_01/server.102/b14214/chapter2.htm#g62359" target="_top">Oracle 10g Release Documentation</a></p></li>
</ul></div><p>It is generally useful to run a particular Oracle version with
its latest patchset. At the time of writing these were 8.1.7.4 and
9.2.0.5, both of which are considered to be very stable.</p><p>To be able to download a patchset, you need a (to-pay-for)
account on <a class="ulink" href="http://metalink.oracle.com" target="_top">Metalink</a>. You may find the appropriate patchset
by following <a class="ulink" href="http://openacs.org/forums/message-view?message_id=33004" target="_top">Andrew&#39;s suggestion</a>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-oracle-keepinmind" id="install-oracle-keepinmind"></a>Things to Keep in Mind</h3></div></div></div><p>Oracle is very well-documented software, the <a class="ulink" href="http://tahiti.oracle.com" target="_top">online
documentation</a> comes with printable PDFs and full-text search.
Altogether there is more than 20.000 pages of documentation, so do
not expect to understand Oracle within in a few hours. The best
starting pointing into Oracle is the Concepts book. Here&#39;s the
<a class="ulink" href="http://otn.oracle.com/pls/tahiti/tahiti.to_toc?pathname=server.817%2Fa76965%2Ftoc.htm&amp;remark=docindex" target="_top">8i version</a> and the <a class="ulink" href="http://otn.oracle.com/pls/db92/db92.to_toc?pathname=server.920%2Fa96524%2Ftoc.htm&amp;remark=docindex" target="_top">9.2 version</a>.</p><p>To give you an idea of how configurable Oracle is and how much
thought you may need to put into buying the proper hardware and
creating a sane setup, you should thoroughly read Cary
Millsap&#39;s <a class="ulink" href="http://www.miracleas.dk/BAARF/0.Millsap1996.08.21-VLDB.pdf" target="_top">Configuring Oracle Server for VLDB</a> and the
<a class="ulink" href="https://en.wikipedia.org/wiki/Optimal_Flexible_Architecture" target="_top">Optimal Flexible Architecture</a> standard.</p><p>Throughout these instructions, we will refer to a number of
configurable settings and advise certain defaults. With the
exception of passwords, we advise you to follow these defaults
unless you know what you are doing. Subsequent documents will
expect that you used the defaults, so a change made here will
necessitate further changes later. For a guide to the defaults,
please see <a class="xref" href="oracle" title="Defaults">the section
called &ldquo;Defaults&rdquo;</a>.</p><p>In order for OpenACS to work properly you need to set the
environment appropriately.</p><pre class="programlisting">
export ORACLE_BASE=/ora8/m01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/8.1.7
export PATH=$PATH:$ORACLE_HOME/bin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export ORACLE_SID=ora8
export ORACLE_TERM=vt100
export ORA_NLS33=$ORACLE_HOME/ocommon/nls/admin/data

umask 022
</pre><pre class="programlisting">
open_cursors = 500
</pre><pre class="programlisting">
nls_date_format = "YYYY-MM-DD"
</pre><p>For additional resources/documentation, please see this
<a class="ulink" href="http://openacs.org/forums/message-view?message_id=28829" target="_top">thread</a> and <a class="ulink" href="http://openacs.org/forums/message-view?message_id=67108" target="_top">Andrew Piskorski&#39;s mini-guide</a>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-oracle-preinstall" id="install-oracle-preinstall"></a>Pre-Installation Tasks</h3></div></div></div><p>Though Oracle 8.1.7 has an automated installer, we still need to
perform several manual, administrative tasks before we can launch
it. You must perform all of these steps as the <code class="computeroutput">root</code> user. We recommend entering the X
window system as a normal user and then doing a <code class="computeroutput">su -</code>. This command gives you full root
access.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Login as a non-root user and start X by typing <code class="computeroutput">startx</code>
</p><pre class="programlisting">
[joeuser ~]$ startx
</pre>
</li><li class="listitem">
<p>Open a terminal window type and login as root</p><pre class="programlisting">
[joeuser ~]$ su -
Password: ***********
[root ~]#
</pre>
</li><li class="listitem">
<p>Create and setup the <code class="computeroutput">oracle</code>
group and <code class="computeroutput">oracle</code> account</p><p>We need to create a user <code class="computeroutput">oracle</code>, which is used to install the
product, as well as starting and stopping the database.</p><pre class="programlisting">
[root ~]# groupadd dba
[root ~]# groupadd oinstall
[root ~]# groupadd oracle
[root ~]# useradd -g dba -G oinstall,oracle -m oracle
[root ~]# passwd oracle
</pre><p>You will be prompted for the New Password and Confirmation of
that password.</p>
</li><li class="listitem">
<p>Setup the installation location for Oracle. While Oracle can
reside in a variety of places in the file system, OpenACS has
adopted <code class="computeroutput">/ora8</code> as the base
directory.</p><p>
<span class="strong"><strong>Note:</strong></span> the Oracle
install needs about 1 GB free on <code class="computeroutput">/ora8</code> to install successfully.</p><pre class="programlisting">
[root ~]# mkdir /ora8
root:/ora8# cd /ora8
root:/ora8# mkdir -p m01 m02 m03/oradata/ora8
root:/ora8# chown -R oracle.dba /ora8
root:/ora8# exit
</pre>
</li><li class="listitem">
<p>Set up the <code class="computeroutput">oracle</code> user&#39;s
environment</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>Log in as the user <code class="computeroutput">oracle</code> by
typing the following:</p><pre class="programlisting">
[joeuser ~]$ su - oracle
Password: ********
</pre>
</li><li class="listitem">
<p>Use a text editor to edit the <code class="computeroutput">.bash_profile</code> file in the <code class="computeroutput">oracle</code> account home directory.</p><pre class="programlisting">
[oracle ~]$ emacs .bash_profile
</pre><p>You may get this error trying to start emacs:</p><pre class="programlisting">
Xlib: connection to ":0.0" refused by server
Xlib: Client is not authorized to connect to Server
emacs: Cannot connect to X server :0.
Check the DISPLAY environment variable or use `-d'.
Also use the `xhost' program to verify that it is set to permit
connections from your machine.
</pre><p>If so, open a new terminal window and do the following:</p><pre class="programlisting">
[joeuser ~]$ xhost +localhost
</pre><p>Now, back in the oracle terminal:</p><pre class="programlisting">
[oracle ~]$ export DISPLAY=localhost:0.0
[oracle ~]$ emacs .bash_profile
</pre><p>Try this procedure anytime you get an Xlib connection refused
error.</p>
</li><li class="listitem">
<p>Add the following lines (substituting your Oracle version number
as needed) to <code class="computeroutput">.bash_profile</code>:</p><pre class="programlisting">
export ORACLE_BASE=/ora8/m01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/8.1.7
export PATH=$PATH:$ORACLE_HOME/bin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export ORACLE_SID=ora8
export ORACLE_TERM=vt100
export ORA_NLS33=$ORACLE_HOME/ocommon/nls/admin/data

umask 022
</pre><p>Save the file by typing <code class="computeroutput">CTRL-X
CTRL-S</code> and then exit by typing <code class="computeroutput">CTRL-X CTRL-C</code>. Alternatively, use the
menus.</p>
</li>
</ul></div><p>Make sure that you do <span class="strong"><strong>not</strong></span> add any lines like the
following</p><pre class="programlisting">
# NLS_LANG=american
# export NLS_LANG
</pre><p>These lines will change the Oracle date settings and will break
OpenACS since OpenACS depends on the ANSI date format, YYYY-MM-DD
dates.</p>
</li><li class="listitem">
<p>Log out as oracle</p><pre class="programlisting">
[oracle ~]$ exit
</pre>
</li><li class="listitem">
<p>Log back in as <code class="computeroutput">oracle</code> and
double check that your environment variables are as intended. The
<code class="computeroutput">env</code> command lists all of the
variables that are set in your environment, and <code class="computeroutput">grep</code> shows you just the lines you want
(those with ORA in it).</p><pre class="programlisting">
[joeuser ~]$ su - oracle
[oracle ~]$ env | grep ORA
</pre><p>If it worked, you should see:</p><pre class="programlisting">
ORACLE_SID=ora8
ORACLE_BASE=/ora8/m01/app/oracle
ORACLE_TERM=vt100
ORACLE_HOME=/ora8/m01/app/oracle/product/8.1.7
ORA_NLS33=/ora8/m01/app/oracle/product/8.1.7/ocommon/nls/admin/data
</pre><p>If not, try adding the files to <code class="computeroutput">~/.bashrc</code> instead of <code class="computeroutput">.bash_profile</code>. Then logout and log back in
again. Also, be certain you are doing <code class="computeroutput">su - oracle</code> and not just <code class="computeroutput">su oracle</code>. The <code class="computeroutput">-</code> means that <code class="computeroutput">.bashrc</code> and <code class="computeroutput">.bash_profile</code> will be evaluated.</p><p>Make sure that <code class="computeroutput">/bin</code>,
<code class="computeroutput">/usr/bin</code>, and <code class="computeroutput">/usr/local/bin</code> are in your path by
typing:</p><pre class="programlisting">
[oracle ~]$ echo $PATH
/bin:/usr/bin:/usr/local/bin:/usr/bin/X11:/usr/X11R6/bin:/home/oracle/bin:/ora8/m01/app/oracle/product/8.1.7/bin
</pre><p>If they are not, then add them to the <code class="computeroutput">.bash_profile</code> by changing the PATH
statement above to <code class="computeroutput">PATH=$PATH:/usr/local/bin:$ORACLE_HOME/bin</code>
</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-oracle-install" id="install-oracle-install"></a>Installing Oracle 8.1.7 Server</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Log in as <code class="computeroutput">oracle</code> and start X
if not already running. Start a new terminal:</p><pre class="programlisting">
[joeuser ~]$ xhost +localhost
[joeuser ~]$ su - oracle
Password: **********
[oracle ~]$ export DISPLAY=localhost:0.0
</pre>
</li><li class="listitem">
<p>Find the <code class="computeroutput">runInstaller</code>
script</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>If you are installing Oracle from a CD-ROM, it is located in the
<code class="computeroutput">install/linux</code> path from the
cd-rom mount point</p><pre class="programlisting">
[oracle ~]$ su - root
[root ~]# mount -t iso9660 /dev/cdrom /mnt/cdrom
[root ~]# exit
[oracle ~]$ cd /mnt/cdrom
</pre>
</li><li class="listitem">
<p>If you are installing from the tarball, the install script is
located in the <code class="computeroutput">Oracle8iR2</code>
directory that was created when you expanded the archive.</p><pre class="programlisting">
[oracle ~]$ cd /where/oracle/Disk1
</pre>
</li>
</ul></div><p>Check to make sure the file is there.</p><pre class="programlisting">
oracle:/where/oracle/Disk1$ ls
doc  index.htm  install  runInstaller  stage  starterdb
</pre><p>If you don&#39;t see <code class="computeroutput">runInstaller</code>, you are in the wrong
directory.</p>
</li><li class="listitem">
<p>Run the installer</p><pre class="programlisting">
oracle:/where/oracle/Disk1$ ./runInstaller
</pre><p>A window will open that welcomes you to the 'Oracle
Universal Installer' (OUI). Click on "<code class="computeroutput">Next</code>"</p><div class="note" style="margin-left: 0.5in; margin-right: 0.5in;">
<h3 class="title">Note</h3><p>Some people have had trouble with this step on RedHat 7.3 and
8.0. If so, try the following steps before calling <span class="command"><strong>./runInstaller</strong></span>:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Execute the following command: <span class="command"><strong>/usr/i386-glibc21-linux/bin/i386-glibc21-linux-env.sh</strong></span>
</p></li><li class="listitem"><p>Type <span class="command"><strong>export
LD_ASSUME_KERNEL=2.2.5</strong></span>
</p></li>
</ol></div>
</div>
</li><li class="listitem">
<p>The "File Locations" screen in the OUI:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>"Source" path should have been prefilled with
"(wherever you mounted the CDROM)<code class="computeroutput">/stage/products.jar</code>"</p></li><li class="listitem">
<p>"destination" path says "<code class="computeroutput">/ora8/m01/app/oracle/product/8.1.7</code>"</p><p>If the destination is not correct it is because your environment
variables are not set properly. Make sure you logged on as
<code class="computeroutput">oracle</code> using <code class="computeroutput">su - oracle</code>. If so, edit the <code class="computeroutput">~/.bash_profile</code> as you did in <a class="xref" href="oracle" title="Pre-Installation Tasks">the section called
&ldquo;Pre-Installation Tasks&rdquo;</a>
</p>
</li><li class="listitem"><p>Click "Next" (a pop up window will display Loading
Product information).</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Unix Group Name" screen in the OUI:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>The Unix Group name needs to be set to '<code class="computeroutput">oinstall</code>' ( we made this Unix group
earlier ).</p></li><li class="listitem"><p>Click "Next"</p></li><li class="listitem"><p>A popup window appears instantly, requesting you to run a script
as root:</p></li><li class="listitem"><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;"><li class="listitem">
<p>Debian users need to link <code class="computeroutput">/bin/awk</code> to <code class="computeroutput">/usr/bin/awk</code> before running the script
below</p><pre class="programlisting">
[joueser ~]$ su -
[root ~]# ln -s /usr/bin/awk /bin/awk
</pre>
</li></ul></div></li><li class="listitem">
<p>Open a new terminal window, then type:</p><pre class="programlisting">
[joeuser ~]$ su -
[root ~]# cd /ora8/m01/app/oracle/product/8.1.7
[root ~]# ./orainstRoot.sh  
; You should see:
Creating Oracle Inventory pointer file (/etc/oraInst.loc)
Changing groupname of /ora8/m01/app/oracle/oraInventory to oinstall.
[root ~]# mkdir -p /usr/local/java
[root ~]# exit
[joeuser ~]$ exit
</pre>
</li><li class="listitem"><p>Click "Retry"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Available Products" screen in the OUI:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Select "Oracle 8i Enterprise Edition 8.1.7.1.0"</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Installation Types" screen</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Select the "Custom" installation type.</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Available Product Components" screen</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>In addition to the defaults, make sure that "Oracle SQLJ
8.1.7.0," "Oracle Protocol Support 8.1.7.0.0," and
"Linux Documentation 8.1.7.0.0" are also checked.</p></li><li class="listitem"><p>Click "Next"</p></li><li class="listitem"><p>A progress bar will appear for about 1 minute.</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Component Locations" screen in the OUI</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Click on the "Java Runtime Environment 1.1.8" It
should have the path "<code class="computeroutput">/ora8/m01/app/oracle/jre/1.1.8</code>"</p></li><li class="listitem"><p>Click "Next"</p></li><li class="listitem"><p>A progress bar will appear for about 1 minute.</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Privileged Operation System Groups" screen in the
OUI</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Enter "dba" for "Database Administrator (OSDBA)
Group"</p></li><li class="listitem"><p>Enter "dba" for the "Database Operator (OSOPER)
Group"</p></li><li class="listitem"><p>Click "Next"</p></li><li class="listitem"><p>A progress bar will appear for about 1 minute.</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Authentication Methods" screen</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem"><p>Click "Next"</p></li></ul></div>
</li><li class="listitem">
<p>The next screen is "Choose JDK home directory"</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Keep the default path: <code class="computeroutput">/usr/local/java</code>
</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Create a Database" screen in the OUI</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Select "No" as we will do this later, after some
important configuration changes.</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The next screen is "Oracle Product Support"</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>TCP should be checked with "Status" listed as
Required</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Summary" screen in the OUI</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Check the "Space Requirements" section to verify you
have enough disk space for the install.</p></li><li class="listitem"><p>Check that "(144 products)" is in the "New
Installations" section title.</p></li><li class="listitem"><p>Click "Install"</p></li><li class="listitem"><p>A progress bar will appear for about 20 - 30 minutes. Now is a
good time to take a break.</p></li><li class="listitem"><p>A "Setup Privileges" window will popup towards the end
of the installation asking you to run a script as <code class="computeroutput">root</code>
</p></li><li class="listitem">
<p>Run the script. Switch to the oracle user first to set the
environment appropriately and then do <span class="command"><strong>su</strong></span> to get root privileges, while
keeping the oracle user&#39;s environment.</p><pre class="programlisting">
[joeuser ~]$ su - oracle
Password: *********
[oracle ~]$ su
Password: *********
[root ~]# /ora8/m01/app/oracle/product/8.1.7/root.sh
; You should see the following.   

Creating Oracle Inventory pointer file (/etc/oraInst.loc)
Changing groupname of /ora8/m01/app/oracle/oraInventory to oinstall.
# /ora8/m01/app/oracle/product/8.1.7/root.sh
Running Oracle8 root.sh script...
The following environment variables are set as:
    ORACLE_OWNER= oracle
    ORACLE_HOME=  /ora8/m01/app/oracle/product/8.1.7
    ORACLE_SID=   ora8

Enter the full pathname of the local bin directory: [/usr/local/bin]: 

<code class="computeroutput">Press ENTER here to accept default of /usr/local/bin</code>
      

Creating /etc/oratab file...
Entry will be added to the /etc/oratab file by
Database Configuration Assistants when a database is created
Finished running generic part of root.sh script.
Now product-specific root actions will be performed.
IMPORTANT NOTE: Please delete any log and trace files previously
                created by the Oracle Enterprise Manager Intelligent
                Agent. These files may be found in the directories
                you use for storing other Net8 log and trace files.
                If such files exist, the OEM IA may not restart.
</pre>
</li><li class="listitem"><p>Do not follow the instructions on deleting trace and log files,
it is not necessary.</p></li>
</ul></div><pre class="programlisting">
[root ~]# exit
[joeuser ~]$ exit
</pre>
</li><li class="listitem"><p>Go back to the pop-up window and click "OK"</p></li><li class="listitem">
<p>The "Configuration Tools" screen in the OUI</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem"><p>This window displays the config tools that will automatically be
launched.</p></li></ul></div>
</li><li class="listitem">
<p>The "Welcome" screen in the "net 8 Configuration
Assistant"</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Make sure the "Perform Typical installation" is
<span class="strong"><strong>not</strong></span> selected.</p></li><li class="listitem"><p>Click "Next"</p></li><li class="listitem"><p>The "Directory Service Access" screen in the "Net
8 Configuration Assistant"</p></li><li class="listitem"><p>Select "No"</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Listener Configuration, Listener Name" screen in
the "Net 8 Configuration Assistant"</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Accept the default listener name of "LISTENER"</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Listener Configuration, Select Protocols" screen
in the "Net 8 Configuration Assistant"</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>The only choice in "Select protocols:" should be
"TCP/IP"</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Listener Configuration TCP/IP Protocol" screen in
the "Net 8 Configuration Assistant"</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Default Port should be 1521 and selected.</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Listener Configuration, More Listeners" screen in
the "Net 8 Configuration Assistant"</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Select "No"</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Listener Configuration Done" screen in the
"Net 8 Configuration Assistant"</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem"><p>Click "Next"</p></li></ul></div>
</li><li class="listitem">
<p>The "Naming Methods Configuration" screen in the
"Net 8 Configuration Assistant"</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Select "No"</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Done" screen in the "Net 8 Configuration
Assistant"</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem"><p>Click "Finish"</p></li></ul></div>
</li><li class="listitem">
<p>The "End of Installation" screen in the OUI</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Click "Exit"</p></li><li class="listitem"><p>Click "Yes" on the confirmation pop up window.</p></li><li class="listitem"><p>The Oracle Universal Installer window should have
disappeared!</p></li>
</ul></div>
</li>
</ul></div><p>Congratulations, you have just installed Oracle 8.1.7 Server!
However, you still need to create a database which can take about
an hour of non-interactive time, so don&#39;t quit yet.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-oracle-create" id="install-oracle-create"></a>Creating the First Database</h3></div></div></div><p>This step will take you through the steps of creating a
customized database. Be warned that this process takes about an
hour on a Pentium II with 128 MB of RAM.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Make sure you are running X. Open up a terminal and <code class="computeroutput">su</code> to oracle and then run the <code class="computeroutput">dbassist</code> program.</p><pre class="programlisting">
[joeuser ~]$ xhost +localhost
[joeuser ~]$ su - oracle
Password: *********
[oracle ~]$ export DISPLAY=localhost:0.0
[oracle ~]$ dbassist
</pre>
</li><li class="listitem">
<p>The "Welcome" screen in the Oracle Database
Configuration Agent (ODCA)</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Select "Create a database"</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Select database type" screen in the ODCA</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Select "Custom"</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "Primary Database Type" window in ODCA</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Select "Multipurpose"</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem">
<p>The "concurrent users" screen of the ODCA</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Select "60" concurrent users.</p></li><li class="listitem"><p>Click "Next"</p></li>
</ul></div>
</li><li class="listitem"><p>Select "<code class="computeroutput">Dedicated Server
Mode</code>", click "<code class="computeroutput">Next</code>"</p></li><li class="listitem"><p>Accept all of the options, and click <code class="computeroutput">Next</code> Oracle Visual Information Retrieval
may be grayed out. If so, you can ignore it; just make sure that
everything else is checked.</p></li><li class="listitem"><p>For "Global Database Name", enter "<code class="computeroutput">ora8</code>"; for "SID", also enter
"<code class="computeroutput">ora8</code>" (it should do
this automatically). Click <code class="computeroutput">"Change Character Set</code> and select
<code class="computeroutput">UTF8</code>. Click "<code class="computeroutput">Next</code>".</p></li><li class="listitem"><p>Accept the defaults for the next screen (control file location).
Click "<code class="computeroutput">Next</code>"</p></li><li class="listitem"><p>Go to the "temporary" and "rollback" tabs,
and change the Size (upper-right text box) to <code class="computeroutput">150</code>MB. Click "<code class="computeroutput">Next</code>"</p></li><li class="listitem"><p>Increase the redo log sizes to <code class="computeroutput">10000K</code> each. Click "<code class="computeroutput">Next</code>"</p></li><li class="listitem"><p>Use the default checkpoint interval &amp; timeout. Click
"<code class="computeroutput">Next</code>"</p></li><li class="listitem"><p>Increase "<code class="computeroutput">Processes</code>" to <code class="computeroutput">100</code>; "<code class="computeroutput">Block Size</code>" to <code class="computeroutput">4096</code> (better for small Linux boxes; use
8192 for a big Solaris machine).</p></li><li class="listitem"><p>Accept the defaults for the Trace File Directory. Click
"<code class="computeroutput">Next</code>"</p></li><li class="listitem"><p>Finally, select "<code class="computeroutput">Save
information to a shell script</code>" and click
"<code class="computeroutput">Finish</code>" (We&#39;re
going to examine the contents of this file before creating our
database.)</p></li><li class="listitem"><p>Click the "<code class="computeroutput">Save</code>"
button. Oracle will automatically save it to the correct directory
and with the correct file name. This will likely be <code class="computeroutput">/ora8/m01/app/oracle/product/8.1.7/assistants/dbca/jlib/sqlora8.sh</code>
</p></li><li class="listitem"><p>It will alert you that the script has been saved
successfully.</p></li><li class="listitem">
<p>Now we need to customize the database configuration a bit. While
still logged on as <code class="computeroutput">oracle</code>, edit
the database initialization script (run when the db loads). The
scripts are kept in <code class="computeroutput">$ORACLE_HOME/dbs</code> and the name of the script
is usually <code class="computeroutput">init</code><span class="emphasis"><em>SID</em></span><code class="computeroutput">.ora</code> where <span class="emphasis"><em>SID</em></span> is the SID of your database.
Assuming your <code class="computeroutput">$ORACLE_HOME</code>
matches our default of <code class="computeroutput">/ora8/m01/app/oracle/product/8.1.7</code>, the
following will open the file for editing.</p><pre class="programlisting">
[oracle ~]$ emacs /ora8/m01/app/oracle/product/8.1.7/dbs/initora8.ora
</pre>
</li><li class="listitem">
<p>Add the following line to the end:</p><pre class="programlisting">
nls_date_format = "YYYY-MM-DD"
</pre>
</li><li class="listitem">
<p>Now find the <code class="computeroutput">open_cursors</code>
line in the file. If you&#39;re using <code class="computeroutput">emacs</code> scroll up to the top of the buffer
and do <code class="computeroutput">CTRL-S</code> and type
<code class="computeroutput">open_cursors</code> to find the line.
The default is <code class="computeroutput">100</code>. Change it
to <code class="computeroutput">500</code>.</p><pre class="programlisting">
open_cursors = 500
</pre>
</li><li class="listitem"><p>Save the file. In emacs, do <code class="computeroutput">CTRL-X
CTRL-S</code> to save followed by <code class="computeroutput">CTRL-X CTRL-C</code> to exit or use the menu.</p></li><li class="listitem"><p>At this point, you are ready to initiate database creation. We
recommend shutting down X to free up some RAM unless you have 256
MB of RAM or more. You can do this quickly by doing a <code class="computeroutput">CRTL-ALT-BACKSPACE</code>, but make sure you have
saved any files you were editing. You should now be returned to a
text shell prompt. If you get sent to a graphical login screen
instead, switch to a virtual console by doing <code class="computeroutput">CRTL-ALT-F1</code>. Then login as <code class="computeroutput">oracle</code>.</p></li><li class="listitem">
<p>Change to the directory where the database creation script is
and run it:</p><pre class="programlisting">
[oracle ~]$ cd /ora8/m01/app/oracle/product/8.1.7/assistants/dbca/jlib
oracle:/ora8/m01/app/oracle/product/8.1.7/assistants/dbca/jlib$ ./sqlora8.sh
</pre><p>In some instances, Oracle will save the file to <code class="computeroutput">/ora8/m01/app/oracle/product/8.1.7/assistants/dbca</code>
Try running the script there if your first attempt does not
succeed.</p>
</li><li class="listitem">
<p>Your database will now be built. It will take &gt; 1 hour - no
fooling. You will see lots of errors scroll by (like:
"ORA-01432: public synonym to be dropped does not exist")
Fear not, this is normal.</p><p>Eventually, you&#39;ll be returned to your shell prompt. In the
meantime, relax, you&#39;ve earned it.</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="istall-oracle-test" id="istall-oracle-test"></a>Acceptance Test</h3></div></div></div><p>For this step, open up a terminal and <code class="computeroutput">su</code> to <code class="computeroutput">oracle</code> as usual. You should be running X
and Netscape (or other web browser) for this phase.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>You need to download the "Oracle Acceptance Test"
file. It&#39;s available <a class="ulink" href="files/acceptance-sql.txt" target="_top">here</a> and at <a class="ulink" href="http://philip.greenspun.com/wtr/oracle/acceptance-sql.txt" target="_top">http://philip.greenspun.com/wtr/oracle/acceptance-sql.txt</a>.
Save the file to <code class="computeroutput">/var/tmp</code>
</p></li><li class="listitem">
<p>In the oracle shell, copy the file.</p><pre class="programlisting">
[oracle ~]$ cp /var/tmp/acceptance-sql.txt /var/tmp/acceptance.sql
</pre>
</li><li class="listitem">
<p>Once you&#39;ve got the acceptance test file all set, stay in
your term and type the following:</p><pre class="programlisting">
[oracle ~]$ sqlplus system/manager
</pre><p>SQL*Plus should startup. If you get an <code class="computeroutput">ORA-01034: Oracle not Available</code> error, it
is because your Oracle instance is not running. You can manually
start it as the <code class="computeroutput">oracle</code>
user.</p><pre class="programlisting">
[oracle ~]$ svrmgrl
SVRMGR&gt; connect internal
SVRMGR&gt; startup
</pre>
</li><li class="listitem">
<p>Now that you&#39;re into SQL*Plus, change the default passwords
for system, sys, and ctxsys to "alexisahunk" (or to
something you&#39;ll remember):</p><pre class="programlisting">
SQL&gt; alter user system identified by alexisahunk;
SQL&gt; alter user sys identified by alexisahunk;
SQL&gt; alter user ctxsys identified by alexisahunk;
</pre>
</li><li class="listitem">
<p>Verify that your date settings are correct.</p><pre class="programlisting">
SQL&gt; select sysdate from dual;
</pre><p>If you don&#39;t see a date that fits the format <code class="computeroutput">YYYY-MM-DD</code>, please read <a class="xref" href="oracle" title="Troubleshooting Oracle Dates">the section called
&ldquo;Troubleshooting Oracle
Dates&rdquo;</a>.</p>
</li><li class="listitem">
<p>At this point we are going to hammer your database with an
intense acceptance test. This usually takes around 30 minutes.</p><pre class="programlisting">
SQL&gt; \@ /var/tmp/acceptance.sql

; A bunch of lines will scroll by.  You&#39;ll know if the test worked if
; you see this at the end:

SYSDATE
----------
2000-06-10

SQL&gt;
</pre><p>Many people encounter an error regarding <code class="computeroutput">maximum key length</code>:</p><pre class="programlisting">
ERROR at line 1:
ORA-01450: maximum key length (758) exceeded
</pre><p>This error occurs if your database block size is wrong and is
usually suffered by people trying to load OpenACS into a
pre-existing database. Unfortunately, the only solution is to
create a new database with a block size of at least <code class="computeroutput">4096</code>. For instructions on how to do this,
see <a class="xref" href="oracle" title="Creating the First Database">the section called
&ldquo;Creating the First Database&rdquo;</a>
above. You can set the parameter using the <code class="computeroutput">dbassist</code> program or by setting the
<code class="computeroutput">DB_BLOCK_SIZE</code> parameter in your
database&#39;s creation script.</p><p>If there were no errors, then consider yourself fortunate. Your
Oracle installation is working.</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-oracle-automating" id="install-oracle-automating"></a>Automating Startup &amp;
Shutdown</h3></div></div></div><p>You will want to automate the database startup and shutdown
process. It&#39;s probably best to have Oracle spring to life when
you boot up your machine.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Oracle includes a script called <code class="computeroutput">dbstart</code> that can be used to automatically
start the database. Unfortunately, the script shipped in the Linux
distribution does not work out of the box. The fix is simple.
Follow these directions to apply it. First, save <a class="ulink" href="files/dbstart.txt" target="_top">dbstart</a> to <code class="computeroutput">/var/tmp</code>. Then, as <code class="computeroutput">oracle</code>, do the following:</p><pre class="programlisting">
[oracle ~]$ cp /var/tmp/dbstart.txt /ora8/m01/app/oracle/product/8.1.7/bin/dbstart 
[oracle ~]$ chmod 755 /ora8/m01/app/oracle/product/8.1.7/bin/dbstart
</pre>
</li><li class="listitem">
<p>While you&#39;re logged in as <code class="computeroutput">oracle</code>, you should configure the
<code class="computeroutput">oratab</code> file to load your
database at start. Edit the file <code class="computeroutput">/etc/oratab</code>:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>You will see this line.</p><pre class="programlisting">
ora8:/ora8/m01/app/oracle/product/8.1.7:N
</pre><p>By the way, if you changed the service name or have multiple
databases, the format of this file is:</p><p><span class="emphasis"><em><code class="computeroutput">service_name:$ORACLE_HOME:Y || N (for
autoload)</code></em></span></p>
</li><li class="listitem">
<p>Change the last letter from "N" to "Y". This
tells Oracle that you want the database to start when the machine
boots. It should look like this.</p><pre class="programlisting">
ora8:/ora8/m01/app/oracle/product/8.1.7:Y
</pre>
</li><li class="listitem"><p>Save the file &amp; quit the terminal.</p></li>
</ul></div>
</li><li class="listitem">
<p>You need a script to automate startup and shutdown. Save
<a class="ulink" href="files/oracle8i.txt" target="_top">oracle8i.txt</a> in <code class="computeroutput">/var/tmp</code>. Then login as <code class="computeroutput">root</code> and install the script. (Debian users:
substitute <code class="computeroutput">/etc/init.d</code> for
<code class="computeroutput">/etc/rc.d/init.d</code> throughout
this section)</p><pre class="programlisting">
[oracle ~]$ su -
[root ~]# cp /var/tmp/oracle8i.txt /etc/rc.d/init.d/oracle8i
[root ~]# chown root.root /etc/rc.d/init.d/oracle8i
[root ~]# chmod 755 /etc/rc.d/init.d/oracle8i
</pre>
</li><li class="listitem">
<p>Test the script by typing the following commands and checking
the output. (Debian Users: as root, do <code class="computeroutput">mkdir /var/lock/subsys</code> first)</p><pre class="programlisting">
[root ~]# /etc/rc.d/init.d/oracle8i stop
Oracle 8i auto start/stop
Shutting Oracle8i:
Oracle Server Manager Release 3.1.7.0.0 - Production

Copyright (c) 1997, 1999, Oracle Corporation.  All
Rights Reserved.

Oracle8i Enterprise Edition Release 8.1.7.0.1 -
Production
With the Partitioning option
JServer Release 8.1.7.0.1 - Production

SVRMGR&gt; Connected.
SVRMGR&gt; Database closed.
Database dismounted.
ORACLE instance shut down.
SVRMGR&gt;
Server Manager complete.
Database "ora8" shut down.
      
[root ~]# /etc/rc.d/init.d/oracle8i start
Oracle 8i auto start/stop
Starting Oracle8i: 
SQL*Plus: Release 8.1.7.0.0 - Production on Wed Mar 6 17:56:02 2002

(c) Copyright 2000 Oracle Corporation.  All rights reserved.

SQL&gt; Connected to an idle instance.
SQL&gt; ORACLE instance started.

Total System Global Area   84713632 bytes
Fixed Size                    73888 bytes
Variable Size              76079104 bytes
Database Buffers            8388608 bytes
Redo Buffers                 172032 bytes
Database mounted.
Database opened.
SQL&gt; Disconnected

Database "ora8" warm started.

Database "ora8" warm started.
</pre>
</li><li class="listitem">
<p>If it worked, then run these commands to make the startup and
shutdown automatic.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>Red Hat users:</p><pre class="programlisting">
[root ~]# cd /etc/rc.d/init.d/                      
[root ~]# chkconfig --add oracle8i
[root ~]# chkconfig --list oracle8i
; You should see:
oracle8i        0:off   1:off   2:off   3:on    4:on    5:on    6:off
</pre>
</li><li class="listitem">
<p>Debian users:</p><pre class="programlisting">
[root ~]# update-rc.d oracle8i defaults
 Adding system startup for /etc/init.d/oracle8i ...
   /etc/rc0.d/K20oracle8i -&gt; ../init.d/oracle8i
   /etc/rc1.d/K20oracle8i -&gt; ../init.d/oracle8i
   /etc/rc6.d/K20oracle8i -&gt; ../init.d/oracle8i
   /etc/rc2.d/S20oracle8i -&gt; ../init.d/oracle8i
   /etc/rc3.d/S20oracle8i -&gt; ../init.d/oracle8i
   /etc/rc4.d/S20oracle8i -&gt; ../init.d/oracle8i
   /etc/rc5.d/S20oracle8i -&gt; ../init.d/oracle8i
</pre>
</li><li class="listitem">
<p>SuSE users:</p><pre class="programlisting">
[root ~]# cd /etc/rc.d/init.d
root:/etc/rc.d/init.d# ln -s /etc/rc.d/init.d/oracle8i K20oracle8i
root:/etc/rc.d/init.d# ln -s /etc/rc.d/init.d/oracle8i S20oracle8i
root:/etc/rc.d/init.d# cp K20oracle8i rc0.d
root:/etc/rc.d/init.d# cp S20oracle8i rc0.d
root:/etc/rc.d/init.d# cp K20oracle8i rc1.d
root:/etc/rc.d/init.d# cp S20oracle8i rc1.d 
root:/etc/rc.d/init.d# cp K20oracle8i rc6.d
root:/etc/rc.d/init.d# cp S20oracle8i rc6.d
root:/etc/rc.d/init.d# cp K20oracle8i rc2.d
root:/etc/rc.d/init.d# cp S20oracle8i rc2.d
root:/etc/rc.d/init.d# cp K20oracle8i rc3.d
root:/etc/rc.d/init.d# cp S20oracle8i rc3.d 
root:/etc/rc.d/init.d# cp K20oracle8i rc4.d  
root:/etc/rc.d/init.d# cp S20oracle8i rc4.d  
root:/etc/rc.d/init.d# cp K20oracle8i rc5.d
root:/etc/rc.d/init.d# cp S20oracle8i rc5.d
root:/etc/rc.d/init.d# rm K20oracle8i
root:/etc/rc.d/init.d# rm S20oracle8i
root:/etc/rc.d/init.d# cd
[root ~]# SuSEconfig
Started the SuSE-Configuration Tool.
Running in full featured mode.
Reading /etc/rc.config and updating the system...
Executing /sbin/conf.d/SuSEconfig.gdm...   
Executing /sbin/conf.d/SuSEconfig.gnprint...
Executing /sbin/conf.d/SuSEconfig.groff...   
Executing /sbin/conf.d/SuSEconfig.java...    
Executing /sbin/conf.d/SuSEconfig.kdm...   
Executing /sbin/conf.d/SuSEconfig.pcmcia...
Executing /sbin/conf.d/SuSEconfig.perl...
Executing /sbin/conf.d/SuSEconfig.postfix...
Executing /sbin/conf.d/SuSEconfig.sendmail...
Executing /sbin/conf.d/SuSEconfig.susehilf...
Executing /sbin/conf.d/SuSEconfig.susehilf.add...
Executing /sbin/conf.d/SuSEconfig.susewm...
Executing /sbin/conf.d/SuSEconfig.tetex...
Executing /sbin/conf.d/SuSEconfig.ypclient...
Processing index files of all manpages...
Finished.
</pre>
</li>
</ul></div>
</li><li class="listitem">
<p>You also need some scripts to automate startup and shutdown of
the Oracle8i listener. The listener is a name server that allows
your Oracle programs to talk to local and remote databases using a
standard naming convention. It is required for Intermedia Text and
full site search.</p><p>Download these three scripts into <code class="computeroutput">/var/tmp</code>
</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p><a class="ulink" href="files/startlsnr.txt" target="_top">startlsnr.txt</a></p></li><li class="listitem"><p><a class="ulink" href="files/stoplsnr.txt" target="_top">stoplsnr.txt</a></p></li><li class="listitem"><p><a class="ulink" href="files/listener8i.txt" target="_top">listener8i.txt</a></p></li>
</ul></div><p>Now issue the following commands (still as <code class="computeroutput">root</code>).</p><pre class="programlisting">
[root ~]# su - oracle
[oracle ~]$ cp /var/tmp/startlsnr.txt /ora8/m01/app/oracle/product/8.1.7/bin/startlsnr
[oracle ~]$ cp /var/tmp/stoplsnr.txt /ora8/m01/app/oracle/product/8.1.7/bin/stoplsnr    
[oracle ~]$ chmod 755 /ora8/m01/app/oracle/product/8.1.7/bin/startlsnr
[oracle ~]$ chmod 755 /ora8/m01/app/oracle/product/8.1.7/bin/stoplsnr
[oracle ~]$ exit
[root ~]# cp /var/tmp/listener8i.txt /etc/rc.d/init.d/listener8i
[root ~]# cd /etc/rc.d/init.d
root:/etc/rc.d/init.d# chmod 755 listener8i
</pre><p>Test the listener automation by running the following commands
and checking the output.</p><pre class="programlisting">
root:/etc/rc.d/init.d# ./listener8i stop
Oracle 8i listener start/stop
Shutting down Listener for 8i: 
LSNRCTL for Linux: Version 8.1.7.0.0 - Production on 06-MAR-2002 18:28:49

(c) Copyright 1998, Oracle Corporation.  All rights reserved.

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost.localdomain)(PORT=1521)))
The command completed successfully

    
root:/etc/rc.d/init.d# ./listener8i start
Oracle 8i listener start/stop
Starting the Listener for 8i: 
LSNRCTL for Linux: Version 8.1.7.0.0 - Production on 06-MAR-2002 18:28:52

(c) Copyright 1998, Oracle Corporation.  All rights reserved.

Starting /ora8/m01/app/oracle/product/8.1.7/bin/tnslsnr: please wait...

TNSLSNR for Linux: Version 8.1.7.0.0 - Production
System parameter file is /ora8/m01/app/oracle/product/8.1.7/network/admin/listener.ora
Log messages written to /ora8/m01/app/oracle/product/8.1.7/network/log/listener.log
Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=localhost.localdomain)(PORT=1521)))
Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC)))

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost.localdomain)(PORT=1521)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 8.1.7.0.0 - Production
Start Date                06-MAR-2002 18:28:53
Uptime                    0 days 0 hr. 0 min. 0 sec
Trace Level               off
Security                  OFF
SNMP                      OFF
Listener Parameter File   /ora8/m01/app/oracle/product/8.1.7/network/admin/listener.ora
Listener Log File         /ora8/m01/app/oracle/product/8.1.7/network/log/listener.log
Services Summary...
  PLSExtProc        has 1 service handler(s)
  ora8      has 1 service handler(s)
The command completed successfully
</pre><p>This test will verify that the listener is operating normally.
Login into the database using the listener naming convention.</p><p>
<code class="computeroutput">sqlplus</code><span class="emphasis"><em><code class="computeroutput">username/password/\@SID</code></em></span>
</p><pre class="programlisting">
[root ~]# su - oracle
[oracle ~]$ sqlplus system/alexisahunk\@ora8

SQL&gt; select sysdate from dual;

SYSDATE
----------
2002-02-22

SQL&gt; exit
[oracle ~]$ exit
[root ~]#
</pre><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>RedHat users:</p><p>Now run <code class="computeroutput">chkconfig</code> on the
<code class="computeroutput">listener8i</code> script.</p><pre class="programlisting">
[root ~]# cd /etc/rc.d/init.d/
root:/etc/rc.d/init.d# chkconfig --add listener8i
root:/etc/rc.d/init.d# chkconfig --list listener8i
listener8i      0:off   1:off   2:off   3:on    4:on    5:on    6:off
</pre>
</li><li class="listitem">
<p>Debian users:</p><p>Now run <code class="computeroutput">update-rc.d</code> on the
<code class="computeroutput">listener8i</code> script.</p><pre class="programlisting">
[root ~]# update-rc.d listener8i defaults 21 19
 Adding system startup for /etc/init.d/listener8i ...
   /etc/rc0.d/K19listener8i -&gt; ../init.d/listener8i
   /etc/rc1.d/K19listener8i -&gt; ../init.d/listener8i
   /etc/rc6.d/K19listener8i -&gt; ../init.d/listener8i
   /etc/rc2.d/S21listener8i -&gt; ../init.d/listener8i
   /etc/rc3.d/S21listener8i -&gt; ../init.d/listener8i
   /etc/rc4.d/S21listener8i -&gt; ../init.d/listener8i
   /etc/rc5.d/S21listener8i -&gt; ../init.d/listener8i
</pre>
</li>
</ul></div>
</li><li class="listitem">
<p>Test the automation</p><p>As a final test, reboot your computer and make sure Oracle comes
up. You can do this by typing</p><pre class="programlisting">
[root ~]# /sbin/shutdown -r -t 0 now
</pre><p>Log back in and ensure that Oracle started automatically.</p><pre class="programlisting">
[joeuser ~]$ su - oracle
[oracle ~]$ sqlplus system/alexisahunk\@ora8

SQL&gt; exit
</pre>
</li>
</ul></div><p>Congratulations, your installation of Oracle 8.1.7 is
complete.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-oracle-troubleshooting" id="install-oracle-troubleshooting"></a>Troubleshooting Oracle
Dates</h3></div></div></div><p>Oracle has an internal representation for storing the data based
on the number of seconds elapsed since some date. However, for the
purposes of inputing dates into Oracle and getting them back out,
Oracle needs to be told to use a specific date format. By default,
it uses an Oracle-specific format which isn&#39;t copacetic. You
want Oracle to use the ANSI-compliant date format which is of form
<code class="computeroutput">'YYYY-MM-DD'</code>.</p><p>To fix this, you should include the following line in
<code class="computeroutput">$ORACLE_HOME/dbs/init</code><span class="emphasis"><em>SID</em></span><code class="computeroutput">.ora</code> or for the default case, <code class="computeroutput">$ORACLE_HOME/dbs/initora8.ora</code>
</p><pre class="programlisting">
nls_date_format = "YYYY-MM-DD"
</pre><p>You test whether this solved the problem by firing up
<code class="computeroutput">sqlplus</code> and typing:</p><pre class="programlisting">
SQL&gt; select sysdate from dual;
</pre><p>You should see back a date like <code class="computeroutput">2000-06-02</code>. If some of the date is chopped
off, i.e. like <code class="computeroutput">2000-06-0</code>,
everything is still fine. The problem here is that <code class="computeroutput">sqlplus</code> is simply truncating the output.
You can fix this by typing:</p><pre class="programlisting">
SQL&gt; column sysdate format a15
SQL&gt; select sysdate from dual;
</pre><p>If the date does not conform to this format, double-check that
you included the necessary line in the init scripts. If it still
isn&#39;t working, make sure that you have restarted the database
since adding the line:</p><pre class="programlisting">
[joeuser ~]$ svrmgrl
SVRMGR&gt; connect internal
Connected.
SVRMGR&gt; shutdown
Database closed.
Database dismounted.
ORACLE instance shut down.
SVRMGR&gt; startup
ORACLE instance started.
</pre><p>If you&#39;re sure that you have restarted the database since
adding the line, check your initialization scripts. Make sure that
the following line is not included:</p><pre class="programlisting">
export nls_lang = american
</pre><p>Setting this environment variable will override the date
setting. Either delete this line and login again or add the
following entry to your login scripts <span class="emphasis"><em>after</em></span> the <code class="computeroutput">nls_lang</code> line:</p><pre class="programlisting">
export nls_date_format = 'YYYY-MM-DD'
</pre><p>Log back in again. If adding the <code class="computeroutput">nls_date_format</code> line doesn&#39;t help, you
can ask for advice in our <a class="ulink" href="http://www.openacs.org/forums/" target="_top">OpenACS
forums</a>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-oracle-procs" id="install-oracle-procs"></a>Useful Procedures</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<p>Dropping a tablespace</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>Run sqlplus as the dba:</p><pre class="programlisting">
[oracle ~]$ sqlplus system/changeme
</pre>
</li><li class="listitem">
<p>To drop a user and all of the tables and data owned by that
user:</p><pre class="programlisting">
SQL&gt; drop user <span class="emphasis"><em>oracle_user_name</em></span> cascade;
</pre>
</li><li class="listitem">
<p>To drop the tablespace: This will delete everything in the
tablespace overriding any referential integrity constraints. Run
this command only if you want to clean out your database
entirely.</p><pre class="programlisting">
SQL&gt; drop tablespace <span class="emphasis"><em>table_space_name</em></span> including contents cascade constraints;
</pre>
</li>
</ul></div>
</li></ul></div><p>For more information on Oracle, please consult the <a class="ulink" href="https://docs.oracle.com/en/database/" target="_top">documentation</a>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="oracle-next-steps" id="oracle-next-steps"></a>Oracle Next Steps</h3></div></div></div><p><a class="xref" href="maint-performance" title="Creating an appropriate tuning and monitoring environment">the
section called &ldquo;Creating an appropriate tuning
and monitoring environment&rdquo;</a></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-oracle-defaults" id="install-oracle-defaults"></a>Defaults</h3></div></div></div><p>We used the following defaults while installing Oracle.</p><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col>
</colgroup><thead><tr>
<th>Variable</th><th>Value</th><th>Reason</th>
</tr></thead><tbody>
<tr>
<td>ORACLE_HOME</td><td>/ora8/m01/app/oracle/product/8.1.7</td><td>This is the default Oracle installation directory.</td>
</tr><tr>
<td>ORACLE_SERVICE</td><td>ora8</td><td>The service name is a domain-qualified identifier for your
Oracle server.</td>
</tr><tr>
<td>ORACLE_SID</td><td>ora8</td><td>This is an identifier for your Oracle server.</td>
</tr><tr>
<td>ORACLE_OWNER</td><td>oracle</td><td>The user who owns all of the oracle files.</td>
</tr><tr>
<td>ORACLE_GROUP</td><td>dba</td><td>The special oracle group. Users in the dba group are authorized
to do a <code class="computeroutput">connect internal</code> within
<code class="computeroutput">svrmgrl</code> to gain full system
access to the Oracle system.</td>
</tr>
</tbody>
</table></div><div class="cvstag">($&zwnj;Id: oracle.xml,v 1.21.14.6 2017/06/17
08:29:28 gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="unix-installation" leftLabel="Prev" leftTitle="Install a Unix-like system and
supporting software"
		    rightLink="postgres" rightLabel="Next" rightTitle="Install PostgreSQL"
		    homeLink="index" homeLabel="Home" 
		    upLink="complete-install" upLabel="Up"> 
		