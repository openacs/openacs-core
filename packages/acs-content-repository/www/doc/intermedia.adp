
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Content Repository: Testing Intermedia}</property>
<property name="doc(title)">Content Repository: Testing Intermedia</property>
<master>
<h2>Testing Intermedia</h2>
<strong><a href="index">Content Repository</a></strong>
<p>Even if you follow the instructions in the <a href="install">installation notes</a>, content searches may
inexplicably fail to work. This document describes how to create a
simple test case independent of the content repository to verify
that Intermedia is indeed functioning properly.</p>
<h3>Create a document table</h3>
<p>Create a simple table to hold some test documents:</p>
<pre>create table cr_test_documents ( 
  doc_id    integer primary key, 
  author    varchar2(30), 
  format    varchar2(30), 
  title     varchar2(256), 
  doc       blob 
);</pre>
<p>Create an Intermedia preference to specify INSO filtering:</p>
<pre>begin
  ctx_ddl.create_preference
  (
    preference_name =&gt; 'CONTENT_FILTER_PREF',
    object_name     =&gt; 'INSO_FILTER'
  );</pre>
<p>If this preference has already been created, this step will
cause an error that you can ignore.</p>
<p>Create an Intermedia index on the test table with INSO
filtering:</p>
<pre>
create index cr_test_documents_idx on cr_test_documents ( doc )
  indextype is ctxsys.context
  parameters ('FILTER content_filter_pref' );</pre>
<h3>Load test documents</h3>
<p>You can use SQL*Loader to load some documents into the test
table. First create a control file named
<kbd>cr-test-docs.ctl</kbd>:</p>
<pre>load data
INFILE 'cr-test-docs.data'
INTO TABLE cr_test_documents
APPEND
FIELDS TERMINATED BY ','
(doc_id SEQUENCE (MAX,1),
 format,
 title,
 ext_fname FILLER CHAR(80),
 doc LOBFILE(ext_fname) TERMINATED BY EOF)</pre>
<p>Copy any number of documents (Microsoft Word, PDF, text, HTML,
etc.) to the file system of your database server. Create a data
file with an entry for each document you would like to load. This
is simply a comma-separated text file:</p>
<pre>word, Simple Story,sample-docs/simple.doc,
excel, Simple Spreadsheet,sample-docs/simple.xls</pre>
<p>Load the documents from the command line:</p>
<pre>
$ sqlldr userid=cms/cms control=cr-test-docs.ctl log=cr-test-docs.log

SQL*Loader: Release 8.1.6.2.0 - Production on Thu Nov 9 13:36:56 2000

(c) Copyright 1999 Oracle Corporation.  All rights reserved.

Commit point reached - logical record count 2</pre>
<h3>Test search</h3>
<p>Once the documents have been loaded, rebuild the index and run
some test queries:</p>
<pre>
SQL&gt; alter index cr_test_documents_index rebuild online parameters ('sync');
SQL&gt; select score(1), doc_id from cr_test_documents 
       where contains(doc, 'cars', 1) &gt; 0;

  SCORE(1)     DOC_ID
---------- ----------
         4          1
</pre>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<br>

Last revised: $&zwnj;Id: intermedia.html,v 1.2 2017/08/07 23:47:47
gustafn Exp $
