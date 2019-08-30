<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<div class=coverage_stats>
    <div class="@test_coverage_level@ coverage_badge">@test_coverage_percent@%</div>
    <div class=coverage_data>
        <div class=coverage_data_elements>
            Procs: @test_coverage_procs_nr@<br/>
            Procs covered: @test_coverage_procs_cv@<br/>
            Coverage: <span class="@test_coverage_level@ coverage_data_level">@test_coverage_level@</span>
        </div>
    </div>
</div>

<listtemplate name="procs"></listtemplate>
