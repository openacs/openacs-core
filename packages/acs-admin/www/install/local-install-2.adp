<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<p> This is the <if @install:rowcount@ eq 1>package</if><else>list of packages</else> we are going to install. </p>

<p> Please click the link below to begin installation. </p>

<p><listtemplate name="install"></listtemplate></p>

<if @continue_url@ not nil>
  <p>
    <b>&raquo;</b> <a href="@continue_url@">Install above <if @install:rowcount@ eq 1>package</if><else>packages</else></a>
  </p>
</if>

