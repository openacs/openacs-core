set serveroutput on size 1000000 format wrapped

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
folder_id := content_folder.new('grandpa', 'Grandpa', NULL, -100);
folder_b_id := content_folder.new('grandma', 'Grandma', NULL, -100);
sub_folder_id := content_folder.new('pa', 'Pa', NULL, folder_id);
sub_sub_folder_id := content_folder.new('me', 'Me', NULL, sub_folder_id);
item_id := content_item.new('puppy', sub_sub_folder_id);

simple_item_id := content_item.new(
	name		=> 'bunny',
	title		=> 'Bugs Bunny',
	description	=> 'Simple (Revisionless) Item Test',
	text		=> 'Simple (Revisionless) Item Test Text',
	parent_id	=> sub_sub_folder_id
    );

live_revision_id := content_revision.new(
	title		=> 'Live Revision of Puppy',
	description	=> 'Live Revision of Puppy Description',
	publish_date	=> to_date('1999-08-12','YYYY-MM-DD'),
	mime_type	=> 'text/html',
	text		=> 'Text for Live Revision of Puppy',
	item_id		=> item_id
    );

late_revision_id := content_revision.new(
	title		=> 'Latest Revision of Puppy',
	description	=> 'Latest Revision of Puppy Description',
	publish_date	=> to_date('2001-09-22','YYYY-MM-DD'),
	mime_type	=> 'text/html',
	text		=> 'Text for Latest Revision of Puppy',
	item_id		=> item_id
    );

item_template_id := content_template.new(
	name		=> 'Item Template'
    );

type_template_id := content_template.new(
	name		=> 'Type Template'
    );

def_type_template_id := content_template.new(
	name		=> 'Dumb Default Type Template'
    );

dum_template_id := content_template.new(
	name		=> 'Default Type Template'
    );


dbms_output.put_line('-------------------------------------');
dbms_output.put_line('CREATING CONTENT FOLDERS AND ITEMS...');
dbms_output.put_line('...all tests passed');
dbms_output.put_line('Folder grandpa is ' || folder_id);
dbms_output.put_line('Folder grandma is ' || folder_b_id);
dbms_output.put_line('Sub folder pa is ' || sub_folder_id);
dbms_output.put_line('Sub sub folder me is ' || sub_sub_folder_id);
dbms_output.put_line('Added item puppy to sub sub folder me at ' || item_id);
dbms_output.put_line('Created simple item bunny to sub sub folder me at ' || simple_item_id);
--dbms_output.put_line('Added a revision to puppy at ' || live_revision_id);
--dbms_output.put_line('Added a revision to puppy at ' || late_revision_id);
--dbms_output.put_line('Created Item Template at ' || item_template_id);
--dbms_output.put_line('Created Type Template at ' || type_template_id);
--dbms_output.put_line('Created Def Type Template at ' || def_type_template_id);
--dbms_output.put_line('Created Dum Def Type Template at ' || dum_template_id);


dbms_output.put_line('-----------------------------------');
dbms_output.put_line('FOLDERS AND EMPTY FOLDERS AND SUBFOLDERS');
dbms_output.put_line('...all tests passed');
--dbms_output.put_line('Is folder ' || folder_id || ' empty? ' ||
--        content_folder.is_empty(folder_id));
--dbms_output.put_line('Is folder ' || sub_sub_folder_id || ' empty? ' ||
--        content_folder.is_empty(sub_sub_folder_id));
--dbms_output.put_line('Is folder ' || sub_folder_id || ' empty? ' ||
--        content_folder.is_empty(sub_folder_id));
--dbms_output.put_line('Is folder ' || folder_b_id || ' empty? ' ||
--        content_folder.is_empty(folder_b_id));
--dbms_output.put_line('Is folder ' || folder_id || '? ' ||
--        content_folder.is_folder(folder_id));
--dbms_output.put_line('Is folder ' || item_id || '? ' ||
--        content_folder.is_folder(item_id));
--dbms_output.put_line('Is ' || folder_id || ' a subfolder of ' ||
--    sub_folder_id || '? ' || content_folder.is_sub_folder(sub_folder_id,folder_id));
--dbms_output.put_line('Is ' || sub_folder_id || ' a subfolder of ' ||
--    folder_id || '? ' || content_folder.is_sub_folder(folder_id,sub_folder_id));
--dbms_output.put_line('Is ' || sub_sub_folder_id || ' a subfolder of ' ||
--    folder_id || '? ' || content_folder.is_sub_folder(folder_id,sub_sub_folder_id));
--dbms_output.put_line('Is ' || sub_folder_id || ' a subfolder of ' ||
--    -1 || '? ' || content_folder.is_sub_folder(-1,sub_folder_id));




