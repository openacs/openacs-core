<style>
.arrow_box {
	position: relative;
	background: #f3f1e9;
	border: 1px solid #ffffff;
	padding:4px;
}
.arrow_box:after, .arrow_box:before {
	left: 100%;
	top: 50%;
	border: solid transparent;
	content: " ";
	height: 0;
	width: 0;
	position: absolute;
	pointer-events: none;
}

.arrow_box:after {
	border-color: rgba(243, 241, 233, 0);
	border-left-color: #f3f1e9;
	border-width: 14px;
	margin-top: -14px;
}
.arrow_box:before {
	border-color: rgba(255, 255, 255, 0);
	border-left-color: #ffffff;
	border-width: 15px;
	margin-top: -15px;
}
.arrow_box-left {
	position: relative;
	background: #f3f1e9;
	border: 1px solid #ffffff;
	padding:4px;
}
.arrow_box-left:after, .arrow_box:before {
	right: 100%;
	top: 50%;
	border: solid transparent;
	content: " ";
	height: 0;
	width: 0;
	position: absolute;
	pointer-events: none;
}

.arrow_box-left:after {
	border-color: rgba(243, 241, 233, 0);
	border-right-color: #f3f1e9;
	border-width: 14px;
	margin-top: -14px;
}
.arrow_box-left:before {
	border-color: rgba(255, 255, 255, 0);
	border-right-color: #ffffff;
	border-width: 15px;
	margin-top: -15px;
}

</style>

<div class="navheader" style="display:table;width:100%;border-top:1px dashed #ddd;border-bottom:1px dashed #ddd;padding:5px 0;">
    <span style="display:table-cell;text-align:left;width:20%;padding-left:20px;">
    <if @leftLink@ not nil>
        <a accesskey="p" href="@leftLink@" class="arrow_box-left">@leftLabel@</a>
    </if>
    </span>
    <span style="display:table-cell;text-align:center;width:60%;"><strong>@title@</strong></span>
    <span style="display:table-cell;text-align:right;width:20%;padding-right:20px;">
    <if @rightLink@ not nil>
        <a accesskey="n" href="@rightLink@" class="arrow_box">@rightLabel@</a>
    </if>
    </span>
</div>