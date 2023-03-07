create table peers
(
    nickname varchar primary key,
    birthday date
);

create table tasks
(
    title      varchar primary key,
    parenttask varchar,
    maxxp      bigint,
    foreign key (parenttask) references tasks (title)
);

create type checkstatus as enum ('Start', 'Success', 'Failure');

create table checks
(
    id   bigint primary key,
    peer varchar,
    task varchar,
    date date,
    foreign key (peer) references peers (nickname),
    foreign key (task) references tasks (title)
);

create table p2p
(
    id           bigint primary key,
    "check"      bigint,
    checkingpeer varchar,
    state        checkstatus,
    time         timestamp,
    foreign key ("check") references checks (id),
    foreign key (checkingpeer) references peers (nickname)
);

create table verter
(
    id      bigint primary key,
    "check" bigint,
    state   checkstatus,
    time    timestamp,
    foreign key ("check") references checks (id)
);

create table transferredpoints
(
    id           bigint primary key,
    checkingpeer varchar,
    checkedpeer  varchar,
    pointsamount bigint,
    foreign key (checkingpeer) references peers (nickname),
    foreign key (checkedpeer) references peers (nickname)
);

create table friends
(
    id    bigint primary key,
    peer1 varchar,
    peer2 varchar,
    foreign key (peer1) references peers (nickname),
    foreign key (peer2) references peers (nickname)
);

create table recommendations
(
    id              bigint primary key,
    peer            varchar,
    recommendedpeer varchar,
    foreign key (peer) references peers (nickname),
    foreign key (recommendedpeer) references peers (nickname)
);

create table xp
(
    id       bigint primary key,
    "check"  bigint,
    xpamount bigint,
    foreign key ("check") references checks (id)
);

create table timetracking
(
    id    bigint primary key,
    peer  varchar,
    date  date,
    time  time,
    state bigint check ( state in (1, 2) ),
    foreign key (peer) references peers (nickname)
);

insert into peers
values ('pilafber', '2000-01-01'),
       ('violette', '2000-02-02'),
       ('curranca', '2000-03-03'),
       ('lymondgl', '2000-04-04'),
       ('сhastity', '2000-05-05'),
       ('manhunte', '2000-06-06'),
       ('glenpoin', '2000-07-07'),
       ('samualca', '2000-08-08'),
       ('chamomiv', '2000-09-09');

insert into tasks
values ('C2_SimpleBashUtils', null, 250),
       ('C3_s21_string+', 'C2_SimpleBashUtils', 500),

       ('CPP1_s21_matrix+', 'C3_s21_string+', 300),
       ('CPP2_containers', 'CPP1_s21_matrix+', 350),
       ('CPP3_SmartCalc_v2.0', 'CPP2_containers', 600);

insert into checks
values (1, 'pilafber', 'C2_SimpleBashUtils', '2022-05-02'),
       (2, 'pilafber', 'C2_SimpleBashUtils', '2022-05-03'),
       (3, 'curranca', 'C2_SimpleBashUtils', '2022-05-04'),
       (4, 'violette', 'C2_SimpleBashUtils', '2022-05-04'),
       (5, 'сhastity', 'C2_SimpleBashUtils', '2022-05-05'),
       (6, 'lymondgl', 'C2_SimpleBashUtils', '2022-05-05'),
       (7, 'manhunte', 'C2_SimpleBashUtils', '2022-05-05'),
       (8, 'сhastity', 'C2_SimpleBashUtils', '2022-05-05'),
       (9, 'pilafber', 'C3_s21_string+', '2022-05-15'),
       (10, 'violette', 'C3_s21_string+', '2022-05-15'),
       (11, 'curranca', 'C3_s21_string+', '2022-05-15'),
       (12, 'pilafber', 'CPP1_s21_matrix+', '2022-06-01'),
       (13, 'pilafber', 'CPP1_s21_matrix+', '2022-06-02'),
       (14, 'violette', 'CPP1_s21_matrix+', '2022-06-03'),
       (15, 'curranca', 'CPP1_s21_matrix+', '2022-06-03'),
       (16, 'glenpoin', 'C2_SimpleBashUtils', '2022-07-01'),
       (17, 'glenpoin', 'C3_s21_string+', '2022-07-01');

