OpenSTA Workshop
Welcome to the **OpenSTA Workshop**. This repository provides a containerized environment to learn and practice **Static Timing Analysis (STA) using OpenSTA**, a open-source timing engine which is as good as a industrial timing signoff engine.

## Table of Contents
* [Prerequisites](#Prerequisites)
* [Installation](#Prerequisites)
  * [Windows Users: WSL2 Setup](#windows-users-wsl2-setup)
  * [Docker Installation](#docker-installation)
  

Getting Started

Docker Usage Guide

Running OpenSTA

## Prerequisites
Before starting, ensure you have a terminal environment ready. We recommend a Linux-based environment.

## Windows Users: WSL2 Setup
If you are on a Windows laptop, you must install the Windows Subsystem for Linux (WSL2):

Open PowerShell as Administrator.

Run the command in **PowerShell**:
```powershell
wsl --install
```
### Why you don't see the label:
1. **Syntax Highlighting:** The label `powershell` is used for "Syntax Highlighting." If you were writing a long script, it would make variables one color, strings another, and commands a third color.
2. **Clean Look:** Markdown assumes that if the code is inside a block, the reader just wants the code itself. Most platforms (like GitHub) don't display the language name in the corner of the box unless you use a specific theme or plugin.

### Pro-Tip for your SkillSOC Workshop:
Since your students will be switching between Windows (PowerShell) and Linux (Bash), it’s a great idea to be very explicit in your text. 

For example:
> **On Windows (PowerShell):**
> ```powershell
> wsl --install
> ```
> 
> **Once inside Linux (Bash):**
> ```bash
> sudo apt-get update
> ```

This prevents students from trying to run Linux commands in PowerShell or vice-versa!
Restart your computer if prompted.

## Docker Installation
Once logged into your Linux/WSL2 environment, install Docker:

Bash
sudo apt-get update
sudo apt-get install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
Installation
Clone the repository and build the Docker image:

Bash
# Clone the repo
git clone https://github.com/skillsoc/opensta_workshop.git
cd opensta_workshop

# Build the docker image
docker build -t skillsoc .
Docker Usage Guide
Start a new container
To launch a fresh container and enter the interactive terminal:

Bash
docker run -it skillsoc:latest
Manage existing containers
To list all containers (including stopped ones):

Bash
docker ps -a
To restart and enter a container that was previously created:

Bash
# Start the container
docker start <container_name>

# Attach to the running container
docker exec -it <container_name> bash
(Note: Use the name found in the "NAMES" column of docker ps -a)

Running OpenSTA
Once inside the Docker container, navigate to the workshop directory and launch the timing tool:

Bash
cd opensta_workshop
sta
You are now ready to run STA commands and scripts!

