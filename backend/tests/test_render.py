"""
This test suite verifies the functionality of the render script, which processes 3D object groups,
renders them using Blender, and organizes the outputs. The tests cover:

1. Command-line argument handling - Parsing arguments, default values, and validation
2. JSON processing - Loading and validating group definitions from files or strings
3. Object downloading - Converting group definitions to file paths
4. Render command execution - Correctly invoking Blender with appropriate parameters
5. Output organization - Collecting and archiving render results

The render script is responsible for orchestrating the 3D rendering pipeline, managing GPU resources,
and handling various rendering settings like augmentation, multi-view modes, and image resolution.
"""
import pytest
import os
import json
import argparse
import zipfile
from unittest.mock import patch, MagicMock, mock_open, call, ANY
import subprocess 
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from utils.logging_config import setup_custom_logger
from scripts import render
logger = setup_custom_logger("test_render")

from models.render_model import Group, RenderSettings

from scripts.render import (
    parse_arguments,
    load_groups_from_json,
    download_groups,
    execute_command,
    zip_subfolders
)

# --- Fixtures ---

@pytest.fixture(autouse=True)
def mock_logger(mocker):
    """Automatically mock the logger for all tests."""
    mocker.patch('scripts.render.logger', new_callable=MagicMock)
    mocker.patch('scripts.render.setup_custom_logger', return_value=MagicMock())

@pytest.fixture
def mock_args(tmp_path):
    """Fixture for mock command line arguments."""
    args = argparse.Namespace()
    args.groups_json = str(tmp_path / "test_groups.json")
    args.save_path = str(tmp_path / "output_paths")
    args.store_path = str(tmp_path / "objects_database")
    args.output_dir = str(tmp_path / "render_outputs")
    args.num_of_gpus = 2
    args.output_file = str(tmp_path / "output.zip")

    dummy_group_data = [
        {"name": "group1", "object_ids": ["id1", "id2"], "settings": {"separately": False, "num_images": 10}},
        {"name": "group2", "object_ids": ["id3"], "settings": {"separately": True, "num_images": 5}}
    ]
    with open(args.groups_json, 'w') as f:
        json.dump(dummy_group_data, f)
    os.makedirs(args.save_path, exist_ok=True)
    os.makedirs(args.output_dir, exist_ok=True)
    return args

@pytest.fixture
def mock_group_settings():
    """Fixture for mock RenderSettings."""
    return RenderSettings(
        separately=False,
        num_images=10,
        resolution=512,
        azimuth_aug=False,
        elevation_aug=False,
        mode_multi=True,
        mode_front_view=False,
        mode_four_view=False,
        only_northern_hemisphere=False
    )

@pytest.fixture
def mock_group(mock_group_settings):
    """Fixture for a mock Group object."""
    return Group(name="group1", object_ids=["id1", "id2"], settings=mock_group_settings)

@pytest.fixture
def mock_fs(mocker):
    """Fixture to mock filesystem operations."""
    original_relpath = os.path.relpath
    
    mock_exists = mocker.patch('os.path.exists')
    mock_makedirs = mocker.patch('os.makedirs')
    mock_open_func = mocker.patch('builtins.open', mock_open())
    mock_walk = mocker.patch('os.walk')
    mock_relpath = mocker.patch('os.path.relpath')
    mock_isfile = mocker.patch('os.path.isfile')
    mock_basename = mocker.patch('os.path.basename')
    mock_dirname = mocker.patch('os.path.dirname')
    
    mock_relpath.side_effect = original_relpath
    
    return {
        "exists": mock_exists,
        "makedirs": mock_makedirs,
        "open": mock_open_func,
        "walk": mock_walk,
        "relpath": mock_relpath,
        "isfile": mock_isfile,
        "basename": mock_basename,
        "dirname": mock_dirname,
    }

@pytest.fixture
def mock_subprocess(mocker):
    """Fixture to mock subprocess.run."""
    return mocker.patch('subprocess.run', return_value=MagicMock(stdout=b'success', stderr=b'', returncode=0))

@pytest.fixture
def mock_zipfile(mocker):
    """Fixture to mock zipfile.ZipFile."""
    mock_zip = MagicMock()
    mock_cm = MagicMock()
    mock_cm.__enter__.return_value = mock_zip
    mocker.patch('zipfile.ZipFile', return_value=mock_cm)
    return mock_zip

