# PiQuick_Objects 
### *Web application for Objaverse Tooling*

PiQuick_Objects is a toolkit and web application designed for preparing datasets for large machine learning models. It allows users to download, process, and analyze 3D objects and their metadata from the Objaverse database, making it easier to curate and organize data for machine learning and other data-driven applications.

## Main Features:

**Metadata Collection**: Gather specific metadata from the Objaverse dataset with configurable extraction options.

**Object Organization and Rendering**: Utilize Blender to render 3D objects and arrange them in scenes, including handling multi-object scenes for large-scale rendering tasks.


**Web Interface**: Enables browsing, filtering, and customized downloads, allowing users to select and flag objects of interest based on metadata, 3D previews, and other features.

## Setup and Installation

### download.py
The ```download.py``` script downloads 3D objects from Objaverse based on a specified list of object IDs. This script checks existing files to avoid redundant downloads, handles missing objects, and supports multiprocessing to improve speed by leveraging available CPU cores.

```                             
python3 scripts/download.py    --id_file_path src/three_groups.json\
                                --save_path src/\
                                --store_in_save_path 0
```