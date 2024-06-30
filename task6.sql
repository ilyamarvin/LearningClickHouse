create table current.employee_actions
(
    employee_id UInt32,
    dt          DateTime,
    action_id   UInt32,
    action_type LowCardinality(String),
    tsd_id      UInt32,
    dt_created  DateTime
)
engine = ReplacingMergeTree()
partition by toYYYYMMDD(dt)
order by employee_id
ttl toStartOfDay(dt) + interval 1 day
comment 'Таблица последних действий сотрудников, совершенных на складе';

create materialized view stg.mv_employee_actions to current.employee_actions as
    select employee_id
        , dt
        , action_id
        , action_type
        , tsd_id
        , dt_created
    from stg.employee_actions;