import pytest
import os
import json
import sys
from unittest.mock import patch, MagicMock, mock_open, call
import argparse

# Ahhoz, hogy a teszt megtalálja a 'scripts' és 'models' modulokat,
# hozzá kell adni a projekt gyökerét a Python elérési úthoz.
# Ezt megteheted a pytest konfigurációban (conftest.py) vagy itt ideiglenesen.
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

# Most már importálhatjuk a tesztelendő modulokat és osztályokat
from scripts import download
from models.render_model import Group # Feltételezve, hogy ez az elérési út helyes

from utils.logging_config import setup_custom_logger

logger = setup_custom_logger("test_download")

# --- Fixtures ---

@pytest.fixture
def mock_args(tmp_path):
    """Fixture for mock command line arguments."""
    args = argparse.Namespace()
    args.groups_json = str(tmp_path / "test_groups.json")
    args.save_path = str(tmp_path / "output_paths")
    args.store_path = str(tmp_path / "objects_database")
    # Hozzunk létre egy dummy input json fájlt is
    dummy_group_data = [{"name": "group1", "object_ids": ["id1", "id2"]}]
    with open(args.groups_json, 'w') as f:
        json.dump(dummy_group_data, f)
    return args

@pytest.fixture
def mock_group():
    """Fixture for a mock Group object."""
    return Group(name="group1", object_ids=["id1", "id2"])

@pytest.fixture(autouse=True)
def mock_objaverse_and_logger(mocker):
    """Automatically mock objaverse and logger for all tests in this module."""
    mocker.patch('scripts.download.objaverse.load_objects')
    mocker.patch('scripts.download.objaverse._VERSIONED_PATH', new_callable=mocker.PropertyMock)
    mocker.patch('scripts.download.logger', new_callable=MagicMock) # Mock logger methods like info, error, etc.
    mocker.patch('scripts.download.setup_custom_logger', return_value=MagicMock()) # Mock the setup function itself if called within download

@pytest.fixture
def mock_fs(mocker):
    """Fixture to mock filesystem operations."""
    mock_exists = mocker.patch('os.path.exists')
    mock_listdir = mocker.patch('os.listdir')
    mock_makedirs = mocker.patch('os.makedirs')
    mock_open_func = mocker.patch('builtins.open', mock_open())
    return {
        "exists": mock_exists,
        "listdir": mock_listdir,
        "makedirs": mock_makedirs,
        "open": mock_open_func
    }

# --- Test Functions ---

def test_parse_arguments(mocker):
    """Test command line argument parsing."""
    test_argv = ['download.py', '--groups_json', 'groups.json', '--save_path', 'output', '--store_path', 'db']
    mocker.patch('sys.argv', test_argv)
    args = download.parse_arguments()
    assert args.groups_json == 'groups.json'
    assert args.save_path == 'output'
    assert args.store_path == 'db'

def test_parse_arguments_required(mocker):
    """Test that required arguments raise an error if missing."""
    test_argv = ['download.py']
    mocker.patch('sys.argv', test_argv)
    # Argparse exits on error, we catch SystemExit
    with pytest.raises(SystemExit):
        download.parse_arguments()

# --- Tests for search_in_database ---

def test_search_in_database_store_does_not_exist(mock_fs):
    """Test when the store directory doesn't exist."""
    mock_fs["exists"].return_value = False
    store_folder = "/fake/store"
    ids = ["id1", "id2"]
    expected_paths = [os.path.join(store_folder, "id1.glb"), os.path.join(store_folder, "id2.glb")]

    filepaths, ids_to_download = download.search_in_database(store_folder, ids)

    mock_fs["exists"].assert_called_once_with(store_folder)
    assert filepaths == expected_paths
    assert ids_to_download == ids

def test_search_in_database_store_exists_no_files(mock_fs):
    """Test when store exists but contains no relevant files."""
    mock_fs["exists"].return_value = True
    mock_fs["listdir"].return_value = [] # Empty directory
    store_folder = "/fake/store"
    ids = ["id1", "id2"]
    expected_paths = [os.path.join(store_folder, "id1.glb"), os.path.join(store_folder, "id2.glb")]

    filepaths, ids_to_download = download.search_in_database(store_folder, ids)

    mock_fs["exists"].assert_called_once_with(store_folder)
    mock_fs["listdir"].assert_called_once_with(store_folder)
    assert filepaths == expected_paths
    assert ids_to_download == ids

