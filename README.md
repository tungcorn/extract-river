# extract-river

Extract river/stream centerlines from a DEM file and output as shapefile. Two approaches available:

**[Tiếng Việt](README.vi.md)**

## Methods

| | QGIS/GRASS (recommended) | WhiteboxTools |
|---|---|---|
| **Script** | `extract_river_qgis.bat` | `extract_river_whitebox.bat` |
| **Algorithm** | MFD (Multi-Flow Direction) | D8 (Single-Flow Direction) |
| **Depression handling** | A* priority-flood | Simple fill |
| **Stream quality** | Better (more complete network) | Good (may miss small branches) |
| **Dependency** | QGIS installed | WhiteboxTools + Python rasterio |
| **Threshold default** | 100 (watershed basin size) | auto (1% of max accumulation) |

## Quick Start

### Method 1: QGIS/GRASS (recommended)

```bash
# Requires: QGIS installed (winget install OSGeo.QGIS_LTR)
extract_river_qgis.bat D:\data\dem.tif D:\data\river.shp
extract_river_qgis.bat D:\data\dem.tif D:\data\river.shp 100
```

Results are identical to running GRASS `r.watershed` + `r.to.vect` in QGIS GUI.

### Method 2: WhiteboxTools

```bash
# Requires: Python 3 + rasterio, WhiteboxTools binary
extract_river_whitebox.bat D:\data\dem.tif D:\data\river.shp
extract_river_whitebox.bat D:\data\dem.tif D:\data\river.shp 500
```

## Parameters

| Parameter | Required | Description |
|---|---|---|
| `dem.tif` | Yes | Input DEM raster file |
| `output.shp` | Yes | Output shapefile path |
| `threshold` | No | Stream extraction threshold (see below) |

### Threshold guide

- **QGIS method**: min watershed basin size in cells. Default: 100
- **WhiteboxTools method**: flow accumulation cell count. Default: auto (1% of max)

Higher threshold = fewer streams (main rivers only). Lower = more tributaries.

## Setup

### For QGIS method

```bash
winget install OSGeo.QGIS_LTR
```

### For WhiteboxTools method

```bash
pip install rasterio
# Download WhiteboxTools from https://www.whiteboxgeo.com/download-whiteboxtools/
# Extract so that whitebox_tools.exe is at:
#   WhiteboxTools_win_amd64/WBT/whitebox_tools.exe
```

## How it works

### QGIS/GRASS pipeline
1. **GRASS r.watershed** — A* priority-flood + MFD flow accumulation + stream extraction
2. **GRASS r.to.vect** — Convert stream raster to polyline shapefile with smoothing

### WhiteboxTools pipeline
1. **Convert** — Re-encode DEM to compatible GeoTIFF (removes PREDICTOR=3)
2. **Fill Depressions** — Remove spurious sinks
3. **D8 Flow Direction** — Compute flow direction per pixel
4. **D8 Flow Accumulation** — Count upstream contributing cells
5. **Extract Streams + Vectorize** — Threshold and convert to polyline shapefile

## Credits

- [GRASS GIS](https://grass.osgeo.org/) via [QGIS](https://qgis.org/) `qgis_process`
- [WhiteboxTools](https://github.com/jblindsay/whitebox-tools) by Prof. John Lindsay (MIT License)
- [rasterio](https://github.com/rasterio/rasterio) for GeoTIFF I/O