@pytest.fixture
def mock_multiprocessing(mocker):
    """Fixture to mock multiprocessing.Pool."""
    mock_pool_instance = MagicMock()
    mock_pool_context = MagicMock(__enter__=MagicMock(return_value=mock_pool_instance), __exit__=MagicMock())
    mocker.patch('multiprocessing.Pool', return_value=mock_pool_context)
    return mock_pool_instance

@pytest.fixture
def mock_random(mocker):
    """Fixture to mock random functions."""
    mocker.patch('random.uniform', return_value=0.5)
    mocker.patch('random.randint', return_value=15)

# --- Test Functions ---

def test_parse_arguments(mocker):
    """RTC1: Verifies that command line arguments are correctly parsed with expected values."""
    test_argv = [
        'render.py',
        '--groups_json', 'groups.json',
        '--save_path', 'output',
        '--store_path', 'db',
        '--output_dir', 'renders',
        '--num_of_gpus', '4',
        '--output_file', 'final.zip'
    ]
    mocker.patch('sys.argv', test_argv)
    args = parse_arguments()
    assert args.groups_json == 'groups.json'
    assert args.save_path == 'output'
    assert args.store_path == 'db'
    assert args.output_dir == 'renders'
    assert args.num_of_gpus == 4
    assert args.output_file == 'final.zip'

def test_parse_arguments_defaults(mocker):
    """RTC2: Ensures default values are applied when optional arguments are not provided."""
    test_argv = ['render.py', '--groups_json', 'groups.json']
    mocker.patch('sys.argv', test_argv)
    args = parse_arguments()
    assert args.groups_json == 'groups.json'
    assert args.save_path is None
    assert args.store_path is None
    assert args.output_dir == '/outputs/.'
    assert args.num_of_gpus == 2
    assert args.output_file is None

def test_parse_arguments_required(mocker):
    """RTC3: Checks that the script exits when required arguments are missing."""
    test_argv = ['render.py']
    mocker.patch('sys.argv', test_argv)
    with pytest.raises(SystemExit):
        parse_arguments()

def test_load_groups_from_json_file(mock_fs, tmp_path):
    """RTC4: Tests loading Group objects from a JSON file, verifying proper parsing and instantiation."""
    json_path = tmp_path / "groups.json"
    group_data = [{"name": "g1", "object_ids": ["id1"], "settings": {"num_images": 5}}]
    json_content = json.dumps(group_data)
    mock_fs["open"].configure_mock(return_value=mock_open(read_data=json_content).return_value)
    mock_fs["open"].reset_mock()

    groups = load_groups_from_json(str(json_path))

    mock_fs["open"].assert_called_once_with(str(json_path), 'r')
    assert len(groups) == 1
    assert isinstance(groups[0], Group)
    assert groups[0].name == "g1"
    assert groups[0].object_ids == ["id1"]
    assert groups[0].settings.num_images == 5

def test_load_groups_from_json_string():
    """RTC5: Verifies that groups can be loaded directly from a JSON string instead of a file."""
    group_data = [{"name": "g2", "object_ids": ["id2", "id3"], "settings": {"resolution": 256}}]
    json_string = json.dumps(group_data)

    groups = load_groups_from_json(json_string)

    assert len(groups) == 1
    assert isinstance(groups[0], Group)
    assert groups[0].name == "g2"
    assert groups[0].object_ids == ["id2", "id3"]
    assert groups[0].settings.resolution == 256

def test_load_groups_from_json_file_not_found(mocker, mock_fs, tmp_path):
    """RTC6: Tests error handling when the JSON file cannot be found."""
    json_path = tmp_path / "nonexistent.json"
    mock_fs["open"].side_effect = FileNotFoundError("File not found")
    mock_exit = mocker.patch('sys.exit')
    mock_fs["open"].reset_mock()

    load_groups_from_json(str(json_path))

    mock_fs["open"].assert_called_once_with(str(json_path), 'r')
    mock_exit.assert_called_once_with(1)