def test_search_in_database_store_exists_some_files(mock_fs):
    """Test when store exists and contains some of the files."""
    mock_fs["exists"].return_value = True
    mock_fs["listdir"].return_value = ["id1.glb", "otherfile.txt"] # id1 exists
    store_folder = "/fake/store"
    ids = ["id1", "id2", "id3"]
    expected_paths = [
        os.path.join(store_folder, "id1.glb"),
        os.path.join(store_folder, "id2.glb"),
        os.path.join(store_folder, "id3.glb")
    ]
    expected_ids_to_download = ["id2", "id3"]

    filepaths, ids_to_download = download.search_in_database(store_folder, ids)

    mock_fs["exists"].assert_called_once_with(store_folder)
    mock_fs["listdir"].assert_called_once_with(store_folder)
    assert filepaths == expected_paths
    assert sorted(ids_to_download) == sorted(expected_ids_to_download) # Order doesn't matter

def test_search_in_database_store_exists_all_files(mock_fs):
    """Test when store exists and contains all the files."""
    mock_fs["exists"].return_value = True
    mock_fs["listdir"].return_value = ["id1.glb", "id2.glb", "id3.glb"] # All exist
    store_folder = "/fake/store"
    ids = ["id1", "id2", "id3"]
    expected_paths = [
        os.path.join(store_folder, "id1.glb"),
        os.path.join(store_folder, "id2.glb"),
        os.path.join(store_folder, "id3.glb")
    ]
    expected_ids_to_download = []

    filepaths, ids_to_download = download.search_in_database(store_folder, ids)

    mock_fs["exists"].assert_called_once_with(store_folder)
    mock_fs["listdir"].assert_called_once_with(store_folder)
    assert filepaths == expected_paths
    assert ids_to_download == expected_ids_to_download

# --- Tests for write_group_to_json ---

def test_write_group_to_json(mock_fs, tmp_path):
    """Test writing the file paths to a JSON file."""
    group_name = "test_group"
    filepaths = ["/path/to/id1.glb", "/path/to/id2.glb"]
    save_path = str(tmp_path / "output")
    groups_json_path = str(tmp_path / "input/my_groups.json")  # Dummy input path
    expected_output_dir = os.path.join(save_path, "my_groups_paths")
    expected_json_path = os.path.join(expected_output_dir, f"{group_name}.json")

    # Call the function
    download.write_group_to_json(group_name, filepaths, save_path, groups_json_path)

    # Check that makedirs and open were called
    mock_fs["makedirs"].assert_called_once_with(expected_output_dir, exist_ok=True)
    mock_fs["open"].assert_called_once_with(expected_json_path, "w")

    # Reconstruct all written content
    file_handle_mock = mock_fs["open"]().__enter__()
    all_written_content = "".join(call_arg[0][0] for call_arg in file_handle_mock.write.call_args_list)

    # Now parse it as JSON
    written_data = json.loads(all_written_content)

    assert written_data == filepaths

# def test_write_group_to_json(mock_fs, tmp_path):
#     """Test writing the file paths to a JSON file."""
#     group_name = "test_group"
#     filepaths = ["/path/to/id1.glb", "/path/to/id2.glb"]
#     save_path = str(tmp_path / "output")
#     groups_json_path = str(tmp_path / "input/my_groups.json") # Dummy input path
#     expected_output_dir = os.path.join(save_path, "my_groups_paths")
#     expected_json_path = os.path.join(expected_output_dir, f"{group_name}.json")

#     download.write_group_to_json(group_name, filepaths, save_path, groups_json_path)

#     mock_fs["makedirs"].assert_called_once_with(expected_output_dir, exist_ok=True)
#     mock_fs["open"].assert_called_once_with(expected_json_path, "w")
#     # Get the file handle mock used in the 'with open(...)' statement
#     file_handle_mock = mock_fs["open"]().__enter__()
#     # Check if json.dump was called correctly
#     # json.dump(data, json_file, indent=2)
#     dump_args, dump_kwargs = file_handle_mock.write.call_args_list[0] # json.dump writes stringified json
#     written_data = json.loads(dump_args[0]) # Parse the written string back to Python object
#     assert written_data == filepaths


