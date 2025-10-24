from pathlib import Path
import shutil
import subprocess

from behave import given, when, then


REPO_ROOT = Path(__file__).resolve().parents[3]
ARTIFACTS = [
    REPO_ROOT / "rootfs",
    REPO_ROOT / "staging",
    REPO_ROOT / "iso",
    REPO_ROOT / "DoomLinux.iso",
]


def cleanup_workspace() -> None:
    for path in ARTIFACTS:
        if path.is_file():
            path.unlink()
        elif path.is_dir():
            shutil.rmtree(path)


@given("a clean workspace")
def step_clean_workspace(context):
    cleanup_workspace()


@when("I run DoomLinux in smoke mode")
def step_run_smoke_build(context):
    subprocess.run(
        ["bash", "-lc", "DOOMLINUX_TEST_MODE=smoke ./DoomLinux.sh"],
        cwd=REPO_ROOT,
        check=True,
    )


@then("the ISO artifact exists")
def step_iso_exists(context):
    assert (REPO_ROOT / "DoomLinux.iso").is_file()


@then("the TrenchBroom instructions are available")
def step_trenchbroom_exists(context):
    instructions = REPO_ROOT / "rootfs" / "root" / "TRENCHBROOM-INSTALL.txt"
    assert instructions.is_file()
    content = instructions.read_text()
    assert "TrenchBroom" in content


@then("the root filesystem directories are scaffolded")
def step_rootfs_dirs(context):
    required = ["bin", "dev", "mnt", "proc", "sys", "tmp", "root", "etc"]
    for name in required:
        path = REPO_ROOT / "rootfs" / name
        assert path.is_dir(), f"Expected directory missing: {path}"


@then("the GRUB configuration references DoomLinux")
def step_grub_config(context):
    grub_cfg = REPO_ROOT / "iso" / "boot" / "grub" / "grub.cfg"
    assert grub_cfg.is_file()
    assert 'menuentry "DoomLinux"' in grub_cfg.read_text()
