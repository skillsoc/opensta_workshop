# OpenSTA Workshop — Installation Guide

> **Audience:** Beginners with little to no prior experience in Static Timing Analysis.
> **Last updated:** April 2026

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Linux Installation (Ubuntu / Debian)](#2-linux-installation-ubuntu--debian)
3. [Windows WSL2 Installation](#3-windows-wsl2-installation)
4. [Common Setup Steps](#4-common-setup-steps)
5. [Troubleshooting](#5-troubleshooting)
6. [Quick Reference](#6-quick-reference)

---

## 1. Introduction

### 1.1 What This Guide Covers

This guide walks you through setting up a complete **OpenSTA** (Open Static Timing Analyzer) environment using **Docker**. By the end, you will have a fully working container with OpenSTA built from source, ready to run the workshop labs.

We use Docker so that every participant has an **identical, reproducible environment** — regardless of their host operating system or installed libraries.

### 1.2 What Is OpenSTA?

OpenSTA is an open-source, gate-level static timing verifier from [The OpenROAD Project](https://github.com/The-OpenROAD-Project/OpenSTA). It reads a circuit netlist, a technology library, and timing constraints, then reports whether the design meets its timing requirements. You interact with it through a **Tcl command-line interface**.

### 1.3 Workshop Architecture

```
┌─────────────────────────────────────────────┐
│  Your Computer (Host)                       │
│                                             │
│   workshop/          ← workshop materials   │
│   ├── docker/        ← Dockerfiles & scripts│
│   ├── labs/          ← lab exercises        │
│   └── libs/          ← technology libraries │
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │  Docker Container                   │   │
│   │  ┌───────────┐  ┌───────────────┐   │   │
│   │  │  OpenSTA  │  │ Icarus Verilog│   │   │
│   │  └───────────┘  └───────────────┘   │   │
│   │  /workspace ← mounted from host     │   │
│   └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

Your workshop files live on the **host** machine and are *mounted* into the container at `/workspace`. Any edits you make on either side are instantly visible to the other.

### 1.4 Prerequisites

| Requirement | Minimum | Recommended |
|---|---|---|
| **RAM** | 4 GB | 8 GB or more |
| **Disk space** | 5 GB free | 10 GB free |
| **CPU** | Any 64-bit x86 processor | Multi-core (speeds up the build) |
| **OS (Linux)** | Ubuntu 20.04 / Debian 11 | Ubuntu 22.04+ |
| **OS (Windows)** | Windows 10 version 22H2 | Windows 11 |
| **Internet** | Required during build | Required during build |

> **Note:** Hardware virtualisation (VT-x / AMD-V) must be **enabled in your BIOS/UEFI**. Most modern machines have it on by default, but if Docker fails to start, this is the first thing to check.

---

## 2. Linux Installation (Ubuntu / Debian)

### 2.1 Install Docker Engine

The steps below install Docker Engine from Docker's official `apt` repository. Run every command in a terminal.

#### 2.1.1 Remove Old / Conflicting Packages

```bash
# Remove unofficial or outdated Docker packages
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null
```

> **Tip:** It is safe to run this even if none of these packages are installed.

#### 2.1.2 Install Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

#### 2.1.3 Add Docker's Official GPG Key and Repository

```bash
# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

> **Debian users:** Replace `ubuntu` with `debian` in the URL above.

#### 2.1.4 Install Docker Engine

```bash
sudo apt-get update
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
```

### 2.2 Post-Installation Steps

#### 2.2.1 Run Docker Without `sudo`

By default, Docker commands require root privileges. Add your user to the `docker` group so you can run Docker without `sudo`:

```bash
sudo groupadd docker          # may already exist — that's fine
sudo usermod -aG docker $USER
```

**You must log out and log back in** (or reboot) for the group change to take effect. Then verify:

```bash
docker run hello-world
```

You should see a "Hello from Docker!" message **without** using `sudo`.

> ⚠️ **Warning:** Adding a user to the `docker` group grants privileges equivalent to root. On shared machines, consider the security implications.

#### 2.2.2 Enable Docker to Start on Boot

```bash
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

### 2.3 Build the OpenSTA Docker Image

Navigate to the workshop's `docker/` directory and build the image:

git clone https://github.com/skillsoc/opensta_workshop.git

```bash
cd opensta_workshop/

#Run the Docker Build script
docker build -f Dockerfile -t opensta_workshop .
```

> **Note:** The first build downloads the Ubuntu 22.04 base image, installs all dependencies, and compiles OpenSTA from source. This can take **10–20 minutes** depending on your internet speed and CPU. Subsequent builds use Docker's cache and are much faster.

**What happens during the build:**

1. Pulls the `ubuntu:22.04` base image.
2. Installs build tools (`cmake`, `gcc`, `swig`, `tcl-dev`, etc.).
3. Clones the OpenSTA repository from GitHub.
4. Compiles OpenSTA with `cmake` and `make`.
5. Installs Icarus Verilog (used in some labs for simulation).

### 2.4 Run the Container

```bash
docker run --rm -it -v $(pwd):/workspace opensta_workshop
```

You will be dropped into a bash shell inside the container. You should see:

```
============================================
 OpenSTA Workshop Environment
 Type: sta  to start OpenSTA
 Workshop files: /workspace/
============================================
```

### 2.5 Verify the Installation

Inside the container, run:

```bash
# Check that OpenSTA is available
sta -version

# Check that Icarus Verilog is available
iverilog -V

# List the mounted workshop files
ls 
```

If `sta -version` prints a version string (or starts the OpenSTA Tcl shell), your installation is working correctly.

> **Tip:** Type `exit` or press `Ctrl+D` to leave the container.

---

## 3. Windows WSL2 Installation

## Follow this video if you want:
## https://www.youtube.com/watch?v=J8cy6MDkacI

### 3.1 Enable WSL2

Open **PowerShell as Administrator** and run:

```powershell
wsl --install
```

This single command:
- Enables the "Windows Subsystem for Linux" feature.
- Enables the "Virtual Machine Platform" feature.
- Downloads and installs the latest Linux kernel.
- Sets WSL 2 as the default version.
- Installs **Ubuntu** as the default distribution.

**Restart your computer** when prompted.

> **Note:** If `wsl --install` says WSL is already installed, make sure you are on version 2 by running:
> ```powershell
> wsl --set-default-version 2
> ```

### 3.2 Set Up Ubuntu on WSL2

After rebooting, the Ubuntu terminal will open automatically and ask you to create a **username and password**. These are your Linux credentials (separate from your Windows login).

Once setup completes, verify the WSL version:

```powershell
# In PowerShell (not inside Ubuntu)
wsl -l -v
```

You should see output like:

```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

The **VERSION** column must show **2**. If it shows 1, convert it:

```powershell
wsl --set-version Ubuntu 2
```

### 3.3 Install Docker Desktop for Windows

1. Download **Docker Desktop** from [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/).
2. Run the installer.
3. During installation, ensure **"Use WSL 2 based engine"** is checked.
4. Complete the installation and **restart** if prompted.
5. Launch Docker Desktop from the Start menu.

### 3.4 Configure WSL2 Integration

1. Open Docker Desktop.
2. Click the **⚙ Settings** (gear icon) in the top-right.
3. Go to **General** → confirm **"Use the WSL 2 based engine"** is enabled.
4. Go to **Resources → WSL Integration**.
5. Toggle **ON** the switch next to your Ubuntu distribution.
6. Click **Apply & Restart**.

![WSL Integration Setting](https://i.ytimg.com/vi/izpYsEn2V4I/maxresdefault.jpg)

### 3.5 Verify Docker Inside WSL2

Open your **Ubuntu (WSL2) terminal** and run:

```bash
docker --version
docker run hello-world
```

If you see "Hello from Docker!", Docker is correctly integrated with WSL2.

> ⚠️ **Important:** Always run Docker commands from the **WSL2 Ubuntu terminal**, not from PowerShell or CMD. This ensures proper Linux filesystem performance.

### 3.6 Build the OpenSTA Docker Image

Inside your **WSL2 Ubuntu terminal**:

```bash
cd ~/opensta_workshop

# Run docker build directly
docker build -f Dockerfile -t opensta_workshop .
```

> **Performance tip:** Keep all workshop files inside the WSL2 filesystem (e.g., `/home/yourname/opensta_workshop/`), **not** on a Windows mount like `/mnt/c/Users/...`. File I/O on Windows mounts is significantly slower under WSL2.

### 3.7 Run the Container

```bash
# Run docker directly
docker run --rm -it -v $(pwd):/workspace opensta_workshop
```
============================================
 OpenSTA Workshop Environment (WSL2)
 Type: sta  to start OpenSTA
 Workshop files: /workspace/

 Running on Docker Desktop + WSL2
 Your files are mounted from the host.
============================================
```

### 3.8 Verify the Installation

Inside the container:

```bash
sta -version
iverilog -V
ls /workspace/
```

If `sta` responds, you are ready for the workshop.

---

## 4. Common Setup Steps

These steps apply to **both** Linux and Windows WSL2 users, and should be performed **after** you have a working Docker container.

### 4.1 Download Workshop Materials

If you haven't already obtained the workshop files:

```bash
# On your host machine (or inside WSL2 terminal)
git clone https://github.com/skillsoc/opensta_workshop.git
cd opensta_workshop
```

> Replace `<WORKSHOP_REPO_URL>` with the URL provided by your instructor.

The expected directory structure is:

```
opensta_workshop/
├── docker/                 # Dockerfiles and scripts
│   ├── Dockerfile│        
│   
├── labs/                   # Lab exercises
│   ├── lab0/
│   ├── lab1/
│   └── ...
├── libs/                   # Technology libraries (.lib files)
└── INSTALLATION_GUIDE.md   # This file
```

### 4.2 Mounting Volumes

When you run the container with `-v $(pwd):/workspace`, your current directory on the host is mounted at `/workspace` inside the container.

```bash
# Mount the workshop root directory
docker run --rm -it -v $(pwd):/workspace opensta_workshop

# Inside the container, your files are at:
ls
 
```

**Key points about mounted volumes:**

- Files edited on the host appear instantly inside the container, and vice versa.
- You can use your favourite editor (VS Code, Sublime, etc.) on the host to edit files, then run OpenSTA inside the container.
- Files created inside the container in `/workspace` persist on the host after the container exits.
- Files created *outside* `/workspace` inside the container are **lost** when the container exits (unless you commit the container).

### 4.3 Using Docker

If you prefer Exciting docker present inside:

```bash
cd opensta_workshop/

# command to check docker
docker ps -a

# Start an interactive session
docker start -i <container_id>  #If the docker is stopped

docker exec -it <container_id>  #If the docker is still running
```

### 4.4 Test the OpenSTA Installation

Inside the container, start an interactive OpenSTA session:

```bash
sta
```

You will enter the OpenSTA Tcl shell (the prompt changes to `%` or `sta>`). Try a few commands:

```tcl
# Print help
help

# Exit OpenSTA
exit
```

### 4.5 Run Your First Timing Analysis

If the workshop includes a sample design (e.g., in `labs/lab1_basics/`), you can run a quick test:

```bash
# Inside the container
cd /workspace/labs1/
```

Create or use the provided Tcl script (e.g., `run_sta.tcl`):

```tcl
# run_sta.tcl — Minimal timing analysis example

# 1. Read the technology library
read_liberty ../../libs/Nangate45.lib

# 2. Read the design netlist
read_verilog my_design.v

# 3. Link the design
link_design top_module_name

# 4. Read timing constraints
read_sdc constraints.sdc

# 5. Report setup timing (worst path)
report_checks -path_delay max -format full

# 6. Report hold timing (worst path)
report_checks -path_delay min -format full
```

Run it:

```bash
sta run_sta.tcl
```

If the script completes and prints a timing report with slack values, **congratulations — your environment is fully working!**

---

## 5. Troubleshooting

### 5.1 Docker Permission Errors

**Symptom:**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solution (Linux):**

```bash
# Add yourself to the docker group
sudo usermod -aG docker $USER

# IMPORTANT: Log out and log back in, then verify
groups   # should list 'docker'
```

If you cannot log out, you can temporarily use:

```bash
newgrp docker
```

**Solution (WSL2):**

Ensure Docker Desktop is **running** on Windows. The Docker daemon runs inside Docker Desktop, not inside WSL2 itself.

---

### 5.2 Docker Daemon Not Running

**Symptom:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solution (Linux):**

```bash
sudo systemctl start docker
sudo systemctl status docker   # should show "active (running)"
```

**Solution (WSL2):**

- Open Docker Desktop from the Windows Start menu.
- Wait for the whale icon in the system tray to stop animating (indicates Docker is ready).
- If Docker Desktop fails to start, ensure virtualisation is enabled in BIOS/UEFI.

---

### 5.3 WSL2-Specific Issues

#### WSL2 Not Version 2

```powershell
# Check version
wsl -l -v

# Convert if needed
wsl --set-version Ubuntu 2
```

#### Docker Not Available Inside WSL2

1. Open Docker Desktop → Settings → Resources → WSL Integration.
2. Ensure your Ubuntu distribution is toggled **ON**.
3. Click **Apply & Restart**.
4. Close and reopen your WSL2 terminal.

#### Slow File Performance in WSL2

If builds or file operations are very slow, your files are likely on a Windows mount (`/mnt/c/...`).

**Fix:** Move your workshop files to the WSL2 native filesystem:

```bash
# Inside WSL2
cp -r /mnt/c/Users/YourName/opensta_workshop ~/opensta_workshop
cd ~/opensta_workshop
```

Files under `/home/yourname/` use the native ext4 filesystem and are **much** faster.

#### WSL2 Running Out of Memory

Docker Desktop may consume too much memory. Create or edit `%UserProfile%\.wslconfig`:

```ini
[wsl2]
memory=4GB
processors=2
```

Then restart WSL:

```powershell
wsl --shutdown
```

---

### 5.4 OpenSTA Build Errors

#### CMake Errors During Docker Build

**Symptom:** Build fails at the `cmake ..` step.

**Possible causes:**
- Network issue preventing the `git clone` of OpenSTA inside the container.
- Missing dependencies (unlikely with the provided Dockerfile, but possible if modified).

**Solution:**

```bash
# Rebuild without cache to start fresh
docker build --no-cache -f Dockerfile.linux -t opensta_workshop .
```

#### Build Runs Out of Memory

If `make -j$(nproc)` fails with out-of-memory errors, limit parallelism by editing the Dockerfile:

```dockerfile
# Change this line:
make -j$(nproc)

# To:
make -j2
```

Then rebuild.

---

### 5.5 Container Cannot Find Workshop Files

**Symptom:** `/workspace/` is empty inside the container.

**Solution:** Make sure you run `docker run` from the **workshop root directory**, not from inside `docker/`:

```bash
# ✗ Wrong — mounts only the docker/ subdirectory
cd opensta_workshop/docker/
docker run -it -v $(pwd):/workspace opensta_workshop

# ✓ Correct — mounts the entire workshop
cd opensta_workshop/
docker run -it -v $(pwd):/workspace You should see:

```

```

---

### 5.6 "sta: command not found" Inside Container

**Solution:** The OpenSTA binary may not be on the PATH. Try the full path:

```bash
/opt/OpenSTA/build/sta -version
```

If that works, add it to your PATH inside the container:

```bash
export PATH="/opt/OpenSTA/build:$PATH"
```

This is already configured in the provided Dockerfiles, so this issue typically only arises with custom images.

---

## 6. Quick Reference

### 6.1 Essential Docker Commands

| Command | Description |
|---|---|
| `docker build -f Dockerfile.linux -t opensta_workshop .` | Build the image |
| `docker run --rm -it -v $(pwd):/workspace opensta_workshop` | Run an interactive container |
| `docker run --rm -v $(pwd):/workspace opensta_workshop sta script.tcl` | Run a script and exit |
| `docker ps` | List running containers |
| `docker ps -a` | List all containers (including stopped) |
| `docker images` | List downloaded/built images |
| `docker system prune` | Remove unused containers, networks, and images |
| `docker compose build` | Build using Docker Compose |
| `docker compose run opensta` | Run using Docker Compose |
| `Ctrl+D` or `exit` | Exit the container |

### 6.2 OpenSTA Basic Commands

| Command | Description | Example |
|---|---|---|
| `read_liberty` | Load a technology library (`.lib`) | `read_liberty Nangate45.lib` |
| `read_verilog` | Load a Verilog netlist (`.v`) | `read_verilog design.v` |
| `link_design` | Link the netlist to the library | `link_design top_module` |
| `read_sdc` | Load timing constraints (`.sdc`) | `read_sdc constraints.sdc` |
| `create_clock` | Define a clock signal | `create_clock -name clk -period 2.0 [get_ports clk]` |
| `set_input_delay` | Set arrival time at input ports | `set_input_delay 0.5 -clock clk [all_inputs]` |
| `set_output_delay` | Set required time at output ports | `set_output_delay 0.8 -clock clk [all_outputs]` |
| `set_load` | Apply capacitive load to ports | `set_load -pin_load 0.05 [all_outputs]` |
| `report_checks` | Report timing paths and slack | `report_checks -path_delay max -format full` |
| `report_checks -path_delay min` | Report hold timing | `report_checks -path_delay min -format full` |
| `set_false_path` | Exclude a path from analysis | `set_false_path -from [get_ports reset]` |
| `exit` | Quit OpenSTA | `exit` |

### 6.3 Typical Workflow Cheat Sheet

```tcl
# Complete timing analysis in 6 commands:
read_liberty  my_library.lib
read_verilog  my_design.v
link_design   top_module_name
read_sdc      constraints.sdc
report_checks -path_delay max -format full   ;# Setup check
report_checks -path_delay min -format full   ;# Hold check
```

---

## Need Help?

If you encounter issues not covered here:

1. **Re-read the error message carefully** — it usually tells you exactly what went wrong.
3. **Ask your workshop instructor** — they might have seen these issues before! contact nijanthan.r@skillsoc.com

