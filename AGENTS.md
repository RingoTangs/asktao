# Repository Guidelines

## Project Structure & Module Organization

This repository contains the AskTao (问道) game server runtime and Docker base-image tooling.

- `1.4_server/` contains runnable server scripts and runtime assets.
- `1.4_server/{aaa,ccs,dba,gs}/` contain service-specific `.ini` files and `pack_data/*.pak` bundles.
- `1.4_server/magic_Linux32` is a 32-bit Linux executable used by the `run*` launch scripts.
- `dockerbase/centos5.8/` and `dockerbase/centos7.9/` contain build scripts and image export/load/push notes.
- `.vscode/settings.json` sets UTF-8 defaults and GBK handling for game `.ini` files.

There is no separate source tree or test directory at present; treat packaged runtime files as deployment artifacts.

## Build, Test, and Development Commands

- `sudo ./dockerbase/centos7.9/build-centos79.sh` builds and verifies `ringotangs/at-centos79:0.1`.
- `sudo ./dockerbase/centos5.8/build-centos58-minimal.sh` builds and verifies `ringotangs/at-centos58:0.1`.
- `docker run --rm -it ringotangs/at-centos79:0.1 bash` opens a shell in the CentOS 7.9 image.
- `docker save ringotangs/at-centos79:0.1 -o at-centos79-0.1.tar` exports an image for transfer.

The build scripts require Docker and root privileges because they create build directories under `/root` and, for CentOS 5.8, mount chroot filesystems.

## Coding Style & Naming Conventions

Shell scripts should use POSIX `sh` for server launchers and `bash` for Docker build automation, matching existing files. Keep indentation at two spaces in shell blocks. Prefer `set -euo pipefail` for new Bash scripts when practical.

Preserve existing service names: `aaa`, `ccs`, `dba`, and `gs`. Name launch scripts with the `run<service>` pattern, for example `rungs`. All `.ini` configuration files are encoded as GBK; edit them with GBK-compatible tooling to avoid corrupting Chinese text.

## Testing Guidelines

No automated unit test framework is configured. Validate Docker changes by running the relevant build script and checking its embedded verification output. For server runtime changes, at minimum confirm launch scripts remain executable and command paths still match the service directory layout under `1.4_server/`.

## Commit & Pull Request Guidelines

Recent commits use short imperative messages, sometimes with Conventional Commit prefixes, such as `fix: update file associations...` or `add build script...`. Keep commits focused and mention the affected area.

Pull requests should include a concise summary, changed paths, validation commands run, and any operational impact. Include screenshots or terminal excerpts only when they clarify Docker builds, image tags, or server startup behavior.

## Security & Configuration Tips

Do not commit secrets, private registry credentials, or environment-specific IP changes without review. Document any image tag changes in the matching `dockerbase/*/README.md`.
