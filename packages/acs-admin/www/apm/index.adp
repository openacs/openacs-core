<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>

<div style="margin: 0 auto;">
     @dimensional_list;noquote@
</div>

<h3>Packages</h3>
<div style='text-align: right;'>
  @reload_filter;noquote@
</div>

<listtemplate name="package_list"></listtemplate>

<ul>
<li><a href="package-add">Create a new package.</a>
<li><a href="write-all-specs">Write new specification files for all installed, locally generated packages.</a>
<li><a href="/acs-admin/install/">Install or Upgrade packages.</a>
</ul>

@watches_html;noquote@

<h3>Help</h3>

<blockquote>
<p>A package is <strong>enabled</strong> if it is scheduled to run at server startup
and is deliverable by the request processor.
</p>
<p>If a Tcl library file (<kbd>*-procs.tcl</kbd>) or query file (<kbd>*.xql</kbd>) is being
<strong>watched</strong>, the request processor monitors it, reloading it into running interpreters
whenever it is changed. This is useful during development
(so you don't have to restart the server for your changes to take
effect). To watch a file, click its package key above, click <em>Manage file
information</em> on the next screen, and click <em>watch</em> next to
the file's name on the following screen.
</blockquote>
