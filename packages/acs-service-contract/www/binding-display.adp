  <master>
  <property name="doc(title)">Contract @contract_name;noquote@</property>
  <property name="context">{@contract_name;noquote@}</property>

  <h2>Binding @contract_name@</h2>
  <p><listtemplate name="binding"></listtemplate></p>

  <h2>Contract details</h2>
  <ul>
    <multiple name=contract>
      <li> <strong>@contract.operation_name@</strong> -
        @contract.operation_desc@ 
        <ul>
          <group column="operation_name">
            <li>@contract.inout@ @contract.param@
              @contract.param_type@ <if @contract.set_p;literal@ true>[]</if></li>
          </group>
        </ul>
    </multiple>
  </ul>


