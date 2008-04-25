alter table cr_folders add foreign key (folder_id) references cr_items(item_id) on delete cascade; 
 drop trigger cr_folder_ins_up_ri_trg on cr_folders;