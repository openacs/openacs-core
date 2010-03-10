alter table apm_package_dependencies drop constraint apm_package_deps_type_ck;
alter table apm_package_dependencies add
  constraint apm_package_deps_type_ck
  check (dependency_type in ('provides', 'requires', 'extends', 'embeds'));
