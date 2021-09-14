# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

    #-----
    # Create virtual machine, named "ldbt-databases" ("ldbt-" Laminas DataBase Test).
    # It contain all databases, what we want test locally.
    config.vm.define "ldbt-databases" do |configNode|
        configNode.vm.box = 'bento/ubuntu-20.10'
        configNode.vm.define "ldbt-databases"
        configNode.vm.hostname = "ldbt-databases"
        configNode.vm.provider "virtualbox" do |v|
            v.name = "ldbt-databases"
            v.memory = 4096
            v.cpus = 2
        end
        configNode.vm.network "private_network", ip: "192.168.20.20"

        configNode.vm.provision 'shell', inline: $init_debian

        configNode.vm.provision 'shell', inline: $install_mysql_debian
        configNode.vm.provision 'shell', privileged: false, inline: '/vagrant/.ci/mysql_fixtures.sh'

        configNode.vm.provision 'shell', inline: $install_postgresql_debian
        configNode.vm.provision 'shell', privileged: false, inline: '/vagrant/.ci/pgsql_fixtures.sh'

        configNode.vm.provision 'shell', inline: $install_mssql_server_debian
        configNode.vm.provision 'shell', inline: $install_mssql_client_debian
        configNode.vm.provision 'shell', privileged: false, inline: '/vagrant/.ci/sqlsrv_fixtures.sh'

        configNode.vm.provision 'shell', inline: $setup_vagrant_user_environment
    end

    #-----
    # Install virtual machine, named "ldbt-phpunit" ("ldbt-" Laminas DataBase Test)
    # It contains php-cli, composer and all php extensions for work with "ldbt-databases"
    config.vm.define "ldbt-phpunit" do |configNode|
        configNode.vm.box = 'bento/ubuntu-20.10'
        configNode.vm.define "ldbt-phpunit"
        configNode.vm.hostname = "ldbt-phpunit"
        configNode.vm.provider "virtualbox" do |v|
            v.name = "ldbt-phpunit"
            v.memory = 1024
            v.cpus = 1
        end
        configNode.vm.network "private_network", ip: "192.168.20.21"
        configNode.vm.provision 'shell', inline: $init_debian
        configNode.vm.provision 'shell', inline: $install_mssql_client_debian
        configNode.vm.provision 'shell', inline: $install_composer_debian
    end

end

#------------------------------------------------------------------------------
# Init debian system.
# If you need, you can enable 'apt-cacher-ng'.
#-----

$init_debian = <<SCRIPT

    echo '-- SCRIPT: $init_debian'

#    # use "apt-cacher-ng", if you need it.
#    # It is a good idea if you have slow (GPRS|3G) internet, and want update "Vagrantfile".
#    # @see: homepage @link:{ http://www.unix-ag.uni-kl.de/~bloch/acng/}
#    # @see: How to use by Docker @link:{https://docs.docker.com/samples/apt-cacher-ng/}
#    # 1. replace the IP with yours.
#    # 2. configure "apt-cacher-ng" to allow SSL for "microsoft" repositary
#    # @see: How to enable SSL @link:{https://blog.packagecloud.io/eng/2015/05/05/using-apt-cacher-ng-with-ssl-tls/}
#    #-----
#
#    echo "-- configure apt utilite for use 'apt-cacher-ng' proxy"
#cat << 'EOF' > /etc/apt/apt.conf.d/02proxy
#Acquire::http::proxy "http://172.18.0.2:3142";
#Acquire::ftp::proxy "http://172.18.0.2:3142";
#EOF

    export DEBIAN_FRONTEND=noninteractive
    apt-get -yq update

SCRIPT

#------------------------------------------------------------------------------
# Install MySQL database
# actual version is 8.x
#-----

$install_mysql_debian = <<SCRIPT
    
    echo '-- SCRIPT: $install_mysql_debian'

    debconf-set-selections <<< "mysql-server mysql-server/root_password password Password123"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password Password123"
    apt-get -yq install mysql-server

    echo "-- Configure MySQL"
    # Allow external connections to MySQL as root (with password Password123)
    sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
    mysql -u root -pPassword123 -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="root"; FLUSH PRIVILEGES;'

    echo "-- Restart MySQL"
    service mysql restart
SCRIPT

#------------------------------------------------------------------------------
# Install PostgreSQL database
# actual version is 12.x
#-----

$install_postgresql_debian = <<SCRIPT

    echo '-- SCRIPT: $install_postgresql_debian'

    apt-get -yq install postgresql

    echo "-- Configure PostgreSQL"
    # Allow external connections to PostgreSQL as postgres
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/12/main/postgresql.conf
    sed -i "s/peer/trust/" /etc/postgresql/12/main/pg_hba.conf
    echo 'host all all 0.0.0.0/0 trust' >> /etc/postgresql/12/main/pg_hba.conf

    echo "-- Restart PostgreSQL"
    service postgresql restart