# --- Tests for load_groups_from_json ---

def test_load_groups_from_json_file(mock_fs, tmp_path):
    """Test loading group data from a valid JSON file."""
    json_path = tmp_path / "groups.json"
    group_data = [{"name": "g1", "object_ids": ["id1"]}]
    json_content = json.dumps(group_data)
    # Configure mock_open to return the JSON content
    mock_fs["open"].configure_mock(return_value=mock_open(read_data=json_content).return_value)

    groups = download.load_groups_from_json(str(json_path))

    mock_fs["open"].assert_called_once_with(str(json_path), 'r')
    assert len(groups) == 1
    assert isinstance(groups[0], Group)
    assert groups[0].name == "g1"
    assert groups[0].object_ids == ["id1"]

def test_load_groups_from_json_string():
    """Test loading group data directly from a JSON string."""
    group_data = [{"name": "g2", "object_ids": ["id2", "id3"]}]
    json_string = json.dumps(group_data)

    groups = download.load_groups_from_json(json_string)

    assert len(groups) == 1 
    assert isinstance(groups[0], Group)
    assert groups[0].name == "g2"
    assert groups[0].object_ids == ["id2", "id3"]


def test_load_groups_from_json_file_not_found(mocker, mock_fs, tmp_path):
    """Test error handling for a non-existent JSON file."""
    json_path = tmp_path / "nonexistent.json"
    mock_fs["open"].side_effect = FileNotFoundError("File not found")
    mock_exit = mocker.patch('sys.exit')

    download.load_groups_from_json(str(json_path))

    mock_fs["open"].assert_called_once_with(str(json_path), 'r')
    mock_exit.assert_called_once_with(1)

def test_load_groups_from_json_invalid_json(mocker, mock_fs, tmp_path):
    """Test error handling for invalid JSON content."""
    json_path = tmp_path / "invalid.json"
    invalid_json_content = '{"name": "g1", "object_ids": ["id1"]' # Missing closing brace
    mock_fs["open"].configure_mock(return_value=mock_open(read_data=invalid_json_content).return_value)
    mock_exit = mocker.patch('sys.exit')

    download.load_groups_from_json(str(json_path))

    mock_fs["open"].assert_called_once_with(str(json_path), 'r')
    mock_exit.assert_called_once_with(1)


# --- Tests for process_groups ---

@pytest.fixture
def mock_process_deps(mocker):
    """Fixture to mock dependencies of process_groups."""
    return {
        "search": mocker.patch('scripts.download.search_in_database'),
        "write": mocker.patch('scripts.download.write_group_to_json'),
        "load_objects": mocker.patch('scripts.download.objaverse.load_objects')
    }

def test_process_groups_all_exist(mock_process_deps, mock_args, mock_group):
    """Test process_groups when all files already exist."""
    mock_process_deps["search"].return_value = (["/path/id1.glb", "/path/id2.glb"], []) # No IDs to download
    groups = [mock_group]
    cpu_count = 4

    download.process_groups(groups, mock_args, cpu_count)

    expected_store_path = os.path.join(mock_args.store_path, "glbs", "000-023")
    mock_process_deps["search"].assert_called_once_with(expected_store_path, mock_group.object_ids)
    mock_process_deps["load_objects"].assert_not_called() # Should not download
    mock_process_deps["write"].assert_called_once_with(
        mock_group.name, ["/path/id1.glb", "/path/id2.glb"], mock_args.save_path, mock_args.groups_json
    )

def test_process_groups_none_exist(mock_process_deps, mock_args, mock_group):
    """Test process_groups when no files exist and all need downloading."""
    expected_paths = [os.path.join(mock_args.store_path, "glbs", "000-023", f"{id}.glb") for id in mock_group.object_ids]
    mock_process_deps["search"].return_value = (expected_paths, mock_group.object_ids) # All IDs to download
    groups = [mock_group]
    cpu_count = 4

    download.process_groups(groups, mock_args, cpu_count)

    expected_store_path = os.path.join(mock_args.store_path, "glbs", "000-023")
    mock_process_deps["search"].assert_called_once_with(expected_store_path, mock_group.object_ids)
    mock_process_deps["load_objects"].assert_called_once_with(
        uids=mock_group.object_ids,
        download_processes=cpu_count
    )
    mock_process_deps["write"].assert_called_once_with(
        mock_group.name, expected_paths, mock_args.save_path, mock_args.groups_json
    )

