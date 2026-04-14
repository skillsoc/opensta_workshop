OpenSTA Workshop
Welcome to the **OpenSTA Workshop**. This repository provides a containerized environment to learn and practice **Static Timing Analysis (STA) using OpenSTA**, a open-source timing engine which is as good as a industrial timing signoff engine.

## Table of Contents
* [Prerequisites](#Prerequisites)
* [Installation](#Prerequisites)
  * [1. Windows Users: WSL2 Setup](#1. Windows Users: WSL2 Setup)
  * [Docker Installation](#2. Docker Installation)

Getting Started

Docker Usage Guide

Running OpenSTA

## Prerequisites
Before starting, ensure you have a terminal environment ready. We recommend a Linux-based environment.

## 1. Windows Users: WSL2 Setup
If you are on a Windows laptop, you must install the Windows Subsystem for Linux (WSL2):

Open PowerShell as Administrator.

Run the command:

PowerShell
wsl --install
Restart your computer if prompted.

## 2. Docker Installation
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

