import json
import subprocess
from pathlib import Path

terraform_output = subprocess.run(
    ["terraform", "output", "-json"],
    check=True,
    stdout=subprocess.PIPE,
).stdout

outputs = json.loads(terraform_output)

machine_configuration = {
    "controlplane": outputs["controlplane_machine_configuration"]["value"],
    "worker": outputs["worker_machine_configuration"]["value"],
}
talosconfig = outputs["talosconfig"]["value"]

dir_path = Path.home() / ".talos"
config_file_path = dir_path / "config"

dir_path.mkdir(parents=True, exist_ok=True)
config_file_path.write_text(talosconfig)

lines = talosconfig.splitlines()
first_endpoint = None

for i, line in enumerate(lines):
    if "endpoints:" in line:
        first_endpoint = lines[i + 1].strip().lstrip("- ")
        break

if first_endpoint is None:
    raise RuntimeError("Failed to find the first Talos endpoint in talosconfig")

subprocess.run(
    [
        "talosctl",
        "kubeconfig",
        "--force",
        "-n",
        first_endpoint,
    ],
    check=True,
)

Path("talosconfig").write_text(talosconfig)

with open("controlplane.yaml", "w") as f:
    f.write(machine_configuration["controlplane"])

with open("worker.yaml", "w") as f:
    f.write(machine_configuration["worker"])