def test_load_groups_from_json_invalid_json(mocker, mock_fs, tmp_path):
    """RTC7: Tests error handling when the JSON content is malformed or invalid."""
    json_path = tmp_path / "invalid.json"
    invalid_json_content = '[{"name": "g1", "object_ids": ["id1"]'
    mock_fs["open"].configure_mock(return_value=mock_open(read_data=invalid_json_content).return_value)
    mock_exit = mocker.patch('sys.exit')
    mock_fs["open"].reset_mock()

    load_groups_from_json(str(json_path))

    mock_fs["open"].assert_called_once_with(str(json_path), 'r')
    mock_exit.assert_called_once_with(1)

def test_download_groups(mock_args, mock_group, mock_subprocess, mock_fs, tmp_path):
    """RTC8: Tests that download_groups correctly invokes the download script and retrieves object paths."""
    groups = [mock_group]
    group_name = mock_group.name
    groups_json_basename = "test_groups"
    expected_output_json_dir = os.path.join(mock_args.save_path, f"{groups_json_basename}_paths")
    expected_group_json_path = os.path.join(expected_output_json_dir, f"{group_name}.json")
    expected_paths_data = ["/path/to/id1.glb", "/path/to/id2.glb"]

    mock_fs["basename"].return_value = f"{groups_json_basename}.json"
    mock_fs["exists"].return_value = True
    mock_fs["open"].configure_mock(return_value=mock_open(read_data=json.dumps(expected_paths_data)).return_value)
    mock_fs["open"].reset_mock()

    group_paths = download_groups(mock_args, groups)

    expected_download_args = [
        "python3", ANY,
        "--groups_json", mock_args.groups_json,
        "--save_path", mock_args.save_path,
        "--store_path", mock_args.store_path,
    ]
    mock_subprocess.assert_called_once_with(expected_download_args, check=True)

    mock_fs["basename"].assert_called_once_with(mock_args.groups_json)
    mock_fs["exists"].assert_called_once_with(expected_group_json_path)
    mock_fs["open"].assert_called_once_with(expected_group_json_path, "r")

    assert group_paths == {group_name: expected_paths_data}

def test_download_groups_file_not_found(mock_args, mock_group, mock_subprocess, mock_fs, tmp_path):
    """RTC9: Tests error handling when the download process completes but the paths file is missing."""
    groups = [mock_group]
    group_name = mock_group.name
    groups_json_basename = "test_groups"
    expected_output_json_dir = os.path.join(mock_args.save_path, f"{groups_json_basename}_paths")
    expected_group_json_path = os.path.join(expected_output_json_dir, f"{group_name}.json")

    mock_fs["basename"].return_value = f"{groups_json_basename}.json"
    mock_fs["exists"].return_value = False

    with pytest.raises(FileNotFoundError):
        download_groups(mock_args, groups)

    mock_subprocess.assert_called_once()
    mock_fs["exists"].assert_called_once_with(expected_group_json_path)
    mock_fs["open"].assert_not_called()
    

@pytest.mark.parametrize("azimuth_aug,elevation_aug,expected_suffix", [
    (False, False, ""),
    (True, False, "_az0.50"),
    (True, True, "_az0.50_el15"),
])
def test_execute_command_augmentation(
    mock_subprocess, mock_random, mock_args, mock_group_settings,
    azimuth_aug, elevation_aug, expected_suffix
):
    """RTC10: Verifies that render commands include proper augmentation suffixes based on settings."""
    objects_paths = ["/path/obj1.glb"]
    save_file_name = "my_render"
    gpu_id = 0
    
    mock_group_settings.azimuth_aug = azimuth_aug
    mock_group_settings.elevation_aug = elevation_aug
    
    execute_command(objects_paths, save_file_name, mock_args.output_dir, 
                   gpu_id, False, mock_group_settings)
    
    called_command = mock_subprocess.call_args[0][0]
    expected_output_path = f"{mock_args.output_dir}/{save_file_name}{expected_suffix}"
    
    assert f"--output_dir {expected_output_path}" in called_command

