<master>
<property name="title">@pa.title@</property>

<!-- START LEFT PANEL -->

<div class="left-panel">

<!-- START NEWS -->
<div class="news">
<include src="widgets/news" title="News">
</div>
<!-- END NEWS -->

<!-- START POSTINGS -->
<div class="postings">
<include src="widgets/postings" title="Recent Posts">
</div>
<!-- END POSTINGS -->

</div>

<!-- END LEFT PANEL -->


<!-- START MAIN CONTENT -->

<div class="main-content">
@pa.content;noquote@
</div>

<!-- END MAIN CONTENT -->


<!-- START RIGHT PANEL -->
<div class="right-panel">

<!-- START DOWNLOAD -->
<div class="download">
<center>
<a href="/projects/openacs/download/"><img src="/templates/slices/unleash.gif" width="118" height="53"  border="0" alt="Download OpenACS"></a>
</center>
</div>
<!-- END DOWNLOAD -->
<include src="widgets/about" title="About OpenACS">
<include src="widgets/features" title="Features Articles">
</div>
<!-- END RIGHT PANEL -->



