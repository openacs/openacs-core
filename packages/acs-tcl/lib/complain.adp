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
    <if @complaints:rowcount@ gt 1>
      <li>
    </if>
    @complaints.text;noquote@
  </multiple>
</ul>

<p>
  Please back up using your browser, correct the above <if @complaints:rowcount@ gt 1>s</if>, and resubmit your entry.
</p>

<p>
  Thank you.
</p>
