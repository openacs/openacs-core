ad_library {
    Callback contract definitions for page rendering.

    Typically the callbacks also have a corresponding
    .adp for rendering their output, see the specific callbacks 
    for details.

    @author Jeff Davis (davis@xarg.net)
    @creation-date 2005-03-11
    @cvs-id $Id$
}

ad_proc -public -callback navigation::package_admin {
    -package_id
    -user_id
    {-return_url {}}
} {
    <p>Returns the list of available admin actions for the passed in 
    user on the passed in package_id.</p>
    <pre>
    {
       {LINK url_stub text title_text long_text}
       {SECTION title long_text}
    }
    </pre>
    <p>Where LINK and SECTION are the literal strings.</p>

    <p>For LINK the url and text are required, text and title should be plain text
    but long_text should be html (and renderers should present it noquote).</p>

    <p>For SECTION both title and long_text can be blank which for the
    rendering agent would imply a section break with something like
    blank space or an &lt;hr&gt; tag.  Also keep in mind the rendering
    agent may be creating dropdown menus which would only display the
    link text and title or might be rendering in a page in which case
    all things might be rendered so try to make sure the short "title"
    and "text" fields are not abiguous.  heading should be plain text
    but long_text is treated as html.
    </p>

    <p><b>url_stub</b> should be relative to the package mountpoint
    and without a leading / since the link may be prefixed by the
    full path or by the vhost url depending on context.</p>

    <p>The <code>/packages/acs-tcl/lib/actions.adp<code> file is an include which
    will render admin actions returned by this callback.</p>

    @param package_id - the package for which to generate the admin links
    @param user_id - the user_id for whom the list should be generated
    @param return_url - a return_url provided by the rendering agent 
                        for those actions which could come back

    @return a list with one element, the list of actions
              {{{LINK url_stub text title_text long_text} ... }}

    @see callback::package::admin_actions::impl::forums
    @see /packages/acs-tcl/lib/actions.adp
    @see /packages/acs-tcl/lib/actions.tcl

    @author Jeff Davis (davis@xarg.net)
} -

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
