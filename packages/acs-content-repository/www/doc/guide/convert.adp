
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Content Repository Developer Guide: HTML Conversion}</property>
<property name="doc(title)">Content Repository Developer Guide: HTML Conversion</property>
<master>
<h2>Converting Binary Documents to HTML</h2>
<strong>
<a href="../index">Content Repository</a> : Developer
Guide</strong>
<p>The content repository uses the INSO libraries included with
Intermedia to support conversion of binary files such as Microsoft
Word documents to HTML. This document describes how to make this
conversion be part of the item creation or editing process, such
that the content is always stored in the repository as HTML.</p>
<p>
<strong>Note:</strong> Because temporary tables and LOB storage
are used during the conversion process, the entire process
described here must be performed within the context of a single
transaction.</p>
<h3>Create the Revision</h3>
<p>The first step is to create the revision that will be associated
with the converted document, and obtain the corresponding ID. The
<kbd>content</kbd> column for the revision must be initialized with
an empty blob object:</p>
<pre>
revision_id := content_revision.new(item_id =&gt; :item_id,
                                    revision_id =&gt; :revision_id,
                                    data =&gt; empty_blob(),
                                    title =&gt; 'My Word Document',
                                    ...);
</pre>
<h3>Uploading Binary Files</h3>
<p>The next step in the process is to upload the binary file into
the temporary table <kbd>cr_doc_filter</kbd>. This may be done
using any standard technique for uploading a binary file, such as
an image. The temporary table has only two columns; one is a BLOB
to store the document itself, and one is the revision ID.</p>
<h3>Converting the Document</h3>
<p>Once the revision has been created and the file has been
uploaded, the file may be converted to HTML and written into the
empty blob associated with the revision. This is done with the
<kbd>to_html</kbd> procedure in the <kbd>content_revision</kbd>
package:</p>
<pre>
begin
  content_revision.to_html(:revision_id);
end;
/
</pre>
<p>Once the transaction is committed, the uploaded document is
automatically deleted from the <kbd>cr_doc_filter</kbd> table.</p>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<br>

Last Modified: $&zwnj;Id: convert.html,v 1.1.1.1.30.1 2016/06/22 07:40:41
gustafn Exp $
