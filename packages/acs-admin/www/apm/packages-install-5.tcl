ad_page_contract {

    Kill (restart) the server after package installation.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 27:th of March 2003
    @cvs-id $Id$
}

# This page cannot be templated, because it needs to make AOLserver exit after serving the page.

ReturnHeaders
ns_write "[apm_header  "Server Restart"]

<p>
  The server process has been killed. If your AOLServer is not set up to restart automatically you need to start it
  manually now.
</p>

<p>
  Please wait for your server to get back up, then ...
</p>

<p>
  <b>&raquo;</b> <a href=\"/acs-admin/apm\">Return to the APM index page</a>
</p>

<p>
  <b>&raquo;</b> <a href=\"/admin/site-map/\">Visit the site-map on the main site to mount your packages</a>.
</p>

<p>
  <b>&raquo;</b> <a href=\"/\">Go to the home page</a>.
</p>

[ad_footer]
"

exit
