ad_page_contract {

    Kill (restart) the server after package installation.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 27:th of March 2003
    @cvs-id $Id$
}

ReturnHeaders
ns_write "[apm_header  "Server Restart"]

<p>
  The server process has been killed. If your AOLServer is not set up to restart automatically you need to start it
  manually now.
</p>

<p>
  <a href=\"/acs-admin/apm\">Return to the APM index page</a>
</p>

[ad_footer]
"

exit
