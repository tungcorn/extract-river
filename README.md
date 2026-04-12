# extract-river

Extract river/stream centerlines from a DEM file and output as shapefile. No QGIS needed.

Trích xuất đường sông (centerline) từ file DEM, xuất ra shapefile. Không cần mở QGIS.

## Requirements / Yêu cầu

- Python 3 + rasterio (`pip install rasterio`)
- WhiteboxTools — download from [whiteboxgeo.com](https://www.whiteboxgeo.com/download-whiteboxtools/) and extract into `WhiteboxTools_win_amd64/` folder

## Usage / Cách dùng

```
extract_river.bat <dem.tif> <output.shp> [threshold]
```

| Parameter | Required | Description |
|---|---|---|
| `dem.tif` | Yes | Input DEM raster file |
| `output.shp` | Yes | Output shapefile path |
| `threshold` | No | Flow accumulation threshold. Default: auto (1% of max accumulation) |

The threshold controls stream detail level:
- **High** (500, 1000) — main rivers only, fewer branches
- **Low** (5, 10) — includes small tributaries

Threshold quyết định mức độ chi tiết:
- **Cao** (500, 1000) → chỉ sông chính, ít nhánh
- **Thấp** (5, 10) → nhiều nhánh nhỏ

## Examples / Ví dụ

```bash
# Auto threshold (recommended)
extract_river.bat D:\data\dem.tif D:\data\river.shp

# Manual threshold
extract_river.bat D:\data\dem.tif D:\data\river.shp 500
```

## How it works / Pipeline

1. **Convert** — Re-encode DEM to WhiteboxTools-compatible GeoTIFF (removes PREDICTOR=3)
2. **Fill Depressions** — Remove spurious sinks in the DEM
3. **D8 Flow Direction** — Compute flow direction for each pixel (8-direction model)
4. **D8 Flow Accumulation** — Count upstream contributing cells per pixel
5. **Extract Streams + Vectorize** — Threshold the accumulation raster and convert stream pixels to polyline shapefile

## Setup / Cài đặt

```bash
# 1. Install Python dependency
pip install rasterio

# 2. Download WhiteboxTools
# From https://www.whiteboxgeo.com/download-whiteboxtools/
# Extract so that whitebox_tools.exe is at:
#   WhiteboxTools_win_amd64/WBT/whitebox_tools.exe

# 3. Run
extract_river.bat path\to\dem.tif path\to\output.shp
```

## Credits

- [WhiteboxTools](https://github.com/jblindsay/whitebox-tools) by Prof. John Lindsay (MIT License)
- [rasterio](https://github.com/rasterio/rasterio) for GeoTIFF I/O
