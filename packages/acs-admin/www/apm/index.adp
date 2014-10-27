<master>
<property name="doc(title)">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>

<center>
    <table>
        <tr>
            <td>@dimensional_list;noquote@</td>
        </tr>
    </table>
</center>

<h3>Packages</h3>

<table width="100%">
    <tr><td align="right">@reload_filter;noquote@</td</tr>
</table>

<listtemplate name="package_list"></listtemplate>

<ul>
<li><a href="package-add">Create a new package.</a>
<li><a href="write-all-specs">Write new specification files for all installed, locally generated packages.</a>
<li><a href="package-load">Load a new package from a URL or local directory.</a>
<li><a href="packages-install">Install packages.</a>
</ul>

@watches_html;noquote@

<h3>Help</h3>

<blockquote>
A package is <b>enabled</b> if it is scheduled to run at server startup
and is deliverable by the request processor.

<p>If a Tcl library file (<tt>*-procs.tcl</tt>) or query file (<tt>*.xql</tt>) is being
<b>watched</b>, the request processor monitors it, reloading it into running interpreters
whenever it is changed. This is useful during development
(so you don't have to restart the server for your changes to take
effect). To watch a file, click its package key above, click <i>Manage file
information</i> on the next screen, and click <i>watch</i> next to
the file's name on the following screen.
</blockquote>
