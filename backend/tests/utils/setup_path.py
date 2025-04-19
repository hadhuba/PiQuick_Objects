import os
import sys

def add_project_root():
    current_file = os.path.abspath(__file__)
    project_root = os.path.abspath(os.path.join(os.path.dirname(current_file), '..', '..'))
    if project_root not in sys.path:
        sys.path.insert(0, project_root)
    return project_root