insert into p2p
values (1, 1, 'violette', 'Start', '2022-05-02 09:00:00'),
       (2, 1, 'violette', 'Failure', '2022-05-02 10:00:00'),

       (3, 2, 'curranca', 'Start', '2022-05-03 09:00:00'),
       (4, 2, 'curranca', 'Success', '2022-05-03 10:00:00'),

       (5, 3, 'lymondgl', 'Start', '2022-05-04 09:00:00'),
       (6, 3, 'lymondgl', 'Success', '2022-05-04 10:00:00'),

       (7, 4, 'lymondgl', 'Start', '2022-05-04 11:00:00'),
       (8, 4, 'lymondgl', 'Failure', '2022-05-04 12:00:00'),

       (9, 5, 'pilafber', 'Start', '2022-09-04 09:00:00'),
       (10, 5, 'pilafber', 'Success',
        '2022-09-04 10:00:00'), -- но завалил вертер

       (11, 6, 'glenpoin', 'Start', '2022-05-05 09:00:00'),
       (12, 6, 'glenpoin', 'Success', '2022-05-05 10:00:00'),

       (13, 7, 'chamomiv', 'Start', '2022-05-05 09:00:00'),
       (14, 7, 'chamomiv', 'Success', '2022-05-05 10:00:00'),

       (15, 8, 'chamomiv', 'Start', '2022-05-05 11:00:00'),
       (16, 8, 'chamomiv', 'Success', '2022-05-05 12:00:00'),

       (17, 9, 'lymondgl', 'Start', '2022-05-15 09:00:00'),
       (18, 9, 'lymondgl', 'Success', '2022-05-15 10:00:00'),

       (19, 10, 'lymondgl', 'Start', '2022-05-15 11:00:00'),
       (20, 10, 'lymondgl', 'Success', '2022-05-15 12:00:00'),

       (21, 11, 'lymondgl', 'Start', '2022-05-15 13:00:00'),
       (22, 11, 'lymondgl', 'Success', '2022-05-15 14:00:00'),

       (23, 12, 'violette', 'Start', '2022-06-01 09:00:00'),
       (24, 12, 'violette', 'Failure', '2022-06-01 10:00:00'),

       (25, 13, 'curranca', 'Start', '2022-06-02 09:00:00'),
       (26, 13, 'curranca', 'Success', '2022-06-02 10:00:00'),

       (27, 14, 'pilafber', 'Start', '2022-06-03 09:00:00'),
       (28, 14, 'pilafber', 'Failure', '2022-06-03 10:00:00'),

       (29, 15, 'pilafber', 'Start', '2022-06-03 11:00:00'),
       (30, 15, 'pilafber', 'Failure', '2022-06-03 12:00:00'),

       (31, 16, 'lymondgl', 'Start', '2022-07-01 09:00:00');

insert into verter
values (1, 2, 'Start', '2022-05-03 10:01:00'),
       (2, 2, 'Success', '2022-05-03 10:02:00'),

       (3, 3, 'Start', '2022-05-04 10:01:00'),
       (4, 3, 'Success', '2022-05-04 10:02:00'),

       (5, 4, 'Start', '2022-05-04 12:01:00'),
       (6, 4, 'Success', '2022-05-04 12:02:00'),

       (7, 5, 'Start', '2022-09-04 10:01:00'),
       (8, 5, 'Failure', '2022-09-04 10:02:00'),

       (9, 6, 'Start', '2022-05-05 10:01:00'),
       (10, 6, 'Success', '2022-05-05 10:02:00'),

       (11, 7, 'Start', '2022-05-05 10:01:00'),
       (12, 7, 'Success', '2022-05-05 10:02:00'),

       (13, 8, 'Start', '2022-05-05 12:01:00'),
       (14, 8, 'Success', '2022-05-05 12:02:00'),

       (15, 9, 'Start', '2022-05-15 10:01:00'),
       (16, 9, 'Success', '2022-05-15 10:02:00'),

       (17, 10, 'Start', '2022-05-15 12:01:00'),
       (18, 10, 'Success', '2022-05-15 12:02:00'),

       (19, 11, 'Start', '2022-05-15 14:01:00'),
       (20, 11, 'Success', '2022-05-15 14:02:00');

insert into transferredpoints
values (1, 'violette', 'pilafber', 2),
       (2, 'curranca', 'pilafber', 2),
       (3, 'lymondgl', 'curranca', 2),
       (4, 'lymondgl', 'violette', 2),
       (5, 'pilafber', 'сhastity', 1),
       (6, 'glenpoin', 'lymondgl', 1),
       (7, 'chamomiv', 'manhunte', 1),
       (8, 'chamomiv', 'сhastity', 1),
       (9, 'lymondgl', 'pilafber', 1),
       (10, 'pilafber', 'violette', 1),
       (11, 'pilafber', 'curranca', 1),
       (12, 'pilafber', 'glenpoin', 1);

