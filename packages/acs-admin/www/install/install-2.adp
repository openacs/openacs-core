<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<if @problems_p;literal@ true>

  <p> We're sorry. Some packages which are required in order to
  install the packages you want could not be found. </p>

</if>
<else>
  <if @extras_p@ true >
    <p> The packages you want to install require some other
    packages. These have been added to the list, and are marked
    below. </p>
 </if>

  <p> This is the <if @install:rowcount@ eq 1>package</if><else>list of packages</else> we are going to install. </p>

  <p> Please click the link below to begin installation. </p>
</else>

<listtemplate name="install"></listtemplate>

<if @continue_url@ not nil>
  <p>
    <a href="@continue_url@" class="button">Install above <if @install:rowcount@ eq 1>package</if><else>packages</else></a>
  </p>
</if>
<if @problems_p;literal@ true>

  <p> Please hit the Back button in your browser and go back and remove the packages we cannot install.</p>

</if>
