<master>
  <property name="doc(title)">#acs-tcl.lt_Problem_with_your_inp#</property>

<p>
  #acs-tcl.We_had#
  <if @complaints:rowcount@ gt 1>#acs-tcl.some_problems#</if><else>#acs-tcl.a_problem#</else>
  #acs-tcl.with_your_input#
  <if @context;literal@ ne "">(@context@)</if>
</p>

<ul>
  <multiple name="complaints">
    <li>@complaints.text;noquote@</li>
  </multiple>
</ul>

<p>
  #acs-tcl.lt_Please_back_up_using_# <if @complaints:rowcount@ gt 1>#acs-tcl.errors#</if><else>#acs-tcl.error#</else>#acs-tcl.lt__and_resubmit_your_en#
</p>

<p>
  #acs-tcl.Thank_you#
</p>
<if @prev_url@ defined and @prev_url@ not nil><p> <a href="@prev_url@">#acs-tcl.Return_prev#</a></if></p>

