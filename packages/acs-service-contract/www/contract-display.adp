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