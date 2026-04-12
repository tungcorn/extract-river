# extract-river

Trích xuất đường sông (centerline) từ file DEM, xuất ra shapefile. Không cần mở QGIS.

**[English](README.md)**

## Yêu cầu

- Python 3 + rasterio (`pip install rasterio`)
- [WhiteboxTools](https://www.whiteboxgeo.com/download-whiteboxtools/) — tải về và giải nén vào thư mục `WhiteboxTools_win_amd64/`

## Cách dùng

```
extract_river.bat <dem.tif> <output.shp> [threshold]
```

| Tham số | Bắt buộc | Mô tả |
|---|---|---|
| `dem.tif` | Có | File DEM đầu vào |
| `output.shp` | Có | File shapefile đầu ra |
| `threshold` | Không | Ngưỡng tích lũy dòng chảy. Mặc định: tự tính (1% max accumulation) |

Threshold quyết định mức độ chi tiết:
- **Cao** (500, 1000) → chỉ sông chính, ít nhánh
- **Thấp** (5, 10) → nhiều nhánh nhỏ

## Ví dụ

```bash
# Tự tính threshold (khuyên dùng)
extract_river.bat D:\data\dem.tif D:\data\river.shp

# Chỉ định threshold
extract_river.bat D:\data\dem.tif D:\data\river.shp 500
```

## Cài đặt

```bash
# 1. Cài thư viện Python
pip install rasterio

# 2. Tải WhiteboxTools
# Từ https://www.whiteboxgeo.com/download-whiteboxtools/
# Giải nén sao cho whitebox_tools.exe nằm tại:
#   WhiteboxTools_win_amd64/WBT/whitebox_tools.exe

# 3. Chạy
extract_river.bat duong_dan\dem.tif duong_dan\output.shp
```

## Cách hoạt động

1. **Convert** — Chuyển DEM sang format tương thích WhiteboxTools (bỏ PREDICTOR=3)
2. **Fill Depressions** — Lấp hố trũng giả trong DEM
3. **D8 Flow Direction** — Tính hướng chảy mỗi pixel (mô hình 8 hướng)
4. **D8 Flow Accumulation** — Đếm số pixel thượng nguồn chảy qua mỗi điểm
5. **Extract Streams + Vector hóa** — Lọc theo ngưỡng và chuyển pixel sông thành polyline shapefile

## Credits

- [WhiteboxTools](https://github.com/jblindsay/whitebox-tools) — Prof. John Lindsay (MIT License)
- [rasterio](https://github.com/rasterio/rasterio) — đọc/ghi GeoTIFF
