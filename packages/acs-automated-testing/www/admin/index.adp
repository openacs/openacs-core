<master>
<property name="&doc">doc</property>
<property name="context">@context;literal@</property>
  <table class="main-table">
    <tr>
      <th class="main-table-header">Category</th>
      <th class="main-table-header">Mode</th>
      <th class="main-table-header">View by</th>
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
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" class="info-icon">
                  View and run only tests in this category.  Tests can
      have more than one category.  (<a
      href="/api-doc/proc-view?proc=aa%5fregister%5fcase">more info</a>)
                </div>

<p><if @stress;literal@ true>
      <a href="index?stress=0&amp;security_risk=@security_risk@&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@by_category@&amp;quiet=0" class="checkbox-on">
        <img src="/resources/acs-subsite/checkboxchecked.gif" class="checkbox-icon">
      </a>
    </if>
    <else>
      <a href="index?stress=1&amp;security_risk=@security_risk@&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@by_category@&amp;quiet=0" class="checkbox-off">
        <img src="/resources/acs-subsite/checkbox.gif" alt="checkbox" class="checkbox-icon">
      </a>
    </else>
    Include Stress tests
</p>
<p><if @security_risk;literal@ true>
      <a href="index?stress=@stress@&amp;security_risk=0&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@by_category@&amp;quiet=0" class="checkbox-on">
        <img src="/resources/acs-subsite/checkboxchecked.gif" class="checkbox-icon">
      </a>
    </if>
    <else>
      <a href="index?stress=@stress@&amp;security_risk=1&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@by_category@&amp;quiet=0" class="checkbox-off">
        <img src="/resources/acs-subsite/checkbox.gif" alt="checkbox" class="checkbox-icon">
      </a>
    </else>
    Include tests that may compromise security
