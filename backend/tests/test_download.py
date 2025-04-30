"""
This test suite verifies the functionality of the download script, which is responsible for
retrieving 3D object files from Objaverse based on group definitions. The tests cover:

1. Command-line argument handling - Parsing arguments with proper defaults and validation
2. Database searching - Finding existing objects in the local database to avoid redundant downloads
3. Group data processing - Loading and validating group definitions from JSON
4. File management - Creating proper directory structures and writing path information
5. Main workflow execution - Coordinating the download process with proper error handling

The download script serves as the data acquisition layer for the 3D object pipeline,
ensuring efficient retrieval and storage of 3D models while avoiding duplicate downloads.
"""
import pytest
import os
import json
import sys
from unittest.mock import patch, MagicMock, mock_open, call
import argparse
from scripts import download
from models.render_model import Group
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
    mocker.patch('scripts.download.logger', new_callable=MagicMock)
    mocker.patch('scripts.download.setup_custom_logger', return_value=MagicMock())

@pytest.fixture
def mock_fs(mocker):
    """Fixture to mock filesystem operations."""
    mock_exists = mocker.patch('os.path.exists')
    mock_makedirs = mocker.patch('os.makedirs')
    mock_open_func = mocker.patch('builtins.open', mock_open())
    mock_remove = mocker.patch('os.remove')
    return {
        "exists": mock_exists,
        "makedirs": mock_makedirs,
        "open": mock_open_func,
        "remove": mock_remove
    }

# --- Test Functions ---

def test_parse_arguments(mocker):
    """DTC1: Test command line argument parsing."""
    test_argv = ['download.py', '--groups_json', 'groups.json', '--save_path', 'output', '--store_path', 'db']
    mocker.patch('sys.argv', test_argv)
    args = download.parse_arguments()
    assert args.groups_json == 'groups.json'
    assert args.save_path == 'output'
    assert args.store_path == 'db'

def test_parse_arguments_required(mocker):
    """DTC2: Test that required arguments raise an error if missing."""
    test_argv = ['download.py']
    mocker.patch('sys.argv', test_argv)
    with pytest.raises(SystemExit):
        download.parse_arguments()

# --- Tests for paths database operations ---

def test_load_paths_database_file_exists(mock_fs):
    """Test loading an existing paths database."""
    db_path = "/fake/store"
    db_file = os.path.join(db_path, "paths_for_db.json")
    db_content = {"id1": "/path/to/id1.glb", "id2": "/path/to/id2.glb"}
    mock_fs["exists"].return_value = True
    mock_fs["open"].return_value.__enter__.return_value.read.return_value = json.dumps(db_content)
    
    result = download.load_paths_database(db_path)
    
    mock_fs["exists"].assert_called_once_with(db_file)
    mock_fs["open"].assert_called_once_with(db_file, 'r')
    assert result == db_content

def test_load_paths_database_file_does_not_exist(mock_fs):
    """Test loading a paths database when the file doesn't exist."""
    db_path = "/fake/store"
    db_file = os.path.join(db_path, "paths_for_db.json")
    mock_fs["exists"].return_value = False
    
    result = download.load_paths_database(db_path)
    
    mock_fs["exists"].assert_called_once_with(db_file)
    mock_fs["open"].assert_not_called()
    assert result == {}

def test_load_paths_database_json_error(mock_fs, mocker):
    """Test error handling when loading an invalid JSON database."""
    db_path = "/fake/store"
    db_file = os.path.join(db_path, "paths_for_db.json")
    mock_fs["exists"].return_value = True
    mock_fs["open"].return_value.__enter__.return_value.read.side_effect = json.JSONDecodeError("Invalid JSON", "", 0)
    mock_warning = mocker.patch.object(download.logger, 'warning')
    
    result = download.load_paths_database(db_path)
    
    mock_fs["exists"].assert_called_once_with(db_file)
    mock_fs["open"].assert_called_once_with(db_file, 'r')
    mock_warning.assert_called_once()
    assert result == {}

