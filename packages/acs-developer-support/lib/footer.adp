<if @show_p@ true>
  <if @comments:rowcount@ gt 0>
    <div class="developer-support-footer">
      <multiple name="comments">
        <b>Comment:</b> <pre style="display: inline;">@comments.text@</pre><br />
      </multiple>
    </div>
  </if>
  <if @user_switching_p@ true>
    <form action="@set_user_url@">
      @export_vars;noquote@
      <div class="developer-support-footer">
        Real user: @real_user_name@ (@real_user_email@) [user_id #@real_user_id@]<br />
        <if @real_user_id@ ne @fake_user_id@>      
          Faked user: @fake_user_name@ <if @fake_user_email@ not nil>(@fake_user_email@)</if> [user_id #@fake_user_id@] <a href="@unfake_url@">(Unfake)</a><br />
        </if>
        <else>
          Faked user: <i>Not faking.</i><br />
        </else>
        Change faked user: <select name="user_id">
          <multiple name="users">
            <option value="@users.user_id@" <if @users.selected_p@>selected</if>>@users.name@ <if @users.email@ not nil>(@users.email@)</if></option>
          </multiple>
        </select>
        <input type="submit" value="Go">
      </div>
    </form>
  </if>
  <if @profiling:rowcount@ gt 0>
    <div class="developer-support-footer">
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
            <td>@profiling.tag@</td>
            <td align="right">@profiling.num_iterations@</td>
            <td align="right">@profiling.total_ms@ ms</td>
            <td align="right">@profiling.ms_per_iteration@ ms</td>
          </tr>
        </multiple>
      </table>
    </div>
  </if>
</if>
