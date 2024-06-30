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