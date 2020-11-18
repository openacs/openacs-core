<master>
<property name="doc(title)">Contributions of @user_info.first_names;noquote@ @user_info.last_name;noquote@</property>
<property name="context">@context;literal@</property>

<h1>Contributions of @user_info.name@</h1>

These are the @number_contributions@ contributions of
user @user_info.name@ (user_id <a href="./one?user_id=@user_id@">@user_id@</a>
username @user_info.username@ email @user_info.email@).

<multiple name="user_contributions">

  <h2>@user_contributions.pretty_plural@</h2>
  <ul>

  <group column="pretty_name">
    <li>@user_contributions.creation_date@: @user_contributions.object_name@</li>
  </group>
  </ul>

</multiple>
