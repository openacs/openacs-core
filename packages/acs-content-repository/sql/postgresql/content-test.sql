-- set serveroutput on

create function content_test__put_line(text) returns integer as '
begin
        raise NOTICE ''%'', $1;
        return null;
end;' language 'plpgsql';

create function test_content() returns integer as '
declare
  folder_id		cr_folders.folder_id%TYPE;
  folder_b_id		cr_folders.folder_id%TYPE;
  sub_folder_id		cr_folders.folder_id%TYPE;
  sub_sub_folder_id	cr_folders.folder_id%TYPE;
  item_id		cr_items.item_id%TYPE;
  simple_item_id	cr_items.item_id%TYPE;
  live_revision_id	cr_revisions.revision_id%TYPE;
  late_revision_id	cr_revisions.revision_id%TYPE;
  item_template_id	cr_templates.template_id%TYPE;
  type_template_id	cr_templates.template_id%TYPE;
  def_type_template_id	cr_templates.template_id%TYPE;
  dum_template_id	cr_templates.template_id%TYPE;

  symlink_a_id		cr_symlinks.symlink_id%TYPE;
  symlink_b_id		cr_symlinks.symlink_id%TYPE;

  found_folder_id	cr_folders.folder_id%TYPE;
begin

   -- create folders and an item

   folder_id         := content_folder__new(''grandpa'',''Grandpa'',NULL,-1);
   folder_b_id       := content_folder__new(''grandma'',''Grandma'',NULL,-1);
   sub_folder_id     := content_folder__new(''pa'',''Pa'',NULL,folder_id);
   sub_sub_folder_id := content_folder__new(''me'',''Me'',NULL,sub_folder_id);
   item_id           := content_item__new(''puppy'',sub_sub_folder_id);

   simple_item_id := content_item__new(
	''bunny'',
	sub_sub_folder_id
	''Bugs Bunny'',
	''Simple (Revisionless) Item Test'',
	''Simple (Revisionless) Item Test Text'',
   );

   live_revision_id := content_revision__new(
	''Live Revision of Puppy'',
	''Live Revision of Puppy Description'',
	to_date(''1999-08-12'',''YYYY-MM-DD''),
	''text/html'',
	''Text for Live Revision of Puppy'',
	item_id
   );

   late_revision_id := content_revision__new(
	''Latest Revision of Puppy'',
	''Latest Revision of Puppy Description'',
	to_date(''2001-09-22'',''YYYY-MM-DD''),
	''text/html'',
	''Text for Latest Revision of Puppy'',
	item_id
   );

   item_template_id := content_template__new(
        ''Item Template''
   );

   type_template_id := content_template__new(
	''Type Template''
   );

   def_type_template_id := content_template__new(
	''Dumb Default Type Template''
   );

   dum_template_id := content_template__new(
	''Default Type Template''
   );


   PERFORM content_test__put_line(''-------------------------------------'');
   PERFORM content_test__put_line(''CREATING CONTENT FOLDERS AND ITEMS...'');
   PERFORM content_test__put_line(''...all tests passed'');
   PERFORM content_test__put_line(''Folder grandpa is '' || folder_id);
   PERFORM content_test__put_line(''Folder grandma is '' || folder_b_id);
   PERFORM content_test__put_line(''Sub folder pa is '' || sub_folder_id);
   PERFORM content_test__put_line(''Sub sub folder me is '' || sub_sub_folder_id);
   PERFORM content_test__put_line(''Added item puppy to sub sub folder me at '' || item_id);
   PERFORM content_test__put_line(''Created simple item bunny to sub sub folder me at '' || simple_item_id);
   PERFORM content_test__put_line(''Added a revision to puppy at '' || live_revision_id);
   PERFORM content_test__put_line(''Added a revision to puppy at '' || late_revision_id);
   PERFORM content_test__put_line(''Created Item Template at '' || item_template_id);
   PERFORM content_test__put_line(''Created Type Template at '' || type_template_id);
   PERFORM content_test__put_line(''Created Def Type Template at '' || def_type_template_id);
   PERFORM content_test__put_line(''Created Dum Def Type Template at '' || dum_template_id);


   PERFORM content_test__put_line(''-----------------------------------'');
   PERFORM content_test__put_line(''FOLDERS AND EMPTY FOLDERS AND SUBFOLDERS'');
   PERFORM content_test__put_line(''...all tests passed'');
   PERFORM content_test__put_line(''Is folder '' || folder_id || '' empty? '' 
                                  || content_folder__is_empty(folder_id)
           );
   PERFORM content_test__put_line(''Is folder '' || sub_sub_folder_id || 
                                  '' empty? '' ||
                                  content_folder__is_empty(sub_sub_folder_id)
           );
   PERFORM content_test__put_line(''Is folder '' || sub_folder_id || 
                                  '' empty? '' ||
                                  content_folder__is_empty(sub_folder_id)
           );
   PERFORM content_test__put_line(''Is folder '' || folder_b_id || 
                                  '' empty? '' ||
                                  content_folder__is_empty(folder_b_id)
           );
   PERFORM content_test__put_line(''Is folder '' || folder_id || ''? '' ||
                                  content_folder__is_folder(folder_id)
           );
   PERFORM content_test__put_line(''Is folder '' || item_id || ''? '' ||
                                  content_folder__is_folder(item_id)
           );
   PERFORM content_test__put_line(''Is '' || folder_id || '' a subfolder of ''
                                  || sub_folder_id || ''? '' || 
                                  content_folder__is_sub_folder(sub_folder_id,
                                                                folder_id
                                  )
           );
   PERFORM content_test__put_line(''Is '' || sub_folder_id || 
                                  '' a subfolder of '' ||
                                  folder_id || ''? '' || 
                                  content_folder__is_sub_folder(folder_id,
                                                                sub_folder_id
                                  )
           );
   PERFORM content_test__put_line(''Is '' || sub_sub_folder_id || 
                                  '' a subfolder of '' ||
                                  folder_id || ''? '' || 
                                  content_folder__is_sub_folder(folder_id,
                                                              sub_sub_folder_id
                                  )
           );
   PERFORM content_test__put_line(''Is '' || sub_folder_id || 
                                  '' a subfolder of '' ||
                                  --    -1 || ''? '' || 
                                  content_folder__is_sub_folder(-1,
                                                                sub_folder_id
                                  )
           );


   PERFORM content_test__put_line(''-------------------------------------'');
   PERFORM content_test__put_line(''LIVE AND LATEST REVISIONS...'');
   PERFORM content_test__put_line(''...all tests passed'');
   PERFORM content_test__put_line(''Get live_revision_id for item puppy '' || 
                                  item_id ||
                                  '' is '' || 
                                  content_item__get_live_revision(item_id)
           );

   PERFORM content_item__set_live_revision(live_revision_id);

   PERFORM content_test__put_line(''Set '' || live_revision_id || 
                                  '' as the live revision for item puppy '' 
                                  || item_id);

   PERFORM content_test__put_line(''Get live_revision_id for item puppy '' 
                                  || item_id || '' is '' || 
                                  content_item__get_live_revision(item_id)
           );
   PERFORM content_test__put_line(''Get live_revision_id for item kitty '' || 
                                  simple_item_id || '' is '' || 
                                  content_item__get_live_revision(simple_item_id)
           );
   PERFORM content_test__put_line(''Get late_revision_id for item puppy '' || 
                                  item_id || '' is '' || 
                                  content_item__get_latest_revision(item_id)
           );
   PERFORM content_test__put_line(''Get late_revision_id for item bunny '' || 
                                  simple_item_id || '' is '' || 
                                  content_item__get_latest_revision(simple_item_id)
           );


   PERFORM content_item__register_template(item_id,
                                           item_template_id,
                                           ''public''
           );
   PERFORM content_type__register_template(''content_revision'',
                                           type_template_id,
                                           ''public''
           );
   PERFORM content_type__register_template(''content_revision'',
                                           def_type_template_id,
                                           ''admin''
           );
   PERFORM content_type__register_template(''content_revision'',
                                           dum_template_id,
                                           ''admin'',
                                           ''t''
           );
   PERFORM content_type__set_default_template(''content_revision'',
                                              def_type_template_id,
                                              ''admin''
           );

   PERFORM content_test__put_line(''-------------------------------------'');
   PERFORM content_test__put_line(''REGISTERING TEMPLATES TO ITEMS AND TYPES...'');
   PERFORM content_test__put_line(''...all tests passed'');
   PERFORM content_test__put_line(''Registered Item Template '' || 
                                  item_template_id || '' to item puppy '' || 
                                  item_id || '' with public context''
           );
   PERFORM content_test__put_line(''Registered Type Template '' || 
                                  type_template_id || '' to content_revision ''
                                  || item_id || '' with public context''
           );
   PERFORM content_test__put_line(''Registered Default Type Template '' || 
                                  def_type_template_id || 
                                  '' to content_revision '' || item_id || 
                                  '' with admin context''
           );
   PERFORM content_test__put_line(''Get template id for item puppy '' || 
                                  item_id || '' and context public is '' || 
                                  content_item__get_template(item_id,
                                                             ''public''
                                  )
           );
   PERFORM content_test__put_line(''Get template id for item puppy '' || 
                                  item_id || '' and context admin is '' || 
                                  content_item__get_template(item_id,
                                                             ''admin''
                                  )
           );

   found_folder_id := content_item__get_id(''grandpa/pa/me'', -1);

   PERFORM content_test__put_line(''-------------------------------------'');
   PERFORM content_test__put_line(''LOCATING CONTENT FOLDERS AND ITEMS...'');
   PERFORM content_test__put_line(''...all tests passed!'');
   PERFORM content_test__put_line(''Found me at grandpa/pa/me: '' || 
                                  found_folder_id
           );
   PERFORM content_test__put_line(''Path for '' || found_folder_id || '' is ''
                                  || content_item__get_path(found_folder_id)
           );
   PERFORM content_test__put_line(''Path for puppy '' || item_id || '' is '' 
                                  || content_item__get_path(item_id)
           );
   PERFORM content_test__put_line(''Path for puppy '' || item_id || 
                                  '' from folder_id: '' || folder_id || 
                                  '' is '' || 
                                  content_item__get_path(item_id,folder_id)
           );
   PERFORM content_test__put_line(''Path for puppy '' || item_id ||
                                  '' from sub_folder_id: '' || 
                                  sub_folder_id || '' is '' || 
                                  content_item__get_path(item_id,
                                                        sub_folder_id
                                  )
           );
   PERFORM content_test__put_line(''Path for puppy'' || item_id
                                  || '' from sub_sub_folder_id: '' || 
                                  sub_sub_folder_id || '' is '' || 
                                  content_item__get_path(item_id,
                                                         sub_sub_folder_id
                                  )
           );
   PERFORM content_test__put_line(''Get id of item with invalid path - shouldn''''t return anything'');
   PERFORM content_test__put_line(''Found item at '' || 
                                  content_item__get_id(''grandpa/me'', -200)
           );
   PERFORM content_test__put_line(''Get id of item using subpath'');
   PERFORM content_test__put_line(''Found item at '' || 
                                  content_item__get_id(''pa/me/puppy'', 
                                                       folder_id
                                  )
           );
   PERFORM content_test__put_line(''This is the path to a folder from a subfolder'');
   PERFORM content_test__put_line(''Path for '' || sub_folder_id || 
                                  '' from sub_sub_folder_id: '' || 
                                  sub_sub_folder_id || '' is '' || 
                                  content_item__get_path(sub_folder_id,
                                                         sub_sub_folder_id
                                  )
           );
   PERFORM content_test__put_line(''This is a path to an item from a non-existant item'');
   PERFORM content_test__put_line(''Path for '' || item_id || 
                                  '' from nonexistant_id: '' || 
                                  -200 || '' is '' || 
                                  content_item__get_path(item_id,-200)
           );
   PERFORM content_test__put_line(''This is a path to an item from a non-related branch'');
   PERFORM content_test__put_line(''Path for '' || item_id || 
                                  '' from unrelated branch: '' || 
                                  folder_b_id || '' is '' || 
                                  content_item__get_path(item_id,folder_b_id)
           );


   PERFORM content_test__put_line(''-------------------------------------'');
   PERFORM content_test__put_line(''MOVING/RENAMING CONTENT FOLDERS...'');
   PERFORM content_test__put_line(''...all tests passed'');
   PERFORM content_test__put_line(''Moving me from under pa to under grandpa'');
   PERFORM content_item__move(sub_sub_folder_id, folder_id);
   PERFORM content_test__put_line(''Path for '' || item_id || '' is '' || 
                                  content_item__get_path(item_id)
           );
   PERFORM content_test__put_line(''Moving grandpa to pa - this should''''nt work'');
   PERFORM content_folder__move(folder_id, sub_folder_id);
   PERFORM content_test__put_line(''Path for '' || item_id || '' is '' || 
                                  content_item__get_path(item_id)
           );
   PERFORM content_test__put_line(''Renaming puppy to kitty...'');
   PERFORM content_item__rename(item_id, ''kitty'');
   PERFORM content_test__put_line(''Renaming me to aunty...'');
   PERFORM content_folder__rename(sub_sub_folder_id, ''aunty'');
   PERFORM content_test__put_line(''Path for '' || item_id || '' is '' || 
                                  content_item__get_path(item_id)
           );
   PERFORM content_test__put_line(''Renaming kitty to pa -- this should work'');
   PERFORM content_item__rename(item_id, ''pa'');
   PERFORM content_test__put_line(''Path for '' || item_id || '' is '' || 
                                  content_item__get_path(item_id)
           );

   PERFORM content_test__put_line(''-------------------------------------'');
   PERFORM content_test__put_line(''SYMLINKS...'');
   PERFORM content_test__put_line(''...all tests passed'');

   symlink_a_id := content_symlink__new(''link_a'',
                                        sub_sub_folder_id,
                                        sub_folder_id
                   );
   PERFORM content_test__put_line(''Create a link in pa to aunty: Symlink is '' || symlink_a_id);

   PERFORM content_test__put_line(''Is '' || symlink_a_id || '' a symlink?: ''
                                  || content_symlink__is_symlink(symlink_a_id)
           );

   PERFORM content_test__put_line(''Is '' || folder_id || '' a symlink?: '' ||
                                  content_symlink__is_symlink(folder_id)
           );

   PERFORM content_test__put_line(''Path for symlink '' || symlink_a_id ||
                                  '' is '' || 
                                  content_item__get_path(symlink_a_id)
           );

   PERFORM content_test__put_line(''Resolving symlink '' || symlink_a_id ||
                                  '' is '' || 
                                  content_symlink__resolve(symlink_a_id)
           );

   PERFORM content_test__put_line(''Resolved path for symlink '' || 
                                  symlink_a_id || '' is '' || 
             content_item__get_path(content_symlink__resolve(symlink_a_id))
           );

   PERFORM content_test__put_line(''Path to item '' || item_id || 
                                  '' from symlink '' ||
                                  symlink_a_id || '' is '' ||
                                  content_item__get_path(item_id, symlink_a_id)
           );
   PERFORM content_test__put_line(''Path to item '' || item_id || 
                                  '' from aunty '' ||
                                  sub_sub_folder_id || '' is '' ||
                          content_item__get_path(item_id, sub_sub_folder_id)
           );
   PERFORM content_test__put_line(''Path to pa '' || sub_folder_id || 
                                  '' from symlink '' ||
                                  symlink_a_id || '' is '' ||
                                  content_item__get_path(sub_folder_id, 
                                                         symlink_a_id
                                  )
           );

   PERFORM content_test__put_line(''Found item '' || item_id || '' at '' ||
                          content_item__get_id(''/grandpa/aunty/kitty'')
           );
   PERFORM content_test__put_line(''Found item '' || item_id || '' at '' ||
                           content_item__get_id(''/grandpa/pa/link_a/kitty'')
           );
   PERFORM content_test__put_line(''Found item '' || item_id || 
                                  '' starting at aunty '' ||
                                  sub_sub_folder_id || '' at '' ||
                                  content_item__get_id(''kitty'',
                                                        sub_sub_folder_id
                                  )
           );
   PERFORM content_test__put_line(''Found item '' || item_id || 
                               '' starting at symlink '' ||
                               symlink_a_id || '' at '' ||
                               content_item__get_id(''kitty'',symlink_a_id)
           );
   PERFORM content_test__put_line(''Found item '' || item_id || 
                                  '' starting at pa '' ||
                                  sub_folder_id || '' at '' ||
                                  content_item__get_id(''link_a/kitty'',
                                                       sub_folder_id
                                  )
           );


   PERFORM content_test__put_line(''--------------------------------'');


   PERFORM content_test__put_line(''Moving item '' || item_id || 
                                  '' to grandma '' || 
                                  folder_b_id
           );
   PERFORM content_item__move(item_id,folder_b_id);
   PERFORM content_test__put_line(''Path for item '' || item_id || '' is '' ||
                                  content_item__get_path(item_id)
           );     

   PERFORM content_test__put_line(''Moving folder '' || folder_b_id || 
                                  '' to aunty '' || sub_sub_folder_id
           );
   PERFORM content_item__move(folder_b_id,sub_sub_folder_id);
   PERFORM content_test__put_line(''Path for item '' || item_id || '' is '' ||
                                  content_item__get_path(item_id)
           );     

   PERFORM content_test__put_line(''--------------------------------'');

-- symlinks/revisions should be deleted automatically
   PERFORM content_item__delete(simple_item_id);
   PERFORM content_template__delete(item_template_id);
   PERFORM content_item__delete(item_id);
   PERFORM content_template__delete(type_template_id);
   PERFORM content_template__delete(def_type_template_id);
   PERFORM content_template__delete(dum_template_id);
   PERFORM content_folder__delete(sub_sub_folder_id);
   PERFORM content_folder__delete(sub_folder_id);
   PERFORM content_folder__delete(folder_id);
   PERFORM content_folder__delete(folder_b_id);

   return null;

end;' language 'plpgsql';


select test_content();

drop function test_content();

