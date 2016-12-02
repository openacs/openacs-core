<master>
<property name="doc(title)">@title;literal@</property>
  <table border="0" cellspacing="0" cellpadding="3" width="100%">
    <tr>
      <th style="background-color:#ECECEC">Category</th>
      <th style="background-color:#ECECEC">Mode</th>
      <th style="background-color:#ECECEC">View by</th>
    </tr>
    <tr>

      <td> [
      <if @by_category@ eq "">
         <strong> all </strong>
      </if><else>
         <a href="index?stress=@stress@&amp;security_risk=@security_risk@&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;quiet=@quiet@">all</a>
      </else>
      <multiple name="main_categories">
        |
        <if @by_category@ eq @main_categories.name@>
           <strong> @main_categories.name@ </strong>
        </if><else>
           <a href="index?stress=@stress@&amp;security_risk=@security_risk@&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@main_categories.name@&amp;quiet=@quiet@">@main_categories.name@</a>
        </else>
      </multiple> ]
 <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" style="border:0">
                  View and run only tests in this category.  Tests can
      have more than one category.  (<a
      href="/api-doc/proc-view?proc=aa%5fregister%5fcase">more info</a>)
                </div>

<p><if @stress@ eq 1>                
      <a href="index?stress=0&amp;security_risk=@security_risk@&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@by_category@&amp;quiet=0" style="padding-top: 2px; padding-bottom: -2px;">
        <img src="/resources/acs-subsite/checkboxchecked.gif" style="border:0" height="13" width="13">
      </a>
    </if>
    <else>
      <a href="index?stress=1&amp;security_risk=@security_risk@&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@by_category@&amp;quiet=0" style="padding: 0px;">
        <img src="/resources/acs-subsite/checkbox.gif" alt="checkbox" style="border:0" height="13" width="13">
      </a>
    </else>
    Include Stress tests
</p>
<p><if @security_risk@ eq 1>                
      <a href="index?stress=@stress@&amp;security_risk=0&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@by_category@&amp;quiet=0" style="padding-top: 2px; padding-bottom: -2px;">
        <img src="/resources/acs-subsite/checkboxchecked.gif" style="border:0" height="13" width="13">
      </a>
    </if>
    <else>
      <a href="index?stress=@stress@&amp;security_risk=1&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@by_category@&amp;quiet=0" style="padding: 0px;">
        <img src="/resources/acs-subsite/checkbox.gif" alt="checkbox" style="border:0" height="13" width="13">
      </a>
    </else>
    Include tests that may compromise security
