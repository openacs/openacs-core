<if @jobs:rowcount@ gt 0>
  <master src="../box-master">
  <property name="title"><a href="/community/jobs/">@title@</a></property>
  
  <multiple name=jobs>
  <if @jobs.rownum@ le @n_jobs@>
    <span id="title"><a href="jobs/@jobs.url@">@jobs.title@</a></span>
    <if @jobs.description@ not nil>
    <span id="description"> - @jobs.description@</span>
    </if>
    <br><br>
  </if>
  </multiple>
  
  <if @jobs:rowcount@ gt @n_jobs@>
    <span id="more"><a href="jobs">more jobs</a>...</span>
  </if>
</if>
