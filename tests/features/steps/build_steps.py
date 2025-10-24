from pathlib import Path
import json
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


@then("the install script exists and is executable")
def step_install_script(context):
    script = REPO_ROOT / "scripts" / "install-deps.sh"
    assert script.is_file(), "install-deps.sh not found"
    assert script.stat().st_mode & 0o111, "install-deps.sh is not executable"


@then("the devcontainer configuration is available")
def step_devcontainer(context):
    devcontainer_dir = REPO_ROOT / ".devcontainer"
    config = devcontainer_dir / "devcontainer.json"
    dockerfile = devcontainer_dir / "Dockerfile"
    assert config.is_file(), "devcontainer.json missing"
    assert dockerfile.is_file(), "Devcontainer Dockerfile missing"
    data = json.loads(config.read_text())
    assert data.get("dockerFile") == "Dockerfile", "devcontainer should reference Dockerfile"
    assert "postCreateCommand" in data, "devcontainer postCreateCommand missing"


@then("the VSCode launch configuration is available")
def step_vscode_launch(context):
    launch = REPO_ROOT / ".vscode" / "launch.json"
    tasks = REPO_ROOT / ".vscode" / "tasks.json"
    assert launch.is_file(), "launch.json missing"
    assert tasks.is_file(), "tasks.json missing"
    launch_data = json.loads(launch.read_text())
    configs = launch_data.get("configurations", [])
    assert configs, "launch.json configurations missing"
    assert configs[0].get("preLaunchTask") == "Build ISO", "preLaunchTask should be Build ISO"


@then("the README references miso usage")
def step_readme_miso(context):
    readme = REPO_ROOT / "README.md"
    assert "miso" in readme.read_text().lower(), "README should mention miso"


@then("the smoke summary log is emoji rich")
def step_smoke_summary(context):
    summary = REPO_ROOT / "tests" / "artifacts" / "smoke-summary.txt"
    assert summary.is_file(), "Smoke summary log missing"
    content = summary.read_text()
    assert "✅" in content and "✨" in content, "Smoke summary should contain celebratory emojis"


@when("I convert the log summaries")
def step_convert_logs(context):
    subprocess.run([
        "bash",
        "-lc",
        "./scripts/log-convert.sh"
    ], cwd=REPO_ROOT, check=True)


@then("CSV and LaTeX summaries exist")
def step_csv_tex_outputs(context):
    base = REPO_ROOT / "tests" / "artifacts"
    smoke_csv = base / "smoke-summary.csv"
    smoke_tex = base / "smoke-summary.tex"
    assert smoke_csv.is_file(), "smoke-summary.csv missing"
    assert smoke_tex.is_file(), "smoke-summary.tex missing"


@then("the log lint passes")
def step_log_lint(context):
    subprocess.run([
        "bash",
        "-lc",
        "./scripts/log-lint.sh"
    ], cwd=REPO_ROOT, check=True)
