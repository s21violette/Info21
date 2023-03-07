create or replace procedure add_p2p_review(in checkedpeer varchar,
                                           in checkingpeer varchar,
                                           in tasktitle varchar,
                                           in status checkstatus,
                                           in "time" timestamp default current_timestamp) as
$$
begin
    if status = 'Start' then
        insert into checks
        values ((select max(id) + 1 from checks), checkedpeer, tasktitle,
                "time"::date);
        insert into p2p
        values ((select max(id) + 1 from p2p),
                (select max(id) from checks),
                checkingpeer,
                status, "time");
    else
        insert into p2p
        values ((select max(id) + 1 from p2p),
                (select "check"
                 from p2p
                 where p2p.checkingpeer = add_p2p_review.checkingpeer
                   and state = 'Start'
                 order by p2p.time desc
                 limit 1),
                checkingpeer,
                status, "time");
    end if;
end;
$$ language plpgsql;

call add_p2p_review('glenpoin', 'lymondgl', 'C2_SimpleBashUtils', 'Success');
call add_p2p_review('chamomiv', 'lymondgl', 'C2_SimpleBashUtils', 'Start');
call add_p2p_review('chamomiv', 'lymondgl', 'C2_SimpleBashUtils', 'Success');

create or replace procedure add_verter_review(in checkedpeer varchar,
                                              in tasktitle varchar,
                                              in status checkstatus,
                                              in "time" timestamp default current_timestamp) as
$$
begin
    insert into verter
    values ((select max(id) + 1 from verter),
            (select "check"
             from p2p
                      join checks on checks.id = p2p."check"
             where state = 'Success'
               and checks.peer = add_verter_review.checkedpeer
               and checks.task = tasktitle
             order by p2p."time" desc
             limit 1), status, add_verter_review."time");
end;
$$ language plpgsql;

call add_verter_review('glenpoin', 'C2_SimpleBashUtils', 'Start');
call add_verter_review('glenpoin', 'C2_SimpleBashUtils', 'Success');

create or replace function fnc_trg_p2p_insert_audit()
    returns trigger as
$$
begin
    if new.state = 'Start' then
        if exists(select *
                  from transferredpoints
                  where checkingpeer =
                        new.checkingpeer
                    and checkedpeer =
                        (select peer
                         from checks
                         where new."check" = checks.id)) then
            update transferredpoints
            set pointsamount = pointsamount + 1
            where checkingpeer =
                  new.checkingpeer
              and checkedpeer =
                  (select peer from checks where new."check" = checks.id);
        else
            insert into transferredpoints
            values ((select max(id) + 1 from transferredpoints),
                    (select peer from checks where new."check" = checks.id),
                    new.checkingpeer,
                    1);
        end if;
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_p2p_insert_audit
    after insert
    on p2p
    for each row
execute procedure fnc_trg_p2p_insert_audit();

call add_p2p_review('manhunte', 'pilafber', 'C3_s21_string+', 'Start');
call add_p2p_review('manhunte', 'pilafber', 'C3_s21_string+', 'Success');

create or replace function fnc_trg_xp_insert_audit() returns trigger as
$$
begin
    if new.xpamount > (select maxxp
                       from tasks
                                join checks on tasks.title = checks.task
                       where checks.id = new."check") or
       (select state
        from p2p
                 join checks on checks.id = p2p."check"
        where checks.id = new."check"
          and state in ('Success', 'Failure')) <> 'Success' or
       (exists(select state
               from verter
                        join checks on checks.id = verter."check"
               where checks.id = new."check")
           and
        (select state
         from verter
                  join checks on checks.id = verter."check"
         where checks.id = new."check"
           and (state in ('Success', 'Failure')))
            <> 'Success') then
        raise exception 'Invalid insertion on xp';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_xp_insert_audit
    before insert
    on xp
    for each row
execute procedure fnc_trg_xp_insert_audit();

insert into xp
values ((select max(id) + 1 from xp), 18, '200');
