  <master>
    <property name=title>Merging ... </property>
    <property name="context">@context;noquote@</property>
    
    <h2>Merging ...</h2>

    <if @merge_p@ ne 0>
      <p/>
        @results;noquote@
      <p/>
        @msg@
    </if>  
