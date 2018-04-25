
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Using PSGML mode in Emacs}</property>
<property name="doc(title)">Using PSGML mode in Emacs</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="docbook-primer" leftLabel="Prev"
			title="Chapter 13. Documentation
Standards"
			rightLink="nxml-mode" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="psgml-mode" id="psgml-mode"></a>Using PSGML mode in Emacs</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By David Lutterkort</span></p><span style="color: red">&lt;/authorblurb&gt;</span><p>Note: <code class="computeroutput">nxml</code> mode replaces
and/or complements psgml mode. <a class="ulink" href="http://www.xmlhack.com/read.php?item=2061" target="_top">More
information</a>.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="psgml-mode-whatisit" id="psgml-mode-whatisit"></a>What it is</h3></div></div></div><p>PSGML Mode is a mode for editing, umm, SGML and XML documents in
emacs. It can parse a DTD and help you insert the right tags in the
right place, knows about tags' attributes and can tell you in
which contexts a tag can be used. <span class="emphasis"><em>If</em></span> you give it the right DTD, that is.
But even without a DTD, it can save you some typing since pressing
<code class="computeroutput">C-c/</code> will close an open tag
automatically.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="psgml-mode-getit" id="psgml-mode-getit"></a>Where to get it</h3></div></div></div><p>Most newer emacsen come with PSGML mode preinstalled. You can
find out whether your emacs has it with the <code class="computeroutput">locate-library</code> command. In Emacs, type
<code class="computeroutput">M-x locate-library</code> and enter
<code class="computeroutput">psgml</code>. Emacs will tell you if
it found it or not.</p><p>If you don&#39;t have PSGML preinstalled in your Emacs, there
are two things you can do:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>On Linux: Get the <a class="ulink" href="ftp://sourceware.cygnus.com:/pub/docbook-tools/docware/RPMS/noarch/psgml-1.2.1-1.noarch.rpm" target="_top">psgml rpm</a> from <a class="ulink" href="http://sources.redhat.com/docbook-tools/" target="_top">RedHat&#39;s docbook-tools</a> and install it as usual.</p></li><li class="listitem"><p>On other systems: Get the tarball from the <a class="ulink" href="https://www.emacswiki.org/emacs/PsgmlMode" target="_top">PSGML Website.</a> Unpack it and follow the install
instructions.</p></li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="psgml-mode-catalogs" id="psgml-mode-catalogs"></a>Using <code class="computeroutput">CATALOG</code> files</h3></div></div></div><p>The easiest way to teach PSGML mode about a DTD is by adding it
to your own <code class="computeroutput">CATALOG</code>. Here is an
example of how you can set that up for the Docbook XML DTD.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Get the <a class="ulink" href="http://docbook.org/xml/index.html" target="_top">Docbook XML
DTD</a> zip archive from <a class="ulink" href="http://docbook.org/" target="_top">docbook.org</a>
</p></li><li class="listitem">
<p>Go somewhere in your working directory and do</p><pre class="programlisting">
      mkdir -p dtd/docbook-xml
      cd dtd/docbook-xml
      unzip -a &lt;docbook XML DTD zip archive&gt;
   
</pre>
</li><li class="listitem">
<p>Create a file with the name <code class="computeroutput">CATALOG</code> in the <code class="computeroutput">dtd</code> directory and put the line</p><pre class="programlisting">
      CATALOG "docbook-xml/docbook.cat"
