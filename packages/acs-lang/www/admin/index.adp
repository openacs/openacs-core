<master>
  <property name="title">Administration of Localized Messages</property>
  <property name="header_stuff">
    <style>
      tr.oddrow { background: #EEEEEE;  }
      td.tab_selected {
          background: #333366;
          color: #EEEEFF;
      }     
    </style>    
  </property>

<div>

<include src="locales-tabs" tab="@tab@" show_locales_p="@show_locales_p@">

<if @tab@ eq "home">
  <p>I want to ...</p>
  <ul>
    <p>
      <li>
        <a href=".?tab=locales">Edit locales</a>
      </li>
    </p>
    <p>
      <li>
        <a href=".?tab=localized-messages">Edit Messages</a>
      </li>
    </p>
    <p>
      <li>
        <a href="translator-mode-toggle">Toggle translator mode</a> (Currently 
        <if @translator_mode_p@ true><font color="red"><b>ON</b></font></if>
        <else>off</else>)
        
      </li>
    </p>
    <p>
      <li>
        <a href="load-catalog-files">Load all Catalog Files</a>. This
        will overwrite any values in the database (the catalog files
        take precedence).
      </li>
    </p>

    <p>
      <li>
        <a href="reload-cache">Reload the message cache</a>. 
      </li>
    </p>
  </ul>
</if>

<if @tab@ eq "locales">
  <include src="locales" tab="@tab@">
</if>

<if @tab@ eq "localized-messages">
 <include src="localized-messages" tab="@tab@">
</if>

</div>