</p>
    </td>

    <td align="center" valign="top"> [
      <if @quiet@ eq "1">
         <strong> quiet </strong> | 
         <a href="index?stress=@stress@&amp;security_risk=@security_risk@&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@by_category@&amp;quiet=0">verbose</a>
      </if><else>
         <a href="index?stress=@stress@&amp;security_risk=@security_risk@&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@by_category@&amp;quiet=1">quiet</a>
         | <strong> verbose </strong>
      </else>  ]
 <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" style="border:0">
                  Quiet mode shows only test failures.
                </div>
    </td>

    <td align="center" valign="top"> [
      <if @view_by@ eq "" or @view_by@ eq "package">
         <strong> package </strong> | 
         <a href="index?stress=@stress@&amp;security_risk=@security_risk@&amp;by_package_key=@by_package_key@&amp;view_by=testcase&amp;by_category=@by_category@&amp;quiet=@quiet@">testcase</a>
      </if><else>
         <a href="index?stress=@stress@&amp;security_risk=@security_risk@&amp;view_by=package&amp;by_category=@by_category@&amp;quiet=@quiet@">package</a>
         | <strong> testcase </strong>
      </else>  ]
    </td>

    </tr>
  </table>

  <blockquote>
    <div><strong>&raquo;</strong>
    <a href="rerun?package_key=@by_package_key@&amp;category=@by_category@&amp;view_by=@view_by@&amp;quiet=@quiet@&amp;stress=@stress@&amp;security_risk=@security_risk@"> Rerun displayed test cases</a>
    </div>
    <div>
    <strong>&raquo;</strong>
    <a href="clear?package_key=@by_package_key@&amp;category=@by_category@&amp;view_by=@view_by@&amp;quiet=@quiet@&amp;stress=@stress@&amp;security_risk=@security_risk@"> Clear test result data</a>
    </div>
    <if @by_package_key@ ne "">
      <div>
      <strong>&raquo;</strong>
      <a href="@record_url@"> Record a test</a>
      </div>
    </if>

 </blockquote>
  <if @view_by@ eq "package">
    <table cellpadding="2px">
    <tr style="background-color:#c0c0c0">
        <th>Package key</th>
        <th>Testcases run</th>
        <th>Passes</th>
        <th>Fails</th>
        <th>Result</th>
    </tr>
    <multiple name="packageinfo">
        <if @packageinfo.rownum@ odd>
          <tr class="odd">
        </if>
        <else>
          <tr class="even">
        </else>
        <td> <a href="index?stress=@stress@&amp;security_risk=@security_risk@&amp;by_package_key=@packageinfo.key@&amp;view_by=testcase&amp;quiet=@quiet@">@packageinfo.key@</a></td>
        <if @packageinfo.total@ eq "0">
          <td align="right">No data</td>
          <td align="right">-</td>
          <td align="right">-</td>
          <td align="right">-</td>
        </if><else>
          <td align="right"> @packageinfo.total@ </td>
          <td align="right"> @packageinfo.passes@ </td>
          <td align="right"> @packageinfo.fails@ </td>
          <td align="right">
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
    <tr  style="background-color:#c0c0c0">
        <th>Package key</th>
        <th>Testcase id</th>
        <th>Categories</th>
        <th>Description</th>
        <th>Result</th>
        <th>Timestamp</th>
        <th>Passes</th>
        <th>Fails</th>
    </tr>
    <multiple name="tests">
      <if @tests.marker@ eq 1>
        <tr><td colspan="8" align="center" bgcolor="#c0f0c0"><strong>@tests.package_key@</strong></td></tr>
      </if>
        <if @tests.rownum@ odd>
          <tr class="odd">
        </if>
        <else>
          <tr class="even">
        </else>
        <td> @tests.package_key@ </td>
        <td><a href="@tests.url@">@tests.id@</a></td>
        <td> @tests.categories@ </td>
        <td> @tests.description@ </td>
        <if @tests.timestamp@ eq "">
          <td>No data</td>
          <td>-</td>
          <td align="right">-</td>
          <td align="right">-</td>
        </if><else>
          <td>
            <if @tests.fails@ gt 0>
               <span style="background-color: red; color: white; font-weight: bold; padding: 4px;">FAILED</span>
            </if><else>
              OK
            </else>
          </td>
          <td> @tests.timestamp@ </td>
          <td align="right"> @tests.passes@ </td>
          <td align="right"> @tests.fails@ </td>
        </else>
      </tr>
    </multiple>
    </table>
  </else>

  <blockquote>
    <div>
    <strong>&raquo;</strong>
    <a href="rerun?package_key=@by_package_key@&amp;category=@by_category@&amp;view_by=@view_by@&amp;quiet=@quiet@&amp;stress=@stress@&amp;security_risk=@security_risk@"> Rerun displayed test cases</a>
    </div>
    <div>
    <strong>&raquo;</strong>
    <a href="clear?package_key=@by_package_key@&amp;category=@by_category@&amp;view_by=@view_by@&amp;quiet=@quiet@&amp;stress=@stress@&amp;security_risk=@security_risk@"> Clear test result data</a> 
    </div>
    <if @by_package_key@ ne "">
      <div>
      <strong>&raquo;</strong>
      <a href="@record_url@"> Record a test</a>
      </div>
    </if>
    
  </blockquote>
<p><a href="doc/">Documentation</a>

