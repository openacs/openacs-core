  <master>
    <property name="doc(title)">Contract @contract_name;noquote@</property>
    <property name="context">{@contract_name;noquote@}</property>

    <ul>
      <multiple name=contract>
        <li> <strong>@contract.operation_name@</strong> -
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

    <p><listtemplate name="bindings"></listtemplate></p>


