<master>
  <property name="doc(title)">#acs-tcl.Server#</property>
<p>
  #acs-tcl.There#
</p>
<if @message@ not nil>
  <p>
    @message;noquote@
  </p>
</if>
<br>

 <a href="@prev_url@">#acs-tcl.Return_prev#</a>

 <if @bt_instance@ ne "">
  <if @auto_submit_p@ gt 0>
    <if @user_id@ gt 0> 
      <br>
      <formtemplate id="bug_edit"></formtemplate>
      <br>
	#acs-tcl.Bug_History#
	<br><br>
	  <formtemplate id="bug_history"></formtemplate>
      </if>
      <else>
         
      </else>
    </if>
  </if>
 <else>
 <pre>@stacktrace@</pre>
</else>

