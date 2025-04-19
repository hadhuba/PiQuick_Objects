import pytest
import os
import argparse
import json
import multiprocessing
import sys
from unittest.mock import patch, MagicMock, call, mock_open

# Mock bpy module before importing the script - use a simple dict-like object
# to avoid RecursionError with complex MagicMock structures
class MockBpy:
    # Mock the types module for type annotations
    class Types:
        Scene = type('Scene', (), {})
        Object = type('Object', (), {})
        Material = type('Material', (), {})
        Texture = type('Texture', (), {})
        Image = type('Image', (), {})
        Action = type('Action', (), {})
    
    class Ops:
        class ImportScene:
            def __init__(self):
                self.gltf = MagicMock()
                self.fbx = MagicMock()
        
        def __init__(self):
            self.import_scene = self.ImportScene()
    
    class Data:
        def __init__(self):
            self.objects = MagicMock()
            self.materials = MagicMock()
            self.textures = MagicMock()
            self.images = MagicMock()
            self.actions = MagicMock()
    
    class Context:
        def __init__(self):
            self.scene = MagicMock()
    
    def __init__(self):
        self.ops = self.Ops()
        self.data = self.Data()
        self.context = self.Context()
        self.types = self.Types()

# Create a simpler mock that won't cause recursion depth issues
mock_bpy = MockBpy()
sys.modules['bpy'] = mock_bpy

# Now we can safely import the functions
from scripts.metadata_multiproc import task, save_to_file, main, split_list, parse_args

# filepath: PiQuick_Objects/scripts/test_metadata_multiproc.py

# Since the parent directory has no __init__.py, use absolute import
# Assuming tests are run from the project root (PiQuick_Objects)

# Mock the bpy module as it's not available outside Blender
@pytest.fixture
def mock_bpy(mocker):
    """Mocks the bpy module and its relevant parts."""
    # Use our simplified mock structure
    mock_bpy_instance = MockBpy()
    
    # Set up specific behaviors
    mock_mesh_obj = MagicMock(type="MESH", name="mesh_obj")
    mock_camera_obj = MagicMock(type="CAMERA", name="camera_obj")
    mock_light_obj = MagicMock(type="LIGHT", name="light_obj")
    
    # Create a fixed list of objects for iteration
    mock_objects_list = [mock_mesh_obj, mock_camera_obj, mock_light_obj]
    mock_bpy_instance.data.objects.__iter__.side_effect = lambda: iter(mock_objects_list)
    mock_bpy_instance.data.objects.remove = MagicMock()
    
    # Set up materials
    mock_mat1 = MagicMock(name="mat1")
    materials_list = [mock_mat1]
    mock_bpy_instance.data.materials.__iter__.side_effect = lambda: iter(materials_list)
    mock_bpy_instance.data.materials.__len__.return_value = len(materials_list)
    mock_bpy_instance.data.materials.remove = MagicMock()
    
    # Set up textures
    mock_tex1 = MagicMock(name="tex1")
    textures_list = [mock_tex1]
    mock_bpy_instance.data.textures.__iter__.side_effect = lambda: iter(textures_list)
    mock_bpy_instance.data.textures.remove = MagicMock()
    
    # Set up images
    mock_img1 = MagicMock(name="img1")
    images_list = [mock_img1]
    mock_bpy_instance.data.images.__iter__.side_effect = lambda: iter(images_list)
    mock_bpy_instance.data.images.remove = MagicMock()
    
    # Set up actions
    mock_action1 = MagicMock(name="action1")
    actions_list = [mock_action1]
    mock_bpy_instance.data.actions.__iter__.side_effect = lambda: iter(actions_list)
    mock_bpy_instance.data.actions.__len__.return_value = len(actions_list)
    
    # Patch the bpy module in the script
    mocker.patch('scripts.metadata_multiproc.bpy', mock_bpy_instance)
    return mock_bpy_instance

