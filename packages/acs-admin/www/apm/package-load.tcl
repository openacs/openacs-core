ad_page_contract {
    Loads a package from a URL into the package manager.
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date September 1 2000
    @cvs-id $Id$
} {
}

doc_body_append "[apm_header -form "action=package-load-2" "Load a New Package"]
<p>
You can retrieve a package archive to prepare for installation by using
one of the options below.  
Otherwise, please specify a filesystem location for the packages you want to install.
You can also copy the extracted package files directly into the <code>[acs_root_dir]/packages/</code> directory if you prefer.
<p>
"

doc_body_append "
    Load a package from the <tt>.apm</tt> file at this URL:

    <blockquote>http:// <input name=url size=50></blockquote><p>
    "

doc_body_append "
Specify a local path including a filename for the APM file or a directory containing several APM files.<p>
<blockquote>Path: <input name=file_path size=50></blockquote>

<p>
<input type=checkbox name=delete value=1>Check this box if you want to delete all of the packages
currently in the installation directory.<p>
<center><input type=submit value=Load></blockquote></center>

[ad_footer]
"

