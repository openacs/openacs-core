<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>


<if @callbacks:rowcount@ gt 0>
  <table cellspacing="1" cellpadding="4" bgcolor="#999999">
    <tr bgcolor="#ffffff">
      <th>Type</th>
      <th>Tcl Proc</th>
      <th>Action</th>
    </tr>
    <multiple name="callbacks">
      <tr bgcolor="#ffffff">
        <td>@callbacks.type@</td>
        <td><code>@callbacks.proc@</code></td>
        <td>
          <a href="version-callback-add-edit?version_id=@version_id@&type=@callbacks.type@">Edit</a> 
          <a href="version-callback-delete?version_id=@version_id@&type=@callbacks.type@">Delete</a>
        </td>
      </tr>
    </multiple>
  </table>
</if>
<else>
  <i>There are no Tcl callbacks defined for the package.</i>
</else>

<if @unused_types_p@ eq 1>
  <p>
    <b>&raquo;</b> <a href="version-callback-add-edit?version_id=@version_id@">Add callback</a>
  </p>
</if>

<h3>Help</h3>

<p>
  Here's the list of available callbacks and the parameters they will be called with.
</p>

<p>
  For install, uninstall, and upgrade, the before/after part of the
  name refers to before or after the database create/upgrade/drop
  scripts have been run. For mounting and instantiating, well, that should be fairly obvious.
</p>

<p>
  For the upgrade callbacks, you should definitely check out the <a
  href="/api-doc/proc-view?proc=apm%5fupgrade%5flogic">apm_upgrade_logic</a>,
  which makes it very easy to handle the logic of which things to
  process depending on which version you're upgrading from and to.
</p>

<table cellspacing="1" cellpadding="4" bgcolor="#999999">
  <tr bgcolor="white">
    <th>Callback</th>
    <th>Parameters</th>
  </tr>

  <tr bgcolor="white">
    <td>
      before-install
    </td>
    <td>
      
    </td>
  </tr>

  <tr bgcolor="white">
    <td>
      after-install
    </td>
    <td>
      
    </td>
  </tr>

  <tr bgcolor="white">
    <td>
      before-upgrade
    </td>
    <td>
      from_version_name
      to_version_name
    </td>
  </tr>

  <tr bgcolor="white">
    <td>
      after-upgrade
    </td>
    <td>
      from_version_name
      to_version_name
    </td>
  </tr>

  <tr bgcolor="white">
    <td>
      before-uninstall
    </td>
    <td>
      
    </td>
  </tr>

  <tr bgcolor="white">
    <td>
      after-instantiate
    </td>
    <td>
      package_id      
    </td>
  </tr>

  <tr bgcolor="white">
    <td>
      before-uninstantiate
    </td>
    <td>
      package_id
    </td>
  </tr>

  <tr bgcolor="white">
    <td>
      after-mount
    </td>
    <td>
      package_id
      node_id
    </td>
  </tr>

  <tr bgcolor="white">
    <td>
      before-unmount
    </td>
    <td>
      package_id 
      node_id
    </td>
  </tr>

</table>
