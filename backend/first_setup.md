# Quick setup for the PiQuick_Objects backend

### fetch some ids from Objaverse to a models/Group like structure
´´´
python3 scripts/utils/uid_prep.py   --group_names "example_metadata"\
                                    --number_of_glbs "50"\
                                    --save_path src/\
                                    --name example_metadata_ids
´´´

### download the files
```
python3 scripts/download.py     --groups_json src/example_metadata_ids.json
```

### get blender
```
cd scripts

wget https://download.blender.org/release/Blender3.2/blender-3.2.2-linux-x64.tar.xz && \
    tar -xf blender-3.2.2-linux-x64.tar.xz && \
    rm blender-3.2.2-linux-x64.tar.xz
```

#### If you're on a headless Linux server, install Xorg and start it:
```
cd utils
sudo apt-get install xserver-xorg -y && \
  sudo python3 start_x_server.py start
cd ../..\
```

### run the metadata extractor on the prepared files
´´´
scripts/blender-3.2.2-linux-x64/blender --background --python scripts/metadata_multiproc.py -- \
        --save_path metadata/ \
        --objects_path src/example_metadata_ids_paths/
´´´

### for rendering let's fetch two small groups
´´´
python3 scripts/utils/uid_prep.py       --group_names "example_render_five,example_render_three"\
                                        --number_of_glbs "5,3"\
                                        --save_path src/\
                                        --name example_render_ids
´´´

### convert them to the Group structure with default settings
```
python3 scripts/utils/ids_to_groups.py  --path_to_groups src/example_render_ids.json\
                                        --save_path src\
                                        --name example_render_group
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