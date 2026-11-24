-- Easy random sampling in PostgreSQL: systematic stratified sampling index
-- github.com/sqlxpert/postgresql-systematic-stratified-sampling-index
-- GPLv3, Copyright Paul Marcelin



-- check that sample buckets have similar summary statistics



\connect sampling
set search_path to sampling;



with
   observ_bucket_summary_new as (
     select
        source_id
       ,bucket
       ,buck.count                          as count
       ,buck.range_0min                     as range_0min
       ,buck.avg                            as avg
       ,buck.range_1max                     as range_1max
       ,buck.stddev                         as stddev
       ,abs((buck.avg - src.avg) / src.avg) as avg_vary_frac
     from observ_source_summary src
     join observ_bucket_summary buck
     using (
        source_id
     )
   )
  ,
   observ_all_source_bucket_summary as (
     (
       select
          cast('all' as source_id)          as source_id
         ,cast('all' as observ_id)          as bucket
         ,count
         ,range_0min
         ,avg
         ,range_1max
         ,stddev
         ,0                                 as avg_vary_frac
       from observ_summary
     )
     union all
     (
       select
          source_id
         ,cast('all' as observ_id)          as bucket
         ,count
         ,range_0min
         ,avg
         ,range_1max
         ,stddev
         ,0                                 as avg_vary_frac
       from observ_source_summary
     )
     union all
     (
       select
          source_id
         ,bucket
         ,count
         ,range_0min
         ,avg
         ,range_1max
         ,stddev
         ,avg_vary_frac
       from observ_bucket_summary_new
       where
         avg_vary_frac >  0.0002
         -- average observation for bucket varies by more than
         -- one fiftieth of a percentage point from average observation for source
     )
   )
select
   source_id
  ,bucket
  ,count
  ,round2(range_0min)                       as range_0min
  ,round2(avg)                              as avg
  ,round2(range_1max)                       as range_1max
  ,round2(stddev)                           as stddev
from observ_all_source_bucket_summary
order by
   (source_id = 'all')  asc  -- summaries of sources first (false < true)
  ,source_id            asc
  ,(bucket    = 'all')  asc  -- summaries of buckets before their source
  ,avg_vary_frac       desc
  ,bucket               asc
;
