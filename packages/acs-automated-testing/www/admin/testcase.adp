<master>
  <property name="doc(title)">@title;noquote@ (@package_key@)</property>
  <property name="context">@context;literal@</property>
  <h1>@title@</h1>
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
      <if @url_blurb@ not nil>  
        <dt>URLs:</dt><dd>This test case covers the following URLs:
          @url_blurb;noquote@</dd>
      </if>
      <if @testcase_inits@ ne "">
        <dt>Initialisation Classes:</dt><dd>@testcase_inits@</dd>
      </if>
      <if @fails@ gt 0 and @testcase_on_error@ ne "">
        <dt class="fail">Testcase failure error response:</dt>
        <dd>@testcase_on_error;noquote@</dd>
      </if>
      <if @showsource;literal@ true>
        <multiple name="bodys">
	  <if @bodys:rowcount;literal@ lt 2><dt>Body:</dt></if>
	  <else><dt>Body (part @bodys.body_number@)</dt></else>
          <dd><pre class="code">@bodys.body;literal@</pre></dd>
        </multiple>
      </if>
    </dl>
  </div>

  <if @showsource;literal@ false>
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
    [<if @quiet;literal@ true>
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
          <td class="log">@tests_quiet.result@</td>
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
	<td> @tests.timestamp@ </td>
        <if @tests.result@ eq "fail">
          <td class="fail">FAILED</td>
	  <td><pre>@tests.notes;literal@</pre></td>	  
        </if>
        <elseif @tests.result@ eq "pass">
          <td class="ok">@tests.result@</td>
  	  <td><pre>@tests.notes;literal@</pre></td>
        </elseif>
        <elseif @tests.result@ eq "warn">
          <td class="warn">@tests.result@</td>
  	  <td><pre class="warn">@tests.notes;literal@</pre></td>
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
    <li><a href="@resource_file_url@">Resource test definition file</a></li>
    <li><a href="@return_url@">Back to testcase list</a></li>
  </ul>
