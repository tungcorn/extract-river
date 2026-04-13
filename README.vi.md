# extract-river

Trích xuất đường sông (centerline) từ file DEM, xuất ra shapefile. Có 2 phương pháp:

**[English](README.md)**

## Phương pháp

| | QGIS/GRASS (khuyên dùng) | WhiteboxTools |
|---|---|---|
| **Script** | `extract_river_qgis.bat` | `extract_river_whitebox.bat` |
| **Thuật toán** | MFD (Multi-Flow Direction) | D8 (Single-Flow Direction) |
| **Xử lý hố trũng** | A* priority-flood | Fill đơn giản |
| **Chất lượng** | Tốt hơn (mạng lưới đầy đủ hơn) | Tốt (có thể thiếu nhánh nhỏ) |
| **Phụ thuộc** | Cần cài QGIS | WhiteboxTools + Python rasterio |
| **Threshold mặc định** | 100 (kích thước lưu vực tối thiểu) | Tự tính (1% max accumulation) |

## Bắt đầu nhanh

### Cách 1: QGIS/GRASS (khuyên dùng)

```bash
# Yêu cầu: đã cài QGIS (winget install OSGeo.QGIS_LTR)
extract_river_qgis.bat D:\data\dem.tif D:\data\river.shp
extract_river_qgis.bat D:\data\dem.tif D:\data\river.shp 100
```

Kết quả giống hệt chạy GRASS `r.watershed` + `r.to.vect` trong QGIS GUI.

### Cách 2: WhiteboxTools

```bash
# Yêu cầu: Python 3 + rasterio, WhiteboxTools binary
extract_river_whitebox.bat D:\data\dem.tif D:\data\river.shp
extract_river_whitebox.bat D:\data\dem.tif D:\data\river.shp 500
```

## Tham số

| Tham số | Bắt buộc | Mô tả |
|---|---|---|
| `dem.tif` | Có | File DEM đầu vào |
| `output.shp` | Có | File shapefile đầu ra |
| `threshold` | Không | Ngưỡng trích xuất sông (xem bên dưới) |

### Hướng dẫn threshold

- **QGIS**: kích thước lưu vực tối thiểu (cells). Mặc định: 100
- **WhiteboxTools**: số cells tích lũy dòng chảy. Mặc định: tự tính (1% max)

Threshold cao → ít sông hơn (chỉ sông chính). Thấp → nhiều nhánh nhỏ hơn.

## Cài đặt

### Cho QGIS method

```bash
winget install OSGeo.QGIS_LTR
```

### Cho WhiteboxTools method

```bash
pip install rasterio
# Tải WhiteboxTools từ https://www.whiteboxgeo.com/download-whiteboxtools/
# Giải nén sao cho whitebox_tools.exe nằm tại:
#   WhiteboxTools_win_amd64/WBT/whitebox_tools.exe
```

## Credits

- [GRASS GIS](https://grass.osgeo.org/) qua [QGIS](https://qgis.org/) `qgis_process`
- [WhiteboxTools](https://github.com/jblindsay/whitebox-tools) — Prof. John Lindsay (MIT License)
- [rasterio](https://github.com/rasterio/rasterio) — đọc/ghi GeoTIFF
