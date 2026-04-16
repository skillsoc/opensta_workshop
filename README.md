OpenSTA Workshop
Welcome to the **OpenSTA Workshop**. This repository provides a containerized environment to learn and practice **Static Timing Analysis (STA) using OpenSTA**, a open-source timing engine which is as good as a industrial timing signoff engine.

## Table of Contents
* [Prerequisites](#Prerequisites)
* [Installation](#Prerequisites)
  * [Windows Users: WSL2 Setup](#windows-users-wsl2-setup)
  * [Docker Installation](#docker-installation)


| Requirement | Minimum | Recommended |
|---|---|---|
| **RAM** | 4 GB | 8 GB or more |
| **Disk space** | 5 GB free | 10 GB free |
| **CPU** | Any 64-bit x86 processor | Multi-core (speeds up the build) |
| **OS (Linux)** | Ubuntu 20.04 / Debian 11 | Ubuntu 22.04+ |
| **OS (Windows)** | Windows 10 version 22H2 | Windows 11 |
| **Internet** | Required during build | Required during build |


> **Note:** Hardware virtualisation (VT-x / AMD-V) must be **enabled in your BIOS/UEFI**. Most modern machines have it on by default, but if Docker fails to start, this is the first thing to check.


Getting Started

Docker Usage Guide

Running OpenSTA

## Prerequisites
Before starting, ensure you have a terminal environment ready. We recommend a Linux-based environment.

## Windows Users: WSL2 Setup
If you are on a Windows laptop, you must install the Windows Subsystem for Linux (WSL2):

Open PowerShell as Administrator.

watch this guide to install wsl on windows
https://www.youtube.com/watch?v=J8cy6MDkacI

**do not install ubuntu from windows store use only wsl**

> **On Windows (PowerShell):**
> ```powershell
> wsl --install
> ```

## Docker Installation
Once logged into your Linux/WSL2 environment, install Docker:

check out this video to understand better : https://workdrive.zohoexternal.in/external/47bca38d1446abc3daf47d65f496a98778e929d02dd77a62b3159bf4d437b7b5

```bash
sudo apt-get update
sudo apt-get install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
```
Installation
Clone the repository and build the Docker image:

```bash
# Clone the repo
git clone https://github.com/skillsoc/opensta_workshop.git
cd opensta_workshop

# Build the docker image
docker build -t skillsoc .
```
Docker Usage Guide
Start a new container
To launch a fresh container and enter the interactive terminal:

```bash
docker run -it skillsoc:latest
```

Manage existing containers
To list all containers (including stopped ones):

```bash
docker ps -a
```
To restart and enter a container that was previously created:

```bash
# Start the container
docker start <container_name>

# Attach to the running container
docker exec -it <container_name> bash
```
(Note: Use the name found in the "NAMES" column of docker ps -a)

Running OpenSTA
Once inside the Docker container, navigate to the workshop directory and launch the timing tool:

```bash
cd opensta_workshop
sta
```
You are now ready to run STA commands and scripts!

Lets get started
