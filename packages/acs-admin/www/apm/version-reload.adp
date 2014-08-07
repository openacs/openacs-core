<master>
<property name="doc(title)">@title@</property>
<property name="context">@context;noquote@</property>

<style type="text/css">
  dl.error, dl.error dt { display:inline; color:red; }
/*  dl.error dd { display: none; }*/
  dl.error dt { font-weight:bold; }
  dl.error    { margin-left:1em; cursor:pointer; }
</style>

@body;noquote@

<!--
<script type="text/javascript">
  <% template::head::add_javascript -src "//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js" %>
  $('#files dd').click(function () {
	$(this).slideToggle();
  });
  $('#files dt').click(function () {
	$(this.nextElementSibling).slideToggle();
  });
</script>

-->
