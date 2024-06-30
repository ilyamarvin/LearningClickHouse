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