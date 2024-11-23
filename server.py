from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

GLB_FILES = [
    {"id": "1", "name": "Model1", "path": "/models/model1.glb"},
    {"id": "2", "name": "Model2", "path": "/models/model2.glb"},
    {"id": "3", "name": "Model3", "path": "/models/model3.glb"},
]

filter_aspects = {
    "armature": (None, None),
    "edge": (None, None),
    "mesh": (None, None),
    "poly": (None, None),
    "vertex": (None, None),
}

@app.route('/api/filter', methods=['POST'])
def filter_models():
    data = request.json
    search_term = data.get("search_term", "").lower()
    
    filtered = [f for f in GLB_FILES if search_term in f["name"].lower()]
    
    return jsonify({"filtered_files": filtered})

@app.route('/api/glb/<file_id>', methods=['GET'])
def get_glb_file(file_id):
    glb_file = next((f for f in GLB_FILES if f["id"] == file_id), None)
    if glb_file:
        return jsonify({"file": glb_file})
    else:
        return jsonify({"error": "File not found"}), 404

if __name__ == '__main__':
    app.run(debug=True)