<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Samples}</property>
<property name="doc(title)">Templating System Samples</property>
<master>
<h2>Samples</h2>
<a href="..">Templating System</a>
 : Demo

As the links reveal, the "Data" files have the extension
<code>.tcl</code>
 and the "Template" files have
<code>.adp</code>
. If you want to see a little behind the scenes,
you can look at the Tcl code into which we compile the template.
The last column will deliver the resulting page to your browser.
<p>Mechanisms underlaid in red are known to not work.</p>
<h3>General</h3>
<a name="hello" id="hello"></a>
<a name="bind" id="bind"></a>
<a name="legacy" id="legacy"></a>
<a name="if" id="if"></a>
<a name="comment" id="comment"></a>
<table cellpadding="6" cellspacing="0" border="1" width="95%">
<tr bgcolor="#CCCCCC">
<th>Description</th><th width="15%">Data</th><th width="15%">Template</th><th width="15%">Compiled<br>
Template</th><th width="15%">Output</th>
</tr><tr>
<td>Simple variable substitution</td><td align="center"><a href="show.tcl?file=hello.tcl">View</a></td><td align="center"><a href="show.tcl?file=hello.adp">View</a></td><td align="center"><a href="compile.tcl?file=hello.adp">View</a></td><td align="center"><a href="hello">View</a></td>
</tr><tr>
<td>Using bind variables in your query</td><td align="center"><a href="show.tcl?file=bind.tcl">View</a></td><td align="center"><a href="show.tcl?file=bind.adp">View</a></td><td align="center"><a href="compile.tcl?file=bind.adp">View</a></td><td align="center"><a href="bind?user_id=1">View</a></td>
</tr><tr>
<td>A plain Tcl page that returns its own output</td><td align="center"><a href="show.tcl?file=legacy.tcl">View</a></td><td align="center">None</td><td align="center">None</td><td align="center"><a href="legacy">View</a></td>
</tr><tr>
<td>Conditional Expressions</td><td align="center"><a href="show.tcl?file=if.tcl">View</a></td><td align="center"><a href="show.tcl?file=if.adp">View</a></td><td align="center"><a href="compile.tcl?file=if.adp">View</a></td><td align="center"><a href="if">View</a></td>
</tr><tr>
<td>Comments</td><td align="center">None</td><td align="center"><a href="show.tcl?file=comment.adp">View</a></td><td align="center"><a href="compile.tcl?file=comment.adp">View</a></td><td align="center"><a href="comment">View</a></td>
</tr>
</table>
<h3>Combining templates</h3>
<a name="include" id="include"></a>
<a name="slave-default" id="slave-default"></a>
<table cellpadding="6" cellspacing="0" border="1" width="95%">
<tr bgcolor="#CCCCCC">
<th rowspan="">Description</th><th width="15%">Data</th><th width="15%">Template</th><th width="15%">Compiled<br>
Template</th><th width="15%">Output</th>
</tr><tr>
<td>Include a template within another template</td><td align="center"><a href="show.tcl?file=include.tcl">View</a></td><td align="center">
<a href="show.tcl?file=include.adp">include</a><br><a href="show.tcl?file=included.adp">included</a>
</td><td align="center">
<a href="compile.tcl?file=include.adp">include</a><br><a href="compile.tcl?file=included.adp">included</a>
</td><td align="center"><a href="include">View</a></td>
</tr><tr>
<td>Wrap a page within a master template</td><td align="center">None</td><td align="center">
<a href="show.tcl?file=slave.adp">Slave</a><br><a name="master" id="master"></a><a href="show.tcl?file=master.adp">Master</a>
</td><td align="center">
<a href="compile.tcl?file=slave.adp">Slave</a><br><a href="compile.tcl?file=master.adp">Master</a>
</td><td align="center"><a href="slave">View</a></td>
</tr><tr>
<td>Using the default master</td><td align="center">None</td><td align="center"><a href="show.tcl?file=slave-default.adp">View</a></td><td align="center"><a href="compile.tcl?file=slave-default.adp">View</a></td><td align="center"><a href="slave-default">View</a></td>
</tr><tr>
<td>Include with master and recursion.<br>
Remember Fibonacci from pset 1, exercise 1?</td><td align="center">
<a href="show.tcl?file=fibo-start.tcl">Start</a><br><a name="fibo" id="fibo"></a><a href="show.tcl?file=fibo.tcl">Included</a><br><a href="show.tcl?file=fibo-master.tcl">Master</a>
</td><td align="center">
<a href="show.tcl?file=fibo-start.adp">Start</a><br><a href="show.tcl?file=fibo.adp">Included</a><br><a href="show.tcl?file=fibo-master.adp">Master</a>
</td><td align="center">
<a href="compile.tcl?file=fibo-start.adp">Start</a><br><a href="compile.tcl?file=fibo.adp">Included</a><br><a href="compile.tcl?file=fibo-master.adp">Master</a>
</td><td align="center"><a href="fibo-start?m=7">View</a></td>
</tr>
</table>
<h3>Embedded Tcl</h3>
<a name="implicit_escape" id="implicit_escape"></a>
<a name="explicit_escape" id="explicit_escape"></a>
<a name="embed_escape" id="embed_escape"></a>
<a name="puts" id="puts"></a>
<table cellpadding="6" cellspacing="0" border="1" width="95%">
<tr bgcolor="#CCCCCC">
<th>Description</th><th width="15%">Data</th><th width="15%">Template</th><th width="15%">Compiled<br>
Template</th><th width="15%">Output</th>
</tr><tr>
<td>Tcl escape with implicit output</td><td align="center"><a href="show.tcl?file=implicit_escape.tcl">View</a></td><td align="center"><a href="show.tcl?file=implicit_escape.adp">View</a></td><td align="center"><a href="compile.tcl?file=implicit_escape.adp">View</a></td><td align="center"><a href="implicit_escape">View</a></td>
</tr><tr>
<td>Tcl escape with explicit output</td><td align="center">None</td><td align="center"><a href="show.tcl?file=explicit_escape.adp">View</a></td><td align="center"><a href="compile.tcl?file=explicit_escape.adp">View</a></td><td align="center"><a href="explicit_escape">View</a></td>
</tr><tr>
<td>Template chunks within escaped Tcl code blocks</td><td align="center"><a href="show.tcl?file=embed_escape.tcl">View</a></td><td align="center"><a href="show.tcl?file=embed_escape.adp">View</a></td><td align="center"><a href="compile.tcl?file=embed_escape.adp">View</a></td><td align="center"><a href="embed_escape">View</a></td>
</tr><tr>
<td>Puts (if you absolutely must)</td><td align="center"><a href="show.tcl?file=puts.tcl">View</a></td><td align="center"><a href="show.tcl?file=puts.adp">View</a></td><td align="center"><a href="compile.tcl?file=puts.adp">View</a></td><td align="center"><a href="puts">View</a></td>
</tr>
</table>
<h3>Iteration</h3>

