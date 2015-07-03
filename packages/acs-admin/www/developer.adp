<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<div style="float: right;">
  <table style="border: 1px solid #cccccc; border-collapse: collapse; background-color: #eeeeee;">
    <tr style="background-color: #ccccff">
          <th>
            Quick Links
          </th>
    </tr>
    <tr>
          <td>
            <a href="http://openacs.org/">Developer Community</a>
          </td>
    </tr>
    <tr>
          <td>
            <a
               href="http://openacs.org/forums/forum-view?forum_id=14013">OpenACS Q&amp;A forum</a>
          </td>
    </tr>
    <tr>
          <td>
            <a href="http://openacs.org/forums/">Other OpenACS forums</a>
          </td>
    </tr>
    <tr>
          <td>
            <a href="http://openacs.org/bugtracker/openacs/">Report a bug</a>
          </td>
    </tr>
  </table>
</div>

<h3>Tools For Developers</h3>

<include src="/packages/acs-admin/lib/developer-services">


      <h3>Configure This Site</h3>

      <p>Thank you for using OpenACS. Please write to us at the <a
      href="http://openacs.org/forums/forum-view?forum_id=14013">OpenACS discussion forums</a> to let
      us know of your experience with installing and using OpenACS. </p>
      
      <ul>
      <li>
	<b>Customize the front page</b>. Edit the files
      <code>@acs::rootdir@/www/index.adp</code> and
      <code>@acs::rootdir@/www/index.tcl</code>.  (<a
      href="/doc/templates.html">More information</a>)
      </li>
      <li>Change the site's overall appearance by <b>editing the master template</b> that wraps every page. The master template is <code>@acs::rootdir@/www/default-master.adp</code>.       An ADP file is almost like HTML, except with a few extra bells
      and whistles (<a href="/doc/acs-templating/designer-guide.html"
      title="Templating Designer's Guide">more information</a>).</li>

      <li><a href="/admin/" title="Package and User
      administration">Site Administration</a>
      <ul>
      <li>Invite <a href="/acs-admin/users/">Users</a> or create <a href="/admin/groups/">Groups</a> (<a href="doc/permissions.html">More information</a>)</li>
      <li><b>Download contributed  packages</b> at the <a href="http://openacs.org/software/" 
      title="Software Page on openacs.org">OpenACS Software Page</a>.</li>
      <li><b>Install packages</b>. In addition to the Core packages,
      which are already installed, OpenACS ships with many Standard
      packages with additional functionality.  Install these packages
      with the <a href="/acs-admin/apm/" title="OpenACS Package Manager on your server">Package Manager</a>.</li>

      <li>Use the <a href="/admin/site-map/" 
      title="The Site Map on your server">Site Map</a> to <b>mount and configure packages</b>. </li>
      </ul>
</ul> 
      
     
      <h3>Learn More</h3>
      <ul>
      <li>OpenACS <a href="/doc/" title="Documentation Home on your
      server"><b>Documentation</b></a> on this server. 
      <li><a href="/api-doc/" 
      title="API Documentation">API documentation</a>.
      </li>
      <li>The home of the <b>OpenACS community</b> is
      at <a href="http://openacs.org/" 
      title="OpenACS Developer Community">http://openacs.org</a>.</li>
      <li>Visit the <a href="http://openacs.org/forums/"
      title="OpenACS Discussion Forums">discussion forums</a> on
      openacs.org, including the <a
      href="http://openacs.org/forums/forum-view?forum_id=14013"
      title="OpenACS discussion forum on openacs.org">OpenACS Q&amp;A
      forum</a>.</li>
      <li>Post <b>bugs</b> and <b>feature requests</b> in the <a href="http://openacs.org/bugtracker/openacs/" 
      title="Software Development Manager on openacs.org">Bug
      Tracker</a>. 
      </li>
      <li>Please read our <a href="http://openacs.org/contribute">contribution instructions</a> to learn how you can become involved in the OpenACS project.
      If you develop your own OpenACS packages there is a good chance they will be useful to other people in the community and after review they can be included in the OpenACS distribution.</li>
      </ul>	
