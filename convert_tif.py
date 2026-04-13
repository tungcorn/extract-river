"""Convert GeoTIFF to WhiteboxTools-compatible format and compute auto threshold."""

import sys
import rasterio
import numpy as np


def convert(src_path, dst_path):
    with rasterio.open(src_path) as src:
        profile = src.profile.copy()
        profile.update(compress="lzw", predictor=2, tiled=True)
        with rasterio.open(dst_path, "w", **profile) as dst:
            for i in range(1, src.count + 1):
                dst.write(src.read(i), i)


def auto_threshold(accum_path):
    with rasterio.open(accum_path) as src:
        data = src.read(1)
        nodata = src.nodata
        valid = data[data != nodata] if nodata is not None else data.flatten()
        valid = valid[~np.isnan(valid)]
        max_accum = np.max(valid)
        threshold = max(5, int(max_accum * 0.01))
        return threshold, int(max_accum)


def write_prj_cpg(dem_path, shp_path):
    import os
    from rasterio.crs import CRS

    with rasterio.open(dem_path) as src:
        crs = src.crs

    if crs is None:
        return

    base = os.path.splitext(shp_path)[0]

    with open(base + ".prj", "w") as f:
        f.write(crs.to_wkt())

    with open(base + ".cpg", "w") as f:
        f.write("UTF-8")


if __name__ == "__main__":
    if sys.argv[1] == "convert":
        convert(sys.argv[2], sys.argv[3])
        print("Done.")
    elif sys.argv[1] == "auto_threshold":
        t, m = auto_threshold(sys.argv[2])
        print(f"{t} {m}")
    elif sys.argv[1] == "write_prj":
        write_prj_cpg(sys.argv[2], sys.argv[3])
        print("Done.")
