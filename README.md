﻿# LearningClickHouse
## Задание
1) Поднять кликхаус в докере
2) Настроить пользователя администратора
3) Создать базы для стейджинга, исторических данных, текущих данных и буферных таблиц
4) Создать роль только для чтения и роль с возможность создавать и заполнять данные в БД стейджинга(stg). Создать двух пользователей с такими правами по умолчанию.
5) Реализовать через буфферную таблицу заполнение stg слоя
6) Создать матереализованное представление для перемещения данных из stg слоя в слой текущих данных
7) Смоделировать вставку данных в буфферную таблицу для stg слоя. В конечном итоге данные должны быть заполнены и в stg слое, и в слое текущих данных.
Команды для выполнениния пунктов 2-7 включительно, выложить в свой git. Каждый пункт - отдельный файл
Для пункта 7 необходимы скриншоты данных в таблице stg и current слоя
P.S. просьба делать осмысленную структуру таблицы(поля). Их может быть 3-4, но чтобы они могли нести какую то потенциально полезную информацию

## Выполнение
1. Для того чтобы поднять кликхаус напишем собственный [docker-compose файл](docker-compose.yml) и воспользуемся [официальным образом ClickHouse](https://hub.docker.com/r/clickhouse/clickhouse-server/)
    ```
    docker compose up -d
    ```

2. Для настройки пользователя администратора воспользуемся следующим запросом:
    ```sql
    create user admin_sereda identified with sha256_password by 'admin_sereda';
    ```
    - Откроем файл users.xml в контейнере по пути /etc/clickhouse-server/ и добавим новые строки для пользователя default:

    ```xml
    <access_management>1</access_management>
    <named_collection_control>1</named_collection_control>
    <show_named_collections>1</show_named_collections>
    <show_named_collections_secrets>1</show_named_collections_secrets>
    ```
    - Выдадим пользователю ‘admin’ все привелегии:
    ```sql
    grant all on *.* to admin_sereda with grant option;
    ```

3. Создадим базы для стейджинга, исторических данных, текущих данных и буферных таблиц
    ```sql
    create database stg;
    create database history;
    create database current;
    create database direct_log;
    ```

4. Создадим роль только для чтения и роль с возможностью создания и заполнения данными в БД стейджинга(stg). Создать двух пользователей с такими правами по умолчанию.
    ```sql
    create role readonly;
    create role stg_access;

    grant select on *.* to readonly;
    grant create table, insert on stg.* to stg_access;

    create user readonly identified with sha256_password by 'readonly' default role readonly;
    create user stg_access identified with sha256_password by 'stg_access' default role stg_access;
    ```

5. Реализация заполнения stg слоя через буферную таблицу
    ```sql
    create table stg.employee_actions
    (
        employee_id UInt32,
        dt          DateTime,
        action_id   UInt32,
        action_type LowCardinality(String),
        tsd_id      UInt32,
        dt_created  DateTime
    )
    engine = MergeTree
    partition by toYYYYMMDD(dt)
    order by employee_id
    comment 'Таблица действий сотрудников, совершаемых на складе';

    create table direct_log.employee_actions_buf
    (
        employee_id UInt32,
        dt          DateTime,
        action_id   UInt32,
        action_type LowCardinality(String),
        tsd_id      UInt32,
        dt_created  MATERIALIZED now()
    )
    engine = Buffer(stg, employee_actions, 16, 10, 100, 10000, 1000000, 10000000, 100000000)
    comment 'Буферная таблица для заполнения таблицы employee_actions (Действия сотрудников)';
    ```

6. Создание матереализованного представления для перемещения данных из stg слоя в слой текущих данных
    ```sql
    create table current.employee_actions
    (
        employee_id UInt32,
        dt          DateTime,
        action_id   UInt32,
        action_type LowCardinality(String),
        tsd_id      UInt32,
        dt_created  DateTime
    )
    engine = ReplacingMergeTree(dt)
    partition by toYYYYMMDD(dt)
    order by employee_id
    ttl toStartOfDay(dt) + interval 1 day
    comment 'Таблица последних действий сотрудников, совершенных на складе';

    create materialized view stg.mv_employee_actions to current.employee_actions 
        (
            employee_id UInt32,
            dt          DateTime,
            action_id   UInt32,
            action_type LowCardinality(String),
            tsd_id      UInt32,
            dt_created  DateTime
        ) as
        select employee_id
            , dt
            , action_id
            , action_type
            , tsd_id
            , dt_created
        from stg.employee_actions;
    ```

7. Смоделируем вставку данных в буфферную таблицу для stg слоя. В конечном итоге данные должны быть заполнены и в stg слое, и в слое текущих данных.
    ```sql
    insert into direct_log.employee_actions_buf (employee_id, dt, action_id, action_type, tsd_id)
    values (1, now(), 4, 'ASM', 111),
           (1, now() - interval 5 minute, 3, 'ASM', 111),
           (1, now() - interval 6 minute, 2, 'ASM', 111),
           (1, now() - interval 7 minute, 1, 'ASM', 111),
           (2, now() - interval 1 hour, 5, 'SRT', 222),
           (3, now() - interval 2 hour, 6, 'ASS', 333);

    select *, dt_created from direct_log.employee_actions_buf;

    select * from stg.employee_actions;

    select * from current.employee_actions final;
    ```

Скриншоты данных в таблице stg и current слоя представлены [тут](screenshots)
