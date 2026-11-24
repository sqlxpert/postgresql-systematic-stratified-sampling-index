-- Easy random sampling in PostgreSQL: systematic stratified sampling index
-- github.com/sqlxpert/postgresql-systematic-stratified-sampling-index
-- GPLv3, Copyright Paul Marcelin



-- check that sample buckets are similar in size



\connect sampling
set search_path to sampling;



with
   observ_source_summary_short as (
     select
        source_id
       ,count
     from observ_source_summary
   )
  ,
   observ_bucket_summary_short as (
     select
        source_id
       ,bucket
       ,count
     from observ_bucket_summary
   )
  ,
   observ_source_summary_new as (
     select
        source_id
       ,round(
            cast(src.count as double precision)  --   observations from source
          / cast(count(*)  as double precision)  -- / number of buckets
        )                        as count_per_bucket_avg
     from observ_source_summary_short src
     join observ_bucket_summary_short buck
     using (
        source_id
     )
     group by
        source_id
       ,src.count
   )
  ,
   observ_bucket_summary_new as (
     select
        source_id
       ,bucket
       ,src.count_per_bucket_avg as count_per_bucket_avg
       ,buck.count               as count
       ,buck.count - src.count_per_bucket_avg
                                 as count_vary
       ,abs(
            cast(buck.count - src.count_per_bucket_avg as double precision)
          / cast(src.count_per_bucket_avg              as double precision)
        )                        as count_vary_frac
     from observ_source_summary_new   src
     join observ_bucket_summary_short buck
     using (
        source_id
     )
   )
select
   source_id
  ,bucket
  ,round(cast(count_vary_frac * 100 as numeric), 2) 
                                 as count_vary_percent
  ,count_per_bucket_avg
  ,count_vary
  ,count
from observ_bucket_summary_new
where
  count_vary_frac >  0.005 
  -- bucket size varies by more than half a percentage point
  -- from average bucket size for source
order by
   source_id        asc
  ,count_vary_frac desc 
  ,bucket           asc
;
