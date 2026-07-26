import sys, os

# make backend/ importable (config.py, models.py etc. live there)
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app import create_app

app = create_app('production')