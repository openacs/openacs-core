<master>
<property name="title">@title;noquote@</property>

<html>
  <body>
  <table border=0 cellspacing=0 cellpadding=3 width="100%">
    <tr>
      <th bgcolor="#ECECEC">Category</th>
      <th bgcolor="#ECECEC">Mode</th>
      <th bgcolor="#ECECEC">View by</th>
    </tr>
    <tr>

      <td> [
      <if @by_category@ eq "">
         <strong> all </strong>
      </if><else>
         <a href="index?stress=@stress@&security_risk=@security_risk@&by_package_key=@by_package_key@&view_by=@view_by@&quiet=@quiet@">all</a>
      </else>
      <multiple name="main_categories">
        |
        <if @by_category@ eq @main_categories.name@>
           <strong> @main_categories.name@ </strong>
        </if><else>
           <a href="index?stress=@stress@&security_risk=@security_risk@&by_package_key=@by_package_key@&view_by=@view_by@&by_category=@main_categories.name@&quiet=@quiet@">@main_categories.name@</a>
        </else>
      </multiple> ]
 <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  View and run only tests in this category (<a
      href="/api-doc/proc-view?proc=aa%5fregister%5fcase">more info</a>)
                </div>

<p><if @stress@ eq 1>                
      <a href="index?stress=0&security_risk=@security_risk@&by_package_key=@by_package_key@&view_by=@view_by@&by_category=@by_category@&quiet=0" style="padding-top: 2px; padding-bottom: -2px;">
        <img src="/resources/acs-subsite/checkboxchecked.gif" border="0" height="13" width="13"/>
      </a>
    </if>
    <else>
      <a href="index?stress=1&security_risk=@security_risk@&by_package_key=@by_package_key@&view_by=@view_by@&by_category=@by_category@&quiet=0" style="padding: 0px;">
        <img src="/resources/acs-subsite/checkbox.gif" border="0" height="13" width="13"/>
      </a>
      </button>
    </else>
    Include Stress tests
</p>
<p><if @security_risk@ eq 1>                
      <a href="index?stress=@stress@&security_risk=0&by_package_key=@by_package_key@&view_by=@view_by@&by_category=@by_category@&quiet=0" style="padding-top: 2px; padding-bottom: -2px;">
        <img src="/resources/acs-subsite/checkboxchecked.gif" border="0" height="13" width="13"/>
      </a>
    </if>
    <else>
      <a href="index?stress=@stress@&security_risk=1&by_package_key=@by_package_key@&view_by=@view_by@&by_category=@by_category@&quiet=0" style="padding: 0px;">
        <img src="/resources/acs-subsite/checkbox.gif" border="0" height="13" width="13"/>
      </a>
      </button>
    </else>
    Include tests that may compromise security
