# PiQuick_Objects 
### *Web application for Objaverse Tooling*

PiQuick_Objects is a toolkit and web application designed for preparing datasets for machine learning models. It allows users to download, process, and analyze 3D objects and their metadata from the Objaverse database, making it easier to curate and organize data for machine learning and other data-driven applications.

## Main Features:

**Metadata Collection**: Gather specific metadata from the Objaverse dataset with configurable extraction options.

**Object Organization and Rendering**: Utilize Blender to render 3D objects and arrange them in scenes, including handling multi-object scenes for large-scale rendering tasks.

**Web Interface**: Enables browsing, filtering, and customized downloads, allowing users to select and group together objects of interest based on metadata, 3D previews, and other features.


## Setup and Installation
Navigate to the root of the backend.

>For the necessary dependencies:

```
pip install -r requirements.txt
```

### ***download.py***

The ```download.py``` script downloads 3D objects from Objaverse based on a specified list of object IDs. This script checks existing files to avoid redundant downloads, handles missing objects, and supports multiprocessing to improve speed by leveraging available CPU cores. The script creates a *filename_paths* directory containing *groupname_paths.json* files, which can be used by the other scripts.


>Fetch some ids from Objaverse and organize them to a *models/Group* like structure. The output can be given to the download script. For further information regarding the helper script, see below.
```
python3 scripts/utils/uid_prep.py   --group_names "example_metadata"\
                                    --number_of_glbs "50"\
                                    --save_path src/\
                                    --name example_metadata_ids
```

"group" file without settings created at src/example_metadata_ids.json

>run *download.py* with the created example file
```
python3 scripts/download.py     --groups_json src/example_metadata_ids.json
```

### ***metadata_multiproc.py***
The ```metadata_multiproc``` script uses Blender to extract and save metadata for a given set of objects. The key feature of this script is its flexibility in easily adding new rendering parameters or metadata extraction criteria. You can customize what metadata to extract for each 3D object and how to organize the output, making it simple to adapt the process to new requirements.

This script is designed to be extended, allowing you to add additional metadata extraction features or render parameters at any point in the process.

>first let us download Blender:
```
cd scripts

wget https://download.blender.org/release/Blender3.2/blender-3.2.2-linux-x64.tar.xz && \
    tar -xf blender-3.2.2-linux-x64.tar.xz && \
    rm blender-3.2.2-linux-x64.tar.xz
```

>if you're on a headless Linux server, install Xorg and start it:
```
sudo apt-get install xserver-xorg -y && \
  sudo python3 start_x_server.py start
```
>Rrn *metadata_multiproc.py* with the output of the *download.py* script
```
scripts/blender-3.2.2-linux-x64/blender --background --python scripts/metadata_multiproc.py -- \
        --save_path metadata/ \
        --objects_path src/example_metadata_ids_paths/
```

### ***render.py***
This script automates the **downloading** and **rendering** of 3D objects in scenes using Blender. 
It leverages multiprocessing to distribute rendering tasks across available GPUs, ensuring efficient processing of multiple objects and scenes.
> Download Blender (if have not done already):
```
cd scripts

wget https://download.blender.org/release/Blender3.2/blender-3.2.2-linux-x64.tar.xz && \
    tar -xf blender-3.2.2-linux-x64.tar.xz && \
    rm blender-3.2.2-linux-x64.tar.xz
```

>if you're on a headless Linux server, install Xorg and start it (if have not done already):
```
sudo apt-get install xserver-xorg -y && \
  sudo python3 start_x_server.py start
```
>lets use the helper script to download some groups
```
python3 scripts/utils/uid_prep.py       --group_names "example_render_five,example_render_three"\
                                        --number_of_glbs "5,3"\
                                        --save_path src/\
                                        --name example_render_ids
```
>Let us use this another helper script to give the groups some default settings. For further information regarding the helper script, see below.
```
python3 scripts/utils/ids_to_groups.py  --path_to_groups src/example_render_ids.json\
                                        --save_path src\
                                        --name example_render_group
```
We can manually tweak the settings a little.

>run *render.py* with the desired settings
```
python3 scripts/render.py \
    --groups_json "src/example_render_group.json" \
    --save_path "src/" \
    --output_dir "results/" \
    --num_of_gpus 2 \
    --output_file results/result.zip
```

## The flutter application

Navigate to the root of the flutter project.

>run 

```flutter pub get```

run the server in the backend project with the command:

```
uvicorn server.main:app --host 127.0.0.1 --port 8007
```

run the flutter project from the root as:

```flutter run```

## utils

#### ***uid_prep.py***

The ```uid_prep.py``` script is a utility for generating the groups_json file required by download.py. It creates properly formatted JSON files containing object groups with randomly selected Objaverse UIDs.

```
python3 scripts/uid_prep.py     --group_names "creating,some,files"\
                                --number_of_glbs "10,50,8"\
                                --save_path src/\
                                --name download_test
```

This helper script:
1. Loads all available UIDs from the Objaverse database
2. Creates specified groups with randomly assigned unique object IDs
3. Saves a properly formatted JSON file that can be directly used with download.py

Note that the groups_json file can either be created with this helper script or manually constructed following the same format. The format requires an array of objects, each with a "name" field and an array of "object_ids".

#### ***ids_to_groups.py***

The ```ids_to_groups.py``` script is a utility for creating a JSON file containing object groups with default render settings applied. It processes input JSON files with group names and object IDs and outputs a properly formatted JSON file with additional render settings.

```
python3 ids_to_groups.py   --path_to_groups input/groups.json \
                                         --save_path output/ \
                                         --name render_groups
```

This helper script:

- Loads input groups from a JSON file, each containing a "name" and an array of "object_ids".
- Applies default render settings to each group using the ```get_default_settings()``` function.
- Saves the resulting groups with settings as a new JSON file in the specified output directory.

The output JSON file can be directly used for rendering tasks, ensuring consistent default settings for all groups.


####

Example tweaking of config file:

```
//example src/render_group.json
[
  {
    "name": "example_render_five",
    "object_ids": [
      "a1e1c4d21c8440bfaae07701f76f34ef",
      "81c74e93020f4748bd2e4dfe243f54b7",
      "8bd89478b6e8424ba762d1f9da9a89ea",
      "90d734bc9b14485db13868e94b864c0a",
      "b84520a8e3e94002b9d1edd378148a79"
    ],
    "settings": {
      "num_images": 8, //here
      "azimuth_aug": true,
      "elevation_aug": false,
      "resolution": 512, //here
      "mode_multi": true,
      "mode_front_view": false,
      "mode_four_view": false,
      "only_northern_hemisphere": true
    }
  },
  {
    "name": "example_render_three",
    "object_ids": [
      "83dd979948384297b49e681a18ed6bd5",
      "07385e2f33c64363852363346b9f0bd2",
      "738ccbf3a6ba403bbd359388c8839606"
    ],
    "settings": {
      "num_images": 12,
      "azimuth_aug": true,
      "elevation_aug": true,
      "resolution": 512, //here
      "mode_multi": false, //here
      "mode_front_view": true, //here
      "mode_four_view": false,
      "only_northern_hemisphere": true
    }
  }
]
```