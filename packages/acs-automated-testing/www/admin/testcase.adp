<master>
  <property name="doc(title)">@title;noquote@ (@package_key@)</property>
  <property name="context">@context;literal@</property>

  <div class="description">
    <dl>
      <dt>Description:</dt><dd>@testcase_desc@</dd>
      <dt>Defined in file:</dt><dd>@testcase_file@</dd>
      <dt>Categories:</dt><dd>@testcase_cats@</dd>
      <if @bug_blurb@ not nil>
        <dt>Bugs:</dt><dd>This test case covers OpenACS bug number(s):
          @bug_blurb;noquote@</dd>
      </if>
      <if @proc_blurb@ not nil>  
        <dt>Procs:</dt><dd>This test case covers OpenACS proc(s):
          @proc_blurb;noquote@</dd>
      </if>
      <if @testcase_inits@ ne "">
        <dt>Initialisation Classes:</dt><dd>@testcase_inits@</dd>
      </if>
      <if @fails@ gt 0 and @testcase_on_error@ ne "">
        <dt class="fail">Testcase failure error response:</dt>
        <dd>@testcase_on_error;noquote@</dd>
      </if>
      <if @showsource@ eq 1>
        <multiple name="bodys">
          <dt>  Body @bodys.body_number@ source  </dt>
          <dd><pre>@bodys.body@</pre></dd>
        </multiple>
      </if>
    </dl>
  </div>

  <if @showsource@ eq 0>
    [<a href="testcase?testcase_id=@testcase_id@&amp;package_key=@package_key@&amp;showsource=1&amp;quiet=@quiet@">
      show testcase source
    </a>]
  </if>
  <else>
    [<a href="testcase?testcase_id=@testcase_id@&amp;package_key=@package_key@&amp;showsource=0&amp;quiet=@quiet@">
      hide testcase source
    </a>]
  </else>

  <ul>
    <li><a href="@rerun_url@">Rerun this test case</a></li>
    <li><a href="@resource_file_url@">Resource test definition file</a></li>
    <li><a href="@return_url@">Back to testcase list</a></li>
  </ul>
  
  <p>
    <strong>Results</strong> 
    [<if @quiet@ eq "1">
      <strong> quiet </strong> | 
      <a href="@verbose_url@">verbose</a>
    </if><else>
      <a href="@quiet_url@">quiet</a>
      | <strong> verbose </strong>
    </else>]
  </p>

  <table>
    <tr>
      <th>Result</th>
      <th>Count</th>
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
          <td>@tests_quiet.result@</td>
        </else>
        <td align="right" class="@tests_quiet.result@">@tests_quiet.count@</td>
      </tr>
    </multiple>
  </table>

  <table>
    <tr>
      <th>Time</th>
      <th>Result</th>
      <th>Notes</th>
    </tr>
    <if @tests:rowcount@ eq 0>
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
        
        <td> @tests.timestamp@ </td>
        <if @tests.result@ eq "fail">
          <td class="fail">FAILED</td>
        </if>
        <elseif @tests.result@ eq "pass">
          <td class="ok">@tests.result@</td>
        </elseif>
        <else>
          <td>@tests.result@</td>
        </else>
        <td><pre>@tests.notes@</pre></td>
      </tr>
      </multiple>
    </else>
  </table>

  <ul>
    <li><a href="@rerun_url@">Rerun this test case</a></li>
    <li><a href="@resource_file_url@">Resource test definition file</a></li>
    <li><a href="@return_url@">Back to testcase list</a></li>
  </ul>
