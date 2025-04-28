"""
This test suite verifies the functionality of the FastAPI server components, which provide
API endpoints for filtering, rendering, and retrieving 3D objects. The tests cover:

1. API endpoint validation - Ensuring proper responses from all endpoints
2. Object filtering - Testing the filter logic that selects objects based on metadata criteria
3. File retrieval - Verifying object files can be correctly fetched from the database
4. Rendering process - Testing the server-side rendering pipeline with proper error handling
5. Error conditions - Validating error handling for edge cases and invalid inputs

The server acts as the central integration point for the 3D object pipeline, connecting the
filtering, object retrieval, and rendering components through a unified REST API interface.
"""
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from fastapi.testclient import TestClient
from server.main import app
from server.routes import filter_repo
from server.routes import picker_repo
from server.routes import render_repo

from utils.logging_config import setup_custom_logger
import pytest
import os
import json
from unittest import mock
from unittest.mock import MagicMock
from models.filters_model import Filters, Filter
from models.render_model import Group, RenderSettings
import tempfile

logger = setup_custom_logger("test_server")

client = TestClient(app)

# --- Test Root Endpoint ---
def test_read_root():
    """STC1: Test the root endpoint of the API"""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"PiQuick": "Objects"}

# --- Test Filter Routes ---
def test_fetch_filters():
    """STC2: Test getting available filter options"""
    response = client.get("/filters/options")
    assert response.status_code == 200
    data = response.json()
    
    assert "filters" in data
    assert len(data["filters"]) > 0
    
    for filter_item in data["filters"]:
        assert "type" in filter_item
        assert "minValue" in filter_item
        assert "maxValue" in filter_item

@mock.patch('server.routes.filter_repo.list_by')
def test_apply_filters_success(mock_list_by):
    """STC3: Test successfully applying filters"""
    mock_list_by.return_value = ["obj1", "obj2", "obj3"]
    
    filters = {
        "filters": [
            {"type": "vertex_num", "minValue": 100, "maxValue": 1000},
            {"type": "poly_count", "minValue": 50, "maxValue": 500}
        ]
    }
    
    response = client.post("/filters/apply", json=filters)
    assert response.status_code == 200
    data = response.json()
    
    assert "object_ids" in data
    assert isinstance(data["object_ids"], list)
    assert len(data["object_ids"]) > 0

@mock.patch('server.routes.filter_repo.list_by')
def test_apply_filters_no_matches(mock_list_by):
    """STC4: Test applying filters with no matching results"""
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
    """STC5: Test applying invalid filters"""
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
    """STC6: Test successfully retrieving an object file"""
    temp_file = tempfile.NamedTemporaryFile(delete=False)
    temp_file.write(b"fake glb data")
    temp_file.close()
    
    mock_fetch_glb.return_value = temp_file.name
    mock_exists.return_value = True
    
    try:
        response = client.get("/picker/updateobj?newObj=test_obj")
        assert response.status_code == 200
        assert response.headers["content-type"] == "model/gltf-binary"
        assert len(response.content) > 0
    finally:
        os.unlink(temp_file.name)

@mock.patch('server.routes.picker_repo.fetch_glb')
def test_host_object_not_found(mock_fetch_glb):
    """STC7: Test retrieving a non-existent object file"""
    mock_fetch_glb.return_value = None
    
    response = client.get("/picker/updateobj?newObj=nonexistent_obj")
    assert response.status_code == 404

def test_host_object_missing_param():
    """STC8: Test host object endpoint without required parameter"""
    response = client.get("/picker/updateobj")
    assert response.status_code == 422

# --- Test Render Routes ---
@mock.patch('subprocess.run')
@mock.patch('tempfile.mkdtemp')
@mock.patch('tempfile.NamedTemporaryFile')
def test_render_groups_success(mock_temp_file, mock_temp_dir, mock_subprocess):
    """STC9: Test successfully rendering object groups using temporary files"""
    mock_temp_dir.return_value = "/tmp/mock_render_temp_dir"
    
    output_path = "/tmp/mock_output.zip"
    with open(output_path, "wb") as f:
        f.write(b"fake zip data")
    
    try:
        mock_named_temp = MagicMock()
        mock_named_temp.name = output_path
        mock_temp_file.return_value = mock_named_temp
        
        mock_subprocess.return_value = MagicMock(returncode=0)
        
        groups_data = [
            {
                "name": "test_group",
                "object_ids": ["obj1", "obj2"],
                "settings": {
                    "num_images": 5,
                    "resolution": 512,
                    "engine": "CYCLES",
                    "mode_multi": True,
                    "mode_front_view": False,
                    "mode_four_view": False
                }
            }
        ]
        
        with mock.patch('builtins.open', mock.mock_open(read_data=b"fake zip data")), \
             mock.patch('json.dump'), \
             mock.patch('shutil.rmtree'), \
             mock.patch('os.path.exists', return_value=True):
            
            response = client.post("/render/", json=groups_data)
            
            assert response.status_code == 201
            assert response.headers["content-type"] == "application/zip"
            
            mock_temp_dir.assert_called_once()
            mock_temp_file.assert_called_once()
            
            mock_subprocess.assert_called_once()
            call_args = mock_subprocess.call_args[0][0]
            assert "--groups_json" in call_args
            assert "--output_dir" in call_args
            assert "/tmp/mock_render_temp_dir" in call_args
            assert "--output_file" in call_args
            assert output_path in call_args
    
    finally:
        if os.path.exists(output_path) and output_path.startswith("/tmp/"):
            os.unlink(output_path)

def test_render_groups_empty():
    """STC10: Test rendering with no groups"""
    response = client.post("/render/", json=[])
    assert response.status_code == 400
    assert "No groups provided" in response.json()["detail"]

@mock.patch('subprocess.run')
def test_render_groups_script_error(mock_subprocess):
    """STC11: Test rendering when script execution fails"""
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



