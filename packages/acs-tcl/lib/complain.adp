<master>
  <property name="title">Problem with your input</property>

<p>
  We had
  <if @complaints:rowcount@ gt 1>some problems</if>
  <else>a problem</else>
  with your input:
</p>

<ul>
  <multiple name="complaints">
    <li>@complaints.text@</li>
  </multiple>
</ul>

<p>
  Please back up using your browser, correct the above problem<if @complaints:rowcount@ gt 1>s</if>, and resubmit your entry.
</p>

<p>
  Thank you.
</p>
