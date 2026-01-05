from pathlib import Path
import shutil


REPO_ROOT = Path(__file__).resolve().parents[2]


def cleanup_workspace() -> None:
    paths = [
        REPO_ROOT / "rootfs",
        REPO_ROOT / "staging",
        REPO_ROOT / "iso",
        REPO_ROOT / "DoomLinux.iso",
    ]

    for path in paths:
        if path.is_file():
            path.unlink()
        elif path.is_dir():
            shutil.rmtree(path)


def before_scenario(context, scenario) -> None:
    cleanup_workspace()


def after_scenario(context, scenario) -> None:
    cleanup_workspace()
