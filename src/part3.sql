---------------------------------   01   ---------------------------------

create or replace function transferedpoints_in_human_readable_form()
    returns table
            (
                peer1        varchar,
                peer2        varchar,
                pointsamount bigint
            )
as
$$
begin
    return query (select tp.checkingpeer,
                         tp.checkedpeer,
                         tp.pointsamount - tp1.pointsamount
                  from transferredpoints as tp
                  join transferredpoints as tp1 on tp.checkedpeer = tp1.checkingpeer and
                                                   tp.checkingpeer = tp1.checkedpeer and
                                                   tp.id < tp1.id);
end;
$$ language plpgsql;

select *
from transferedpoints_in_human_readable_form();

---------------------------------   02   ---------------------------------

create or replace function number_of_xp()
    returns table
            (
                peer varchar,
                task varchar,
                xp   bigint
            )
as
$$
begin
    return query (select checks.peer, checks.task, xpamount
                  from checks
                  join xp x on checks.id = x."check"
                  order by checks.peer);
end;
$$ language plpgsql;

select *
from number_of_xp();

---------------------------------   03   ---------------------------------

create or replace function peers_didnt_come_out_for_the_day(in somedate date)
    returns table
            (
                nickname varchar
            )
as
$$
        select peer
        from timetracking
        where state = 1 and date = somedate
    except
        select peer
        from timetracking
        where state = 2 and date = somedate;
$$ language sql;

select *
from peers_didnt_come_out_for_the_day('2022-01-02');

---------------------------------   04   ---------------------------------

create or replace procedure successful_and_unsuccessful_checks(inout successfulchecks numeric,
                                                               inout unsuccessfulchecks numeric) as
$$
begin
    select round(sc * 100),
           round((1 - sc) * 100)
    into successfulchecks, unsuccessfulchecks
    from (select (select count(id)
                  from p2p
                  where state = 'Success')::numeric /
                 (select count(id)
                  from p2p
                  where state in ('Success', 'Failure'))::numeric as sc) as foo;
end;
$$ language plpgsql;

call successful_and_unsuccessful_checks(0, 0);

---------------------------------   05   ---------------------------------

create or replace procedure changing_points_according_to_transferedpoints(in ref refcursor) as
$$
begin
    open ref for
        select *
        from (select distinct checkingpeer,
                              ((select sum(pointsamount)
                                from transferredpoints as bar
                                where foo.checkingpeer = bar.checkingpeer) -
                               (select sum(pointsamount)
                                from transferredpoints as bar
                                where foo.checkingpeer = bar.CheckedPeer))::bigint as pointschange
              from transferredpoints as foo
              order by 2 desc) as foo
        where pointschange is not null;
end;
$$ language plpgsql;

begin;
call changing_points_according_to_transferedpoints('ref');
fetch all in "ref";
end;

---------------------------------   06   ---------------------------------

create or replace procedure changing_points_according_to_function(in ref refcursor) as
$$
begin
    open ref for
        select peer1 as Peer, sum(pointsamount) as PointsChange
        from transferedpoints_in_human_readable_form()
        group by peer1
        order by PointsChange desc;
end;
$$ language plpgsql;

begin;
call changing_points_according_to_function('ref');
fetch all in "ref";
end;

---------------------------------   07   ---------------------------------

create or replace procedure most_frequently_checked_task_for_each_day(in ref refcursor) as
$$
begin
    open ref for
        with spam as (
            select time, count(time) as cnt, foo.task
            from (select time::date, "check", checks.task
                  from p2p
                  join checks on "check" = checks.id
                  where state in ('Success', 'Failure')) as foo
            group by time, "check", foo.task)
        select distinct time as day, eggs.task
        from spam as eggs
        where cnt = (select MAX(cnt) from spam where time = eggs.time);
end;
$$ language plpgsql;

begin;
call most_frequently_checked_task_for_each_day('ref');
fetch all in "ref";
end;

---------------------------------   08   ---------------------------------

create or replace procedure duration_of_last_p2p_check(in ref refcursor) as
$$
begin
    open ref for
        with last_start as (
            select p2p.time, p2p.check
            from p2p
            where state = 'Start'
            order by time desc limit 1)
        select (p2p.time - ls.time)::time as last_eval
        from p2p
        join last_start as ls on ls.check = p2p."check"
        where p2p.state != 'Start';