</pre><p>in it. By maintaining your own <code class="computeroutput">CATALOG</code>, it is easy to add more DTD&#39;s
without changing your emacs settings. (<span class="emphasis"><em>How about that HTML 4.01 DTD you always wanted to
get from <a class="ulink" href="http://www.w3.org/TR/html4/" target="_top">W3C</a> ? The DTD is in the zip archives and tarballs
available on the site.</em></span>)</p>
</li>
</ol></div><p>That&#39;s it. Now you are ready to tell emacs all about PSGML
mode and that funky <code class="computeroutput">CATALOG</code>
</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="psgml-mode-tell-emacs" id="psgml-mode-tell-emacs"></a>What to tell emacs</h3></div></div></div><p>If you installed PSGML mode in a non-standard location, e.g.,
somewhere in your home directory, you need to add this to the
<code class="computeroutput">load-path</code> by adding this line
to your <code class="computeroutput">.emacs</code> file:</p><pre class="programlisting">
      (add-to-list 'load-path "/some/dir/that/contains/psgml.elc")
   
</pre><p>To let PSGML mode find your <code class="computeroutput">CATALOG</code> and to enable PSGML mode for all
your editing, add these lines to your <code class="computeroutput">.emacs</code>:</p><pre class="programlisting">
      (require 'psgml)

      (add-to-list 'auto-mode-alist '("\\.html" . sgml-mode))
      (add-to-list 'auto-mode-alist '("\\.adp" . xml-mode))
      (add-to-list 'auto-mode-alist '("\\.xml" . xml-mode))
      (add-to-list 'auto-mode-alist '("\\.xsl" . xml-mode))
      
      (add-to-list 'sgml-catalog-files "/path/to/your/dtd/CATALOG")
   
</pre><p>If you want font-locking and indentation, you can also add these
lines into the <code class="computeroutput">.emacs</code> file:</p><pre class="programlisting">
      (setq sgml-markup-faces '((start-tag . font-lock-function-name-face)
                                (end-tag . font-lock-function-name-face)
                (comment . font-lock-comment-face)
                (pi . bold)
                (sgml . bold)
                (doctype . bold)
                (entity . font-lock-type-face)
                (shortref . font-lock-function-name-face)))
      (setq sgml-set-face t)
      (setq-default sgml-indent-data t)
      ;; Some convenient key definitions:
      (define-key sgml-mode-map "\C-c\C-x\C-e" 'sgml-describe-element-type)
      (define-key sgml-mode-map "\C-c\C-x\C-i" 'sgml-general-dtd-info)
      (define-key sgml-mode-map "\C-c\C-x\C-t" 'sgml-describe-entity)
   
</pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="psgml-mode-doctype" id="psgml-mode-doctype"></a>What is a <code class="computeroutput">DOCTYPE</code> ?</h3></div></div></div><p>All SGML and XML documents that should conform to a DTD have to
declare a doctype. For the docbook XML, all your <code class="computeroutput">.xml</code> files whould start with the line</p><pre class="programlisting">
      &lt;!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook XML V4.4//EN" "docbookx.dtd"&gt;
   
</pre><p>If your document is only part of a larger XML document, you can
tell PSGML mode about it by <span class="emphasis"><em>appending</em></span> the following lines to your
file. In this case, do <span class="emphasis"><em>not</em></span>
include a DOCTYPE declaration in your file.</p><pre class="programlisting">
      &lt;!--
       Local Variables:
       sgml-parent-document: ("top.xml" "book" "sect1")
       End:
      --&gt;
   
</pre><p>Which says that the parent of this document can be found in the
file <code class="computeroutput">top.xml</code>, that the element
in the parent that will enclose the current document is a
<code class="computeroutput">book</code> and that the current
file&#39;s topmost element is a <code class="computeroutput">sect1</code>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="psgml-mode-usage" id="psgml-mode-usage"></a>How to use it</h3></div></div></div><p>Of course, you should read the emacs texinfo pages that come
with PSGML mode from start to finish. Barring that, here are some
handy commands:</p><div class="informaltable"><table class="informaltable" cellspacing="0" border="0">
<colgroup>
<col><col>
</colgroup><thead><tr>
<th>Key</th><th>Command</th>
</tr></thead><tbody>
<tr>
<td><code class="computeroutput">C-c C-e</code></td><td>Insert an element. Uses completion and only lets you insert
elements that are valid</td>
</tr><tr>
<td><code class="computeroutput">C-c C-a</code></td><td>Edit attributes of enclosing element.</td>
</tr><tr>
<td><code class="computeroutput">C-c C-x C-i</code></td><td>Show information about the document&#39;s DTD.</td>
</tr><tr>
<td><code class="computeroutput">C-c C-x C-e</code></td><td>Describe element. Shows for one element which elements can be
parents, what its contents can be and lists its attributes.</td>
</tr>
</tbody>
</table></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="psgml-mode-reading" id="psgml-mode-reading"></a>Further reading</h3></div></div></div><p>Start with the <a class="xref" href="docbook-primer" title="OpenACS Documentation Guide">the section called “OpenACS
Documentation Guide”</a>
</p><p><span class="cvstag">($&zwnj;Id: psgml-mode.xml,v 1.9 2017/08/07
23:47:54 gustafn Exp $)</span></p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="docbook-primer" leftLabel="Prev" leftTitle="OpenACS Documentation Guide"
			rightLink="nxml-mode" rightLabel="Next" rightTitle="Using nXML mode in Emacs"
			homeLink="index" homeLabel="Home" 
			upLink="doc-standards" upLabel="Up"> 
		    