# Mock the helper metadata functions
@pytest.fixture
def mock_metadata_helpers(mocker):
    """Mocks the metadata counting functions."""
    mocks = {
        'count_vertices': mocker.patch('scripts.metadata_multiproc.count_vertices', return_value=100),
        'count_armatures': mocker.patch('scripts.metadata_multiproc.count_armatures', return_value=1),
        'count_meshes': mocker.patch('scripts.metadata_multiproc.count_meshes', return_value=2),
        'count_poly': mocker.patch('scripts.metadata_multiproc.count_poly', return_value=200),
        'count_edge': mocker.patch('scripts.metadata_multiproc.count_edge', return_value=300),
    }
    return mocks

# Mock the global 'args' object used within the module
@pytest.fixture
def mock_args_all_true(mocker):
    """Mocks the args namespace with all run flags set to True."""
    args = argparse.Namespace(
        run_vertex=True,
        run_armature=True,
        run_mesh=True,
        run_poly=True,
        run_material=True,
        run_edge=True,
        run_animation=True
    )
    mocker.patch('scripts.metadata_multiproc.args', args)
    return args

@pytest.fixture
def mock_args_some_false(mocker):
    """Mocks the args namespace with some run flags set to False."""
    args = argparse.Namespace(
        run_vertex=False,
        run_armature=True,
        run_mesh=True,
        run_poly=False,
        run_material=True,
        run_edge=True,
        run_animation=False
    )
    mocker.patch('scripts.metadata_multiproc.args', args)
    return args

# Mock os.path functions used in task
@pytest.fixture
def mock_os_path(mocker):
    """Mocks os.path.splitext and os.path.basename."""
    real_splitext = os.path.splitext  # <- mentsd el az eredeti függvényt!
    real_basename = os.path.basename  # <- ha a basename-t is mockolod, érdemes azt is elmenteni

    mock_splitext = mocker.patch('os.path.splitext')
    mock_basename = mocker.patch('os.path.basename')

    def basename_side_effect(path):
        return os.path.normpath(path).split(os.sep)[-1]

    def splitext_side_effect(path):
        base = basename_side_effect(path)
        return real_splitext(base)  # <- itt az eredeti splitext-et hívod

    mock_basename.side_effect = basename_side_effect
    mock_splitext.side_effect = splitext_side_effect

    return {'splitext': mock_splitext, 'basename': mock_basename}

# --- Test Functions ---

def test_task_imports_glb_all_flags(mock_bpy, mock_metadata_helpers, mock_args_all_true, mock_os_path):
    """Tests task with a .glb file and all metadata flags enabled."""
    object_files_chunk = ["/fake/path/to/model.glb"]
    expected_obj_id = "model"

    result = task(object_files_chunk)

    # Check import call
    mock_bpy.ops.import_scene.gltf.assert_called_once_with(filepath=object_files_chunk[0])
    mock_bpy.ops.import_scene.fbx.assert_not_called()

    # Check metadata function calls
    mock_metadata_helpers['count_vertices'].assert_called_once_with(mock_bpy.context.scene)
    mock_metadata_helpers['count_armatures'].assert_called_once_with(mock_bpy.context.scene)
    mock_metadata_helpers['count_meshes'].assert_called_once_with(mock_bpy.context.scene)
    mock_metadata_helpers['count_poly'].assert_called_once_with(mock_bpy.context.scene)
    mock_metadata_helpers['count_edge'].assert_called_once_with(mock_bpy.context.scene)

    # Check cleanup calls (only non-camera/light objects removed)
    # Expected calls: remove(mesh_obj), remove(material), remove(texture), remove(image)
    assert mock_bpy.data.objects.remove.call_count == 1
    # Get the mock mesh object that would have been iterated over
    mesh_obj = next(iter(mock_bpy.data.objects.__iter__.side_effect()))
    mock_bpy.data.objects.remove.assert_called_once_with(mesh_obj, do_unlink=True)
    mock_bpy.data.materials.remove.assert_called_once()
    mock_bpy.data.textures.remove.assert_called_once()
    mock_bpy.data.images.remove.assert_called_once()

    # Check result dictionary
    expected_result = {
        "vertex_num": {expected_obj_id: 100},
        "armature_count": {expected_obj_id: 1},
        "mesh_count": {expected_obj_id: 2},
        "poly_count": {expected_obj_id: 200},
        "material_count": {expected_obj_id: 1}, # Based on len(mock_bpy.data.materials)
        "edge_count": {expected_obj_id: 300},
        "animation_count": {expected_obj_id: 1} # Based on len(mock_bpy.data.actions)
    }
    assert result == expected_result

