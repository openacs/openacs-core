<master>
  <property name="&doc">doc</property>
  <property name="context">@context;literal@</property>
  <h1>@doc.title@</h1>
  <div class="description">
    <dl>
      <dt class="description-list">Description:</dt><dd>@testcase_desc@</dd>
      <dt class="description-list">Defined in file:</dt><dd>@testcase_file@</dd>
      <dt class="description-list">Categories:</dt><dd>@testcase_cats@</dd>
      <if @bug_blurb@ not nil>
        <dt class="description-list">Bugs:</dt><dd>This test case covers OpenACS bug number(s):
          @bug_blurb;noquote@</dd>
      </if>
      <if @proc_blurb@ not nil>
        <dt class="description-list">Procs:</dt><dd>This test case covers OpenACS proc(s):
          @proc_blurb;noquote@</dd>
      </if>
      <if @url_blurb@ not nil>
        <dt class="description-list">URLs:</dt><dd>This test case covers the following URLs:
          @url_blurb;noquote@</dd>
      </if>
      <if @testcase_inits@ ne "">
        <dt class="description-list">Initialization Classes:</dt><dd>@testcase_inits@</dd>
      </if>
      <if @fails@ gt 0 and @testcase_on_error@ ne "">
        <dt class="description-list fail">Testcase failure error response:</dt>
        <dd>@testcase_on_error;noquote@</dd>
      </if>
      <if @showsource;literal@ true>
        <multiple name="bodys">
          <if @bodys:rowcount;literal@ lt 2><dt class="description-list">Body:</dt></if>
          <else><dt class="description-list">Body (part @bodys.body_number@)</dt></else>
          <dd><pre class="code">@bodys.body;literal@</pre></dd>
        </multiple>
      </if>
    </dl>
  </div>

  <dl>
      <dt class="description-list">Actions:</dt><dd>
  <ul>
  <li>
  <if @showsource;literal@ false>
      <a href="testcase?testcase_id=@testcase_id@&amp;package_key=@package_key@&amp;showsource=1&amp;quiet=@quiet@">
      Display definition of this test case</a>
  </if>
  <else>
      <a href="testcase?testcase_id=@testcase_id@&amp;package_key=@package_key@&amp;showsource=0&amp;quiet=@quiet@">
      Hide definition of this test case</a>
  </else>
  </li>
    <li><a href="@rerun_url@">Rerun this test case</a></li>
    <li><a href="@return_url@">List all test cases of package @package_key@</a></li>
    <li><a href="@coverage_url@">Coverage of package @package_key@</a></li>    
    <li>
    <strong>Results</strong>
    [<if @quiet;literal@ true>
      <strong> quiet </strong> |
      <a href="@verbose_url@">verbose</a>
    </if><else>
      <a href="@quiet_url@">quiet</a>
      | <strong> verbose </strong>
    </else>]
    </li>
  </ul>
  </dd>
  </dl>

  <table>
    <tr>
      <th class="testcase-table-header">Result</th>
      <th class="testcase-table-header">Count</th>
    </tr>
    <multiple name="tests_quiet">
      <tr>
        <if @tests_quiet.result@ eq "fail">
          <td class="fail">FAILED</td>
        </if>
        <elseif @tests_quiet.result@ eq "pass">
          <td class="ok">@tests_quiet.result@</td>
        </elseif>
        <else>
          <td class="log">@tests_quiet.result@</td>
        </else>
        <td align="right" class="@tests_quiet.result@">@tests_quiet.count@</td>
      </tr>
    </multiple>
  </table>

  <table class="testlog">
    <tr>
      <th class="testcase-table-header timestamp">Time</th>
      <th class="testcase-table-header result">Result</th>
      <th class="testcase-table-header notes">Notes</th>
    </tr>
    <if @tests:rowcount;literal@ eq 0>
      <tr><td> No results </td></tr>
    </if>
    <else>
      <multiple name="tests">
        <if @tests.rownum@ odd>
          <tr class="odd">
        </if>
        <else>
          <tr class="even">
        </else>
        <td class="timestamp"> @tests.timestamp@ </td>
          <if @tests.result@ eq "fail">
            <td class="fail">FAILED</td>
            <td><code>@tests.notes;literal@</code></td>
          </if>
          <elseif @tests.result@ eq "pass">
            <td class="ok">@tests.result@</td>
            <td><code class="ok">@tests.notes;literal@</code></td>
          </elseif>
          <elseif @tests.result@ eq "warn">
            <td class="warn">@tests.result@</td>
            <td><code class="warn">@tests.notes;literal@</code></td>
          </elseif>
          <elseif @tests.result@ eq "sect">
            <td class="sect"></td>
            <td><div class="sect">@tests.notes;literal@</div></td>
          </elseif>
          <else>
            <td class="log">@tests.result@</td>
            <td class="log">@tests.notes;literal@</td>
          </else>
        </tr>
      </multiple>
    </else>
  </table>

  <ul>
    <li><a href="@rerun_url@">Rerun this test case</a></li>
    <li><a href="@return_url@">List all test cases of package @package_key@</a></li>
    <li><a href="@coverage_url@">Coverage of package @package_key@</a></li>    
  </ul>
