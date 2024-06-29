create role readonly;
create role stg_access;

grant select on *.* to readonly;
grant create table, insert on stg.* to stg_access;

create user readonly identified with sha256_password by 'readonly' default role readonly;
create user stg_access identified with sha256_password by 'stg_access' default role stg_access;