</p>
    </td>

    <td align=center valign="top"> [
      <if @quiet@ eq "1">
         <strong> quiet </strong> | 
         <a href="index?stress=@stress@&security_risk=@security_risk@&by_package_key=@by_package_key@&view_by=@view_by@&by_category=@by_category@&quiet=0">verbose</a>
      </if><else>
         <a href="index?stress=@stress@&security_risk=@security_risk@&by_package_key=@by_package_key@&view_by=@view_by@&by_category=@by_category@&quiet=1">quiet</a>
         | <strong> verbose </strong>
      </else>  ]
 <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  Quiet mode shows only test failures.
                </div>
    </td>

    <td align=center valign="top"> [
      <if @view_by@ eq "" or @view_by@ eq "package">
         <strong> package </strong> | 
         <a href="index?stress=@stress@&security_risk=@security_risk@&by_package_key=@by_package_key@&view_by=testcase&by_category=@by_category@&quiet=@quiet@">testcase</a>
      </if><else>
         <a href="index?stress=@stress@&security_risk=@security_risk@&view_by=package&by_category=@by_category@&quiet=@quiet@">package</a>
         | <strong> testcase </strong>
      </else>  ]
    </td>

    </tr>
  </table>

  <blockquote>
    <b>&raquo;</b>
    <a href="rerun?package_key=@by_package_key@&category=@by_category@&view_by=@view_by@&quiet=@quiet@&stress=@stress@&security_risk=@security_risk@"> Rerun displayed test cases</a>
    <br>
    <b>&raquo;</b>
    <a href="clear?package_key=@by_package_key@&category=@by_category@&view_by=@view_by@&quiet=@quiet@&stress=@stress@&security_risk=@security_risk@"> Clear test result data</a> </li>
  </blockquote>

  <if @view_by@ eq "package">
    <table width="100%">
    <tr>
        <th bgcolor=#c0c0c0>Package key</th>
        <th bgcolor=#c0c0c0>Total run testcases</th>
        <th bgcolor=#c0c0c0>Passes</th>
        <th bgcolor=#c0c0c0>Fails</th>
        <th bgcolor=#c0c0c0>Result</th>
    </tr>
    <multiple name="packageinfo">
      <tr>
        <td> <a href="index?stress=@stress@&security_risk=@security_risk@&by_package_key=@packageinfo.key@&view_by=testcase&quiet=@quiet@">@packageinfo.key@</a></td>
        <if @packageinfo.total@ eq "0">
          <td> No Data </td><td>-</td><td>-</td>
          <td>
              <font color=#ff0000> fail </font>
          </td>
        </if><else>
          <td> @packageinfo.total@ </td>
          <td> @packageinfo.passes@ </td>
          <td> @packageinfo.fails@ </td>
          <td>
            <if @packageinfo.fails@ gt 0>
               <span style="background-color: red; color: white; font-weight: bold;">FAILED</span>
            </if><else>
              OK
            </else>
          </td>
        </else>
      </tr>
    </multiple>
    </table>
  </if><else>
    <table width="100%">
    <tr>
        <th bgcolor=#c0c0c0>Package key</th>
        <th bgcolor=#c0c0c0>Testcase id</th>
        <th bgcolor=#c0c0c0>Categories</th>
        <th bgcolor=#c0c0c0>Description</th>
        <th bgcolor=#c0c0c0>Result</th>
        <th bgcolor=#c0c0c0>Timestamp</th>
        <th bgcolor=#c0c0c0>Passes</th>
        <th bgcolor=#c0c0c0>Fails</th>
    </tr>
    <multiple name="tests">
      <if @tests.marker@ eq 1>
        <tr><td colspan=8 align=centre bgcolor=#f0f0f0><strong>@tests.package_key@</strong></td></tr>
      </if>
      <tr valign=top>
        <td> @tests.package_key@ </td>
        <td> <a href="testcase?testcase_id=@tests.id@&package_key=@tests.package_key@&view_by=@view_by@&category=@by_category@&quiet=@quiet@">@tests.id@</a></td>
        <td> @tests.categories@ </td>
        <td> @tests.description@ </td>
        <if @tests.timestamp@ eq "">
          <td> No Data </td><td>-</td><td>-</td>
          <td>
              <font color=#ff0000> fail </font>
          </td>
        </if><else>
          <td>
            <if @tests.fails@ gt 0>
               <span style="background-color: red; color: white; font-weight: bold; padding: 4px;">FAILED</span>
            </if><else>
              OK
            </else>
          </td>
          <td> @tests.timestamp@ </td>
          <td> @tests.passes@ </td>
          <td> @tests.fails@ </td>
        </else>
      </tr>
    </multiple>
    </table>
  </else>

  <blockquote>
    <b>&raquo;</b>
    <a href="rerun?package_key=@by_package_key@&category=@by_category@&view_by=@view_by@&quiet=@quiet@&stress=@stress@&security_risk=@security_risk@"> Rerun displayed test cases</a>
    <br>
    <b>&raquo;</b>
    <a href="clear?package_key=@by_package_key@&category=@by_category@&view_by=@view_by@&quiet=@quiet@&stress=@stress@&security_risk=@security_risk@"> Clear test result data</a> </li>
  </blockquote>

  </body>
</html>
