<if @l@ nil>@indent@ pass the test.</if
><else>@indent@@lt@if @true_condition@>
@indent@ @lt@if @false_condition@>
@indent@   fail '@false_label@' should be false
@indent@ @lt@/if>@lt@else>
<include src=include l="@cdr;literal@" indent="@indent;noquote@  "
>@indent;noquote@ @lt;noquote@/else>
@indent@@lt@/if>@lt@else>
@indent@ fail '@true_label@' should be true
@indent@@lt@/else>
</else>