def test_task_imports_fbx_some_flags(mock_bpy, mock_metadata_helpers, mock_args_some_false, mock_os_path):
    """Tests task with a .fbx file and some metadata flags disabled."""
    object_files_chunk = ["/fake/path/to/another_model.fbx"]
    expected_obj_id = "another_model"

    result = task(object_files_chunk)

    # Check import call
    mock_bpy.ops.import_scene.fbx.assert_called_once_with(filepath=object_files_chunk[0])
    mock_bpy.ops.import_scene.gltf.assert_not_called()

    # Check metadata function calls (only for enabled flags)
    mock_metadata_helpers['count_vertices'].assert_not_called()
    mock_metadata_helpers['count_armatures'].assert_called_once_with(mock_bpy.context.scene)
    mock_metadata_helpers['count_meshes'].assert_called_once_with(mock_bpy.context.scene)
    mock_metadata_helpers['count_poly'].assert_not_called()
    mock_metadata_helpers['count_edge'].assert_called_once_with(mock_bpy.context.scene)

    # Check cleanup calls (should still happen regardless of flags)
    assert mock_bpy.data.objects.remove.call_count == 1
    mesh_obj = next(iter(mock_bpy.data.objects.__iter__.side_effect()))
    mock_bpy.data.objects.remove.assert_called_once_with(mesh_obj, do_unlink=True)
    mock_bpy.data.materials.remove.assert_called_once()
    mock_bpy.data.textures.remove.assert_called_once()
    mock_bpy.data.images.remove.assert_called_once()

    # Check result dictionary (keys for disabled flags should have empty dicts)
    expected_result = {
        "vertex_num": {},
        "armature_count": {expected_obj_id: 1},
        "mesh_count": {expected_obj_id: 2},
        "poly_count": {},
        "material_count": {expected_obj_id: 1}, # Still collected as flag is True
        "edge_count": {expected_obj_id: 300},
        "animation_count": {} # Flag is False
    }
    assert result == expected_result

def test_task_unsupported_file_type(mock_bpy, mock_args_all_true, mock_os_path):
    """Tests task raises ValueError for unsupported file types."""
    object_files_chunk = ["/fake/path/to/document.txt"]

    with pytest.raises(ValueError, match="Unsupported file type: /fake/path/to/document.txt"):
        task(object_files_chunk)

    # Ensure no import or processing happened
    mock_bpy.ops.import_scene.gltf.assert_not_called()
    mock_bpy.ops.import_scene.fbx.assert_not_called()
    # No need to check helpers or cleanup as it should fail before that