To see the following examples with different data, you can enter
additional users into the sample table with "a simple
form" or change them with "editing: several pages in
one" in section <a href="#formmgr">Using the Form Manager</a>

below. <a name="multiple" id="multiple"></a>
<a name="multirow" id="multirow"></a>
<a name="multiaccess" id="multiaccess"></a>
<a name="grid" id="grid"></a>
<a name="list" id="list"></a>
<table cellpadding="6" cellspacing="0" border="1" width="95%">
<tr bgcolor="#CCCCCC">
<th>Description</th><th width="15%">Data</th><th width="15%">Template</th><th width="15%">Compiled<br>
Template</th><th width="15%">Output</th>
</tr><tr>
<td>Repeating template chunks for each row of a query result</td><td align="center"><a href="show.tcl?file=multiple.tcl">View</a></td><td align="center"><a href="show.tcl?file=multiple.adp">View</a></td><td align="center"><a href="compile.tcl?file=multiple.adp">View</a></td><td align="center"><a href="multiple">View</a></td>
</tr><tr>
<td>Generating the multirow datasource in TCL</td><td align="center"><a href="show.tcl?file=multirow.tcl">View</a></td><td align="center"><a href="show.tcl?file=multirow.adp">View</a></td><td align="center"><a href="compile.tcl?file=multirow.adp">View</a></td><td align="center"><a href="multirow">View</a></td>
</tr><tr>
<td>Repeating template chunks for each row of a query result, with
custom manipulation of data</td><td align="center"><a href="show.tcl?file=multiaccess.tcl">View</a></td><td align="center"><a href="show.tcl?file=multiaccess.adp">View</a></td><td align="center"><a href="compile.tcl?file=multiaccess.adp">View</a></td><td align="center"><a href="multiaccess">View</a></td>
</tr><tr>
<td>Repeating template chunks with grouping <a name="group" id="group"></a>
</td><td align="center"><a href="show.tcl?file=group.tcl">View</a></td><td align="center"><a href="show.tcl?file=group.adp">View</a></td><td align="center"><a href="compile.tcl?file=group.adp">View</a></td><td align="center"><a href="group">View</a></td>
</tr><tr>
<td>Repeating template chunks as cells of a grid</td><td align="center"><a href="show.tcl?file=grid.tcl">View</a></td><td align="center"><a href="show.tcl?file=grid.adp">View</a></td><td align="center"><a href="compile.tcl?file=grid.adp">View</a></td><td align="center"><a href="grid">View</a></td>
</tr><tr>
<td>Repeating template chunks for each element of a list</td><td align="center"><a href="show.tcl?file=list.tcl">View</a></td><td align="center"><a href="show.tcl?file=list.adp">View</a></td><td align="center"><a href="compile.tcl?file=list.adp">View</a></td><td align="center"><a href="list">View</a></td>
</tr>
</table>
<h3>Both Iteration and Composition</h3>
<a name="skin" id="skin"></a>
<a name="reference" id="reference"></a>
<a name="string" id="string"></a>
<table cellpadding="6" cellspacing="0" border="1" width="95%">
<tr bgcolor="#CCCCCC">
<th>Description</th><th width="15%">Data</th><th width="15%">Template</th><th width="15%">Compiled<br>
Template</th><th width="15%">Output</th>
</tr><tr>
<td>Apply different skins to the same data</td><td align="center"><a href="show.tcl?file=skin.tcl">View</a></td><td align="center">
<a href="show.tcl?file=skin-plain.adp">Plain</a><br><a href="show.tcl?file=skin-fancy.adp">Fancy</a>
</td><td align="center">
<a href="compile.tcl?file=skin-plain.adp">Plain</a><br><a href="compile.tcl?file=skin-fancy.adp">Fancy</a>
</td><td align="center">
<a href="skin?skin=plain">Plain</a><br><a href="skin?skin=fancy">Fancy</a><br><a href="skin?skin=neither">Absolute</a>
</td>
</tr><tr>
<td>Passing a multirow datasource to an included page</td><td align="center"><a href="show.tcl?file=reference.tcl">View</a></td><td align="center">
<a href="show.tcl?file=reference.adp">Outer</a><br><a href="show.tcl?file=reference-inc.adp">Included</a>
</td><td align="center">
<a href="compile.tcl?file=reference.adp">Outer</a><br><a href="compile.tcl?file=reference-inc.adp">Included</a>
</td><td align="center"><a href="reference">View</a></td>
</tr><tr>
<td>Processing a template from a string (not file)</td><td align="center"><a href="show.tcl?file=string.tcl">View</a></td><td align="center"><a href="show.tcl?file=string.adp">View</a></td><td align="center"><a href="compile.tcl?file=string.adp">View</a></td><td align="center"><a href="string">View</a></td>
</tr>
</table>
<h3>Using ListBuilder</h3>
<a name="listbuilder" id="listbuilder"></a>
<a name="string" id="string"></a>
<a name="string" id="string"></a>
<a name="string" id="string"></a>
<a name="string" id="string"></a>
<a name="string" id="string"></a>
<a name="string" id="string"></a>
<a name="string" id="string"></a>
<a name="string" id="string"></a>
<a name="string" id="string"></a>
<table cellpadding="6" cellspacing="0" border="1" width="95%">
<tr bgcolor="#CCCCCC">
<th>Description</th><th width="15%">Data</th><th width="15%">Template</th><th width="15%">Compiled<br>
Template</th><th width="15%">Output</th>
</tr><tr>
<td>Simplest (single-column) list, no features</td><td align="center">
<a href="show.tcl?file=list1a/index.tcl">View
.tcl</a><br><a href="show.tcl?file=list1a/index-postgresql.xql">postgres
query</a><br><a href="show.tcl?file=list1a/index-oracle.xql">oracle
query</a>
</td><td align="center">
<a href="show.tcl?file=list1b/index.adp">No
master</a><br><a href="show.tcl?file=list1a/index.adp">W/ master</a>
</td><td align="center">
<a href="compile.tcl?file=list1b/index.adp">No
master</a><br><a href="compile.tcl?file=list1a/index.adp">W/ master</a>
</td><td align="center">
<a href="list1b">No master</a><br><a href="list1a">W/ master</a>
</td>
</tr><tr>
<td>Add some columns</td><td align="center">
<a href="show.tcl?file=list2/index.tcl">View
.tcl</a><br><a href="show.tcl?file=list2/index-postgresql.xql">postgres
query</a><br><a href="show.tcl?file=list2/index-oracle.xql">oracle
query</a>
</td><td align="center"><a href="show.tcl?file=list2/index.adp">View</a></td><td align="center"><a href="compile.tcl?file=list2/index.adp">View</a></td><td align="center"><a href="list2">View</a></td>
</tr><tr>
<td>Add the ability to sort by any column</td><td align="center">
<a href="show.tcl?file=list3/index.tcl">View
.tcl</a><br><a href="show.tcl?file=list3/index-postgresql.xql">postgres
query</a><br><a href="show.tcl?file=list3/index-oracle.xql">oracle
query</a>
</td><td align="center"><a href="show.tcl?file=list3/index.adp">View</a></td><td align="center"><a href="compile.tcl?file=list3/index.adp">View</a></td><td align="center"><a href="list3">View</a></td>
</tr><tr>
<td>Link the title to a one-note detail page</td><td align="center">
<a href="show.tcl?file=list4/index.tcl">index</a><br><a href="show.tcl?file=list4/view-one.tcl">detail</a>
</td><td align="center">
<a href="show.tcl?file=list4/index.adp">index</a><br><a href="show.tcl?file=list4/view-one.adp">detail</a>
</td><td align="center">
<a href="compile.tcl?file=list4/index.adp">index</a><br><a href="compile.tcl?file=list4/view-one.adp">detail</a>
</td><td align="center"><a href="list4">View</a></td>
</tr><tr>
<td>Add a bulk action to delete all checked notes</td><td align="center">
<a href="show.tcl?file=list5/index.tcl">index</a><br><a href="show.tcl?file=list5/delete.tcl">delete</a><br><a href="show.tcl?file=list5/delete-postgresql.xql">postgres
query</a><br><a href="show.tcl?file=list5/delete-oracle.xql">oracle
query</a>
</td><td align="center"><a href="show.tcl?file=list5/index.adp">index</a></td><td align="center"><a href="compile.tcl?file=list5/index.adp">index</a></td><td align="center"><a href="list5">View</a></td>
</tr><tr>
<td>Add a single/non-bulk action to create a note</td><td align="center">
<a href="show.tcl?file=list6/index.tcl">index</a><br><a href="show.tcl?file=list6/add-edit.tcl">add-edit</a>
</td><td align="center">
<a href="show.tcl?file=list6/index.adp">index</a><br><a href="show.tcl?file=list6/add-edit.adp">add-edit</a>
</td><td align="center">
<a href="compile.tcl?file=list6/index.adp">index</a><br><a href="compile.tcl?file=list6/add-edit.adp">add-edit</a>
</td><td align="center"><a href="list6">View</a></td>
</tr><tr>
<td>Add a filter</td><td align="center">
<a href="show.tcl?file=list7/index.tcl">index</a><br><a href="show.tcl?file=list7/index-postgresql.xql">postgres
query</a><br><a href="show.tcl?file=list7/index-oracle.xql">oracle
query</a>
</td><td align="center">
<a href="show.tcl?file=list7/index.adp">index</a><br>
</td><td align="center">
<a href="compile.tcl?file=list7/index.adp">index</a><br>
</td><td align="center"><a href="list7">View</a></td>
</tr><tr>
<td>Add pagination with no page group cache</td><td align="center">
<a href="show.tcl?file=list8/index.tcl">index</a><br><a href="show.tcl?file=list8/index-postgresql.xql">postgres
query</a><br><a href="show.tcl?file=list8/index-oracle.xql">oracle
query</a>
</td><td align="center">
<a href="show.tcl?file=list8/index.adp">index</a><br>
</td><td align="center">
<a href="compile.tcl?file=list8/index.adp">index</a><br>
</td><td align="center"><a href="list8">View</a></td>
</tr><tr>
<td>Add page group caching to pagination (no looks difference)</td><td align="center">
<a href="show.tcl?file=list9/index.tcl">index</a><br><a href="show.tcl?file=list9/add-edit.tcl">add-edit</a><br><a href="show.tcl?file=list9/delete.tcl">delete</a><br>
</td><td align="center">
<a href="show.tcl?file=list9/index.adp">index</a><br>
</td><td align="center">
<a href="compile.tcl?file=list9/index.adp">index</a><br>
</td><td align="center"><a href="list9">View</a></td>
</tr>
</table>
<h3>Forms</h3>
<a name="contract" id="contract"></a>
<a name="error" id="error"></a>
<table cellpadding="6" cellspacing="0" border="1" width="95%">
<tr bgcolor="#CCCCCC">
<th>Description</th><th width="15%">Data</th><th width="15%">Template</th><th width="15%">Compiled<br>
Template</th><th width="15%">Output</th>
</tr><tr>
<td>Using ad_page_contract</td><td align="center"><a href="show.tcl?file=contract-2.tcl">Target</a></td><td align="center">
<a href="show.tcl?file=contract.adp">Form</a><br><a href="show.tcl?file=contract-2.adp">Target</a><br><a href="show.tcl?file=contract-err.adp">Error Page</a>
</td><td align="center">
<a href="compile.tcl?file=contract.adp">Form</a><br><a href="compile.tcl?file=contract-2.adp">Target</a><br><a href="compile.tcl?file=contract-err.adp">Error Page</a>
</td><td align="center">
<a href="contract">Form</a><br><a href="contract-2?count=5&amp;noun=racoon">Target</a><br>
 </td>
