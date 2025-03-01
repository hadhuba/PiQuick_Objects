# PiQuick_Objects 
### *Web application for Objaverse Tooling*

PiQuick_Objects is a toolkit and web application designed for preparing datasets for large machine learning models. It allows users to download, process, and analyze 3D objects and their metadata from the Objaverse database, making it easier to curate and organize data for machine learning and other data-driven applications.

## Main Features:

**Metadata Collection**: Gather specific metadata from the Objaverse dataset with configurable extraction options.

**Object Organization and Rendering**: Utilize Blender to render 3D objects and arrange them in scenes, including handling multi-object scenes for large-scale rendering tasks.

**Web Interface**: Enables browsing, filtering, and customized downloads, allowing users to select and flag objects of interest based on metadata, 3D previews, and other features.


## Setup and Installation

### ***download.py***

The ```download.py``` script downloads 3D objects from Objaverse based on a specified list of object IDs. This script checks existing files to avoid redundant downloads, handles missing objects, and supports multiprocessing to improve speed by leveraging available CPU cores.
```
python3 scripts/download.py     --id_file_path src/three_groups.json\
                                --save_path src/three_groups/
                                --store_in_save_path 0
```


### ***metadata_multiproc.py***
The ```metadata_multiproc``` script uses Blender to extract and save metadata for a given set of objects. The key feature of this script is its flexibility in easily adding new rendering parameters or metadata extraction criteria. You can customize what metadata to extract for each 3D object and how to organize the output, making it simple to adapt the process to new requirements.

```
python3 scripts/download.py    --id_file_path src/metadata_test.json\
                                --save_path src/\
                                --store_in_save_path 0
```
This script is designed to be extended, allowing you to add additional metadata extraction features or render parameters at any point in the process.

#### Download Blender:
```
cd scripts

wget https://download.blender.org/release/Blender3.2/blender-3.2.2-linux-x64.tar.xz && \
    tar -xf blender-3.2.2-linux-x64.tar.xz && \
    rm blender-3.2.2-linux-x64.tar.xz
```

#### If you're on a headless Linux server, install Xorg and start it:
```
sudo apt-get install xserver-xorg -y && \
  sudo python3 start_x_server.py start
```
*EITHER*
Run metadata_multiproc
```
cd ..
scripts/blender-3.2.2-linux-x64/blender --background --python scripts/metadata_multiproc.py -- \
        --save_path metadata/ \
        --objects_path src/metadata_test_paths/
```
*OR* run_metadata.py

### ***render.py***
This script automates the **downloading** and **rendering** of 3D objects in scenes using Blender. 
It leverages multiprocessing to distribute rendering tasks across available GPUs, ensuring efficient processing of multiple objects and scenes.
#### Download Blender:
```
cd scripts

wget https://download.blender.org/release/Blender3.2/blender-3.2.2-linux-x64.tar.xz && \
    tar -xf blender-3.2.2-linux-x64.tar.xz && \
    rm blender-3.2.2-linux-x64.tar.xz
```

#### If you're on a headless Linux server, install Xorg and start it:
```
sudo apt-get install xserver-xorg -y && \
  sudo python3 start_x_server.py start
```

Run render.py
```
python3 scripts/render.py \
    --id_file_path "src/three_groups.json" \
    --save_path "src/object_database/" \
    --num_of_gpus 2 \
    --output_dir "results/" \
    --num_images 12       \
    --azimuth_aug  1      \
    --elevation_aug 0     \
    --resolution 256      \
    --mode_multi 1        \
    --mode_static 0       \
    --mode_front_view 0   \
    --mode_four_view 0    \
```
```
    --engine "CYCLES"     \
    --only_northern_hemisphere
```