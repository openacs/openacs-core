
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Write the Requirements and Design Specs}</property>
<property name="doc(title)">Write the Requirements and Design Specs</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="tutorial-advanced" leftLabel="Prev"
			title="Chapter 10. Advanced
Topics"
			rightLink="tutorial-cvs" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-specs" id="tutorial-specs"></a>Write the Requirements and Design Specs</h2></div></div></div><p>Before you get started you should make yourself familiar with
the tags that are used to write your documentation. For tips on
editing SGML files in emacs, see <a class="xref" href="docbook-primer" title="OpenACS Documentation Guide">the
section called “OpenACS Documentation Guide”</a>.</p><p>It&#39;s time to document. For the tutorial we&#39;ll use
pre-written documentation. When creating a package from scratch,
start by copying the documentation template from <code class="computeroutput">/var/lib/aolserver/openacs-dev/packages/acs-core-docs/xml/docs/xml/package-documentation-template.xml</code>
to <code class="computeroutput">myfirstpackage/www/docs/xml/index.xml</code>.</p><p>You then edit that file with emacs to write the requirements and
design sections, generate the html, and start coding. Store any
supporting files, like page maps or schema diagrams, in the
<code class="computeroutput">www/doc/xml</code> directory, and
store png or jpg versions of supporting files in the <code class="computeroutput">www/doc</code> directory.</p><p>For this tutorial, you should instead install the pre-written
documentation files for the tutorial app. Log in as <em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>, create the
standard directories, and copy the prepared documentation:</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/packages/myfirstpackage/</code></strong>
[$OPENACS_SERVICE_NAME myfirstpackage]$ <strong class="userinput"><code>mkdir -p www/doc/xml</code></strong>
[$OPENACS_SERVICE_NAME myfirstpackage]$ <strong class="userinput"><code>cd www/doc/xml</code></strong>
[$OPENACS_SERVICE_NAME xml]$ <strong class="userinput"><code>cp /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/packages/acs-core-docs/www/files/myfirstpackage/* .</code></strong>
[$OPENACS_SERVICE_NAME xml]$</pre><p>OpenACS uses DocBook for documentation. DocBook is an XML
standard for semantic markup of documentation. That means that the
tags you use indicate meaning, not intended appearance. The style
sheet will determine appearance. You will edit the text in an xml
file, and then process the file into html for reading.</p><p>Open the file <code class="computeroutput">index.xml</code> in
emacs. Examine the file. Find the version history (look for the tag
<code class="computeroutput">&lt;revhistory&gt;</code>). Add a new
record to the document version history. Look for the <code class="computeroutput">&lt;authorgroup&gt;</code> tag and add yourself as
a second author. Save and exit.</p><p>Process the xml file to create html documentation. The html
documentation, including supporting files such as pictures, is
stored in the <code class="computeroutput">www/docs/</code>
directory. A Makefile is provided to generate html from the xml,
and copy all of the supporting files. If Docbook is set up
correctly, all you need to do is:</p><pre class="screen">[$OPENACS_SERVICE_NAME xml]$<strong class="userinput"><code> make</code></strong>
cd .. ; /usr/bin/xsltproc ../../../acs-core-docs/www/xml/openacs.xsl xml/index.xml
Writing requirements-introduction.html for chapter(requirements-introduction)
Writing requirements-overview.html for chapter(requirements-overview)
Writing requirements-cases.html for chapter(requirements-cases)
Writing sample-data.html for chapter(sample-data)
Writing requirements.html for chapter(requirements)
Writing design-data-model.html for chapter(design-data-model)
Writing design-ui.html for chapter(design-ui)
Writing design-config.html for chapter(design-config)
Writing design-future.html for chapter(design-future)
Writing filename.html for chapter(filename)
Writing user-guide.html for chapter(user-guide)
Writing admin-guide.html for chapter(admin-guide)
Writing bi01.html for bibliography
Writing index.html for book
[$OPENACS_SERVICE_NAME xml]$</pre><p>Verify that the documentation was generated and reflects your
changes by browsing to <code class="computeroutput">http://<em class="replaceable"><code>yoursite</code></em>:8000/myfirstpackage/doc</code>
</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="tutorial-advanced" leftLabel="Prev" leftTitle="Chapter 10. Advanced
Topics"
			rightLink="tutorial-cvs" rightLabel="Next" rightTitle="Add the new package to CVS"
			homeLink="index" homeLabel="Home" 
			upLink="tutorial-advanced" upLabel="Up"> 
		    