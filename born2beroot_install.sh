#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with administrative privileges (sudo)."
    exit 1
fi

# Prompt the user for the desired username
read -p "Enter the desired username: " USERNAME

# Update system
echo "Updating the system..."
apt update -y
apt upgrade -y

# Install sudo
apt install sudo -y

# Setup users and groups
echo "Setup users and groups and adding $USERNAME to sudo users..."
adduser $USERNAME sudo
echo "$USERNAME    ALL=(ALL) ALL" | sudo tee -a "/etc/sudoers"
groupadd user42
sudo usermod -aG user42 $USERNAME

# Install git
echo "Install git..."
apt update -y
apt upgrade -y
apt install git -y

# Install wget and vim
echo "Install wget and vim..."
apt install wget -y
apt install vim -y

# Install Oh my zsh
echo "Install Oh my zsh..."
sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# Install and configure openssh-server
echo "Setup ssh server..."
apt update -y
apt install openssh-server -y
service ssh restart
sed -i 's/#Port 22/Port 4242/' /etc/ssh/sshd_config
service ssh restart

# Install and configure ufw
echo "Setup firewall..."
apt install ufw -y
ufw reset
ufw enable
ufw allow proto tcp to 0.0.0.0/0 port 4242
ufw allow 80 # Allow HTTP traffic if needed


# Install password quality checking library (libpam-pwquality)
echo "Install libpam-pwquality..."
apt install libpam-pwquality
echo "minlen=10" | sudo tee -a "/etc/pam.d/common-password"
sed -i 's/password    requisite         pam_pwquality.so retry=3/password    requisite         pam_pwquality.so retry=3 lcredit =-1 ucredit=-1 dcredit=-1 maxrepeat=3 usercheck=0 difok=7 enforce_for_root/' /etc/pam.d/common-password
sed -i 's/PASS_MAX_DAYS*9999/PASS_MAX_DAYS 30/' /etc/login.defs
sed -i 's/PASS_MIN_DAYS*0/PASS_MIN_DAYS 2/' /etc/login.defs
#echo "Defaults  env_reset" | sudo tee -a "/etc/sudoers"
#echo "Defaults  mail_badpass" | sudo tee -a "/etc/sudoers"
#echo 'Defaults  secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin' | sudo tee -a "/etc/sudoers"
echo 'Defaults  badpass_message="Password is wrong, please try again!"' | sudo tee -a "/etc/sudoers"
mkdir /var/log/sudo
echo 'Defaults  logfile="/var/log/sudo/sudo.log"' | sudo tee -a "/etc/sudoers"
echo "Defaults  log_input, log_input" | sudo tee -a "/etc/sudoers"
echo "Defaults  requiretty" | sudo tee -a "/etc/sudoers"
echo "$USERNAME ALL=(ALL) NOPASSWD: /usr/local/bin/monitoring.sh" | sudo tee -a "/etc/sudoers"

# Setup crontab script
echo "Setup monitoring script with crontab"
apt install -y net-tools
crontab -l > crontmp
echo "*/10 * * * * /usr/local/bin/monitoring.sh" >> crontmp
crontab crontmp
rm crontmp

echo "Installation completed."
