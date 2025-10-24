from pathlib import Path
import shutil


REPO_ROOT = Path(__file__).resolve().parents[2]


def cleanup_workspace():
    for path in [
        REPO_ROOT / "rootfs",
        REPO_ROOT / "staging",
        REPO_ROOT / "iso",
        REPO_ROOT / "DoomLinux.iso",
    ]:
        if path.is_file():
            path.unlink()
        elif path.is_dir():
            shutil.rmtree(path)


def before_scenario(context, scenario):
    cleanup_workspace()


def after_scenario(context, scenario):
    cleanup_workspace()