def test_task_multiple_files(mock_bpy, mock_metadata_helpers, mock_args_all_true, mock_os_path):
    """Tests task processing multiple files in a chunk."""
    object_files_chunk = ["/path/model1.glb", "/path/model2.fbx"]
    expected_ids = ["model1", "model2"]

    # Reset mocks that accumulate calls across the loop within 'task'
    mock_bpy.ops.import_scene.gltf.reset_mock()
    mock_bpy.ops.import_scene.fbx.reset_mock()
    for helper_mock in mock_metadata_helpers.values():
        helper_mock.reset_mock()
    mock_bpy.data.objects.remove.reset_mock()
    mock_bpy.data.materials.remove.reset_mock()
    mock_bpy.data.textures.remove.reset_mock()
    mock_bpy.data.images.remove.reset_mock()


    result = task(object_files_chunk)

    # Check import calls (one gltf, one fbx)
    mock_bpy.ops.import_scene.gltf.assert_called_once_with(filepath=object_files_chunk[0])
    mock_bpy.ops.import_scene.fbx.assert_called_once_with(filepath=object_files_chunk[1])
    assert mock_bpy.ops.import_scene.gltf.call_count == 1
    assert mock_bpy.ops.import_scene.fbx.call_count == 1


    # Check metadata calls (should be called twice, once per file)
    assert mock_metadata_helpers['count_vertices'].call_count == 2
    assert mock_metadata_helpers['count_armatures'].call_count == 2
    assert mock_metadata_helpers['count_meshes'].call_count == 2
    assert mock_metadata_helpers['count_poly'].call_count == 2
    assert mock_metadata_helpers['count_edge'].call_count == 2
    # Check bpy.data lengths are implicitly checked via result

    # Check cleanup calls (should be called twice, once per file for each type)
    # One mesh object removed per file loop iteration
    assert mock_bpy.data.objects.remove.call_count == 2
    # One material removed per file loop iteration
    assert mock_bpy.data.materials.remove.call_count == 2
    # One texture removed per file loop iteration
    assert mock_bpy.data.textures.remove.call_count == 2
    # One image removed per file loop iteration
    assert mock_bpy.data.images.remove.call_count == 2

    # Check result dictionary contains data for both objects
    expected_result = {
        "vertex_num": {expected_ids[0]: 100, expected_ids[1]: 100},
        "armature_count": {expected_ids[0]: 1, expected_ids[1]: 1},
        "mesh_count": {expected_ids[0]: 2, expected_ids[1]: 2},
        "poly_count": {expected_ids[0]: 200, expected_ids[1]: 200},
        "material_count": {expected_ids[0]: 1, expected_ids[1]: 1},
        "edge_count": {expected_ids[0]: 300, expected_ids[1]: 300},
        "animation_count": {expected_ids[0]: 1, expected_ids[1]: 1}
    }
    assert result == expected_result

def test_split_list():
    """Tests the split_list utility function."""
    # Test with even division
    original_list = [1, 2, 3, 4, 5, 6]
    split_into_3 = split_list(original_list, 3)
    assert split_into_3 == [[1, 4], [2, 5], [3, 6]]
    
    # Test with odd division
    original_list = [1, 2, 3, 4, 5]
    split_into_2 = split_list(original_list, 2)
    assert split_into_2 == [[1, 3, 5], [2, 4]]
    
    # Test with more parts than items
    original_list = [1, 2]
    split_into_4 = split_list(original_list, 4)
    assert split_into_4 == [[1], [2], [], []]

@pytest.fixture
def mock_global_args(mocker):
    """Creates a mock for global args."""
    args = argparse.Namespace(
        save_path="/fake/save/path",
        objects_path="/fake/objects/path",
        cpu_count=4,
        run_vertex=True,
        run_armature=True,
        run_mesh=True,
        run_poly=True,
        run_material=True,
        run_edge=True,
        run_animation=True
    )
    mocker.patch('scripts.metadata_multiproc.args', args)
    return args

def test_save_to_file(mock_global_args, mocker):
    """Tests the save_to_file function."""
    # Create test data
    results = [
        {
            "vertex_num": {"obj1": 100, "obj2": 200},
            "armature_count": {"obj1": 1, "obj2": 0}
        },
        {
            "vertex_num": {"obj3": 300, "obj4": 400},
            "armature_count": {"obj3": 2, "obj4": 1}
        }
    ]
    
    # Mock os.makedirs and open
    mock_makedirs = mocker.patch('os.makedirs')
    mock_file = mock_open()
    mocker.patch('builtins.open', mock_file)
    
    # Mock os.path.join to handle path construction properly
    mocker.patch('os.path.join', lambda *args: '/'.join(args))
    
    # Test saving for vertex_num attribute
    save_to_file(results, "vertex_num")
    
    # Check if directory was created
    mock_makedirs.assert_called_once_with("/fake/save/path", exist_ok=True)
    
    # Check if file was opened with correct path
    mock_file.assert_called_with("/fake/save/path/vertex_num.txt", "a")
    
    # Check if data was written correctly
    file_handle = mock_file()
    # Check write calls - order doesn't matter as dictionaries are unordered
    assert len(file_handle.write.call_args_list) == 4
    assert call("obj1: 100\n") in file_handle.write.call_args_list
    assert call("obj2: 200\n") in file_handle.write.call_args_list
    assert call("obj3: 300\n") in file_handle.write.call_args_list
    assert call("obj4: 400\n") in file_handle.write.call_args_list