def test_save_paths_database(mock_fs):
    """Test saving a paths database."""
    db_path = "/fake/store"
    db_file = os.path.join(db_path, "paths_for_db.json")
    paths_db = {"id1": "/path/to/id1.glb", "id2": "/path/to/id2.glb"}
    mock_fs["exists"].return_value = True
    
    # Configure the mock to capture all write calls
    mock_file_handle = mock_open().return_value.__enter__.return_value
    mock_fs["open"].return_value.__enter__.return_value = mock_file_handle
    
    download.save_paths_database(db_path, paths_db)
    
    mock_fs["exists"].assert_called_once_with(db_file)
    mock_fs["remove"].assert_called_once_with(db_file)
    mock_fs["makedirs"].assert_called_once_with(os.path.dirname(db_file), exist_ok=True)
    mock_fs["open"].assert_called_once_with(db_file, 'w')
    
    # Get the argument passed to json.dump through the mock
    # Instead of checking the written content string, mock the json.dump function
    with patch('json.dump') as mock_json_dump:
        download.save_paths_database(db_path, paths_db)
        mock_json_dump.assert_called_once()
        # Check that the first argument to json.dump is our paths_db dictionary
        saved_data = mock_json_dump.call_args[0][0]
        assert "id1" in saved_data
        assert "id2" in saved_data
        assert saved_data["id1"] == "/path/to/id1.glb"
        assert saved_data["id2"] == "/path/to/id2.glb"

# --- Tests for search_in_database ---

def test_search_in_database_store_does_not_exist(mocker):
    """DTC3: Test searching in database when no paths are stored."""
    mock_load_db = mocker.patch('scripts.download.load_paths_database', return_value={})
    store_path = "/fake/store"
    ids = ["id1", "id2"]
    
    existing_filepaths, ids_to_download = download.search_in_database(store_path, ids)
    
    mock_load_db.assert_called_once_with(store_path)
    assert existing_filepaths == []
    assert sorted(ids_to_download) == sorted(ids)

def test_search_in_database_store_exists_no_files(mocker):
    """DTC4: Test when paths database exists but contains no relevant IDs."""
    mock_load_db = mocker.patch('scripts.download.load_paths_database', return_value={
        "other1": "/path/to/other1.glb",
        "other2": "/path/to/other2.glb"
    })
    store_path = "/fake/store"
    ids = ["id1", "id2"]
    
    existing_filepaths, ids_to_download = download.search_in_database(store_path, ids)
    
    mock_load_db.assert_called_once_with(store_path)
    assert existing_filepaths == []
    assert sorted(ids_to_download) == sorted(ids)

def test_search_in_database_store_exists_some_files(mocker):
    """DTC5: Test when database contains some of the requested IDs."""
    mock_load_db = mocker.patch('scripts.download.load_paths_database', return_value={
        "id1": "/path/to/id1.glb",
        "other": "/path/to/other.glb"
    })
    store_path = "/fake/store"
    ids = ["id1", "id2", "id3"]
    
    existing_filepaths, ids_to_download = download.search_in_database(store_path, ids)
    
    mock_load_db.assert_called_once_with(store_path)
    assert existing_filepaths == ["/path/to/id1.glb"]
    assert sorted(ids_to_download) == sorted(["id2", "id3"])

def test_search_in_database_store_exists_all_files(mocker):
    """DTC6: Test when database contains all the requested IDs."""
    mock_load_db = mocker.patch('scripts.download.load_paths_database', return_value={
        "id1": "/path/to/id1.glb",
        "id2": "/path/to/id2.glb",
        "id3": "/path/to/id3.glb"
    })
    store_path = "/fake/store"
    ids = ["id1", "id2", "id3"]
    
    existing_filepaths, ids_to_download = download.search_in_database(store_path, ids)
    
    mock_load_db.assert_called_once_with(store_path)
    assert sorted(existing_filepaths) == sorted(["/path/to/id1.glb", "/path/to/id2.glb", "/path/to/id3.glb"])
    assert ids_to_download == []

# --- Tests for write_group_to_json ---

def test_write_group_to_json(mock_fs, tmp_path):
    """DTC7: Test writing the file paths to a JSON file."""
    group_name = "test_group"
    filepaths = ["/path/to/id1.glb", "/path/to/id2.glb"]
    save_path = str(tmp_path / "output")
    groups_json_path = str(tmp_path / "input/my_groups.json")
    expected_output_dir = os.path.join(save_path, "my_groups_paths")
    expected_json_path = os.path.join(expected_output_dir, f"{group_name}.json")

    download.write_group_to_json(group_name, filepaths, save_path, groups_json_path)

    mock_fs["makedirs"].assert_called_once_with(expected_output_dir, exist_ok=True)
    mock_fs["open"].assert_called_once_with(expected_json_path, "w")

    file_handle_mock = mock_fs["open"]().__enter__()
    all_written_content = "".join(call_arg[0][0] for call_arg in file_handle_mock.write.call_args_list)

    written_data = json.loads(all_written_content)
    assert written_data == filepaths

