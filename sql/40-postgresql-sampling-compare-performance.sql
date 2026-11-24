-- Easy random sampling in PostgreSQL: systematic stratified sampling index
-- github.com/sqlxpert/postgresql-systematic-stratified-sampling-index
-- GPLv3, Copyright Paul Marcelin



-- compare summary statistics and query performance for sample, entire data set



\connect sampling
set search_path to sampling;



with
   observ_summary_new as (
     select
        cast('all' as source_id)                     as source_id
       ,cast('all' as text)                          as scope
       ,count
       ,range_0min
       ,avg
       ,range_1max
       ,stddev
     from observ_summary
   )
  ,
   observ_sample_0_summary_new as (
     select
        cast('all' as source_id)                     as source_id
       ,cast('sample' as text)                       as scope
       ,count
       ,range_0min
       ,avg
       ,range_1max
       ,stddev
     from observ_sample_0_summary
   )
  ,
   observ_source_summary_new as (
     select
        source_id
       ,cast('all' as text)                          as scope
       ,count
       ,range_0min
       ,avg
       ,range_1max
       ,stddev
     from observ_source_summary
   )
  ,
   observ_source_sample_0_summary_new as (
     select
        source_id
       ,cast('sample' as text)                       as scope
       ,count
       ,range_0min
       ,avg
       ,range_1max
       ,stddev
     from observ_source_sample_0_summary
   )
  ,
   observe_source_all_sample_summary as (
     (select * from observ_source_summary_new)
     union all
     (select * from observ_source_sample_0_summary_new)
     union all
     (select * from observ_summary_new)
     union all
     (select * from observ_sample_0_summary_new)
   )
select
   source_id
  ,scope
  ,count
  ,round2(range_0min)                                as range_0min
  ,round2(avg)                                       as avg
  ,round2(range_1max)                                as range_1max
  ,round2(stddev)                                    as stddev
from observe_source_all_sample_summary
order by
   (source_id = 'all')  asc  -- summaries of sources first (false < true)
  ,source_id            asc
  ,(scope     = 'all')  asc  -- summary of sample first
;



explain (analyze, verbose, format yaml)
select
   cast('all' as source_id)                          as source_id
  ,cast('all' as text)                               as scope
  ,round2(avg(observ_val))                           as avg
from observ
;



explain (analyze, verbose, format yaml)
select
   cast('all' as source_id)                          as source_id
  ,cast('sample' as text)                            as scope
  ,round2(avg(observ_val))                           as avg
from observ
where
  observ_in_sample(source_id, observ_id)
;