def test_main_missing_path(mock_global_args, mocker):
    """Tests main function with a non-existent path."""
    # Mock os.path.isdir to return False (path doesn't exist)
    mocker.patch('os.path.isdir', return_value=False)
    
    # Use pytest.raises to catch SystemExit instead of mocking sys.exit
    with pytest.raises(SystemExit) as excinfo:
        main()
    
    # Check exit code
    assert excinfo.value.code == 1

def test_main_success(mock_global_args, mocker):
    """Tests successful execution of the main function."""
    # Mock os.path.isdir to return True (path exists)
    mocker.patch('os.path.isdir', return_value=True)
    
    # Mock os.listdir to return json files
    mocker.patch('os.listdir', return_value=['objects1.json', 'objects2.json'])
    
    # Mock json.load to return file paths
    json_data = ['path/to/object1.glb', 'path/to/object2.fbx']
    mock_json = mocker.patch('json.load', return_value=json_data)
    
    # Mock file open
    mock_file = mock_open()
    mocker.patch('builtins.open', mock_file)
    
    # Mock multiprocessing.Pool
    mock_pool = MagicMock()
    mock_pool_context = MagicMock()
    mock_pool_context.__enter__.return_value = mock_pool
    mock_pool.starmap.return_value = [
        {
            "vertex_num": {"obj1": 100},
            "armature_count": {"obj1": 1}
        },
        {
            "vertex_num": {"obj2": 200},
            "armature_count": {"obj2": 0}
        }
    ]
    mocker.patch('multiprocessing.Pool', return_value=mock_pool_context)
    
    # Mock split_list
    mock_split_list = mocker.patch('scripts.metadata_multiproc.split_list')
    mock_split_list.return_value = [json_data[:1], json_data[1:]]
    
    # Call main
    main()
    
    # Check that pool was created twice (once for processing, once for saving)
    # And that results were processed correctly
    assert mock_pool.starmap.call_count == 2

@pytest.mark.parametrize("file_type,expected_function", [
    (".glb", "gltf"),
    (".fbx", "fbx")
])
def test_task_file_type_import(mock_bpy, mock_metadata_helpers, mock_args_all_true, mock_os_path, file_type, expected_function):
    """Tests that task correctly imports different file types."""
    object_files_chunk = [f"/path/model{file_type}"]
    
    task(object_files_chunk)
    
    if expected_function == "gltf":
        mock_bpy.ops.import_scene.gltf.assert_called_once_with(filepath=object_files_chunk[0])
        mock_bpy.ops.import_scene.fbx.assert_not_called()
    else:
        mock_bpy.ops.import_scene.fbx.assert_called_once_with(filepath=object_files_chunk[0])
        mock_bpy.ops.import_scene.gltf.assert_not_called()

def test_parse_args():
    """Tests argument parsing with mocked sys.argv."""
    # Test the case where -- is present
    with patch('sys.argv', ['blender', '-b', '-P', 'metadata_multiproc.py', '--', 
               '--save_path', '/test/save', '--objects_path', '/test/objects']):
        args = parse_args()
        assert args.save_path == '/test/save'
        assert args.objects_path == '/test/objects'
        assert args.cpu_count == multiprocessing.cpu_count()
        assert args.run_vertex is True
        assert args.run_mesh is True
    
    # Test the case where -- is not present (testing scenario)
    with patch('sys.argv', ['pytest', 'tests/test_metadata.py']):
        args = parse_args()
        assert args.save_path == './metadata/'  # Default
        assert args.objects_path == './objects/'  # Default
        assert args.cpu_count == multiprocessing.cpu_count()
        assert args.run_vertex is True
        assert args.run_mesh is True