
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Add the new package to CVS}</property>
<property name="doc(title)">Add the new package to CVS</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tutorial-specs" leftLabel="Prev"
		    title="
Chapter 10. Advanced Topics"
		    rightLink="tutorial-etp-templates" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-cvs" id="tutorial-cvs"></a>Add the new package to CVS</h2></div></div></div><p>Before you do any more work, make sure that your work is
protected by putting it all into cvs. The <code class="computeroutput">cvs add</code> command is not recursive, so
you&#39;ll have to traverse the directory tree manually and add as
you go. (<a class="ulink" href="http://www.piskorski.com/docs/cvs-conventions.html" target="_top">More on CVS</a>)</p><pre class="screen">
[$OPENACS_SERVICE_NAME xml]$ <strong class="userinput"><code>cd ..</code></strong>
[$OPENACS_SERVICE_NAME doc]$ <strong class="userinput"><code>cd ..</code></strong>
[$OPENACS_SERVICE_NAME www]$ <strong class="userinput"><code>cd ..</code></strong>
[$OPENACS_SERVICE_NAME myfirstpackage]$ <strong class="userinput"><code>cd ..</code></strong>
[$OPENACS_SERVICE_NAME packages]$ <strong class="userinput"><code>cvs add myfirstpackage/</code></strong>
Directory /cvsroot/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage added to the repository
[$OPENACS_SERVICE_NAME packages]$ <strong class="userinput"><code>cd myfirstpackage/</code></strong>
[$OPENACS_SERVICE_NAME myfirstpackage]$ <strong class="userinput"><code>cvs add www</code></strong>
Directory /cvsroot/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/www added to the repository
[$OPENACS_SERVICE_NAME myfirstpackage]$ <strong class="userinput"><code>cd www</code></strong>
[$OPENACS_SERVICE_NAME www]$ <strong class="userinput"><code>cvs add doc</code></strong>
Directory /cvsroot/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/www/doc added to the repository
[$OPENACS_SERVICE_NAME www]$ <strong class="userinput"><code>cd doc</code></strong>
[$OPENACS_SERVICE_NAME doc]$ <strong class="userinput"><code>cvs add *</code></strong>
cvs add: cannot add special file `CVS'; skipping
cvs add: scheduling file `admin-guide.html' for addition
cvs add: scheduling file `bi01.html' for addition
cvs add: scheduling file `data-model.dia' for addition
cvs add: scheduling file `data-model.png' for addition
cvs add: scheduling file `design-config.html' for addition
cvs add: scheduling file `design-data-model.html' for addition
cvs add: scheduling file `design-future.html' for addition
cvs add: scheduling file `design-ui.html' for addition
cvs add: scheduling file `filename.html' for addition
cvs add: scheduling file `index.html' for addition
cvs add: scheduling file `page-map.dia' for addition
cvs add: scheduling file `page-map.png' for addition
cvs add: scheduling file `requirements-cases.html' for addition
cvs add: scheduling file `requirements-introduction.html' for addition
cvs add: scheduling file `requirements-overview.html' for addition
cvs add: scheduling file `requirements.html' for addition
cvs add: scheduling file `sample-data.html' for addition
cvs add: scheduling file `sample.png' for addition
cvs add: scheduling file `user-guide.html' for addition
cvs add: scheduling file `user-interface.dia' for addition
cvs add: scheduling file `user-interface.png' for addition
Directory /cvsroot/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/www/doc/xml added to the repository
cvs add: use 'cvs commit' to add these files permanently
[$OPENACS_SERVICE_NAME doc]$ <strong class="userinput"><code>cd xml</code></strong>
[$OPENACS_SERVICE_NAME xml]$ <strong class="userinput"><code>cvs add Makefile index.xml</code></strong>
cvs add: scheduling file `Makefile' for addition
cvs add: scheduling file `index.xml' for addition
cvs add: use 'cvs commit' to add these files permanently
[$OPENACS_SERVICE_NAME xml]$<strong class="userinput"><code> cd ../../..</code></strong>
[$OPENACS_SERVICE_NAME myfirstpackage]$ <strong class="userinput"><code>cvs commit -m "new package"</code></strong>
cvs commit: Examining .
cvs commit: Examining www
cvs commit: Examining www/doc
cvs commit: Examining www/doc/xml
RCS file: /cvsroot/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/www/doc/admin-guide.html,v
done
Checking in www/doc/admin-guide.html;
/cvsroot/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/www/doc/admin-guide.html,v  &lt;--  admin-guide.html
initial revision: 1.1
done
<span class="emphasis"><em>(many lines omitted)</em></span>
[$OPENACS_SERVICE_NAME myfirstpackage]$
</pre><div class="figure">
<a name="idp140592099723480" id="idp140592099723480"></a><p class="title"><strong>Figure 10.1. Upgrading a local CVS
repository</strong></p><div class="figure-contents"><div class="mediaobject" align="center"><img src="images/development-with-cvs.png" align="middle" alt="Upgrading a local CVS repository"></div></div>
</div><br class="figure-break">
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tutorial-specs" leftLabel="Prev" leftTitle="Write the Requirements and Design
Specs"
		    rightLink="tutorial-etp-templates" rightLabel="Next" rightTitle="OpenACS Edit This Page Templates"
		    homeLink="index" homeLabel="Home" 
		    upLink="tutorial-advanced" upLabel="Up"> 
		