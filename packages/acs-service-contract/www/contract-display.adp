  <master>
    <property name="title">contract @contract_name@</property>
    <property name="context">"one contract"</property>

    <ul>
      <multiple name=contract>
        <li> <b>@contract.operation_name@</b> -
              @contract.operation_desc@ 
          <ul>
            <group column="operation_name">
              <li>@contract.inout@ @contract.param@
                @contract.param_type@ <if @contract.set_p@ eq t>[]</if></li>
            </group>
          </ul>
      </multiple>
    </ul>

    <h3>Valid Installed Bindings</h3>

    <ul>
      <if @valid_installed_binding:rowcount@ eq 0>
        <li><i>None</i></li>
      </if>
      <else>
        <multiple name=valid_installed_binding>
          <li>@valid_installed_binding.impl_id@
          @valid_installed_binding.impl_name@
          (@valid_installed_binding.impl_owner_name@)
          [<a href="binding-uninstall?contract_id=@valid_installed_binding.contract_id@&impl_id=@valid_installed_binding.impl_id@">Uninstall</a>]</li>
        </multiple>
      </else>
    </ul>

