<div align="center">
<h1>Dev Container</h1>
<h3><a href="https://github.com/simonhyll/devcontainer/wiki">Wiki</a></h3>
</div>

## Commands

```bash
# Launch the Android emulator
emulator -avd dev -no-audio -no-snapshot-load -gpu swiftshader_indirect -qemu -m 2048 -netdev user,id=mynet0,hostfwd=tcp::5555-:5555
```

```bash
# Run the Tauri CLI (with fixes)
cargo tauri dev
```

## Getting started

Before you can get started using dev containers you first need to set up your environment. Make sure you first read the official guide on the topic.

**Read this**: <https://code.visualstudio.com/docs/devcontainers/containers>

### Alternative 1: Submodule

This approach offers easy updates from upstream since you can just pull the latest version from Github.

```bash
# Add the container as a submodule
git submodule add https://github.com/simonhyll/devcontainer .devcontainer
```

Then in order to update the module you can simply do the following:

```bash
# Update the submodule
cd .devcontainer
git checkout v2
git pull
```

Git submodules are pinned to a specific commit, which is why you're going to have to checkout the appropriate branch each time. Submodules aren't always the easiest to work with, but once you get the hang of them the issues, in my opinon, are worth the added benefits.

### Alternative 2: Clone

With this approach you clone the project and then remove the `.git` folder in order to effectively copy the folder from Github. This has the benefit of you not having to learn how submodules work and you won't have another dependency in your project, but it doesn't offer easy updates.

```bash
# Clone the container
git clone https://github.com/simonhyll/devcontainer .devcontainer
# Remove its git repository
rm -rf .devcontainer/.git
```

## Important notes

### Tauri

#### Use `cargo tauri` instead of e.g. `pnpm tauri`

I still haven't found the cause of it but for me `pnpm tauri` doesn't work properly. So I've packaged a version of the CLI that does work for me, and it should work for you too.

### Android

#### Accessing devices on your host is a WIP

- [X] Get ADB to connect to the host: Using port forwarding I've already figured out how to connect your running ADB instance on the host to the one running in the container. Thanks to this you're able to connect to any devices you can find on your host as per usual, both emulators and physical devices
- [ ] Get the frontend running in the container to the device: Currently I have only figured out how to get the app to install. Exposing the frontend to the device however is another story and I haven't quite figured that one out yet
- [ ] Forward a USB connected device straight to the container: Since running an ADB server on the host requires you to set up your host, it'd be even better if you can just access your physical device straight in the container, and to do that the best solution would be to get your USB device to be forwarded, but I haven't figured that one out yet

#### The in-container emulator has poor performance

The solution to this is to run the emulator on your host, or even connecting to a physical device. This however is a work in progress.

## Performance

### Windows

#### Use WSL

If you don't use WSL you will have a massive performance drop related to disk I/O which is caused by differing filesystems. Make sure your project resides in e.g. `~/projects/my-app`

#### Allocate sufficient RAM (recommend >16GB)

If you don't have enoug RAM accessible to WSL then VSCode has a nasty habit of crashing. I'm not sure exactly where the line is drawn, but I'm using 16GB.

#### I've added the Mold linker to the system

This will speed up desktop builds (not Android builds). It's something to be aware of because while it can drastically enhance the speed of which your project is built it's not necessarily suitable for production builds. You have been warned.