</tr><tr>
<td>Report an error related to a request.</td><td align="center"><a href="show.tcl?file=error.tcl">View</a></td><td align="center"><a href="show.tcl?file=error.adp">View</a></td><td align="center"><a href="compile.tcl?file=error.adp">Plain</a></td><td align="center"><a href="error">View</a></td>
</tr>
</table>
<h3>Using the Form Manager.</h3>
<a name="formmgr" id="formmgr"></a>
<a name="form" id="form"></a>
<a name="sandwich" id="sandwich"></a>
<a name="select" id="select"></a>
<a name="state" id="state"></a>
<a name="date-test" id="date-test"></a>
<a name="user-edit" id="user-edit"></a>
<a name="pay" id="pay"></a>
<a name="display-edit-form" id="display-edit-form"></a>
<a name="submit-test-form" id="submit-test-form"></a>
<table cellpadding="6" cellspacing="0" border="1" width="95%">
<tr bgcolor="#CCCCCC">
<th>Description</th><th width="15%">Data</th><th width="15%">Template</th><th width="15%">Compiled<br>
Template</th><th width="15%">Output</th>
</tr><tr>
<td>A simple form</td><td align="center"><a href="show.tcl?file=form.tcl">View</a></td><td align="center"><a href="show.tcl?file=form.adp">View</a></td><td align="center"><a href="compile.tcl?file=form.adp">View</a></td><td align="center"><a href="form">View</a></td>
</tr><tr>
<td>A form with button groups</td><td align="center"><a href="show.tcl?file=sandwich.tcl">View</a></td><td align="center">
<a href="show.tcl?file=sandwich.adp">Simple</a><br><a href="show.tcl?file=sandwich-grid.adp">Gridded</a>
</td><td align="center">
<a href="compile.tcl?file=sandwich.adp">Simple</a><br><a href="compile.tcl?file=sandwich-grid.adp">Gridded</a>
</td><td align="center">
<a href="sandwich">Simple</a><br><a href="sandwich?grid=t">Gridded</a>
</td>
</tr><tr>
<td>A form with Select widgets</td><td align="center"><a href="show.tcl?file=select.tcl">View</a></td><td align="center"><a href="show.tcl?file=select.adp">View</a></td><td align="center"><a href="compile.tcl?file=select.adp">View</a></td><td align="center"><a href="select">View</a></td>
</tr><tr>
<td rowspan="3">Custom validation of a request</td><td rowspan="3" align="center"><a href="show.tcl?file=state.tcl">View</a></td><td rowspan="3" align="center"><a href="show.tcl?file=state.adp">View</a></td><td rowspan="3" align="center"><a href="compile.tcl?file=state.adp">View</a></td><td align="center"><a href="state?state_abbrev=UI">Inline Error
Message</a></td>
</tr><tr><td align="center"><a href="state?state_abbrev=UI&amp;errorpage">Sitewide Error Page</a></td></tr><tr><td align="center"><a href="state?state_abbrev=CA">Valid
Request</a></td></tr><tr>
<td>A form with the Date widget</td><td align="center"><a href="show.tcl?file=date-test.tcl">View</a></td><td align="center"><a href="show.tcl?file=date-test.adp">View</a></td><td align="center"><a href="compile.tcl?file=date-test.adp">View</a></td><td align="center"><a href="date-test">View</a></td>
</tr><tr>
<td>Editing: several pages in one</td><td align="center"><a href="show.tcl?file=user-edit.tcl">View</a></td><td align="center"><a href="show.tcl?file=user-edit.adp">View</a></td><td align="center"><a href="compile.tcl?file=user-edit.adp">View</a></td><td align="center"><a href="user-edit">View</a></td>
</tr><tr>
<td>A form with a custom confirmation page</td><td align="center"><a href="show.tcl?file=pay.tcl">View</a></td><td align="center">
<a href="show.tcl?file=pay.adp">Submit</a><br><a href="show.tcl?file=pay-confirm.adp">Confirm</a>
</td><td align="center">
<a href="compile.tcl?file=pay.adp">Submit</a><br><a href="compile.tcl?file=pay-confirm.adp">Confirm</a>
</td><td align="center"><a href="pay">View</a></td>
</tr><tr>
<td>A form with display/edit modes</td><td align="center"><a href="show.tcl?file=display-edit.tcl">View</a></td><td align="center"><a href="show.tcl?file=display-edit.adp">View</a></td><td align="center"><a href="compile.tcl?file=display-edit.adp">View</a></td><td align="center"><a href="display-edit">View</a></td>
</tr><tr>
<td>A form with multiple submit buttons</td><td align="center"><a href="show.tcl?file=submit-test.tcl">View</a></td><td align="center"><a href="show.tcl?file=submit-test.adp">View</a></td><td align="center"><a href="compile.tcl?file=submit-test.adp">View</a></td><td align="center"><a href="submit-test">View</a></td>
</tr>
</table>
<br>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->
