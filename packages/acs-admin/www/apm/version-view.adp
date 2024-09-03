<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<if @version_upgrade_href@ not nil>
  <p>You may <a href="@version_upgrade_href@">upgrade to this version now</a>.</p>
</if>
<if @prompt_text@ not nil>
  @prompt_text;noquote@
</if>


<h3>Package Information</h3>

<blockquote>
<table>
  <tr valign="baseline"><th align="left">Package Name:</th><td>@pretty_name@</td></tr>
  <tr valign="baseline"><th align="left">Version:</th><td>@version_name@</td></tr>
  <tr valign="baseline"><th align="left">OpenACS Core:</th><td>@initial_install_p_text@</td></tr>
  <tr valign="baseline"><th align="left">Singleton:</th><td>@singleton_p_text@</td></tr>
  <tr valign="baseline"><th align="left">Implements Subsite:</th><td>@implements_subsite_p_text@</td></tr>
  <tr valign="baseline"><th align="left">Inherit Templates:</th><td>@inherit_templates_p_text@</td></tr>
  <tr valign="baseline"><th align="left">Auto-mount:</th><td>@auto_mount@</td></tr>
  <tr valign="baseline"><th align="left">Status:</th><td>@status@</td></tr>
  <tr valign="baseline"><th align="left">Data Model:</th><td>@data_model_status@</td></tr>

  <tr valign="baseline"><th align="left">Database Support:</th><td>@supported_databases@</td></tr>
  <tr valign="baseline"><th align="left">CVS:</th><td>@cvs_status@</td></tr>
  <tr valign="baseline"><th align="left"><if @nr_owners eq 1>Owner</if><else>Owners</else>:</th>
     <td>@owners_text;noquote@</td></tr>
  <tr valign="baseline"><th align="left">Package Key:</th><td>@package_key@</td></tr>
  <tr valign="baseline"><th align="left">Summary:</th><td>@summary@</td></tr>
  <tr valign="baseline"><th align="left">Description:</th><td>@description@</td></tr>
  <tr valign="baseline"><th align="left">Release Date:</th><td>@release_date@</td></tr>
  <if @attribute_text@ not nil>@attribute_text;noquote@</if>
  
  <tr valign="baseline"><th align="left">Vendor:</th><td>@vendorHTML;noquote@</td></tr>
  <tr valign="baseline"><th align="left">Package URL:</th><td><a href="@package_uri@">@package_uri@</a></td></tr>
  <tr valign="baseline"><th align="left">Version URL:</th><td><a href="@version_uri@">@version_uri@</a></td></tr>
  <tr valign="baseline"><th align="left">Distribution File:</th><td>@distributionHTML;noquote@</td></tr>
</table>
</blockquote>
  
<ul class="action-links">
<li><a href="@edit_package_info_href@">Edit above information</a> (Also use this to create a new version)</li>
</ul>

<h4>Manage</h4>

<ul class="action-links">
  <li><a href="@version_files_href@">Files</a></li>
  <li><a href="@version_dependency_href@">Dependencies and Provides</a></li>
  <li><a href="@version_parameters_href@">Parameters <adp:icon name="cog"></a></li>
  <if @sitewide_admin_href@ not nil><li><a href="@sitewide_admin_href@">Sitewide Admin <adp:icon name="admin"></a></li></if>
  <li><a href="@version_callbacks_href@">Tcl Callbacks (install, instantiate, mount)</a></li>
  <li><a href="@i18_href@">Internationalization</a></li>
  <li>@instancesHTML;noquote@</li>
  @instance_createHTML;noquote@
</ul>

<h4>Update Blueprint</h4>

<ul class="action-links">
  <li><a href="@reload_href;noi18n@">Reload this package <adp:icon name="reload" alt="reload"></a></li>
  <li><a href="@watch_href;noi18n@">Watch all files in package <adp:icon name="watch" alt="reload"></a></li>
</ul>

<h4>XML .info package specification file</h4>

<ul class="action-links">
  <li><a href="@version_generate_href@">Display an XML package specification file for this version</a></li>
  <if @version_write_href@ not nil><li><a href="@version_write_href@">Write
        an XML package specification to the <tt>packages/@package_key@/@package_key@.info</tt> file</a></li>
  </if>
  <if @generate_tarball_href@ not nil><li><a href="@generate_tarball_href@">Generate
        a distribution file for this package from the filesystem</a></li>
  </if>
</ul>

<h4>Disable/Uninstall</h4>

<ul class="action-links">
  <if @version_disable_href@ not nil><li><a href="@version_disable_href@">Disable
        this version of the package</a></li>
  </if>
  <if @version_enable_href@ not nil><li><a href="@version_enable_href@">Enable
        this version of the package</a></li>
  </if>
  <if @package_delete_href@ not nil><li><a href="@package_delete_href@">Uninstall
        this package from your system</a> (be very careful!)</li>
  </if>
</ul>
           

