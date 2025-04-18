# PiQuick_Objects 
### *Web application for Objaverse Tooling*

PiQuick_Objects is a toolkit and web application designed for preparing datasets for large machine learning models. It allows users to download, process, and analyze 3D objects and their metadata from the Objaverse database, making it easier to curate and organize data for machine learning and other data-driven applications.

## Main Features:

**Metadata Collection**: Gather specific metadata from the Objaverse dataset with configurable extraction options.

**Object Organization and Rendering**: Utilize Blender to render 3D objects and arrange them in scenes, including handling multi-object scenes for large-scale rendering tasks.

**Web Interface**: Enables browsing, filtering, and customized downloads, allowing users to select and group together objects of interest based on metadata, 3D previews, and other features.


## Setup and Installation

### ***download.py***

The ```download.py``` script downloads 3D objects from Objaverse based on a specified list of object IDs. This script checks existing files to avoid redundant downloads, handles missing objects, and supports multiprocessing to improve speed by leveraging available CPU cores.
```
python3 scripts/download.py     --groups_json src/download_test.json\
                                --save_path src/
```

### ***metadata_multiproc.py***
The ```metadata_multiproc``` script uses Blender to extract and save metadata for a given set of objects. The key feature of this script is its flexibility in easily adding new rendering parameters or metadata extraction criteria. You can customize what metadata to extract for each 3D object and how to organize the output, making it simple to adapt the process to new requirements.

```
python3 scripts/download.py     --groups_json src/metadata_test.json\
                                --save_path src/
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

Run metadata_multiproc
```
cd ..\

scripts/blender-3.2.2-linux-x64/blender --background --python scripts/metadata_multiproc.py -- \
        --save_path metadata/ \
        --objects_path src/metadata_test_paths/
```

<!-- optional parameters \
    --cpu_count 16 \
    --run_vertex \
    --run_armature \
    --run_mesh \
    --run_poly \
    --run_material \
    --run_edge \
    --run_animation
-->

### ***render.py***
This script automates the **downloading** and **rendering** of 3D objects in scenes using Blender. 
It leverages multiprocessing to distribute rendering tasks across available GPUs, ensuring efficient processing of multiple objects and scenes.
#### Download Blender (if have not done already):
```
cd scripts

wget https://download.blender.org/release/Blender3.2/blender-3.2.2-linux-x64.tar.xz && \
    tar -xf blender-3.2.2-linux-x64.tar.xz && \
    rm blender-3.2.2-linux-x64.tar.xz
```

#### If you're on a headless Linux server, install Xorg and start it (if have not done already):
```
sudo apt-get install xserver-xorg -y && \
  sudo python3 start_x_server.py start
```

Run render.py
```
python3 scripts/render.py \
    --groups_json "src/render_test.json" \
    --save_path "src/" \
    --output_dir "results/" \
    --num_of_gpus 2 \
    --output_file results/result.zip
```