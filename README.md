# PiQuick_Objects
 Web application for Objaverse Tooling

## download.py
```
python3 scripts/download.py     --id_file_path src/three_groups.json\
                                --obj_save_path src/three_groups/
```
## metadata_extractor
```
python3 scripts/download2.py    --id_file_path src/metadata_test.json\
                                --save_path src/\
                                --store_in_save_path 0
```

Download Blender:
```
cd scripts

wget https://download.blender.org/release/Blender3.2/blender-3.2.2-linux-x64.tar.xz && \
    tar -xf blender-3.2.2-linux-x64.tar.xz && \
    rm blender-3.2.2-linux-x64.tar.xz
```

If you're on a headless Linux server, install Xorg and start it:
```
sudo apt-get install xserver-xorg -y && \
  sudo python3 start_x_server.py start
```

Run metadata_extractor
```
cd ..

scripts/blender-3.2.2-linux-x64/blender --background --python scripts/metadata_multiproc.py -- \
        --save_path metadata/ \
        --objects_path src/metadata_test_paths/
```
<!-- \
    --cpu_count 16 \
    --run_vertex \
    --run_armature \
    --run_mesh \
    --run_poly \
    --run_material \
    --run_edge \
    --run_animation
-->
