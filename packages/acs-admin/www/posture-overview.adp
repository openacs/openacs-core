<master>
  <property name="&doc">doc</property>
  <property name="context">@context;literal@</property>

<h1>@doc.title@</h1>

<p>This page gives a quick overview of important security and privacy
relevant configuration information of the OpenACS installation. Some
of these parameters are taken from the used configuration file
<i>@ns_info_config@</i>, and some information is defined via
OpenACS package parameters or the OpenACS permission system.

<p>Please note that this page provides just a quick overview of
the configuration of this site and cannot replace any detailed
vulnerability check.

<ul>
<li>Server is running on a public IP address: @public_ip_addr_p_label@</li>
<li>Reverse proxy setup: @reverse_proxy_setup@</li>
<li>System locale: <a title="Detailed Locale Settings" href='/acs-lang/admin/'>@system_locale@</a></li>
<li>Installed locales: <a title="Detailed Locale Settings" href='/acs-lang/admin/'>@installed_locales@</a></li>
<li>Installed packages: <a title="Package Manager" href='./apm'>@number_of_packages@</a></li>

<li>Does NaviServer version number appear on system pages: @version_numbers_on_result_pages@</li>
<li>Custom reply pages: @custom_server_reply_pages;noquote@</li>
<li>Custom error pages: @custom_error_pages@</li>
</ul>

<h2>Package Parameter Check</h2>
<p>The following subset of security parameters are configured for this system.
The full list of parameters are available from the
<a title="Site-Wide Administration" href="/acs-admin">Site-Wide Administration</a> pages and from the
site map of the defined <a title="Manage Subsites" href="/acs-admin/subsites">subsites</a>.</p>

<table class="table table-sm">
<tr>
  <th>Parameter</th>
  <th>Package</th>
  <th>Value</th>
  <th class='px-2'>Diagnosis</th>
</tr>
<multiple name="parameter_check">
<tr>
  <td>@parameter_check.parameter_name@ <adp:icon title="@parameter_check.description@" name="form-info-sign"></td>
  <td>@parameter_check.package@</td>
  <td><a title="Change Parameter Value" href="@parameter_check.link@"><adp:icon name="cog"> @parameter_check.value@</a></td>
  <td class='px-2'>@parameter_check.diagnosis@</td>
</tr>
</multiple>
</table>

<h2>Permission and Accessibility Check of Mounted Packages</h2>

<p>The following information is collected from requests to
<i>@current_location@/...</i> from a not-logged-in user. The
current location is taken from the request URL of this page.  You
might consider calling this page with a different domain name in the
browser URL.</p>

<p>The following sections list common places which might or might not
reveal information to third parties. The requirements for an internal
development instance are typically different from a public community web
site.  The diagnosis is based on the assumption that there is no
firewall protection of the site.

<table class="table table-sm">
<multiple name="link_check">
<tr class='bg-light'><td colspan='4'><p><h4>URLs revealing potentially @link_check.type@ information</h4></td></tr>
<tr>
  <th>URL</th>
  <th>Status</th>
  <th>Permission Info</th>
  <th class='px-2'>Diagnosis</th>
</tr>
<group column='type'>
<tr>
  <td><a title="View Page" href='@link_check.url@'><adp:icon name="arrow-right-square"> @link_check.url@</a></td>
  <td>@link_check.status@</td>
  <td><a title="See Detailed Permissions" href='/permissions/one?object_id=@link_check.package_id@'>
  <if @link_check.permission_info@ not nil><adp:icon name='permissions'> </if>
  @link_check.permission_info@</a></td>
  <td class='px-2'>@link_check.diagnosis@</td>
</tr>
</group>
</multiple>
</table>

<p>In addition to these common places, please check the details via site
nodes. This site has <i>@numSiteNodesEntries@</i> site node entries.
<if @dbPostgresql_p@ false>Extensive permission checks on site nodes are currently only
permitted under <i>PostgreSQL</i>.</if>
<else>
  <if @numPublicReadableSiteNodes@ not nil>
  <i>@numPublicReadableSiteNodes@</i> packages are mounted with public readable access
  (<a href="@checkPublicURL@">details</a>).
  </if><else>
  The permission query might take some time since this number is higher than the threshold
  of <i>@sitenodeBoundary@</i>. Please check on the page 
  <a href="@checkPublicURL@">installed packages</a> for details.
  This page might take up to several minutes.
  </else>
</else>
</p>

<h2>Machine Readable Information for External Parties</h2>

<table class="table table-sm">
<tr>
  <th>URL</th>
  <th>Status</th>
  <th class='px-2'>Diagnosis</th>
</tr>
<multiple name="machine_readable">
<tr>
  <td><a title="View Page" href='@machine_readable.url@'><adp:icon name="arrow-right-square"> @machine_readable.url@</a></td>
  <td>@machine_readable.status@</td>
  <td class='px-2'>@machine_readable.diagnosis@
  <if @machine_readable.detailURL@ not nil> (Details: <a href="@machine_readable.detailURL@">@machine_readable.detailLabel@</a>)</if>
  </td>
</tr>
</multiple>
</table>


<h2>Response Header Check</h2>

<p>The following subset of security-related response header fields will be returned when the home page of this server is requested:</p>
<table class="table table-sm">
<tr>
  <th class="nowrap">Header Field</th>
  <th>Value</th>
</tr>
<multiple name="hdr_check">
<tr>
  <td class="text-nowrap">@hdr_check.field@</td>
  <td>@hdr_check.value@</td>
</tr>
</multiple>
</table>

<if @ssllabs_url@ not nil>
<p>You might consider testing the security of your HTTPs setup for <i>@host_header@</i>
via the <a title="External Link to SSLlabs" href="@ssllabs_url@">SSL Labs service</a> from Qualys.
</if>


<h2>External Library Check</h2>

<p>The following summary is based on the recommended setup of external
JavaScript libraries (providing a proc with "resource_info"). These
libraries can be used via CDN or a local copy of the library. The CDN
state can be altered via the <a href="/acs-admin/">site-wide admin</a>
pages, included in the links below.

<table class="table table-sm">
<tr>
  <th>Library</th>
  <th class="text-center">Installed Locally</th>
  <th class="text-center">Configured Version</th>
  <th class="text-center">Vulnerability Check</th>
  <th class="text-center">Available Version</th>
  <th>Diagnosis</th>
</tr>
<multiple name="library_check">
<tr>
  <td>@library_check.library@</td>
  <td class="text-center">
    <if @library_check.swa_link@ nil>@library_check.installed_locally@
    </if><else>
      <a title="Admin Pages" href="@library_check.swa_link@"><adp:icon name="admin"> @library_check.installed_locally@</a>
    </else>
  </td>  
  <td class="text-center text-@library_check.version_color@">@library_check.configured_version;literal@</td>
  <td  class="text-center"><if @library_check.vulnerability@ not nil>
    <a href="@library_check.vulnerabilityCheckURL@">
    <if @library_check.vulnerability@ true><span class="text-danger"><adp:icon name="warn"></span></if>
    <else><span class="text-success"><adp:icon name="radio-checked"></span></else>
    </a>
  </if</td>
  <td class="text-center">@library_check.available@</td>
  <td>@library_check.diagnosis@</td>
</tr>
</multiple>
</table>
