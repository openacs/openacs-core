<master>
<property name="title">Congratulations</property>
<property name="focus">@focus@</property>

<table cellspacing="4" cellpadding="4" border="0">
  <tr>
    <td valign="top">

      <p>
      You have successfully installed the 
      <b><a href="http://openacs.org/">OpenACS Community System</a></b>
      version @acs_version@ at @system_name@.
      </p>

      <p>
      Thank you for using our software. Please write to us at the <a
      href="http://openacs.org/forums/forum-view?forum_id=14013">OpenACS discussion forums</a> to let
      us know of your experience with installing and using OpenACS. 
      </p>
      
      <p>
      <if @user_id@ gt 0>
        You are currently logged in as @name@ (<a href="/register/">change
        login</a>).
      </if>
      <else>
        Start by <b>logging in</b> in the box on the right, using the email
        address and password that you have just specified for the
        administrator.
      </else>
      </p>
            
      <h2>How to Customize Your Site</h2>
      
      <p>
      If you want to <b>customize the look</b> of your website, the easiest
      way to start is to edit the template that gets wrapped around every
      page. The master template is the file
      <code>@acs_root_dir@/www/default-master.adp</code>. 
      An ADP file is almost like HTML, except with a few extra bells
      and whistles (<a href="/doc/acs-templating/designer-guide.html"
      title="Templating Designer's Guide">learn more</a>).
      </p>
      

      <p>      
      You almost certainly
      also want to <b>customize this page</b>, your front page. To do that,
      edit the files <code>@acs_root_dir@/www/index.adp</code> and
      <code>@acs_root_dir@/www/index.tcl</code>.
      </p>      

      <h2>How to Add Functionality to Your Site</h2>
      
      <p>
      To <b>download application packages</b> that you can install on
      your system, visit the <a href="http://openacs.org/software/" 
      title="Software Page on openacs.org">OpenACS Software Page</a>. 
      To make them available to users of your site, use the <a
      href="/admin/site-map/" title="The Site Map on your
      server">Sitemap</a>.
      </p>      

      <p>
      To <b>manage the packages on your system</b>, visit the <a href="/acs-admin/apm/"
      title="OpenACS Package Manager on your server">Package Manager</a>
      on your own server. 
      </p>      

      <p>
      If you are using OpenACS to develop a website, please read our 
      <a href="http://openacs.org/contribute">conbribution instructions</a> to learn
      how you can become involved in the OpenACS project.
      If you develop your own OpenACS packages there is a good chance they will be 
      useful to other people in the community and after review they can be included in the OpenACS
      distribution.
      </p>      

      <p>
      For more administrative options, visit <a href="/acs-admin/"
      title="Package and User administration">OpenACS-Administration pages</a> 
      for packages and users, or <a href="/admin/" title="Sitemap and Groups administration">Main site admin pages</a>
      for groups and sitemap.
      </p>
      
      <h2>How to Learn More</h2>
      
      <p>
      Your OpenACS installation comes with <a href="/doc/" 
      title="Documentation Home on your server"><b>documentation</b></a>. When you start
      programming, you will also find the <a href="/api-doc/" 
      title="API Documentation">API documentation</a> useful.
      </p>      

      <p>
      Should you ever <b>get stuck</b>, or if you just want to <b>hang out</b> with other
      OpenACS users, visit the <a href="http://openacs.org/forums/"
      title="OpenACS Discussion Forums">discussion forums</a> on openacs.org, in
      particular the <a
      href="http://openacs.org/forums/forum-view?forum_id=14013"
      title="OpenACS discussion forum on openacs.org">OpenACS forum</a>.
      The home of the <b>OpenACS community</b> is
      at <a href="http://openacs.org/" 
      title="OpenACS Developer Community">http://openacs.org</a>.
      </p>      
      
      <p>
      If you <b>find bugs</b> or have <b>feature requests</b>, post them in
      our <a href="http://openacs.org/bugtracker/openacs/" 
      title="Software Development Manager on openacs.org">Bug
      Tracker</a>. If you have bugfixes or patches
      yourself, post them there as well. 
      </p>
      
      <p> 
      Here are the <b>packages currently available</b> on your
      system:
      </p>

      <ul>
        <multiple name=nodes>
          <li><a href="@nodes.url@">@nodes.name@</a></li>
        </multiple>
      </ul>
      
      <if @name@ not nil>
        If you like, you can go directly to <a href="@home_url@">@name@'s
        @home_url_name@</a>.
      </if> 


    </td>
    <td valign="top">

      <if @user_id@ gt 0>
        <!-- Already logged in -->
      </if>
      <else>
        <table bgcolor="#cccccc" cellpadding="0" cellspacing="0" border="0">
          <tr>
            <td>
              <table cellspacing="1" cellpadding="4" border="0">
                <tr bgcolor="#ccccff">
                  <th>
                    Log in
                  </th>
                </tr>
                <form method="post" action="register/user-login" name="login">
                  <tr bgcolor="#eeeeee">
                    <td>
                      @form_vars@
                      <table>
                      <tr><td>Email:</td><td><input type="text" name="email" value="@email@" /></td></tr>
                      <tr><td>Password:</td><td><input type="password" name="password" /></td></tr>
                      
                      <if @allow_persistent_login_p@ eq 1>
                      <tr><td colspan="2"><input type="checkbox" name="persistent_cookie_p" value="1" @remember_password@ /> 
                      Remember this login
                      (<a href="register/explain-persistent-cookies">help</a>)</td></tr>
                      </if>
                      
                      <tr><td colspan="2" align="center"><input type="submit" value="Log in" /></td></tr>
                      </table>
                    </td>
                  </tr>
                </form>
              </table>
            </td>
          </tr>
        </table>
      </else>

      <p></p>

      <table bgcolor="#cccccc" cellpadding="0" cellspacing="0" border="0" align="right">
        <tr>
          <td>
            <table cellspacing="1" cellpadding="4" border="0">
              <tr bgcolor="#ccccff">
                <th>
                  Quick Links
                </th>
              </tr>
              <tr bgcolor="#eeeeee">
                <td>
                  <a href="/doc/">Documentation</a>
                </td>
              </tr>
              <tr bgcolor="#eeeeee">
                <td>
                  <a href="/api-doc/">API Documentation</a>
                </td>
              </tr>
              <tr bgcolor="#eeeeee">
                <td>
                  <a href="/admin/site-map/">Site map</a>
                </td>
              </tr>
              <tr bgcolor="#eeeeee">
                <td>
                  <a href="/acs-admin/apm/">Package Manager</a>
                </td>
              </tr>
              <tr bgcolor="#eeeeee">
                <td>
                  <a href="/acs-admin/users/">Users</a>
                </td>
              </tr>
              <tr bgcolor="#eeeeee">
                <td>
                  <a href="/admin/groups/">Groups</a>
                </td>
              </tr>
              <tr bgcolor="#eeeeee">
                <td>
                  <a href="/admin/">Main site admin</a>
                </td>
              </tr>
              <tr bgcolor="#eeeeee">
                <td>
                  <a href="/acs-admin/">Site-wide admin</a>
                </td>
              </tr>
              <tr bgcolor="#eeeeee">
                <td>
                  <a href="http://openacs.org/software/">Software Downloads</a>
                </td>
              </tr>
              <tr bgcolor="#eeeeee">
                <td>
                  <a href="http://openacs.org/">Developer Community</a>
                </td>
              </tr>
              <tr bgcolor="#eeeeee">
                <td>
                  <a href="http://openacs.org/forums/forum-view?forum_id=14013">OpenACS forums</a>
                </td>
              </tr>
              <tr bgcolor="#eeeeee">
                <td>
                  <a href="http://openacs.org/forums/">Other bboards</a>
                </td>
              </tr>
             <tr bgcolor="#eeeeee">
                <td>
                  <a href="http://openacs.org/bugtracker/openacs/">Report a bug</a>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
