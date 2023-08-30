<if @registries:rowcount;literal@ gt 0>
  <h5>#acs-subsite.external_identity_providers_title#</h5>
  <ul>
    <multiple name="registries">
      <if @registries.login_url@ not nil>
        <li><a href="@registries.login_url@">Login via @registries.name@</a>
      </if>
    </multiple>
  </ul>
</if>