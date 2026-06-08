# AGL CI-Management

This project manages the Jenkins Job Builder (JJB) configuration, Packer templates for build agents, and associated utility scripts for the Automotive Grade Linux (AGL) Continuous Integration (CI) infrastructure.

## Project Structure

- `jjb/`: Jenkins Job Builder (JJB) YAML configurations. Defines CI pipeline jobs, daily tasks, and release workflows across multiple AGL releases (quillback, ricefish, salmon, trout, unagi, vimba).
- `packer/`: Packer templates and scripts for building and provisioning CI agent images (e.g., Ubuntu).
- `jenkins-scripts/`: Initialization and configuration scripts for Jenkins controller and agent nodes.
- `scripts/`: General utility scripts for the CI environment.

## Key Workflows

### JJB Configuration
The `jjb/` directory contains job definitions. 
- Global defaults and macros are in `jjb/global-defaults.yaml` and `jjb/global-macros.yaml`.
- Jobs are categorized by function (verify, release, snapshot, daily tasks).
- Note: `h3ulcb-nogfx` is currently disabled in `ci-AGL-verify` due to a broken BSP.
- Note: `r8a7795-agl-refhw` is currently disabled in `ci-AGL-verify` until the h3ulcb-nogfx machine is enabled.

### Packer Build
CI agents are built using Packer.
- Entry points: `packer/start_local_packer.sh` and `packer/local_packer_run.sh`.
- Provisioning logic resides in `packer/provision/`.

### Jenkins Initialization
- Jenkins node management uses `jenkins-scripts/` for tasks like user creation and basic environment settings.

## Development & Maintenance

- Always check `jjb/global-defaults.yaml` for shared settings before modifying individual jobs.
- Packer templates should be tested locally using the scripts in `packer/` before upstreaming changes.
- Ensure new JJB definitions adhere to the structure established in existing `jjb/` subdirectories.
