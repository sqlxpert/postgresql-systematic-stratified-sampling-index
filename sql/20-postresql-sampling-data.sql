-- Easy random sampling in PostgreSQL: systematic stratified sampling index
-- github.com/sqlxpert/postgresql-systematic-stratified-sampling-index
-- GPLv3, Copyright Paul Marcelin



-- populate data, create sampling index



\connect sampling
set search_path to sampling;



drop index if exists observ_sample_0;
truncate observ;



select
   setseed(0.20261120) as placeholder
;

insert into observ(
   source_id
  ,observ_id
  ,observ_val
)
with
   observ_source (
       source_id
     ,           count
     ,                     observ_val_offset_0min
     ,                           observ_val_offset_1max
   ) as (values                         -- size    bias    precision
      ('red',    25600000, -1.0, +2.0)  -- large   upward  low
     ,
      ('orange',  1600000, -1.0, +1.0)  -- medium  none    medium
     ,
      ('green',    100000, -0.5, +0.5)  -- small   none    high
   )
  ,
   observ_source_new as materialized (
     select
        source_id
       ,count
       ,cast(20.0 + observ_val_offset_0min as double precision)
                                                as observ_val_min
       ,cast(
          observ_val_offset_1max - observ_val_offset_0min 
        as double precision)                    as observ_val_range
     from observ_source
   )
select
   source_id
  ,uuidv7()                                     as observ_id
  ,observ_val_min + random() * observ_val_range as observ_val
from       observ_source_new                src
cross join generate_series(1, src.count) as obs(
              observ_number
           )
;

vacuum analyze observ;
-- analyze alone does not populate visibility map
-- as of postgresql 19, can use analyze alone because a table scan sets the map



create index observ_sample_0
  on observ (
     source_id
    ,observ_id
  )
  include (
     observ_val
  )
  where
    observ_in_sample(source_id, observ_id)
;
comment on index observ_sample_0 is 'reindex if a modification to the function modifies the sample'
;
