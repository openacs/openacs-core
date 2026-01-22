<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<form action="package-load-2" method="post">

<p>
Enter a package source to prepare for installation.
You can provide either a URL (HTTP/HTTPS) or an absolute local path.
</p>

<ul>
  <li>
    <strong>APM archive URL</strong>: <code>https://…/package.apm</code>
  </li>
  <li>
    <strong>GitHub repository</strong>:
    <code>https://github.com/OWNER/REPO</code> or
    <code>https://github.com/OWNER/REPO/tree/REF[/path/to/package]</code><br>
    (the selected directory must contain exactly one <code>*.info</code> file)
  </li>
  <li>
    <strong>Local path</strong> (absolute): <code>/path/to/package.apm</code> or <code>/path/to/apm-directory</code>
  </li>
</ul>

<blockquote>
  Source: <input name="source" size="70" placeholder="https://…  or  /absolute/path">
</blockquote>

<p>
<label>
  <input type="checkbox" name="delete" value="1">
  Delete all packages currently in the installation directory.
</label>
</p>

<button type="submit" class="btn btn-default btn-outline-secondary">
  Load package
</button>

</form>
