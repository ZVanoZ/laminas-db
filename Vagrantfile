# -*- mode: ruby -*-
# vi: set ft=ruby :

# DEBIAN_FRONTEND='noninteractive'

APT_CACHER_NG_ENABLED='N'
APT_CACHER_NG_HTTP='http://172.18.0.2:3142'
APT_CACHER_NG_FTP='http://172.18.0.2:3142'

MYSQL_IS_USED='T'
MYSQL_ROOT_PASSWORD='Password123'

MSSQL_IS_USED='T'
MSSQL_SA_PASSWORD='Password123'

Vagrant.configure(2) do |config|
#    config.ssh.forward_agent = false
#    config.ssh.pty = false

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

        if MSSQL_IS_USED != 'T'
            puts 'SKIP'
        else
            puts 'INSTALL'
            configNode.vm.provision 'shell', inline: $install_mssql_server_debian
            configNode.vm.provision 'shell', inline: $install_mssql_client_debian
            configNode.vm.provision 'shell', privileged: false, inline: '/vagrant/.ci/sqlsrv_fixtures.sh'
        end

        configNode.vm.provision 'shell', inline: $install_mysql_debian
        configNode.vm.provision 'shell', privileged: false, inline: '/vagrant/.ci/mysql_fixtures.sh'

        configNode.vm.provision 'shell', inline: $install_postgresql_debian
        configNode.vm.provision 'shell', privileged: false, inline: '/vagrant/.ci/pgsql_fixtures.sh'

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
    echo '-- APT_CACHER_NG_ENABLED='#{APT_CACHER_NG_ENABLED}

    if [ "#{APT_CACHER_NG_ENABLED}" == 'Y' ]
    then
        echo '-- init "apt-cacher-ng" proxy'
        # use "apt-cacher-ng", if you need it.
        # It is a good idea if you have slow (GPRS|3G) internet, and want update "Vagrantfile".
        # @see: homepage @link:{ http://www.unix-ag.uni-kl.de/~bloch/acng/}
        # @see: How to use by Docker @link:{https://docs.docker.com/samples/apt-cacher-ng/}
        # 1. replace the IP with yours.
        # 2. configure "apt-cacher-ng" to allow SSL for "microsoft" repositary
        # @see: How to enable SSL @link:{https://blog.packagecloud.io/eng/2015/05/05/using-apt-cacher-ng-with-ssl-tls/}
        #-----

        echo "-- configure apt utilite for use 'apt-cacher-ng' proxy"
        cat << 'EOF' > /etc/apt/apt.conf.d/02proxy
Acquire::http::proxy "#{APT_CACHER_NG_HTTP}";
Acquire::ftp::proxy "#{APT_CACHER_NG_FTP}";
EOF
        cat /etc/apt/apt.conf.d/02proxy
    else
        echo '-- SKIP init "apt-cacher-ng" proxy'
    fi

    ## We can add some variables into startap scripts
    #echo "export DEBIAN_FRONTEND=noninteractive" >> /home/vagrant/.profile
    #echo "export DEBIAN_FRONTEND=noninteractive" >> /etc/profile.d/vagrant.sh

    echo "UsePam yes" >> /etc/ssh/sshd_config
#    cat /etc/ssh/sshd_config | grep "UsePam"

    export DEBIAN_FRONTEND='noninteractive'
    apt update -yq

SCRIPT

#------------------------------------------------------------------------------
# Install MySQL database
# actual version is 8.x
#-----

$install_mysql_debian = <<SCRIPT
    
    echo '-- SCRIPT: $install_mysql_debian'
    export DEBIAN_FRONTEND='noninteractive'

    debconf-set-selections <<< "mysql-server mysql-server/root_password password #{MYSQL_ROOT_PASSWORD}"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password #{MYSQL_ROOT_PASSWORD}"

    apt-get -yq install mysql-server

    echo "-- Configure MySQL"
    # Allow external connections to MySQL as root (with password #{MYSQL_ROOT_PASSWORD})
    sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
    mysql -u root -p#{MYSQL_ROOT_PASSWORD} -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="root"; FLUSH PRIVILEGES;'

    echo "-- Restart MySQL"
    service mysql restart
SCRIPT

#------------------------------------------------------------------------------
# Install PostgreSQL database
# actual version is 12.x
#-----

$install_postgresql_debian = <<SCRIPT

    echo '-- SCRIPT: $install_postgresql_debian'

    export DEBIAN_FRONTEND='noninteractive'

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

    export DEBIAN_FRONTEND='noninteractive'
    export ACCEPT_EULA="Y"
    export MSSQL_SA_PASSWORD=#{MSSQL_SA_PASSWORD}

    echo "-- add public key of microsoft repository"
    #wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
    curl -s https://packages.microsoft.com/keys/microsoft.asc | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/microsoft.gpg --import
    chmod -v 744 /etc/apt/trusted.gpg.d/microsoft.gpg
    add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list)"

    echo "-- update software index, using microsoft repository"
    apt update -yq

    echo '-- install "mssql-server"'
    apt-get -yq install mssql-server

    echo '-- configure: mssql-server.'
    echo '---- Here we need ACCEPT_EULA="Y" and MSSQL_SA_PASSWORD="#{MSSQL_SA_PASSWORD}"                      '
    echo '---- We use "Developer" edition                                                                     '
    echo '---- Console-UI provide this variants.                                                              '
    echo '------ Choose an edition of SQL Server:                                                             '
    echo '------   1) Evaluation (free, no production use rights, 180-day limit)                              '
    echo '------   2) Developer (free, no production use rights)                                              '
    echo '------   3) Express (free)                                                                          '
    echo '------   4) Web (PAID)                                                                              '
    echo '------   5) Standard (PAID)                                                                         '
    echo '------   6) Enterprise (PAID) - CPU Core utilization restricted to 20 physical/40 hyperthreaded     '
    echo '------   7) Enterprise Core (PAID) - CPU Core utilization up to Operating System Maximum            '
    echo '------   8) I bought a license through a retail sales channel and have a product key to enter.      '
    printf "2\n" | /opt/mssql/bin/mssql-conf setup

SCRIPT

#------------------------------------------------------------------------------
# Install client library of "MSSQL"
# @see: https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15#debian17
#----

$install_mssql_client_debian = <<SCRIPT

    echo '-- SCRIPT: $install_mssql_client_debian'

    export DEBIAN_FRONTEND='noninteractive'
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

    export DEBIAN_FRONTEND='noninteractive'

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
