<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<h1>@page_title@</h1>
<table style="border: 1px solid gray" border="1" cellspacing="0" cellpadding="3">
  <tr>
    <th>From Repository</th>
    <th>Local Files</th>
  </tr>
  <tr>
    <td>Download and install/upgrade automatically from <a href="http://openacs.org/repository/">OpenACS.org repository</a>
    </td>
    <td>
      Install/upgrade from local files.  Use this if your site has custom code or is in a local CVS repository.  <a href="/doc/upgrade.html">Help</a>
    </td>
  </tr>
  <tr>
    <td>
      <a href="@remote_install_url@">Install from Repository</a>
    </td>
    <td><a href="@local_install_url@">Install from Local</a></td>
  </tr>
  <tr>
    <td>
      <a href="@remote_upgrade_url@">Upgrade from Repository</a>
    </td>
    <td>
      <a href="@local_upgrade_url@">Upgrade from Local</a>
    </td>
  </tr>
</table>

<h2>Installed Packages</h2>

<listfilters name="packages" style="inline-filters"></listfilters>

<listtemplate name="packages"></listtemplate>

