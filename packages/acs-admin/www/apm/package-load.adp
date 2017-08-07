<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<form action='package-load-2' method='post'>

<p>
You can retrieve a package archive to prepare for installation by using
one of the options below.  
Otherwise, please specify a filesystem location for the packages you want to install.
You can also copy the extracted package files directly into the <code>@acs::rootdir@/packages/</code> directory if you prefer.
<p>

Load a package from the <kbd>.apm</kbd> file at this URL:
<blockquote>http:// <input name="url" size="50"></blockquote>
<p>
Specify a local path including a filename for the APM file or a directory containing several APM files.<p>
<blockquote>Path: <input name="file_path" size="50"></blockquote>

<p>
<input type="checkbox" name="delete" value="1">Check this box if you want to delete all of the packages
currently in the installation directory.<p>
<center><input type="submit" value="Load"></blockquote></center>