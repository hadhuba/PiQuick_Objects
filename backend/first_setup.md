# Quick setup for the PiQuick_Objects backend

## preparation of files and blender

### fetch some ids from Objaverse to a models/Group like structure
´´´
python3 scripts/utils/uid_prep.py   --group_names "example_metadata"\
                                    --number_of_glbs "50"\
                                    --save_path src/\
                                    --name example_metadata_ids
´´´
"group" file without settings created at src/example_metadata_ids.json


### download the files
```
python3 scripts/download.py     --groups_json src/example_metadata_ids.json
```
file created at src/example_metadata_ids_paths/example_metadata.json
this contains the paths for the script

### get blender
```
cd scripts

wget https://download.blender.org/release/Blender3.2/blender-3.2.2-linux-x64.tar.xz && \
    tar -xf blender-3.2.2-linux-x64.tar.xz && \
    rm blender-3.2.2-linux-x64.tar.xz
```
blender downloaded to scripts/


#### If you're on a headless Linux server, install Xorg and start it:
```
cd utils
sudo apt-get install xserver-xorg -y && \
  sudo python3 start_x_server.py start
cd ../..\
```



## run the metadata extractor on the prepared files
´´´
scripts/blender-3.2.2-linux-x64/blender --background --python scripts/metadata_multiproc.py -- \
        --save_path metadata/ \
        --objects_path src/example_metadata_ids_paths/
´´´
files created in metadata/

## for rendering let's fetch two small groups
´´´
python3 scripts/utils/uid_prep.py       --group_names "example_render_five,example_render_three"\
                                        --number_of_glbs "5,3"\
                                        --save_path src/\
                                        --name example_render_ids
´´´
"Group" file without settings created at src/example_render_ids.json

### convert them to the Group structure with default settings
```
python3 scripts/utils/ids_to_groups.py  --path_to_groups src/example_render_ids.json\
                                        --save_path src\
                                        --name example_render_group
```
Group file created, this time with basic settings at src/example_render_group.json
### Let's modify the default settings a little by hand

```
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

#### assuming blender is installed and x server is running
### run render with the data
```
python3 scripts/render.py \
    --groups_json "src/example_render_group.json" \
    --save_path "src/" \
    --output_dir "results/" \
    --num_of_gpus 2 \
    --output_file results/result.zip
```
files have been created at results