</p>
    </td>

    <td class="main-table-modes"> [
      <if @quiet;literal@ true>
         <strong> quiet </strong> |
         <a href="index?stress=@stress@&amp;security_risk=@security_risk@&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@by_category@&amp;quiet=0">verbose</a>
      </if><else>
         <a href="index?stress=@stress@&amp;security_risk=@security_risk@&amp;by_package_key=@by_package_key@&amp;view_by=@view_by@&amp;by_category=@by_category@&amp;quiet=1">quiet</a>
         | <strong> verbose </strong>
      </else>  ]
 <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" class="info-icon">
                  Quiet mode shows only test failures.
                </div>
    </td>

    <td class="main-table-modes"> [
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
  <if @view_by@ eq "package">
    <blockquote>
      <div><strong>&raquo;</strong>
        <a href="#" data-action="rerun" class="bulk-action"> Rerun selected test cases</a>
      </div>
      <div>
        <strong>&raquo;</strong>
        <a href="clear?package_key=@by_package_key@&amp;category=@by_category@&amp;view_by=@view_by@&amp;quiet=@quiet@&amp;stress=@stress@&amp;security_risk=@security_risk@"> Clear test result data</a>
      </div>
      <if @by_package_key@ ne "" and @multiple_packages_p@ false>
        <div>
          <strong>&raquo;</strong>
          <a href="@record_url@"> Record a test</a>
        </div>
        <div>
          <strong>&raquo;</strong>
          <a href="@coverage_url@">Coverage of package @by_package_key@</a>
        </div>
      </if>
    </blockquote>
    <form id="bulk-actions-form" action="">
      @bulk_actions_vars;literal@
    <table class="package-table">
    <tr class="package-table-header">
        <th>
          <input data-toggle="true" type="checkbox" checked="true" id="toggle-all"/>
          <script <if @::__csp_nonce@ not nil> nonce="@::__csp_nonce;literal@"</if>>
            document.getElementById('toggle-all').addEventListener('click', function (e) {
                var toggle = this.getAttribute('data-toggle') == 'false' ? 'true' : 'false';
                this.setAttribute('data-toggle', toggle);
                var bulkActions = document.getElementsByName('package_key');
                for (var i = 0; i < bulkActions.length; i++) {
                    bulkActions[i].checked = toggle == 'true';
                }
            });
          </script>
        </th>
        <th>Package key</th>
        <th>Testcases run</th>
        <th>Passes</th>
        <th>Fails</th>
        <th>Warnings</th>
        <th>Result</th>
        <th>Proc coverage</th>
    </tr>
    <multiple name="packageinfo">
        <if @packageinfo.rownum@ odd>
          <tr class="odd">
        </if>
        <else>
          <tr class="even">
        </else>
        <td><input type="checkbox" checked="true" name="package_key" value="@packageinfo.key@"/></td>
        <td> <a href="index?stress=@stress@&amp;security_risk=@security_risk@&amp;by_package_key=@packageinfo.key@&amp;view_by=testcase&amp;quiet=@quiet@">@packageinfo.key@</a></td>
        <if @packageinfo.total;literal@ eq 0>
          <td class="package-table-cell">No data</td>
          <td class="package-table-cell">-</td>
          <td class="package-table-cell">-</td>
          <td class="package-table-cell">-</td>
          <td class="package-table-cell">-</td>
          <td class="proc_coverage_cell @packageinfo.proc_coverage_level@"
              style="background: @packageinfo.background@; color: @packageinfo.foreground@;" >
            <a href=proc-coverage?package_key=@packageinfo.key@>@packageinfo.proc_coverage@%</a></td>
        </if><else>
          <td class="package-table-cell"> @packageinfo.total@ </td>
          <td class="package-table-cell"> @packageinfo.passes@ </td>
          <td class="package-table-cell"> @packageinfo.fails@ </td>
          <td class="package-table-cell"> @packageinfo.warnings@ </td>
          <td class="package-table-cell">
            <if @packageinfo.fails@ gt 0>
               <span class="result-failed">FAILED</span>
            </if>
            <elseif @packageinfo.warnings@ gt 0>
              <span class="result-warning">WARNING</span>
            </elseif>
            <else>
              OK
            </else>
          </td>
          <td class="proc_coverage_cell @packageinfo.proc_coverage_level@"
              style="background: @packageinfo.background@; color: @packageinfo.foreground@;">
          <a href=proc-coverage?package_key=@packageinfo.key@>@packageinfo.proc_coverage@%</a></td>
        </else>
      </tr>
    </multiple>
    <tr>
      <td colspan="8" class="proc_coverage_cell @global_test_coverage_level@"
      style="background: @global_test_coverage_color.background@; color: @global_test_coverage_color.foreground@;">
        <a href=proc-coverage>Global proc coverage: @global_test_coverage_percent@%</a>
      </td>
    </tr>
    </table>
    </form>
    <blockquote>
      <div>
        <strong>&raquo;</strong>
        <a href="#" data-action="rerun" class="bulk-action"> Rerun selected test cases</a>
      </div>
      <div>
        <strong>&raquo;</strong>
        <a href="clear?package_key=@by_package_key@&amp;category=@by_category@&amp;view_by=@view_by@&amp;quiet=@quiet@&amp;stress=@stress@&amp;security_risk=@security_risk@"> Clear test result data</a>
      </div>
      <if @by_package_key@ ne "" and @multiple_packages_p@ false>
        <div>
          <strong>&raquo;</strong>
          <a href="@record_url@"> Record a test</a>
        </div>
        <div>
          <strong>&raquo;</strong>
          <a href="@coverage_url@">Coverage of package @by_package_key@</a>
        </div>
      </if>
    </blockquote>
</if>
<else>
   <blockquote>
     <div><strong>&raquo;</strong>
       <a href="rerun?package_key=@by_package_key@&amp;category=@by_category@&amp;view_by=@view_by@&amp;quiet=@quiet@&amp;stress=@stress@&amp;security_risk=@security_risk@"> Rerun displayed test cases</a>
     </div>
     <div>
       <strong>&raquo;</strong>
       <a href="clear?package_key=@by_package_key@&amp;category=@by_category@&amp;view_by=@view_by@&amp;quiet=@quiet@&amp;stress=@stress@&amp;security_risk=@security_risk@"> Clear test result data</a>
     </div>
     <if @by_package_key@ ne "" and @multiple_packages_p@ false>
       <div>
         <strong>&raquo;</strong>
         <a href="@record_url@"> Record a test</a>
       </div>
       <div>
          <strong>&raquo;</strong>
          <a href="@coverage_url@">Coverage of package @by_package_key@</a>
       </div>       
     </if>
   </blockquote>
    <table width="100%">
    <tr class="package-table-header">
        <th>Package key</th>
        <th>Testcase id</th>
        <th>Categories</th>
        <th>Description</th>
        <th>Result</th>
        <th>Timestamp</th>
        <th>Passes</th>
        <th>Fails</th>
        <th>Warnings</th>
    </tr>
    <multiple name="tests">
      <if @tests.marker;literal@ true>
        <tr><td colspan="9" class="package-table-header-package-key"><strong>@tests.package_key@</strong></td></tr>
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
          <td class="package-table-cell">-</td>
          <td class="package-table-cell">-</td>
        </if><else>
          <td>
            <if @tests.fails@ gt 0>
               <span class="result-failed">FAILED</span>
            </if>
            <elseif @tests.warnings@ gt 0>
               <span class="result-warning">WARNING</span>
            </elseif>
            <else>
              OK
            </else>
          </td>
          <td> @tests.timestamp@ </td>
          <td class="package-table-cell"> @tests.passes@ </td>
          <td class="package-table-cell"> @tests.fails@ </td>
          <td class="package-table-cell"> @tests.warnings@ </td>
        </else>
      </tr>
    </multiple>
    </table>
   <blockquote>
     <div><strong>&raquo;</strong>
       <a href="rerun?package_key=@by_package_key@&amp;category=@by_category@&amp;view_by=@view_by@&amp;quiet=@quiet@&amp;stress=@stress@&amp;security_risk=@security_risk@"> Rerun displayed test cases</a>
     </div>
     <div>
       <strong>&raquo;</strong>
       <a href="clear?package_key=@by_package_key@&amp;category=@by_category@&amp;view_by=@view_by@&amp;quiet=@quiet@&amp;stress=@stress@&amp;security_risk=@security_risk@"> Clear test result data</a>
     </div>
     <if @by_package_key@ ne "" and @multiple_packages_p@ false>
       <div>
         <strong>&raquo;</strong>
         <a href="@record_url@"> Record a test</a>
       </div>
       <div>
         <strong>&raquo;</strong>
         <a href="@coverage_url@">Coverage of package @by_package_key@</a>
       </div>
      </if>
   </blockquote>
  </else>

<p><a href="../doc/">Documentation</a>

<script <if @::__csp_nonce@ not nil> nonce="@::__csp_nonce;literal@"</if>>
  var bulkActions = document.getElementsByClassName('bulk-action');
  for (var i = 0; i < bulkActions.length; i++) {
     bulkActions[i].addEventListener('click', function(e) {
        e.preventDefault();
        var form = document.getElementById('bulk-actions-form');
        form.setAttribute('action', this.getAttribute('data-action'));
        form.submit();
     });
  }
</script>
