# Quick setup for the PiQuick_Objects backend

´´´
python3 scripts/utils/uid_prep.py     --group_names "example"\
                                --number_of_glbs "20"\
                                --save_path src/\
                                --name example_ids
´´´

```
python3 scripts/download.py     --groups_json src/example_ids.json\
                                --save_path src/
```

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

## metadata

´´´
scripts/blender-3.2.2-linux-x64/blender --background --python scripts/metadata_multiproc.py -- \
        --save_path metadata/ \
        --objects_path src/example_ids_paths/
´´´

## render 

˝˝˝
python3 scripts/utils/ids_to_groups.py --path_to_groups src/example_ids.json --save_path src --name example_group
˝˝˝


```
python3 scripts/render.py \
    --groups_json "src/example_group.json" \
    --save_path "src/" \
    --output_dir "results/" \
    --output_file results/result.zip
```

#### or if GPU-s are available
```
python3 scripts/render.py \
    --groups_json "src/example_group.json" \
    --save_path "src/" \
    --output_dir "results/" \
    --num_of_gpus 2 \
    --output_file results/result.zip
```





´´´
python3 scripts/utils/uid_prep.py     --group_names "tiz"\
                                      --number_of_glbs "10"\
                                      --save_path src/\
                                      --name tiz
´´´

```
python3 scripts/download.py     --groups_json src/tiz.json\
                                --save_path src/
```

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

## metadata

´´´
scripts/blender-3.2.2-linux-x64/blender --background --python scripts/metadata_multiproc.py -- \
        --save_path metadata/ \
        --objects_path src/example_ids_paths/
´´´

## render 

˝˝˝
python3 scripts/utils/ids_to_groups.py --path_to_groups src/tiz.json --save_path src --name tiz
˝˝˝


```
python3 scripts/render.py \
    --groups_json "src/tiz.json" \
    --save_path "src/" \
    --output_dir "results/" \
    --output_file results/result.zip
```

#### or if GPU-s are available
```
python3 scripts/render.py \
    --groups_json "src/example_group.json" \
    --save_path "src/" \
    --output_dir "results/" \
    --num_of_gpus 2 \
    --output_file results/result.zip
```