insert into friends
values (1, 'pilafber', 'violette'),
       (2, 'pilafber', 'curranca'),
       (3, 'violette', 'curranca'),
       (4, 'chamomiv', 'glenpoin'),
       (5, 'chamomiv', 'pilafber'),
       (6, 'glenpoin', 'pilafber');

insert into recommendations
values (1, 'pilafber', 'violette'),
       (2, 'pilafber', 'curranca'),
       (3, 'curranca', 'glenpoin'),
       (4, 'glenpoin', 'chamomiv'),
       (5, 'manhunte', 'pilafber');

insert into xp
values (1, 2, 230),
       (2, 3, 250),
       (3, 4, 250),
       (4, 6, 245),
       (5, 7, 250),
       (6, 8, 250),
       (7, 9, 500),
       (8, 10, 500),
       (9, 11, 500),
       (10, 13, 290),
       (11, 14, 300),
       (12, 15, 300);

-- truncate table timetracking;
insert into timetracking
values (1, 'manhunte', current_date - 1, '10:00:00', 1),
       (2, 'pilafber', current_date - 1, '01:00:00', 1),
       (3, 'pilafber', current_date - 1, '09:00:00', 2),
       (4, 'curranca', current_date - 1, '09:40:00', 1),
       (5, 'manhunte', current_date - 1, '23:00:00', 2),
       (6, 'curranca', current_date - 1, '10:00:00', 2),
       (7, 'pilafber', '2022-01-02', '01:00:00', 1),
       (8, 'pilafber', '2022-01-03', '09:00:00', 2),
       (9, 'curranca', current_date, '09:40:00', 1),
       (10, 'manhunte', current_date, '10:00:00', 1),
       (11, 'violette', current_date, '10:00:00', 1),
       (12, 'curranca', current_date, '16:00:00', 2),
       (13, 'violette', current_date, '17:00:00', 2),
       (14, 'manhunte', current_date, '18:00:00', 2),
       (15, 'manhunte', current_date, '19:00:00', 1),
       (16, 'glenpoin', current_date, '20:00:00', 1),
       (17, 'glenpoin', current_date, '23:00:00', 2);

create or replace procedure export(in tablename varchar, in path varchar,
                                   in separator char) as
$$
begin
    execute format('copy %s to ''%s/%s.csv'' with csv header delimiter ''%s'';',
                   tablename, path, tablename, separator);
end;
$$ language plpgsql;

create or replace procedure import(in tablename varchar, in path varchar,
                                   in separator char) as
$$
begin
    execute format(
            'copy %s from ''%s/%s.csv'' with csv header delimiter ''%s'';',
            tablename, path, tablename, separator);
end;
$$ language plpgsql;

-- ***CHECKING PROCEDURES***
-- call export('checks', '/Users/pilafber/Desktop', ',');
-- call export('friends', '/Users/pilafber/Desktop', ',');
-- call export('p2p', '/Users/pilafber/Desktop', ',');
-- call export('peers', '/Users/pilafber/Desktop', ',');
-- call export('recommendations', '/Users/pilafber/Desktop', ',');
-- call export('tasks', '/Users/pilafber/Desktop', ',');
-- call export('timetracking', '/Users/pilafber/Desktop', ',');
-- call export('transferredpoints', '/Users/pilafber/Desktop', ',');
-- call export('verter', '/Users/pilafber/Desktop', ',');
-- call export('xp', '/Users/pilafber/Desktop', ',');
--
-- truncate table peers cascade;
-- truncate table tasks cascade;
-- truncate table p2p cascade;
-- truncate table verter cascade;
-- truncate table checks cascade;
-- truncate table transferredpoints cascade;
-- truncate table friends cascade;
-- truncate table recommendations cascade;
-- truncate table xp cascade;
-- truncate table timetracking cascade;
--
-- call import('peers', '/Users/pilafber/Desktop', ',');
-- call import('tasks', '/Users/pilafber/Desktop', ',');
-- call import('checks', '/Users/pilafber/Desktop', ',');
-- call import('verter', '/Users/pilafber/Desktop', ',');
-- call import('p2p', '/Users/pilafber/Desktop', ',');
-- call import('transferredpoints', '/Users/pilafber/Desktop', ',');
-- call import('friends', '/Users/pilafber/Desktop', ',');
-- call import('recommendations', '/Users/pilafber/Desktop', ',');
-- call import('xp', '/Users/pilafber/Desktop', ',');
-- call import('timetracking', '/Users/pilafber/Desktop', ',');