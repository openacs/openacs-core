<master src="master">
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

<p>Here you can edit locales and internationalize messages in the user interface of the system.</p>

<p>
  <b>&raquo;</b>
  <a href="translator-mode-toggle">Toggle translator mode</a> (Currently 
  <if @translator_mode_p@ true><font color="red"><b>ON</b></font></if>
  <else>off</else>)
</p>


<h2>System Locales</h2>

<include src="locales" tab="@tab;noquote@">

</div>

<if @timezone_p@>
  <h2>Timezone</h2>

  <p>
    <b>&raquo;</b>
    <a href="set-system-timezone">Set system timezone</a>
  </p>
</if>