end;
$$ language plpgsql;

begin;
call duration_of_last_p2p_check('ref');
fetch all in "ref";
end;

---------------------------------   09   ---------------------------------

create or replace procedure whole_block_completed(in ref refcursor, in blockname varchar) as
$$
begin
    open ref for
        with tasks_in_block as (
                select title from tasks
                where title similar to blockname || '[0-9]%'),
             completed_tasks as (
                select peer, task, max(date) as completed_date
                from checks
                where task in (select title from tasks_in_block)
                group by peer, task
             )
        select peer, max(completed_date) as last_completion_date
        from completed_tasks
        group by peer
        having count(distinct task) = (select count(*) from tasks_in_block)
        order by last_completion_date;
end;
$$ language plpgsql;

begin;
call whole_block_completed('cursor_name', 'CPP');
fetch all in "cursor_name";
end;

---------------------------------   10   ---------------------------------

create or replace function get_peers_friends(peer varchar)
    returns table
            (
                friend varchar
            )
as
$$
begin
    return query (select peer1 as friend
                  from friends
                  where peer2 = peer
                  union
                  select peer2 as friend
                  from friends
                  where peer1 = peer);
end;
$$ language plpgsql;

create or replace function get_peers_recommended_peers(recommendingpeer varchar)
    returns table
            (
                recommendedpeer varchar
            )
as
$$
begin
    return query (select recommendations.recommendedpeer
                  from recommendations
                  where recommendations.peer = recommendingpeer);
end;
$$ language plpgsql;

create or replace procedure func10(in ref refcursor) as
$$
begin
    open ref for
        select distinct min(Peer), RecommendedPeer
        from (select *,
                     dense_rank()
                     over (partition by Peer order by count(*) desc) as rank
              from (select nickname                                                 as Peer,
                           get_peers_recommended_peers(get_peers_friends(nickname)) as RecommendedPeer
                    from peers) as foo
              group by Peer, RecommendedPeer) as bar

        where Peer != RecommendedPeer
          and rank = 1
        group by RecommendedPeer;
end;
$$ language plpgsql;

begin;
call func10('ref');
fetch all in "ref";
end;

---------------------------------   11   ---------------------------------

create or replace procedure peers_started_blocks(
    blockname_1 varchar,
    blockname_2 varchar, in ref refcursor) as
$$
begin
    open ref for
        with first_block as (select distinct peer
                             from checks
                             where task similar to blockname_1),
             second_block as (select distinct peer
                              from checks
                              where task similar to blockname_2),
             both_blocks as (select distinct peer
                             from first_block
                             intersect
                             select distinct peer
                             from second_block),
             no_blocks as (select nickname as peer
                           from peers
                           except
                           (select distinct peer
                            from first_block
                            union
                            select distinct peer
                            from second_block))

        select (select count(peer) from first_block) * 100 /
               count(nickname) as StartedBlock1,
               (select count(peer) from second_block) * 100 /
               count(nickname) as StartedBlock2,
               (select count(peer) from both_blocks) * 100 /
               count(nickname) as StartedBothBlocks,
               (select count(peer) from no_blocks) * 100 /
               count(nickname) as DidntStartAnyBlock
        from peers;
end;
$$ language plpgsql;

begin;
call peers_started_blocks('C[0-9]%', 'CPP%', 'ref');
fetch all in "ref";
end;

---------------------------------   12   ---------------------------------

create or replace function peersfriends(peer varchar)
    returns table
            (
                friend varchar
            )
as
$$
begin
    return query
            select peer2
            from friends
            where peer1 = peer
        union
            select peer1
            from friends
            where peer2 = peer;
end;
$$ language plpgsql;

create or replace procedure number_of_friends(numberofpeers bigint,
                                              in ref refcursor) as
$$
begin
    open ref for
        select nickname, count(peersfriends) as FriendsCount
        from peers,
             lateral peersfriends(nickname) as peersfriends
        group by nickname
        order by FriendsCount desc
        limit numberofpeers;
