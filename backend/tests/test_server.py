from fastapi.testclient import TestClient
from utils.setup_path import add_project_root
add_project_root()
from server.main import app
from server.routes import filter_repo
from server.routes import picker_repo
from server.routes import render_repo

from utils.logging_config import setup_custom_logger
import pytest
import os
import json
from unittest import mock
from models.filters_model import Filters, Filter
from models.render_model import Group, RenderSettings
import tempfile

logger = setup_custom_logger("test_server")

client = TestClient(app)

def setup_function():
    """Setup function that runs before each test"""
    pass

def teardown_function():
    """Teardown function that runs after each test"""
    pass

# --- Test Root Endpoint ---
def test_read_root():
    """Test the root endpoint of the API"""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"Hello": "World"}

# --- Test Filter Routes ---
def test_fetch_filters():
    """Test getting available filter options"""
    response = client.get("/filters/options")
    assert response.status_code == 200
    data = response.json()
    
    # Check that we received a filters list
    assert "filters" in data
    assert len(data["filters"]) > 0
    
    # Check filter structure
    for filter_item in data["filters"]:
        assert "type" in filter_item
        assert "minValue" in filter_item
        assert "maxValue" in filter_item

@mock.patch('server.routes.filter_repo.list_by')
def test_apply_filters_success(mock_list_by):
    """Test successfully applying filters"""
    # Mock the list_by function to return some test IDs
    mock_list_by.return_value = ["obj1", "obj2", "obj3"]
    
    # Create filter request
    filters = {
        "filters": [
            {"type": "vertex_num", "minValue": 100, "maxValue": 1000},
            {"type": "poly_count", "minValue": 50, "maxValue": 500}
        ]
    }
    
    response = client.post("/filters/apply", json=filters)
    assert response.status_code == 200
    data = response.json()
    
    # Check the response structure
    assert "object_ids" in data
    assert isinstance(data["object_ids"], list)
    assert len(data["object_ids"]) > 0

@mock.patch('server.routes.filter_repo.list_by')
def test_apply_filters_no_matches(mock_list_by):
    """Test applying filters with no matching results"""
    # Mock the list_by function to return empty list
    mock_list_by.return_value = []
    
    filters = {
        "filters": [
            {"type": "vertex_num", "minValue": 100000, "maxValue": 200000}
        ]
    }
    
    response = client.post("/filters/apply", json=filters)
    assert response.status_code == 404
    assert "No objects found" in response.json()["detail"]

def test_apply_filters_invalid():
    """Test applying invalid filters"""
    # Invalid filter structure
    invalid_filters = {
        "filters": [
            {"wrong_field": "vertex_num", "minValue": 100, "maxValue": 1000}
        ]
    }
    
    response = client.post("/filters/apply", json=invalid_filters)
    assert response.status_code == 422  # Validation error

# --- Test Picker Routes ---
@mock.patch('server.routes.picker_repo.fetch_glb')
@mock.patch('os.path.exists')
def test_host_object_success(mock_exists, mock_fetch_glb):
    """Test successfully retrieving an object file"""
    # Create a temporary file to return
    temp_file = tempfile.NamedTemporaryFile(delete=False)
    temp_file.write(b"fake glb data")
    temp_file.close()
    
    # Mock the necessary functions
    mock_fetch_glb.return_value = temp_file.name
    mock_exists.return_value = True
    
    try:
        response = client.get("/picker/updateobj?newObj=test_obj")
        assert response.status_code == 200
        assert response.headers["content-type"] == "model/gltf-binary"
        assert len(response.content) > 0
    finally:
        # Clean up
        os.unlink(temp_file.name)

@mock.patch('server.routes.picker_repo.fetch_glb')
def test_host_object_not_found(mock_fetch_glb):
    """Test retrieving a non-existent object file"""
    mock_fetch_glb.return_value = None
    
    response = client.get("/picker/updateobj?newObj=nonexistent_obj")
    assert response.status_code == 404

def test_host_object_missing_param():
    """Test host object endpoint without required parameter"""
    response = client.get("/picker/updateobj")
    assert response.status_code == 422

# --- Test Render Routes ---
@mock.patch('subprocess.run')
@mock.patch('os.path.exists')
def test_render_groups_success(mock_exists, mock_subprocess):
    """Test successfully rendering object groups"""
    # Create a temporary file to return
    temp_file = tempfile.NamedTemporaryFile(delete=False)
    temp_file.write(b"fake zip data")
    temp_file.close()
    
    # Mock the necessary functions
    mock_subprocess.return_value = mock.MagicMock(returncode=0)
    mock_exists.return_value = True
    
    # Create test data
    groups_data = [
        {
            "name": "test_group",
            "object_ids": ["obj1", "obj2"],
            "settings": {
                "num_images": 5,
                "resolution": 512,
                "engine": "CYCLES"
            }
        }
    ]
    
    try:
        # Replace the actual output file path with our temp file
        original_path = os.path.join
        def mocked_join(*args, **kwargs):
            path = original_path(*args, **kwargs)
            if path.endswith("render_output.zip"):
                return temp_file.name
            return path
        
        with mock.patch('os.path.join', mocked_join):
            response = client.post("/render/", json=groups_data)
            assert response.status_code == 201
            assert response.headers["content-type"] == "application/zip"
            assert len(response.content) > 0
    finally:
        # Clean up
        os.unlink(temp_file.name)

def test_render_groups_empty():
    """Test rendering with no groups"""
    response = client.post("/render/", json=[])
    assert response.status_code == 400
    assert "No groups provided" in response.json()["detail"]

@mock.patch('subprocess.run')
def test_render_groups_script_error(mock_subprocess):
    """Test rendering when script execution fails"""
    # Mock subprocess to return error
    mock_subprocess.return_value = mock.MagicMock(
        returncode=1, 
        stderr="Error in rendering script"
    )
    
    groups_data = [
        {
            "name": "test_group",
            "object_ids": ["obj1", "obj2"],
            "settings": {
                "num_images": 5
            }
        }
    ]
    
    response = client.post("/render/", json=groups_data)
    assert response.status_code == 500