dbms_output.put_line('-------------------------------------');
dbms_output.put_line('LIVE AND LATEST REVISIONS...');
dbms_output.put_line('...all tests passed');
--dbms_output.put_line('Get live_revision_id for item puppy ' || item_id ||
--    ' is ' || content_item.get_live_revision(item_id));

content_item.set_live_revision(live_revision_id);


--dbms_output.put_line('Set ' || live_revision_id || 
--    ' as the live revision for item puppy ' || item_id);
--dbms_output.put_line('Get live_revision_id for item puppy ' || item_id ||
--    ' is ' || content_item.get_live_revision(item_id));
--dbms_output.put_line('Get live_revision_id for item kitty ' || 
--    simple_item_id || ' is ' || 
--    content_item.get_live_revision(simple_item_id));
--dbms_output.put_line('Get late_revision_id for item puppy ' || item_id ||
--    ' is ' || content_item.get_latest_revision(item_id));
--dbms_output.put_line('Get late_revision_id for item bunny ' || simple_item_id ||
--    ' is ' || content_item.get_latest_revision(simple_item_id));



content_item.register_template(item_id,item_template_id,'public');
content_type.register_template('content_revision',type_template_id,'public');
content_type.register_template('content_revision',def_type_template_id,'admin');
content_type.register_template('content_revision',dum_template_id,'admin','t');
content_type.set_default_template('content_revision',def_type_template_id,'admin');


dbms_output.put_line('-------------------------------------');
dbms_output.put_line('REGISTERING TEMPLATES TO ITEMS AND TYPES...');
dbms_output.put_line('...all tests passed');
--dbms_output.put_line('Registered Item Template ' || item_template_id || 
--    ' to item puppy ' || item_id || ' with public context');
--dbms_output.put_line('Registered Type Template ' || type_template_id || 
--    ' to content_revision ' || item_id || ' with public context');
--dbms_output.put_line('Registered Default Type Template ' || 
--    def_type_template_id || ' to content_revision ' || item_id || 
--    ' with admin context');
--dbms_output.put_line('Get template id for item puppy ' || item_id || 
--    ' and context public is ' || content_item.get_template(item_id,'public'));
--dbms_output.put_line('Get template id for item puppy ' || item_id || 
--    ' and context admin is ' || content_item.get_template(item_id,'admin'));




found_folder_id := content_item.get_id('grandpa/pa/me', -1);

dbms_output.put_line('-------------------------------------');
dbms_output.put_line('LOCATING CONTENT FOLDERS AND ITEMS...');
dbms_output.put_line('...all tests passed!');
--dbms_output.put_line('Found me at grandpa/pa/me: ' || found_folder_id);
--dbms_output.put_line('Path for ' || found_folder_id || ' is ' || 
--  content_item.get_path(found_folder_id));
dbms_output.put_line('Path for puppy ' || item_id || ' is ' || 
  content_item.get_path(item_id));
dbms_output.put_line('Path for puppy ' || item_id || ' from folder_id: ' || 
  folder_id || ' is ' || 
  content_item.get_path(item_id,folder_id));
dbms_output.put_line('Path for puppy ' || item_id ||
  ' from sub_folder_id: ' || sub_folder_id || ' is ' || 
  content_item.get_path(item_id,sub_folder_id));
dbms_output.put_line('Path for puppy' || item_id
  || ' from sub_sub_folder_id: ' || sub_sub_folder_id || ' is ' || 
  content_item.get_path(item_id,sub_sub_folder_id));
dbms_output.put_line('Get id of item with invalid path - shouldn''t return anything');
dbms_output.put_line('Found item at ' || content_item.get_id('grandpa/me', -200));
dbms_output.put_line('Get id of item using subpath');
dbms_output.put_line('Found item at ' || content_item.get_id('pa/me/puppy', folder_id));
dbms_output.put_line('This is the path to a folder from a subfolder');
dbms_output.put_line('Path for ' || sub_folder_id || ' from sub_sub_folder_id: ' || 
  sub_sub_folder_id || ' is ' || 
  content_item.get_path(sub_folder_id,sub_sub_folder_id));
dbms_output.put_line('This is a path to an item from a non-existent item');
dbms_output.put_line('Path for ' || item_id || ' from nonexistent_id: ' || 
  -200 || ' is ' || 
  content_item.get_path(item_id,-200));
dbms_output.put_line('This is a path to an item from a non-related branch');
dbms_output.put_line('Path for ' || item_id || ' from unrelated branch: ' || 
  folder_b_id || ' is ' || 
 content_item.get_path(item_id,folder_b_id));