end;
$$ language plpgsql;

begin;
call number_of_friends(3, 'ref');
fetch all in "ref";
end;

---------------------------------   13   ---------------------------------

create or replace procedure birthday_checks(in ref refcursor) as
$$
begin
    open ref for
        with counts as (select count(peer)
                               filter ( where p2p.state = 'Success' and
                                              verter.state <>
                                              'Failure')            as success,
                               count(peer)
                               filter (where (p2p.state = 'Success' and
                                              verter.state = 'Failure') or
                                             p2p.state = 'Failure') as fail
                        from checks
                                 join p2p on checks.id = p2p."check"
                                 join verter on checks.id = verter."check"
                                 join peers on peers.nickname = checks.peer
                        where extract(month from checks.date) =
                              extract(month from peers.birthday)
                          and extract(day from checks.date) =
                              extract(day from peers.birthday))
        select (success::numeric / (success + fail)::numeric *
                100)::int                                             as SuccessfulChecks,
               (fail::numeric / (success + fail)::numeric * 100)::int as UnsuccessfulChecks
        from counts;
end;
$$ language plpgsql;


begin;
call birthday_checks('ref');
fetch all in "ref";
end;

---------------------------------   14   ---------------------------------

create or replace function xp_amount()
returns table (
                peer varchar(20),
                xp numeric
              ) as
$$
begin
    return query
        WITH max_xp AS (SELECT checks.peer, MAX(table_xp.xpamount) AS max_xp
                        FROM checks
                        JOIN xp AS table_xp ON checks.id = table_xp."check"
                        GROUP BY checks.peer, task)
        SELECT max_xp.peer AS Peer, SUM(max_xp) AS XP
        FROM max_xp
        GROUP BY max_xp.peer
        ORDER BY XP;
end;
$$ language plpgsql;

select * from xp_amount();

---------------------------------   15   ---------------------------------

create or replace procedure passed_tasks(in task1 varchar, in task2 varchar,
                                         in task3 varchar, in ref refcursor) as
$$
begin
    open ref for
        select distinct peer
        from checks as foo
        where exists(select peer
                     from checks
                              join p2p on checks.id = p2p."check"
                     where task = task1
                       and state = 'Success'
                       and peer = foo.peer)
          and exists(select peer
                     from checks
                              join p2p on checks.id = p2p."check"
                     where task = task2
                       and state = 'Success'
                       and peer = foo.peer)
          and (not exists(select peer
                     from checks
                              join p2p on checks.id = p2p."check"
                     where task = task3
                       and state = 'Success'
                       and peer = foo.peer)
            );
end;
$$ language plpgsql;

begin;
call passed_tasks('C2_SimpleBashUtils', 'C3_s21_string+', 'CPP3_SmartCalc_v2.0',
                  'ref');
fetch all in "ref";
end;

---------------------------------   16   ---------------------------------

create or replace procedure previous_tasks(in ref refcursor) as
$$
begin
    open ref for
        with recursive recursion
                           as (select 'C2_SimpleBashUtils'::varchar as task,
                                      0::bigint                     as PrevCount
                               union
                               select title, recursion.PrevCount + 1
                               from recursion,
                                    tasks
                               where parenttask = recursion.task
                                 and PrevCount < (select count(*) from tasks))
        select *
        from recursion;

end;
$$ language plpgsql;

begin;
call previous_tasks('ref');
fetch all in "ref";
end;

---------------------------------   17   ---------------------------------

create or replace procedure lucky_days(in N int, in ref refcursor) as
$$
begin
    open ref for
        select date
        from (select date,
                     sum(case
                             when p2p.state = 'Success' and (xp.xpamount /
                                                             (select maxxp
                                                              from tasks
                                                              where title = checks.task) >=
                                                             0.8) then 1
                             else 0 end)
                     over (partition by date order by p2p.time) as consecutive_success
              from checks
                       join p2p on p2p."check" = checks.id
                       left join xp on xp."check" = checks.id) as t
        where consecutive_success >= N
        group by date;
end;
$$ language plpgsql;

begin;
call lucky_days(2, 'ref');
fetch all in "ref";
end;

