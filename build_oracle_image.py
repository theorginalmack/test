import argparse
import gzip
import html
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tarfile
import urllib.parse
import urllib.request

DISK_IMAGE_PATTERN = re.compile(
    r'<dt>\s*Disk Image\s*</dt>\s*<dd><a href="([^"]+oracle-arm64\.qcow2)"',
    re.IGNORECASE | re.DOTALL,
)

DEFAULT_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/136.0.0.0 Safari/537.36"
    ),
    "Accept": "*/*",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Build an Oracle BYOI Talos image archive from the final Talos Image "
            "Factory page URL."
        )
    )
    parser.add_argument(
        "factory_page_url",
        help=(
            "Final Talos Image Factory page URL, for example "
            "https://factory.talos.dev/?arch=arm64&bootloader=auto..."
        ),
    )
    parser.add_argument(
        "--output-dir",
        default="build/oracle-image",
        help="Directory where downloaded and generated files should be stored.",
    )
    parser.add_argument(
        "--keep-intermediates",
        action="store_true",
        help="Keep downloaded and generated intermediate files after packaging the .oci archive.",
    )
    return parser.parse_args()


def require_binary(name: str) -> None:
    if shutil.which(name) is None:
        raise SystemExit(f"Required command not found in PATH: {name}")


def fetch_text(url: str) -> str:
    request = urllib.request.Request(url, headers=DEFAULT_HEADERS)
    with urllib.request.urlopen(request) as response:
        charset = response.headers.get_content_charset() or "utf-8"
        return response.read().decode(charset)


def extract_qcow2_url(page_html: str) -> str:
    match = DISK_IMAGE_PATTERN.search(page_html)

    if not match:
        raise SystemExit(
            "Unable to find the Oracle disk image URL in the Talos Image Factory page."
        )

    return html.unescape(match.group(1))


def qcow2_to_raw_gz_url(qcow2_url: str) -> str:
    if not qcow2_url.endswith(".qcow2"):
        raise SystemExit(f"Expected a .qcow2 URL, got: {qcow2_url}")

    return qcow2_url.removesuffix(".qcow2") + ".raw.gz"


def parse_version(url: str) -> str:
    parts = pathlib.PurePosixPath(urllib.parse.urlparse(url).path).parts

    for part in parts:
        if part.startswith("v") and len(part) > 1 and part[1].isdigit():
            return part[1:]

    raise SystemExit(
        "Unable to determine Talos version from URL. Expected a path segment like "
        "`/v1.12.6/`."
    )


def download(url: str, destination: pathlib.Path) -> None:
    print(f"Downloading {url}")
    request = urllib.request.Request(url, headers=DEFAULT_HEADERS)
    with urllib.request.urlopen(request) as response, destination.open("wb") as output:
        shutil.copyfileobj(response, output)


def write_metadata(destination: pathlib.Path, version: str) -> None:
    metadata = {
        "version": 2,
        "externalLaunchOptions": {
            "firmware": "UEFI_64",
            "networkType": "PARAVIRTUALIZED",
            "bootVolumeType": "PARAVIRTUALIZED",
            "remoteDataVolumeType": "PARAVIRTUALIZED",
            "localDataVolumeType": "PARAVIRTUALIZED",
            "launchOptionsSource": "PARAVIRTUALIZED",
            "pvAttachmentVersion": 2,
            "pvEncryptionInTransitEnabled": True,
            "consistentVolumeNamingEnabled": True,
        },
        "imageCapabilityData": None,
        "imageCapsFormatVersion": None,
        "operatingSystem": "Talos",
        "operatingSystemVersion": version,
        "additionalMetadata": {
            "shapeCompatibilities": [
                {
                    "internalShapeName": "VM.Standard.A1.Flex",
                    "ocpuConstraints": None,
                    "memoryConstraints": None,
                }
            ]
        },
    }

    destination.write_text(json.dumps(metadata, indent=2) + "\n")


def decompress(raw_gz_path: pathlib.Path) -> pathlib.Path:
    if raw_gz_path.suffixes[-2:] != [".raw", ".gz"]:
        raise SystemExit("Expected a file ending in `.raw.gz`.")

    raw_path = raw_gz_path.with_suffix("")
    with gzip.open(raw_gz_path, "rb") as compressed, raw_path.open("wb") as output:
        shutil.copyfileobj(compressed, output)

    return raw_path


def convert_to_qcow2(raw_path: pathlib.Path, qcow2_path: pathlib.Path) -> None:
    require_binary("qemu-img")
    subprocess.run(
        [
            "qemu-img",
            "convert",
            "-f",
            "raw",
            "-O",
            "qcow2",
            str(raw_path),
            str(qcow2_path),
        ],
        check=True,
    )


def create_archive(
    archive_path: pathlib.Path,
    qcow2_path: pathlib.Path,
    metadata_path: pathlib.Path,
) -> None:
    with tarfile.open(archive_path, "w:gz") as tar:
        tar.add(qcow2_path, arcname=qcow2_path.name)
        tar.add(metadata_path, arcname=metadata_path.name)


def main() -> int:
    args = parse_args()
    output_dir = pathlib.Path(args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    page_html = fetch_text(args.factory_page_url)
    qcow2_url = extract_qcow2_url(page_html)
    raw_gz_url = qcow2_to_raw_gz_url(qcow2_url)
    version = parse_version(raw_gz_url)

    raw_gz_name = pathlib.Path(urllib.parse.urlparse(raw_gz_url).path).name
    raw_gz_path = output_dir / raw_gz_name
    metadata_path = output_dir / "image_metadata.json"
    qcow2_path = output_dir / "oracle-arm64.qcow2"
    oci_archive_path = output_dir / "oracle-arm64.oci"

    print(f"Found disk image URL: {qcow2_url}")
    print(f"Using raw image URL: {raw_gz_url}")

    write_metadata(metadata_path, version)
    download(raw_gz_url, raw_gz_path)
    raw_path = decompress(raw_gz_path)
    convert_to_qcow2(raw_path, qcow2_path)
    create_archive(oci_archive_path, qcow2_path, metadata_path)

    if not args.keep_intermediates:
        for path in (raw_gz_path, raw_path, qcow2_path, metadata_path):
            if path.exists():
                path.unlink()

    print("")
    print("Created files:")
    print(f"- Oracle archive: {oci_archive_path}")
    if args.keep_intermediates:
        print(f"- Metadata: {metadata_path}")
        print(f"- Raw image archive: {raw_gz_path}")
        print(f"- Raw image: {raw_path}")
        print(f"- QCOW2 image: {qcow2_path}")
    else:
        print("- Intermediate files were removed automatically.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
