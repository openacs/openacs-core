<if @show_p@ true>
  <div class="developer-support-footer">
    <if @comments:rowcount@ gt 0>
      <multiple name="comments">
        <b>Comment:</b> <pre style="display: inline;">@comments.text@</pre><br />
      </multiple>
      <hr />
    </if>
    <if @user_switching_p@ true>
      <form action="@set_user_url@">
        @export_vars;noquote@
        Real user: @real_user_name@ (@real_user_email@) [user_id #@real_user_id@]<br />
        <if @real_user_id@ ne @fake_user_id@>      
          Faked user: @fake_user_name@ <if @fake_user_email@ not nil>(@fake_user_email@)</if> [user_id #@fake_user_id@] <a href="@unfake_url@">(Unfake)</a><br />
        </if>
        <else>
          Faked user: <i>Not faking.</i><br />
        </else>
        Change faked user: <if @search_p@ eq "0"><select name="user_id">
          <multiple name="users">
            <option value="@users.user_id@" <if @users.selected_p@>selected</if>>@users.name@ <if @users.email@ not nil>(@users.email@)</if></option>
          </multiple>
        </select></if><else><input type="text" name="keyword"><input type="hidden" name="target" value="@target@"></else>
        <input type="submit" value="Go">
      </form>
      <hr />
    </if>
    <if @profiling:rowcount@ gt 0>
      <h3>Profiling Information</h3>
      <table>
        <tr>
          <th>Tag</th>
          <th># Iterations</th>
          <th>Total time </th>
          <th>Avg. time per iteration</th>
        </tr>
        <multiple name="profiling">
          <tr>
            <td align="left"> @profiling.file_links;noquote@ @profiling.tag@</td>
            <td align="right">@profiling.num_iterations@</td>
            <td align="right">@profiling.total_ms@ ms</td>
            <td align="right">@profiling.ms_per_iteration@ ms</td>
          </tr>
        </multiple>
      </table>
    </if>
  </div>
</if>
