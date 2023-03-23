<div align="center">

# Dev Container
</div>

## Getting started

```bash
# Run the emulator
emulator -avd dev -no-audio -no-snapshot-load -gpu swiftshader_indirect -qemu -m 2048 -netdev user,id=mynet0,hostfwd=tcp::5555-:5555
```

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
git checkout v1
git pull
```

Git submodules are pinned to a specific commit, which is why you're going to have to checkout the appropriate branch each time. Submodules aren't always the easiest to work with, but once you get the hang of them the issues, in my opinon, are worth the added benefits.

### Alternative 2: Clone

With this approach you clone the project and then remove the `.git` folder in order to effectively copy the folder from Github. This has the benefit if you not having to learn how submodules work and you won't have another dependency in your project, but it doesn't offer easy updates.

```bash
# Clone the container
git clone https://github.com/simonhyll/devcontainer .devcontainer
# Remove its git repository
rm -rf .devcontainer/.git
```

## Commands

```bash
# Launch the Android emulator
emulator -avd dev -no-audio -no-snapshot-load -gpu swiftshader_indirect -qemu -m 2048 -netdev user,id=mynet0,hostfwd=tcp::5555-:5555
```

## Performance

### Windows

#### Use WSL

If you don't use WSL you will have a massive performance drop related to disk I/O which is caused by differing filesystems. Make sure your project resides in e.g. `~/projects/my-app`

#### Allocate sufficient RAM (recommend >16GB)

If you don't have enoug RAM accessible to WSL then VSCode has a nasty habit of crashing. I'm not sure exactly where the line is drawn, but I'm using 16GB.

#### I've added the Mold linker to the system

This will speed up desktop builds (not Android builds). It's something to be aware of because while it can drastically enhance the speed of which your project is built it's not necessarily suitable for production builds. You have been warned.