# --- Tests for load_groups_from_json ---

def test_load_groups_from_json_file(mock_fs, tmp_path):
    """DTC8: Test loading group data from a valid JSON file."""
    json_path = tmp_path / "groups.json"
    group_data = [{"name": "g1", "object_ids": ["id1"]}]
    json_content = json.dumps(group_data)
    mock_fs["open"].configure_mock(return_value=mock_open(read_data=json_content).return_value)

    groups = download.load_groups_from_json(str(json_path))

    mock_fs["open"].assert_called_once_with(str(json_path), 'r')
    assert len(groups) == 1
    assert isinstance(groups[0], Group)
    assert groups[0].name == "g1"
    assert groups[0].object_ids == ["id1"]

def test_load_groups_from_json_string():
    """DTC9: Test loading group data directly from a JSON string."""
    group_data = [{"name": "g2", "object_ids": ["id2", "id3"]}]
    json_string = json.dumps(group_data)

    groups = download.load_groups_from_json(json_string)

    assert len(groups) == 1 
    assert isinstance(groups[0], Group)
    assert groups[0].name == "g2"
    assert groups[0].object_ids == ["id2", "id3"]

def test_load_groups_from_json_file_not_found(mocker, mock_fs, tmp_path):
    """DTC10: Test error handling for a non-existent JSON file."""
    json_path = tmp_path / "nonexistent.json"
    mock_fs["open"].side_effect = FileNotFoundError("File not found")
    mock_exit = mocker.patch('sys.exit')

    download.load_groups_from_json(str(json_path))

    mock_fs["open"].assert_called_once_with(str(json_path), 'r')
    mock_exit.assert_called_once_with(1)

def test_load_groups_from_json_invalid_json(mocker, mock_fs, tmp_path):
    """DTC11: Test error handling for invalid JSON content."""
    json_path = tmp_path / "invalid.json"
    invalid_json_content = '{"name": "g1", "object_ids": ["id1"]'
    mock_fs["open"].configure_mock(return_value=mock_open(read_data=invalid_json_content).return_value)
    mock_exit = mocker.patch('sys.exit')

    download.load_groups_from_json(str(json_path))

    mock_fs["open"].assert_called_once_with(str(json_path), 'r')
    mock_exit.assert_called_once_with(1)

# --- Tests for process_groups ---

def test_process_groups_all_exist(mocker, mock_args, mock_group):
    """DTC12: Test process_groups when all files already exist."""
    mock_search = mocker.patch('scripts.download.search_in_database')
    mock_search.return_value = (["/path/id1.glb", "/path/id2.glb"], [])
    
    mock_load_db = mocker.patch('scripts.download.load_paths_database')
    mock_save_db = mocker.patch('scripts.download.save_paths_database')
    mock_write = mocker.patch('scripts.download.write_group_to_json')
    
    groups = [mock_group]
    cpu_count = 4

    download.process_groups(groups, mock_args, cpu_count)

    mock_search.assert_called_once_with(mock_args.store_path, mock_group.object_ids)
    mock_load_db.assert_not_called()
    mock_save_db.assert_not_called()
    mock_write.assert_called_once_with(
        mock_group.name, ["/path/id1.glb", "/path/id2.glb"], mock_args.save_path, mock_args.groups_json
    )

def test_process_groups_none_exist(mocker, mock_args, mock_group):
    """DTC13: Test process_groups when no files exist and all need downloading."""
    # Setup for the first search_in_database call
    mock_search = mocker.patch('scripts.download.search_in_database')
    mock_search.side_effect = [
        ([], mock_group.object_ids),  # First call - no files exist
        (["/path/id1.glb", "/path/id2.glb"], [])  # Second call - files found after download
    ]
    
    mock_load_objects = mocker.patch('scripts.download.objaverse.load_objects')
    mock_load_objects.return_value = {
        "id1": "/path/id1.glb",
        "id2": "/path/id2.glb"
    }
    
    mock_load_db = mocker.patch('scripts.download.load_paths_database')
    mock_load_db.return_value = {}
    
    mock_save_db = mocker.patch('scripts.download.save_paths_database')
    mock_write = mocker.patch('scripts.download.write_group_to_json')
    
    groups = [mock_group]
    cpu_count = 4

    download.process_groups(groups, mock_args, cpu_count)

    # Check first call to search_in_database
    assert mock_search.call_count == 2
    mock_search.assert_any_call(mock_args.store_path, mock_group.object_ids)
    
    # Check that load_objects was called with correct parameters
    mock_load_objects.assert_called_once_with(
        uids=mock_group.object_ids,
        download_processes=cpu_count
    )
    
    # Check that database operations were performed
    mock_load_db.assert_called_once_with(mock_args.store_path)
    mock_save_db.assert_called_once()
    
    # Check that write_group_to_json was called with the right paths
    mock_write.assert_called_once_with(
        mock_group.name, ["/path/id1.glb", "/path/id2.glb"], mock_args.save_path, mock_args.groups_json
    )

