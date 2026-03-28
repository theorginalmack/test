# Oracle Cloud Talos Example

## Prerequisites

- [7-Zip](https://www.7-zip.org/download.html)
- Access to a Terminal/Command Line: You need access to a command-line interface (CLI) on your local machine to execute various commands.
- Basic Understanding of Cloud and Infrastructure as Code: Familiarity with cloud computing concepts and Terraform is essential to follow along with the tutorial.
- [Github Desktop](https://github.com/apps/desktop)
- GitHub Account: Create or have access to a GitHub account where you can create repositories and generate personal access tokens.
- [Kubectl](https://kubernetes.io/docs/tasks/tools)
- [Kubeseal](https://github.com/bitnami-labs/sealed-secrets)
- [Python](https://www.python.org/downloads)
- [Talos ARM64 Image](https://factory.talos.dev/?arch=arm64&cmdline-set=true&extensions=-&extensions=siderolabs%2Fcrun&extensions=siderolabs%2Ffuse3&extensions=siderolabs%2Fiscsi-tools&extensions=siderolabs%2Fnfsd&platform=oracle&target=cloud&version=1.11.1)
- [Talos CLI](https://www.talos.dev/latest/talos-guides/install/talosctl)
- [Terraform CLI](https://developer.hashicorp.com/terraform/install)

## Optional Prerequisites

- [Lens](https://k8slens.dev/download)

## Steps

1. [Follow this tutorial until the "Convert your trial to PAYG" step](https://web.archive.org/web/20231021060449/https://mattscott.cloud/kubernetes-on-oracle-cloud-for-free/)
2. Use this repository as a template repository to make your own
3. Clone the repository
4. Create a bucket on Oracle and note the name
5. [Follow this tutorial under "Upload image" to generate Oracle image](https://www.talos.dev/v1.11/talos-guides/install/cloud-platforms/oracle/#upload-image): you can use this as the image -> [here](https://factory.talos.dev/?arch=arm64&cmdline-set=true&extensions=-&extensions=siderolabs%2Fcrun&extensions=siderolabs%2Ffuse3&extensions=siderolabs%2Fiscsi-tools&extensions=siderolabs%2Fnfsd&platform=oracle&target=cloud&version=1.11.1)
6. Upload the created image (oracle-arm64.oci) to the bucket
7. [Create an Oracle api key](https://cloud.oracle.com/identity/domains/my-profile/api-keys)
8. Click "Add API Key"
9. Click "Add" after downloading the private key
10. For this newly generated api key, click on the 3 dots to the right of it and click "View configuration file"
11. Copy and note all the information there
12. [Sign up for Terraform cloud](https://app.terraform.io)
13. Create a VCS project on terraform cloud and note the name
14. Create a workspace on terraform cloud under that project and note the name
15. [Create a classic Github personal access token with repo permissions using this link and note the value](https://github.com/settings/tokens/new)
16. [Create a new repo titled fleet-infra using this link](https://github.com/new?template_name=oracle-talos-flux-example&template_owner=kanya-approve&name=fleet-infra)...this is only for Flux
17. Under the created workspace variables, create a new workspace terraform variable called cluster_domain_endpoint and make the value your domain (example.com) if you have one otherwise leave it empty
18. Under the created workspace variables, create a new workspace terraform variable called fingerprint and make the value after fingerprint= from what you copied on step #11
19. Under the created workspace variables, create a new workspace terraform variable called region and make the value after region= from what you copied on step #11
20. Under the created workspace variables, create a new workspace terraform variable called tenancy and make the value after tenancy= from what you copied on step #11
21. Under the created workspace variables, create a new workspace terraform variable called user_ocid and make the value after user= from what you copied on step #11
22. Under the created workspace variables, create a new workspace terraform variable called talos_images_bucket and make the value what you noted on step #4
23. Under the created workspace variables, create a new SENSITIVE workspace terraform variable called private_key and make the value the base64 encoded value of contents of the downloaded private key from step #9
24. Under the created workspace variables, create a new SENSITIVE workspace terraform variable called personal_ip and make the value your personal ipv4 address
25. Under the created workspace variables, create a new SENSITIVE workspace ENVIRONMENT variable called GITHUB_TOKEN and make the value what you noted on step #15
26. Start a new terraform cloud run and your new Oracle cloud talos cluster will be live
27. In your Terraform repo folder, create a backend.tf file with the contents below

    ```hcl
    terraform {
        cloud {
            organization = "REPLACE_WITH_YOUR_ORGANIZATION_NAME"

            workspaces {
                name = "REPLACE_WITH_YOUR_WORKSPACE_NAME"
                project = "REPLACE_WITH_YOUR_PROJECT_NAME"
            }
        }
    }
    ```

28. In your repo folder, run ```python get_talos_files.py```
