begin;

ALTER TABLE users ALTER COLUMN password_hash_algorithm SET DEFAULT 'salted_sha1';

update users set
  password_hash_algorithm = 'salted_sha1'
where password_hash_algorithm = 'salted-sha1';

end;