def test_zip_subfolders(mock_fs, mock_zipfile, tmp_path):
    """RTC11: Tests that the zip_subfolders function correctly archives all files in the output directory."""
    output_dir = str(tmp_path / "render_outputs")
    output_file = str(tmp_path / "output.zip")

    walk_data = [
        (output_dir, ['subdir1', 'subdir2'], ['rootfile.txt']),
        (os.path.join(output_dir, 'subdir1'), [], ['file1.png', 'file2.jpg']),
        (os.path.join(output_dir, 'subdir2'), [], ['file3.exr']),
    ]
    mock_fs["walk"].return_value = walk_data

    zip_subfolders(output_dir, output_file)

    expected_calls = [
        call(os.path.join(output_dir, 'rootfile.txt'), 'rootfile.txt'),
        call(os.path.join(output_dir, 'subdir1', 'file1.png'), os.path.join('subdir1', 'file1.png')),
        call(os.path.join(output_dir, 'subdir1', 'file2.jpg'), os.path.join('subdir1', 'file2.jpg')),
        call(os.path.join(output_dir, 'subdir2', 'file3.exr'), os.path.join('subdir2', 'file3.exr')),
    ]

    mock_zipfile.write.assert_has_calls(expected_calls, any_order=True)
    assert mock_zipfile.write.call_count == len(expected_calls)

# --- Test Main Flow ---

@patch('scripts.render.parse_arguments')
@patch('scripts.render.load_groups_from_json')
@patch('scripts.render.download_groups')
@patch('scripts.render.execute_command')
@patch('scripts.render.zip_subfolders')
@patch('os.makedirs')
@patch('os.path.isfile')
@patch('multiprocessing.Pool')
def test_main_flow(mock_pool, mock_isfile, mock_makedirs, mock_zip, mock_execute, mock_download, mock_load, mock_parse, mock_args, mock_multiprocessing, tmp_path):
    """RTC12: Tests the complete execution flow, verifying all components are called in the correct sequence."""
    mock_pool_instance = MagicMock()
    mock_starmap = MagicMock()
    mock_pool_instance.starmap = mock_starmap
    mock_pool.return_value.__enter__.return_value = mock_pool_instance
    
    render_tasks_captured = []
    
    def capture_tasks(func, tasks):
        nonlocal render_tasks_captured
        render_tasks_captured = tasks
        return None
        
    mock_starmap.side_effect = capture_tasks

    mock_parse.return_value = mock_args
    mock_isfile.return_value = True

    settings1 = RenderSettings(separately=False, num_images=10)
    settings2 = RenderSettings(separately=True, num_images=5)
    group1 = Group(name="group1", object_ids=["id1", "id2"], settings=settings1)
    group2 = Group(name="group2", object_ids=["id3", "id4"], settings=settings2)
    mock_load.return_value = [group1, group2]

    mock_group_paths = {
        "group1": ["/path/id1.glb", "/path/id2.glb"],
        "group2": ["/path/id3.glb", "/path/id4.glb"]
    }
    mock_download.return_value = mock_group_paths

    gpu_count = mock_args.num_of_gpus

    render.main()

    mock_parse.assert_called_once()
    mock_isfile.assert_called_once_with(mock_args.groups_json)
    mock_load.assert_called_once_with(mock_args.groups_json)
    mock_download.assert_called_once_with(mock_args, [group1, group2])
    mock_makedirs.assert_called_once_with(mock_args.output_dir, exist_ok=True)

    expected_tasks = [
    (mock_group_paths["group1"], "group1", mock_args.output_dir, 0 % gpu_count, False, settings1),
    ([mock_group_paths["group2"][0]], "group2" + "id3"[:5], mock_args.output_dir, 1 % gpu_count, True, settings2),
    ([mock_group_paths["group2"][1]], "group2" + "id4"[:5], mock_args.output_dir, 2 % gpu_count, True, settings2),
    ]
    assert render_tasks_captured == expected_tasks

    mock_starmap.assert_called_once_with(mock_execute, expected_tasks)
    mock_zip.assert_called_once_with(mock_args.output_dir, mock_args.output_file)


@patch('scripts.render.parse_arguments')
@patch('os.path.isfile')
def test_main_groups_json_not_found(mock_isfile, mock_parse, mock_args):
    """RTC13: Tests that the main function raises a FileNotFoundError when the groups JSON file does not exist."""
    mock_parse.return_value = mock_args
    mock_isfile.return_value = False

    with pytest.raises(FileNotFoundError):
        render.main()

    mock_parse.assert_called_once()
    mock_isfile.assert_called_once_with(mock_args.groups_json)
