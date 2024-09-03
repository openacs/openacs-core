<master>
  <property name="&doc">doc</property>
  <property name="context">@context;literal@</property>

<h1>@doc.title@</h1>

<if @mode@ eq "overview">

  <if @sitenodeModel@ ne huge>
    <p>This site has <i>@numPublicReadableSiteNodes@</i> publicly accessible packages of the following types.
  </if><else>
    <p>This site has <i>@numSiteNodesEntries@</i> mounted packages of the following types.
       Packages which are mounted only once, are only listed, when the package is publicly readable.
       Check per package-key for publicly accessible instances.
  </else>

  <table class="table table-sm">
  <tr>
    <th class="text-end">Count</th>
    <th>Type</th>
    <th>URL</th>
    <th>Status</th>
    <th>Permission Info</th>
    <th>Diagnosis</th>
  </tr>
  <multiple name="per_package_key">
  <tr>
    <td class="text-end">@per_package_key.count@</td>
    <if @per_package_key.count@ eq 1>
        <td>@per_package_key.package_key@</td>
        <td><a title="Visit page" href="@per_package_key.url@">@per_package_key.url@</a>
        </td>
        <td>@per_package_key.status@</td>
        <td><a title="See Detailed Permissions" href='/permissions/one?object_id=@per_package_key.package_id@'>
           <if @per_package_key.permission_info@ not nil><adp:icon name='permissions'> </if>
           @per_package_key.permission_info@</a>
         </td>
         <td>@per_package_key.diagnosis@</td>
    </if><else>
    <td><a title="See URLs and detailed permissions of publicly accessible instances this type" href="@per_package_key.link@">
        <adp:icon name='arrow-right'> @per_package_key.package_key@</a>
    </td>
    </else>
  </tr>
  </multiple>
  </table>
</if>

<else>

  <if @sitenodeModel@ ne huge>
    <p>This site has <i>@numPublicReadableSiteNodes@</i> publicly accessible packages, where <i>@count@</i> of these are of type <i>@package_key@</i>.
  </if><else>
    <p>This site has <i>@count@</i> mounted packages of type <i>@package_key@</i> from which the following are publicly readable.
  </else>

  
  <table class="table table-sm">
  <tr>
    <th>URL</th>
  </tr>
  <multiple name="urls">
  <tr>
    <td><a title="See Detailed Permissions" href='/permissions/one?object_id=@urls.package_id@'><adp:icon name='permissions'> </a>
        <a title="Visit page" href="@urls.url@"><adp:icon name='eye-open'> @urls.url@</a>
     </td>
  </tr>
  </multiple>
  </table>

<a href="@overviewLink@" class="button">Back to Overview of Publicly Accessible Packages</a>
</else>


<if 0 true>
<table class="table table-sm">
<tr>
  <th>Package Key</th>
  <th>URL</th>
</tr>
<multiple name="public_urls">
<tr>
  <td>@public_urls.package_key@</td>
  <td><a title="See Detailed Permissions" href='/permissions/one?object_id=@public_urls.package_id@'><adp:icon name='permissions'> @public_urls.url@</a></td>
</tr>
</multiple>
</table>
</if>

