#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with administrative privileges (sudo)."
    exit 1
fi

# Prompt the user for the desired username
read -p "Enter the desired username: " USERNAME

# Update system
read -p "Update the system ? (y/n): " ACTION

if [ "$ACTION" == "y" ]; then
	echo "Executing system update..."
	apt update -y
	apt upgrade -y
	echo "System updated."
elif [ "$ACTION" == "n" ]; then
	echo "Skipping system update."
fi

# Install sudo
apt install sudo -y

# Setup users and groups
read -p "Setup users and groups and adding $USERNAME to sudo users ? (y/n): " ACTION

if [ "$ACTION" == "y" ]; then
	echo "Executing users and groups setup..."
	usermod -aG sudo $USERNAME
	echo "$USERNAME	ALL=(ALL) ALL" | sudo tee -a "/etc/sudoers"
	groupadd user42
	sudo usermod -aG user42 $USERNAME
	echo "Users and groups setup completed."
elif [ "$ACTION" == "n" ]; then
	echo "Skipping users and groups setup."
fi

# Install wget and vim
read -p "Install git, wget, vim and Oh my zsh ? (y/n): " ACTION

if [ "$ACTION" == "y" ]; then
	echo "Installing wget and vim..."
	apt install git -y
	apt install wget -y
	apt install vim -y
	sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
	echo "wget and vim installed."
elif [ "$ACTION" == "n" ]; then
	echo "Skipping wget and vim installation."
fi

# Install and configure openssh-server
read -p "Setup ssh server ? (y/n): " ACTION

if [ "$ACTION" == "y" ]; then
	echo "Installing and configuring ssh server..."
	apt update -y
	apt install openssh-server -y
	service ssh restart
	sed -i 's/#Port 22/Port 4242/' /etc/ssh/sshd_config
	service ssh restart
	echo "ssh server installed and configured."
elif [ "$ACTION" == "n" ]; then
	echo "Skipping ssh server installation and configuration."
fi

# Install and configure ufw
read -p "Setup firewall ? (y/n): " ACTION

if [ "$ACTION" == "y" ]; then
	echo "Installing and configuring firewall..."
	apt install ufw -y
	ufw enable
	ufw allow proto tcp to 0.0.0.0/0 port 4242
elif [ "$ACTION" == "n" ]; then
	echo "Skipping firewall installation and configuration."
fi

# Install password quality checking library (libpam-pwquality)
read -p "Install libpam-pwquality ? (y/n): " ACTION

if [ "$ACTION" == "y" ]; then
	echo "Installing libpam-pwquality..."
	apt install libpam-pwquality -y
	sed -i 's/password [success=2 default=ignore] pam_unix.so obscure sha512/password [success=2 default=ignore] pam_unix.so obscure sha512 minlen=10/' /etc/pam.d/common-password

	#TODO: check if the following lines are correct

	sed -i 's/password	requisite			pam_pwquality.so retry=3/password	requisite			pam_pwquality.so retry=3 lcredit =-1 ucredit=-1 dcredit=-1 maxrepeat=3 usercheck=0 difok=7 enforce_for_root/' /etc/pam.d/common-password
	sed -i 's/PASS_MAX_DAYS	99999/PASS_MAX_DAYS	30/' /etc/login.defs
	sed -i 's/PASS_MIN_DAYS	0/PASS_MIN_DAYS	2/' /etc/login.defs
	sed -i 's/Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"/Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"/' /etc/sudoers
	echo 'Defaults	badpass_message="Password is wrong, please try again!"' | sudo tee -a "/etc/sudoers"
	mkdir /var/log/sudo
	echo 'Defaults	logfile="/var/log/sudo/sudo.log"' | sudo tee -a "/etc/sudoers"
	echo "Defaults	log_input, log_input" | sudo tee -a "/etc/sudoers"
	echo "Defaults	requiretty" | sudo tee -a "/etc/sudoers"
	echo "$USERNAME	ALL=(ALL) NOPASSWD: /usr/local/bin/monitoring.sh" | sudo tee -a "/etc/sudoers"
	echo "libpam-pwquality installed."
elif [ "$ACTION" == "n" ]; then
	echo "Skipping libpam-pwquality installation."
fi

# Setup crontab script
read -p "Setup monitoring script with crontab ? (y/n): " ACTION

if [ "$ACTION" == "y" ]; then
	echo "Setting up monitoring script with crontab..."
	apt install -y net-tools
	crontab -u $USERNAME -l > crontmp
	echo "*/10 * * * * bash /usr/local/bin/monitoring.sh" >> crontmp
	crontab -u $USERNAME crontmp
	rm crontmp
	cp monitoring.sh /usr/local/bin/monitoring.sh
	echo "Monitoring script setup completed."
elif [ "$ACTION" == "n" ]; then
	echo "Skipping monitoring script setup."
fi

# Setup bonus part
read -p "Setup wordpress ? (y/n): " ACTION

if [ "$ACTION" == "y" ]; then
	echo "Setting up wordpress..."
	apt install -y php7.3 php7.3-fpm php7.3-mysql php-common php7.3-cli php7.3-common php7.3-json php7.3-opcache php7.3-readline php-mbstring php-zip php-gd php-curl php-xml php-pear php-bcmath
	service php7.3-fpm start
	apt install -y nginx
	service nginx start
	apt install -y mariadb-server
	service mysql start
	mysql_secure_installation
	mysql -u root -p
	echo "CREATE DATABASE wordpress;" | mysql -u root -p
	echo "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpressuser'@'localhost' IDENTIFIED BY 'password';" | mysql -u root -p
	echo "FLUSH PRIVILEGES;" | mysql -u root -p
	echo "EXIT;" | mysql -u root -p
	wget https://wordpress.org/latest.tar.gz
	tar -zxvf latest.tar.gz
	mv wordpress /var/www/html/
	chown -R www-data:www-data /var/www/html/wordpress
	chmod -R 755 /var/www/html/wordpress
	cp wp-config.php /var/www/html/wordpress
	service nginx restart
	service php7.3-fpm restart
	service mysql restart
	echo "Wordpress setup completed."
elif [ "$ACTION" == "n" ]; then
	echo "Skipping wordpress setup."
fi

echo "Installation completed."
