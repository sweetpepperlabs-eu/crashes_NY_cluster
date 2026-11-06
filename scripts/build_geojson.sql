-- Fatal NYC crashes (persons_killed >= 1) as one GeoJSON FeatureCollection.
-- DuckDB JSON export wraps the row, so the shell script unwraps `collection`.
COPY (
  WITH fatal AS (
    SELECT
      round(lon, 6) AS lon,
      round(lat, 6) AS lat,
      strftime(crash_date, '%Y-%m-%d') AS crash_date,
      printf('%02d:%02d', hour(crash_time), minute(crash_time)) AS crash_time,
      borough,
      on_street,
      cross_street,
      off_street,
      persons_killed,
      persons_injured,
      coalesce(pedestrians_killed, 0) AS pedestrians_killed,
      coalesce(cyclists_killed, 0) AS cyclists_killed,
      coalesce(motorists_killed, 0) AS motorists_killed,
      factor,
      vehicle,
      collision_id,
      CASE
        WHEN coalesce(pedestrians_killed, 0) > 0
          AND coalesce(pedestrians_killed, 0) >= coalesce(cyclists_killed, 0)
          AND coalesce(pedestrians_killed, 0) >= coalesce(motorists_killed, 0)
          THEN 'pedestrian'
        WHEN coalesce(cyclists_killed, 0) > 0
          AND coalesce(cyclists_killed, 0) >= coalesce(motorists_killed, 0)
          THEN 'cyclist'
        WHEN coalesce(motorists_killed, 0) > 0
          THEN 'motorist'
        ELSE 'other'
      END AS victim
    FROM read_parquet('__PARQUET__')
    WHERE persons_killed >= 1
      AND lon IS NOT NULL
      AND lat IS NOT NULL
  )
  SELECT {
    type: 'FeatureCollection',
    features: list({
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [lon, lat]
      },
      properties: {
        id: collision_id,
        date: crash_date,
        time: crash_time,
        borough: borough,
        on_street: on_street,
        cross_street: cross_street,
        off_street: off_street,
        killed: persons_killed,
        injured: persons_injured,
        ped_killed: pedestrians_killed,
        cyc_killed: cyclists_killed,
        mot_killed: motorists_killed,
        factor: factor,
        vehicle: vehicle,
        victim: victim
      }
    })
  } AS collection
  FROM fatal
) TO '__OUT__' (FORMAT JSON);
