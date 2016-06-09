<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>

<p>
  Please select one of the following packages to mount on <code><strong>@site_node_url@</strong></code>.
</p>

<if @unmounted:rowcount@ gt 0>
  <p>
    These package instances are not mounted anywhere else:
  </p>

  <ul>
    <multiple name="unmounted">
      <li><a href="@unmounted.url@">@unmounted.name@</a> (@unmounted.package_pretty_name@)
    </multiple>
  </ul>
</if>

<if @mounted:rowcount@ gt 0>
  <p>
    These instances are already mounted elsewhere. Selecting one of them
    will create an additional location for the same application:
  </p>

  <ul>
    <multiple name="mounted">
      <li><a href="@mounted.url@">@mounted.name@</a> (@mounted.package_pretty_name@)
    </multiple>
  </ul>
</if>

<if @singleton:rowcount@ gt 0>
  <p>
    These packages are centralized services and are probably not meant to
    be mounted anywhere:
  </p>

  <ul>
    <multiple name="singleton">
      <li><a href="@singleton.url@">@singleton.name@</a> (@singleton.package_pretty_name@)
    </multiple>
  </ul>
</if>
