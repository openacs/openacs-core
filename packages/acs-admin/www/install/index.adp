<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<h1>@page_title@</h1>

<ul>
<li><h3>Install from Repository</h3>

<p>Download and install/upgrade packages from the <a href="http://openacs.org/repository/">OpenACS.org repository</a>.
<br>When using this option, the existing code of the currently installed packages is moved
away <br>and replaced by the chosen packages from the OpenACS respository.

<p><a href="/acs-admin/@remote_install_url@" class="button">Install</a> or
<a href="/acs-admin/@remote_upgrade_url@" class="button">upgrade</a> from repository.</p>

<li><h3>Install from Local File System</h3>

<p>Install/upgrade packages from the local file system (@local_path@).
<br>Use this if your site has
custom code or your packages are kept in a local code repository.
<a href="/doc/upgrade-openacs-files">Help</a>.</p>

<p><a href="@local_install_url@" class="button">Install</a> or
<a href="@local_upgrade_url@" class="button">upgrade</a> from the local file system.</p>

<li><h3>Install from URL or Local Path</h3>
<p>Load a single package an archive stored an a non-standard place on
your local file system or from an URL.</p>
<p><a href="/acs-admin/apm/package-load" class="button">Load</a> from URL or Local Path</p>
</ul>
<hr>
<h3>Package Manager</h3>
<ul>
<li>
<a href="/acs-admin/apm/">Manage Installed Packages</a>
</li>
</ul>

