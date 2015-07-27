# /packages/mbryzek-subsite/www/admin/index.tcl

ad_page_contract {

    View an OpenACS Object Type

    @author Yonantan Feldman (yon@arsdigita.com)
    @creation-date August 13, 2000
    @cvs-id $Id$

} {
    object_type:notnull
}

if { ![db_0or1row object_type {}] } {
    ad_return_complaint 1 "The specified object type, $object_type, does not exist"
    ad_script_abort
}

set page_title "Details for type $pretty_name"
set context [list [list index "Object Type Index"] "Details for type $pretty_name"]

set page "[acs_object_type_hierarchy -object_type $object_type]"

append page [subst {
<p>
<b>Information</b>:
<ul>
  <li>Pretty Name: [lang::util::localize $pretty_name]</li>
  <li>Pretty Plural: [lang::util::localize $pretty_plural]</li>
  <li>Abstract: [ad_decode $abstract_p "f" "False" "True"]</li>
  <li>Dynamic: [ad_decode $dynamic_p "f" "False" "True"]</li>
  [ad_decode $table_name "" "" "<li>Table Name: $table_name</li>"]
  [ad_decode $id_column "" "" "<li>Primary Key: $id_column</li>"]
  [ad_decode $name_method "" "" "<li>Name Method: $name_method</li>"]
  [ad_decode $type_extension_table "" "" "<li>Helper Table: $type_extension_table</li>"]
  [ad_decode $package_name "" "" "<li>Package Name: $package_name</li>"]
</ul>
}]

set i 0
set body [subst {
    <table cellpadding="5" cellspacing="5">
     <tr>
      <th>Attribute Name</th>
      <th>Pretty Name</th>
      <th>Pretty Plural</th>
      <th>Datatype</th>
      <th>Default Value</th>
      <th>Minimum Number of Values</th>
      <th>Maximum Number of Values</th>
      <th>Storage</th>
      <th>Table Name</th>
      <th>Column Name</th>
    </tr>
}]    

db_foreach attribute {
    select attribute_name,
           pretty_name,
           pretty_plural,
           datatype,
           default_value,
           min_n_values,
           max_n_values,
           storage,
           table_name as attr_table_name,
           column_name
      from acs_attributes
     where object_type = :object_type
} {
    incr i
    append body "
     <tr>
      <td>$attribute_name</td>
      <td>$pretty_name</td>
      <td>$pretty_plural</td>
      <td>$datatype</td>
      <td>$default_value</td>
      <td>$min_n_values</td>
      <td>$max_n_values</td>
      <td>$storage</td>
      <td>[string tolower $attr_table_name]</td>
      <td>[string tolower $column_name]</td>
     </tr>"
}

append body "
    </table>"

    if { $i > 0 } {
	append page "
<p>
<b>Attributes</b>:
$body
"
    }

if { ([info exists table_name] && $table_name ne "") } {

    set body [db_string table_comment {} -default ""]

    append body [subst {
    <table border="0" cellpadding="5" cellspacing="5">
     <tr>
      <th>Type</th>
      <th>Name</th>
      <th>Comment</th>
     </tr>
    }]

    set i 0
    db_foreach attribute_comment {} {
	incr i
	append body "
     <tr>
      <td>[string tolower $column_name]</td>
      <td>[string tolower $data_type]</td>
      <td>$comments</td>
     </tr>"
    }

    append body "
    </table>"

    if { $i > 0 } {
	append page [subst {<p><b>Table Attributes</b>:<p>$body\n}]
    }
}

set i 0
set body ""
db_foreach package_index {} {
    incr i
    append body [subst {
	<pre class="code">[ns_quotehtml $text]</pre>
	<p>
    }]
}

if { $i > 0 } {
    append page [subst {<p><b>SQL Functions</b>:<p>$body}]
}

