<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>
<property name="javascript">@javascript;noquote@</property>

<small>
<b>@head;noquote@</b>

<listtemplate name="nodes"></listtemplate>

<b>&raquo;</b><a href="application-new">Create new application</a><br>
<b>&raquo;</b><a href="unmounted">Manage unmounted applications</a><br>
<b>&raquo;</b><a href="site-map">Build Site Map</a>

<h2>Services</h2>
<ul>@services;noquote@</ul>

<h2>Site Map Instructions</h2>

<ul>
<li>To <strong>add an application</strong> to this site, use <em>new sub
folder</em> to create a new site node beneath under the selected
folder.  Then choose <em>new application</em> to select an installed
application package for instantiation.  The application will then be
available at the displayed URL.

<li>To <strong>configure</strong> an application select <em>set
parameters</em> to view and edit application specific options.
<em>set permissions</em> allows one to grant privileges to users and
groups to specific application instances or other application data.
For more info on parameters and permissions, see the package specific
documentation.

<li>To <strong>copy</strong> an application instance to another URL,
create a new folder as above, then select <em>mount</em>.  Select
the application to be copied from the list of available packages.

<li>To <strong>move</strong> an application,
copy it as above to the new location, then select
<em>unmount</em> at the old location.  Selecting <em>delete</em> on
the empty folder will remove it from the site node.

<li>To <strong>remove</strong> an application and all of its data, select
<em>unmount</em> from all the site nodes it is mounted from, then
<em>delete</em> it from the <em>Unmounted Applications</em> link below
the site map.
</ul>
</small>