---------------------------------   18   ---------------------------------

create or replace procedure func18(in ref refcursor) as
$$
begin
    open ref for
        select peer, count(distinct task) as completed
        from checks
        group by peer
        order by 2 desc
        limit 1;
end;
$$
    language plpgsql;

begin;
call func18('ref');
fetch all in "ref";
end;


---------------------------------   19   ---------------------------------

create or replace procedure most_of_all_xp(in ref refcursor)
as
$$
begin
    open ref for
        select * from xp_amount()
        order by xp desc
        limit 1;
end;
$$ language plpgsql;

begin;
call most_of_all_xp('cursor_name');
fetch all in "cursor_name";
end;

---------------------------------   20   --------------------------------

create or replace procedure longest_time(in ref refcursor) as
$$
begin
    open ref for
        with person_in as (
                select tt.peer, tt.date, tt.time
                from timetracking tt
                where state = 1),
             person_out as (
                select tt.peer, tt.date, tt.time
                from timetracking tt
                where state = 2)
        select (po.time - pi.time)::time as diff
        from person_in as pi
        join person_out as po on pi.peer = po.peer
        where pi.date = po.date
        order by diff desc
        limit 1;
end;
$$ language plpgsql;

begin;
call longest_time('cursor_name');
fetch all in "cursor_name";
end;

---------------------------------   21   --------------------------------

create or replace procedure peer_came_early(in "time" time, in n integer, in ref refcursor) as
$$
begin
    open ref for
        with tmp as (
            select tt.peer, count(*)
            from timetracking as tt
            where tt.state = 1 and tt.time <= peer_came_early."time"
            group by tt.peer
            having count(*) >= n)
        select peer from tmp;
end;
$$ language plpgsql;

begin;
call peer_came_early('09:20:00', 2, 'cursor_name');
fetch all in "cursor_name";
end;

---------------------------------   22   --------------------------------

create or replace procedure mtimes_left(in n integer, in m integer, in ref refcursor) as
$$
begin
    open ref for
            with person_out as (
                select peer, date, time,
                       count(*) over (partition by peer) as cnt
                from timetracking
                where state = 2)
            select peer
            from person_out
            where date >= (current_date - n) and cnt >= m;
end;
$$ language plpgsql;

begin;
call mtimes_left(10, 1, 'cursor_name');
fetch all in "cursor_name";
end;

---------------------------------   23   --------------------------------

create or replace procedure last_in(in ref refcursor) as
$$
begin
    open ref for
        select peer
        from timetracking
        where state = 1 and date = current_date
        order by time desc
        limit 1;
end;
$$ language plpgsql;

begin;
call last_in('cursor_name');
fetch all in "cursor_name";
end;

---------------------------------   24   --------------------------------

create or replace procedure nminutes_left(in n integer, in ref refcursor) as
$$
begin
    open ref for
        with person_out as (
                select peer, date,
                       coalesce(lead(time) over (partition by peer), '23:59:59') - time as diff
                from timetracking
                where state = 2
                order by peer)
        select peer
        from person_out
        where date = (current_date - 1) and diff > make_interval(mins => n);
end;
$$ language plpgsql;

begin;
call nminutes_left(850, 'cursor_name');
fetch all in "cursor_name";
end;

---------------------------------   25   --------------------------------

create or replace procedure entries_percentage(in ref refcursor) as
$$
begin
    open ref for
        with months as (
                select date '2000-01-01' + interval '1' month * s.a as date
                from generate_series(0, 11) AS s(a)),
             person_in as (
                select tt.peer, tt.date, tt.time
                from timetracking tt
                where state = 1)
        select to_char(m.date, 'Month') as Month,
            (case
                when count(peer) != 0 then
                    ((count(peer) filter (where time < '12:00:00') / count(peer)::float) * 100)::int
                else
                    0
            end) as EarlyEntries
        from months as m
        left join peers on to_char(m.date, 'Month') = to_char(birthday, 'Month')
        left join person_in as pi on peers.nickname = pi.peer
        group by m.date
        order by m.date;
end;
$$ language plpgsql;

begin;
call entries_percentage('cursor_name');
fetch all in "cursor_name";
end;