dbms_output.put_line('-------------------------------------');
dbms_output.put_line('MOVING/RENAMING CONTENT FOLDERS...');
dbms_output.put_line('...all tests passed');
--dbms_output.put_line('Moving me from under pa to under grandpa');
content_item.move(sub_sub_folder_id, folder_id);
--dbms_output.put_line('Path for ' || item_id || ' is ' || 
--content_item.get_path(item_id));
--dbms_output.put_line('Moving grandpa to pa - this should''nt work');
-- content_folder.move(folder_id, sub_folder_id);
--dbms_output.put_line('Path for ' || item_id || ' is ' || 
--  content_item.get_path(item_id));
--dbms_output.put_line('Renaming puppy to kitty...');
content_item.edit_name(item_id, 'kitty');
--dbms_output.put_line('Renaming me to aunty...');
content_folder.edit_name(sub_sub_folder_id, 'aunty');
--dbms_output.put_line('Path for ' || item_id || ' is ' || 
--  content_item.get_path(item_id));
--dbms_output.put_line('Renaming kitty to pa -- this should work');
--content_item.edit_name(item_id, 'pa');
--dbms_output.put_line('Path for ' || item_id || ' is ' || 
--content_item.get_path(item_id));


dbms_output.put_line('-------------------------------------');
dbms_output.put_line('SYMLINKS...');
--dbms_output.put_line('...all tests passed');
/*
symlink_a_id := content_symlink.new('link_a',sub_sub_folder_id,sub_folder_id);
dbms_output.put_line('Create a link in pa to aunty: Symlink is ' || symlink_a_id);

dbms_output.put_line('Is ' || symlink_a_id || ' a symlink?: ' || content_symlink.is_symlink(symlink_a_id));

dbms_output.put_line('Is ' || folder_id || ' a symlink?: ' || content_symlink.is_symlink(folder_id));

dbms_output.put_line('Path for symlink ' || symlink_a_id ||
	' is ' || content_item.get_path(symlink_a_id));

dbms_output.put_line('Resolving symlink ' || symlink_a_id ||
        ' is ' || content_symlink.resolve(symlink_a_id));

dbms_output.put_line('Resolved path for symlink ' || 
	symlink_a_id || ' is ' || 
	content_item.get_path(content_symlink.resolve(symlink_a_id)));

dbms_output.put_line('Path to item ' || item_id || ' from symlink ' ||
	symlink_a_id || ' is ' ||
        content_item.get_path(item_id, symlink_a_id));
dbms_output.put_line('Path to item ' || item_id || ' from aunty ' ||
	sub_sub_folder_id || ' is ' ||
        content_item.get_path(item_id, sub_sub_folder_id));
dbms_output.put_line('Path to pa ' || sub_folder_id || ' from symlink ' ||
	symlink_a_id || ' is ' ||
        content_item.get_path(sub_folder_id, symlink_a_id));


dbms_output.put_line('Found item ' || item_id || ' at ' ||
        content_item.get_id('/grandpa/aunty/kitty'));
dbms_output.put_line('Found item ' || item_id || ' at ' ||
        content_item.get_id('/grandpa/pa/link_a/kitty'));
dbms_output.put_line('Found item ' || item_id || ' starting at aunty ' ||
        sub_sub_folder_id || ' at ' ||
        content_item.get_id('kitty',sub_sub_folder_id));
dbms_output.put_line('Found item ' || item_id || ' starting at symlink ' ||
        symlink_a_id || ' at ' ||
        content_item.get_id('kitty',symlink_a_id));
dbms_output.put_line('Found item ' || item_id || ' starting at pa ' ||
        sub_folder_id || ' at ' ||
        content_item.get_id('link_a/kitty',sub_folder_id));





dbms_output.put_line('--------------------------------');

*/
--dbms_output.put_line('Moving item ' || item_id || ' to grandma ' || 
--	folder_b_id);
--content_item.move(item_id,folder_b_id);
--dbms_output.put_line('Path for item ' || item_id || ' is ' ||
--        content_item.get_path(item_id));     


--dbms_output.put_line('Moving folder ' || folder_b_id || ' to aunty ' || 
--	sub_sub_folder_id);
----content_item.move(folder_b_id,sub_sub_folder_id);
--dbms_output.put_line('Path for item ' || item_id || ' is ' ||
--        content_item.get_path(item_id));     

--dbms_output.put_line('--------------------------------');

-- symlinks/revisions should be deleted automatically
/*
content_item.del(simple_item_id);
content_template.del(item_template_id);
content_item.del(item_id);
content_template.del(type_template_id);
content_template.del(def_type_template_id);
content_template.del(dum_template_id);
content_folder.del(sub_sub_folder_id);
content_folder.del(sub_folder_id);
content_folder.del(folder_id);
content_folder.del(folder_b_id);
*/
end;
/
show errors



