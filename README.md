# Born2beroot for 42

> :warning: **Project has not been tested yet.** :warning:

## What is it?

Born2beroot project aims to introduce you to the wonderful world of virtualization.

## Subject file

The subject file is available [here](resources/en.subject.born2beroot.pdf).

## What does the script install?

#TODO: finish explainations of each step

1. Install sudo
2. Setup users and groups
3. Install wget and vim
4. Install and configure openssh-server
5. Install and configure ufw
6. Install password quality checking library (libpam-pwquality)
7. Setup crontab script
8. Setup wordpress
9. Setup PocketMine-MP

## How to use installation script

First, you will need to setup on your own the disk partitioning. Then when you are ready, follow the steps below:

### 1. Download the script

Install git if not already done:

```bash
sudo apt install git
```

Clone the repository:

```bash
git clone https://github.com/CleSucre/Born2beroot.git
```

### 2. Run the script

```bash
cd Born2beroot
sudo bash born2beroot_install.sh
```

The script will ask you to enter the username you want to use during the installation.

Example:
```bash
Enter the desired username: julthoma
```

Follow the instuctions, and you will be done !