def test_process_groups_some_exist(mock_process_deps, mock_args, mock_group):
    """Test process_groups when some files exist."""
    ids_to_download = ["id2"]
    existing_paths = [os.path.join(mock_args.store_path, "glbs", "000-023", f"{id}.glb") for id in mock_group.object_ids]
    mock_process_deps["search"].return_value = (existing_paths, ids_to_download) # Only id2 to download
    groups = [mock_group]
    cpu_count = 4

    download.process_groups(groups, mock_args, cpu_count)

    expected_store_path = os.path.join(mock_args.store_path, "glbs", "000-023")
    mock_process_deps["search"].assert_called_once_with(expected_store_path, mock_group.object_ids)
    mock_process_deps["load_objects"].assert_called_once_with(
        uids=ids_to_download,
        download_processes=cpu_count
    )
    mock_process_deps["write"].assert_called_once_with(
        mock_group.name, existing_paths, mock_args.save_path, mock_args.groups_json
    )

# --- Tests for main ---

@patch('scripts.download.parse_arguments')
@patch('scripts.download.load_groups_from_json')
@patch('scripts.download.process_groups')
@patch('os.makedirs')
@patch('multiprocessing.cpu_count')
def test_main_flow(mock_cpu_count, mock_makedirs, mock_process, mock_load_groups, mock_parse_args, mock_args, mock_group):
    """Test the main execution flow."""
    # Setup mocks
    mock_parse_args.return_value = mock_args
    mock_load_groups.return_value = [mock_group]
    mock_cpu_count.return_value = 8

    # Run main
    download.main()

    # Assertions
    mock_parse_args.assert_called_once()
    mock_load_groups.assert_called_once_with(mock_args.groups_json)
    # Check if store_path was created
    mock_makedirs.assert_any_call(mock_args.store_path, exist_ok=True)
    mock_cpu_count.assert_called_once()
    mock_process.assert_called_once_with([mock_group], mock_args, 8)

@patch('scripts.download.parse_arguments')
@patch('scripts.download.load_groups_from_json')
@patch('scripts.download.process_groups')
@patch('os.makedirs')
@patch('multiprocessing.cpu_count')
def test_main_default_paths(mock_cpu_count, mock_makedirs, mock_process, mock_load_groups, mock_parse_args, tmp_path):
    """Test that default paths are set correctly when not provided."""

    # Mock args without save_path and store_path
    args_no_paths = argparse.Namespace()
    args_no_paths.groups_json = str(tmp_path / "input/groups.json")
    args_no_paths.save_path = None
    args_no_paths.store_path = None
    mock_parse_args.return_value = args_no_paths

    # Create dummy input file and directory
    (tmp_path / "input").mkdir(exist_ok=True)
    with open(args_no_paths.groups_json, 'w') as f:
        json.dump([{"name": "g1", "object_ids": ["id1"]}], f)

    mock_group_instance = Group(name="g1", object_ids=["id1"])
    mock_load_groups.return_value = [mock_group_instance]
    mock_cpu_count.return_value = 4

    # Expected default paths
    expected_save_path = str(tmp_path / "input")

    # Dynamically calculate project root based on test location
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    expected_store_path = os.path.join("src", "objects_database")

    # Run main
    download.main()

    # Assertions
    mock_parse_args.assert_called_once()
    mock_load_groups.assert_called_once_with(args_no_paths.groups_json)
    mock_makedirs.assert_any_call(expected_store_path, exist_ok=True)
    mock_cpu_count.assert_called_once()

    call_args, _ = mock_process.call_args
    processed_groups, processed_args, processed_cpu_count = call_args
    assert processed_args.save_path == expected_save_path
    assert processed_args.store_path == expected_store_path
    assert processed_cpu_count == 4
    assert processed_groups[0].name == mock_group_instance.name
