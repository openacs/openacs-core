
create index cr_revisions_content_idx on cr_revisions (substring(content for 100));