SCRIPT

#------------------------------------------------------------------------------
# Install MSSQL Server 2019
# More info @link(https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-ubuntu?view=sql-server-ver15)
# @note: here we dont install "mssql-tools".
# @see:  script "$install_mssql_client_debian"
#-----

$install_mssql_server_debian = <<SCRIPT

    echo '-- SCRIPT: $install_mssql_server_debian'

    echo "-- add public key of microsoft repository"
    #wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
    curl -s https://packages.microsoft.com/keys/microsoft.asc | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/microsoft.gpg --import
    chmod -v 744 /etc/apt/trusted.gpg.d/microsoft.gpg
    add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list)"

    echo "-- update software index, using microsoft repository"
    apt-get -yq update

    echo '-- install "mssql-server"'
    apt-get -yq install mssql-server

    echo '-- configure: mssql-server. Here we need ACCEPT_EULA="Y" and MSSQL_SA_PASSWORD="Password123"'
    export ACCEPT_EULA="Y"
    export MSSQL_SA_PASSWORD="Password123"

    echo '-- configure "mssql-server". We use "Developer" edition - don't use it in production!'
    ## Choose an edition of SQL Server:
    ##   1) Evaluation (free, no production use rights, 180-day limit)
    ##   2) Developer (free, no production use rights)
    ##   3) Express (free)
    ##   4) Web (PAID)
    ##   5) Standard (PAID)
    ##   6) Enterprise (PAID) - CPU Core utilization restricted to 20 physical/40 hyperthreaded
    ##   7) Enterprise Core (PAID) - CPU Core utilization up to Operating System Maximum
    ##   8) I bought a license through a retail sales channel and have a product key to enter.
    printf "2\n" | /opt/mssql/bin/mssql-conf setup

SCRIPT

#------------------------------------------------------------------------------
# Install client library of "MSSQL"
# @see: https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15#debian17
#----

$install_mssql_client_debian = <<SCRIPT

    echo '-- SCRIPT: $install_mssql_client_debian'

    export ACCEPT_EULA="Y"

    echo "-- add public key of microsoft repository"
#   wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | apt-key add -
#   wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
    curl -s https://packages.microsoft.com/keys/microsoft.asc | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/microsoft.gpg --import
    chmod -v 744 /etc/apt/trusted.gpg.d/microsoft.gpg
    curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/msprod.list

    echo "-- update software index, using microsoft repository"
    apt-get -yq update

    echo '-- Start install "mssql-tools". Here we need variable ACCEPT_EULA="Y"'
    apt-get -yq install mssql-tools

    echo '-- "mssql-tools" is installed. Set path.'
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /home/vagrant/.bash_profile
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /home/vagrant/.bashrc

    echo '-- Start install "unixodbc-dev".'
    apt-get install -y unixodbc-dev

    source /home/vagrant/.bashrc

SCRIPT

#------------------------------------------------------------------------------

$setup_vagrant_user_environment = <<SCRIPT

    echo '-- SCRIPT: $setup_vagrant_user_environment'

    if ! grep "cd /vagrant" /home/vagrant/.profile > /dev/null; then
      echo "cd /vagrant" >> /home/vagrant/.profile
    fi

SCRIPT

#------------------------------------------------------------------------------
# Here we install PHP, PHP composer, and PHP extension for work witch databases
# of "ldbt-databases" virtual box
#-----

$install_composer_debian = <<SCRIPT

    echo '-- SCRIPT: $install_composer_debian'

    add-apt-repository ppa:ondrej/php -y
    apt-get update

    echo '-- install "php-cli" and some utils for PECL'
    # apt-get install php7.4 php7.4-dev php7.4-xml -y --allow-unauthenticated
    apt-get -yq install \
        unzip \
        php-cli php-pear php-dev

    php -v

    echo '-- install some PHP extensions'
    apt-get -yq install \
        php-xmlwriter \
        php-mbstring \
        php-mysql \
        php-pgsql

    echo '-- install PHP client library for MSSQL'
    # @see: @link(https://docs.microsoft.com/en-us/sql/connect/php/installation-tutorial-linux-mac?view=sql-server-ver15)
    pecl install sqlsrv
    pecl install pdo_sqlsrv
    printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/7.4/mods-available/sqlsrv.ini
    printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/7.4/mods-available/pdo_sqlsrv.ini

    echo '-- download and install PHP composer'
    curl -sS https://getcomposer.org/installer -o composer-setup.php
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -v composer-setup.php
    composer -V

SCRIPT

#------------------------------------------------------------------------------
