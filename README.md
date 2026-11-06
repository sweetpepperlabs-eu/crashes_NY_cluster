# Fatal crashes in New York City

MapLibre map of motor vehicle collisions in New York City in which at least one person was killed. The source file covers September 2016 through September 2026. The map shows the 2,247 crashes with `persons_killed >= 1` (2,342 people killed).

Clusters follow the [MapLibre HTML cluster example](https://maplibre.org/maplibre-gl-js/docs/examples/display-html-clusters-with-custom-properties/): each donut counts crashes by who was killed, and the number in the middle is the number of crashes. Clusters use an 80px radius and stay grouped through zoom 16.

| Slice | Crashes | Meaning |
| --- | ---: | --- |
| Pedestrian | 1,115 | A pedestrian was the largest group killed |
| Cyclist | 181 | A cyclist was the largest group killed |
| Motorist | 828 | A motorist was the largest group killed |
| Other | 123 | Someone was killed, but not recorded in those three groups |

When a crash kills people in more than one group, it is classed by the larger count. Ties go to pedestrian, then cyclist, then motorist.

## Preview locally

```bash
python3 -m http.server 8000
```

Open http://localhost:8000. The page loads `data/fatal-crashes.geojson`, so it needs a local server rather than a `file://` URL.

## Publish on GitHub Pages

The site is static: `index.html`, `data/fatal-crashes.geojson`, and `data/summary.json`.

1. Create a GitHub repository and push the `main` branch.
2. In the repository, open **Settings → Pages → Build and deployment** and set **Source** to **GitHub Actions**.
3. `.github/workflows/pages.yml` publishes the site on every push to `main`.

The source parquet is about 97 MB and is listed in `.gitignore`. The map does not need it. Commit `data/fatal-crashes.geojson` instead.

## Rebuild the GeoJSON

With the parquet in this folder and [DuckDB](https://duckdb.org/) on your PATH:

```bash
./scripts/build_geojson.sh
```

You can also pass a parquet path:

```bash
./scripts/build_geojson.sh /path/to/MotorVehicleCollisionsCrashes_201609_202609.parquet
```

## Data

NYC Open Data, [Motor Vehicle Collisions — Crashes](https://data.cityofnewyork.us/Public-Safety/Motor-Vehicle-Collisions-Crashes/h9gi-nx95). Rows are kept when `persons_killed` is 1 or greater and both longitude and latitude are present.
