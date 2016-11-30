<!-- Begin of navfooter.adp -->
<div class="navfooter" style="display:table;width:100%;border-top:1px dashed #ddd;border-bottom:1px dashed #ddd;padding:5px 0;">
    <span style="display:table-cell;text-align:left;width:40%;padding-left:20px;">
   <if @leftLink@ not nil>
        <a accesskey="p" href="@leftLink@" class="arrow_box-left">@leftLabel@</a>
   </if>
        <br><span style="color:#696969;display:block;margin-top:3px;">@leftTitle@</span>
    </span>
    <span style="display:table-cell;text-align:center;width:20%;">
        <a accesskey="h" href="@homeLink@">@homeLabel@</a>
        <br><a accesskey="u" href="@upLink@">@upLabel@</a>
    </span>
    <span style="display:table-cell;text-align:right;width:40%;padding-right:20px;">
        <if @rightLink@ not nil>
        <a accesskey="n" href="@rightLink@"  class="arrow_box">@rightLabel@</a>
	</if>
        <br>
	<span style="color:#696969;display:block;margin-top:3px;">@rightTitle@</span>
    </span>
</div>
<!-- End of navfooter.adp -->