<master>
<property name="doc(title)">#acs-subsite.Database_Error#</property>
<property name="context">#acs-subsite.Database_Error#</property>

<p><if @custom_message@ nil>
#acs-subsite.lt_We_had_a_problem_proc#
</if>
<else>
@custom_message@
</else>
</p>
<p>#acs-subsite.lt_Heres_what_the_databa#
<blockquote>
@errmsg@
</blockquote>
</p>

