@doc_type@
<html>
  <head>
    <title>@title@</title>
    @header_stuff@
  </head>

  <body<multiple name=attribute> @attribute.key@="@attribute.value@"</multiple>>

    <if @body_start_include@ not nil>
      <include src="@body_start_include@" />
    </if>

    <h1>@title@</h1>

      <div>
        @context_bar@
        <hr />
      </div>

    <slave>

    <hr />
    <address><a href="mailto:@signatory@">@signatory@</a></address>
    @ds_link@

  </body>
</html>
