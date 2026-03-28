import json
import os
import subprocess

cmd = ["terraform", "state", "pull"]
output = subprocess.run(cmd, check=True, stdout=subprocess.PIPE).stdout
state = json.loads(output)

resources = state.pop("resources")

machine_configuration = {"controlplane": "", "worker": ""}

TALOSCONFIG = ""

for resource in resources:
    if resource["type"] == "talos_client_configuration":
        TALOSCONFIG = resource["instances"][0]["attributes"]["talos_config"]
    elif resource["type"] == "talos_machine_configuration":
        machine_configuration[resource["name"]] = resource["instances"][0][
            "attributes"
        ]["machine_configuration"]

dir_path = os.path.expanduser("~/.talos/")
config_file_path = os.path.join(dir_path, "config")

os.makedirs(dir_path, exist_ok=True)

with open(config_file_path, "w") as f:
    f.write(TALOSCONFIG)

lines = TALOSCONFIG.splitlines()
FIRST_ENDPOINT = None

for i, line in enumerate(lines):
    if "endpoints:" in line:
        FIRST_ENDPOINT = lines[i + 1].strip().lstrip("- ")
        break

os.system(f"talosctl kubeconfig --force -n {FIRST_ENDPOINT}")

with open("talosconfig", "w") as f:
    f.write(TALOSCONFIG)

with open("controlplane.yaml", "w") as f:
    f.write(machine_configuration["controlplane"])

with open("worker.yaml", "w") as f:
    f.write(machine_configuration["worker"])
