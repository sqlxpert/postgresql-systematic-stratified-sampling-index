-- Easy random sampling in PostgreSQL: systematic stratified sampling index
-- github.com/sqlxpert/postgresql-systematic-stratified-sampling-index
-- GPLv3, Copyright Paul Marcelin



-- create database, domains, table, views, sampling function
-- postgresql 18



\connect postgres

drop database if exists sampling;
create database sampling
  template        'template0'
  encoding        'UTF8'
  locale_provider 'builtin'
  builtin_locale  'PG_UNICODE_FAST'
;
\connect sampling

create schema if not exists sampling;
set search_path to sampling;



create domain source_id  as text
  constraint source_id_not_null          check (value is not null)

  constraint source_id_length_minimum    check ( 2 <= length(value)      )
  constraint source_id_length_maximum    check (      length(value) <= 10)

  constraint source_id_lowercase         check (value  = lower(value))
  constraint source_id_alphanumeric      check (value similar to '[0-9a-zA-Z-]*')
;
comment on domain source_id is 'identifies a data source';

create domain observ_id  as text
  constraint observ_id_not_null          check (value is not null)

  constraint observ_id_length_maximum    check (      length(value) <= 50)

  constraint observ_id_alphanumeric      check (value similar to '[0-9a-zA-Z-]*')
;
comment on domain observ_id is 'identifies an observation from a particular data source; intended to hold, unmodified, the literal value provided by the external source';

create domain observ_val as double precision
  constraint observ_val_not_null         check (value is not null)

  constraint observ_val_minimum          check (-100 <= value        )
  constraint observ_val_maximum          check (        value <= +100)
;
comment on domain observ_val is 'an observed value';

create domain goal_val   as numeric(5, 2)
  constraint goal_val_not_null           check (value is not null)

  constraint goal_val_minimum            check (-100 <= value        )
  constraint goal_val_maximum            check (        value <= +100)
;
comment on domain goal_val is 'the exact value that observed values approximate';



create table observ
  (
     source_id  source_id  constraint source_id_not_null  not null
    ,observ_id  observ_id  constraint observ_id_not_null  not null
    ,constraint observ_primary_key primary key (source_id, observ_id)

    ,observ_val observ_val constraint observ_val_not_null not null
  )
;
comment on table observ is 'multiple measurements of the same value from multiple external data sources';



create or replace function observ_in_sample(
   source_id  source_id
  ,observ_id  observ_id
  ,sample_num bigint    default 0
)
  returns boolean

  immutable  -- required when function is referenced in an index predicate.
             -- ref: "indexes on expressions" / function-based indexes.
  leakproof
  strict
  security invoker
  parallel safe

  language sql
  return case
    when sample_num = 0 then  -- our systematic stratified sample
      case                                        -- sampling rate
         when source_id = 'red'
         then (right(observ_id, 2)  = '77')       -- 1/256 =  ~0.4%

         when source_id = 'orange'
         then  right(observ_id, 1) in ('2', '7')  -- 2/ 16 =  12.5%

         when source_id = 'green'
         then  true                               -- 1     = 100.0%

         else  false  -- no error, but user must be aware of new sources
       end

    -- when sample_num = 1 then
    -- ...define other samples here...
  end
;
comment on function observ_in_sample(
   source_id
  ,observ_id
  ,bigint
)
  is 'after modifying this function, reindex any indexes that depend on modified sample(s)'
;


create view observ_summary as
  select
     count(*)                             as count
    ,min(observ_val)                      as range_0min
    ,avg(observ_val)                      as avg
    ,max(observ_val)                      as range_1max
    ,stddev(observ_val)                   as stddev
 from observ
;
comment on view observ_summary is 'summary statistics, all observations';

create view observ_sample_0_summary as
  select
     count(*)                             as count
    ,min(observ_val)                      as range_0min
    ,avg(observ_val)                      as avg
    ,max(observ_val)                      as range_1max
    ,stddev(observ_val)                   as stddev
  from observ
  where
    observ_in_sample(source_id, observ_id)
;
comment on view observ_sample_0_summary is 'summary statistics, using sample 0';

create view observ_source_summary as
  select
     source_id
    ,count(*)                             as count
    ,min(observ_val)                      as range_0min
    ,avg(observ_val)                      as avg
    ,max(observ_val)                      as range_1max
    ,stddev(observ_val)                   as stddev
 from observ
 group by
    source_id
;
comment on view observ_source_summary is 'summary statistics, by external data source';

create view observ_source_sample_0_summary as
  select
     source_id
    ,count(*)                             as count
    ,min(observ_val)                      as range_0min
    ,avg(observ_val)                      as avg
    ,max(observ_val)                      as range_1max
    ,stddev(observ_val)                   as stddev
  from observ
  where
    observ_in_sample(source_id, observ_id)
  group by
     source_id
;
comment on view observ_source_sample_0_summary is 'summary statistics, by external data source, using sample 0';

create view observ_bucket_summary as
  select
     source_id
    ,cast(right(
        observ_id
       ,case
          when source_id = 'red' then 2
                                 else 1
        end
     ) as observ_id)                      as bucket
    ,count(*)                             as count
    ,min(observ_val)                      as range_0min
    ,avg(observ_val)                      as avg
    ,max(observ_val)                      as range_1max
    ,stddev(observ_val)                   as stddev
  from observ
  group by
     source_id
    ,bucket
;
comment on view observ_bucket_summary is 'summary statistics, by external data source, by bucket';



create function round2(val_in observ_val)
  returns goal_val

  immutable
  leakproof
  strict
  security invoker
  parallel safe

  language sql
  return round(cast(val_in as goal_val), 2)
;