def test_process_groups_some_exist(mocker, mock_args, mock_group):
    """DTC14: Test process_groups when some files exist."""
    # Setup for the first search_in_database call
    mock_search = mocker.patch('scripts.download.search_in_database')
    mock_search.side_effect = [
        (["/path/id1.glb"], ["id2"]),  # First call - one file exists, one needs download
        (["/path/id1.glb", "/path/id2.glb"], [])  # Second call - both files found after download
    ]
    
    mock_load_objects = mocker.patch('scripts.download.objaverse.load_objects')
    mock_load_objects.return_value = {
        "id2": "/path/id2.glb"
    }
    
    mock_load_db = mocker.patch('scripts.download.load_paths_database')
    mock_load_db.return_value = {"id1": "/path/id1.glb"}
    
    mock_save_db = mocker.patch('scripts.download.save_paths_database')
    mock_write = mocker.patch('scripts.download.write_group_to_json')
    
    groups = [mock_group]
    cpu_count = 4

    download.process_groups(groups, mock_args, cpu_count)

    # Check calls to search_in_database
    assert mock_search.call_count == 2
    mock_search.assert_any_call(mock_args.store_path, mock_group.object_ids)
    
    # Check that load_objects was called with correct parameters
    mock_load_objects.assert_called_once_with(
        uids=["id2"],
        download_processes=cpu_count
    )
    
    # Check that database operations were performed
    mock_load_db.assert_called_once_with(mock_args.store_path)
    mock_save_db.assert_called_once()
    
    # Check that write_group_to_json was called with the right paths
    mock_write.assert_called_once_with(
        mock_group.name, ["/path/id1.glb", "/path/id2.glb"], mock_args.save_path, mock_args.groups_json
    )

# --- Tests for main ---

@patch('scripts.download.parse_arguments')
@patch('scripts.download.load_groups_from_json')
@patch('scripts.download.process_groups')
@patch('os.makedirs')
@patch('multiprocessing.cpu_count')
def test_main_flow(mock_cpu_count, mock_makedirs, mock_process, mock_load_groups, mock_parse_args, mock_args, mock_group):
    """DTC15: Test the main execution flow."""
    mock_parse_args.return_value = mock_args
    mock_load_groups.return_value = [mock_group]
    mock_cpu_count.return_value = 8

    download.main()

    mock_parse_args.assert_called_once()
    mock_load_groups.assert_called_once_with(mock_args.groups_json)
    mock_makedirs.assert_any_call(mock_args.store_path, exist_ok=True)
    mock_cpu_count.assert_called_once()
    mock_process.assert_called_once_with([mock_group], mock_args, 8)

@patch('scripts.download.parse_arguments')
@patch('scripts.download.load_groups_from_json')
@patch('scripts.download.process_groups')
@patch('os.makedirs')
@patch('multiprocessing.cpu_count')
def test_main_default_paths(mock_cpu_count, mock_makedirs, mock_process, mock_load_groups, mock_parse_args, tmp_path):
    """DTC16: Test that default paths are set correctly when not provided."""
    args_no_paths = argparse.Namespace()
    args_no_paths.groups_json = str(tmp_path / "input/groups.json")
    args_no_paths.save_path = None
    args_no_paths.store_path = None
    mock_parse_args.return_value = args_no_paths

    (tmp_path / "input").mkdir(exist_ok=True)
    with open(args_no_paths.groups_json, 'w') as f:
        json.dump([{"name": "g1", "object_ids": ["id1"]}], f)

    mock_group_instance = Group(name="g1", object_ids=["id1"])
    mock_load_groups.return_value = [mock_group_instance]
    mock_cpu_count.return_value = 4

    expected_save_path = str(tmp_path / "input")
    expected_store_path = os.path.join(os.path.dirname(os.path.abspath(__file__).split(os.sep)[-3]), "src", "objects_database")

    download.main()

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