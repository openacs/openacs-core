<noparse>
  <if \@@list_properties.multirow@:rowcount@ eq 0>
</noparse>
    @list_properties.no_data@
<noparse>
  </if>
  <else>
</noparse>

  <script language="JavaScript" type="text/javascript">
    function ListFindInput() {
      if (document.getElementsByTagName) {
        return document.getElementsByTagName('input');
      } else if (document.all) {
        return document.all.tags('input');
      }
      return false;
    }

    function ListCheckAll(listName, checkP) {
      var Obj, Type, Name, Id;
      var Controls = ListFindInput(); if (!Controls) { return; }
      // Regexp to find name of controls
      var re = new RegExp('^' + listName + ',.+');

      checkP = checkP ? true : false;

      for (var i = 0; i < Controls.length; i++) {
        Obj = Controls[i];
        Type = Obj.type ? Obj.type : false;
        Name = Obj.name ? Obj.name : false;
        Id = Obj.id ? Obj.id : false;

        if (!Type || !Name || !Id) { continue; }

        if (Type == "checkbox" && re.exec(Id)) {
          Obj.checked = checkP;
        }
      }
    }

    function ListBulkActionClick(formName, url) {

      if (document.forms == null) return;
      if (document.forms[formName] == null) return;
    
      var form = document.forms[formName];

      form.action = url;
      form.submit();
    }
  </script>

  <if @actions:rowcount@ gt 0>
    <div class="list-button-bar">
      <multiple name="actions">
        <span class="list-button-header"><a href="@actions.url@" class="list-button" title="@actions.title@">@actions.label@</a></span>
      </multiple>
    </div>
  </if>

  <table class="list-tiny" cellpadding="3" cellspacing="1">

  <form name="@list_properties.name@" method="get">

    <noparse>
      <multiple name="@list_properties.multirow@">
    </noparse>

      <p class="list-row">
        <listrow>
      </p>

    <noparse>
      </multiple>
    </noparse>

  </table>

  <if @bulk_actions:rowcount@ gt 0>
    <div class="list-button-bar">
      <multiple name="bulk_actions">
        <span class="list-button-header"><a href="#" class="list-button" title="@bulk_actions.title@" 
        onclick="ListBulkActionClick('@list_properties.name@', '@bulk_actions.url@')">@bulk_actions.label@</a></span>
      </multiple>
    </div>
  </if>
  </form>


<noparse>
  </else>
</noparse>
