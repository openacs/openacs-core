<master src="master">
  <property name="title">Administration of Localized Messages</property>

<h2>@instance_name@</h2>

@context_bar@

<hr />

<div>

<include src="locales-tabs" tab="@tab@" show_locales_p="@show_locales_p@">

<if @tab@ eq "home">

 <!-- Start home tab -->
 <p>Maybe we should display something useful for the user here ... </p>
 <!-- End home tab -->

</if>

<if @tab@ eq "locales">

 <!-- Start locales tab -->
 <include src="locales" tab="@tab@">
 <!-- End locales tab -->

</if>

<if @tab@ eq "localized-messages">

 <!-- Start localized-messages tab -->
 <include src="localized-messages" tab="@tab@">
 <!-- End localized-messages tab -->

</if>

</div>

<a href="load-catalog-files">Load all Catalog Files</a>. This will overwrite any values in the database (the catalog files take precedence).
