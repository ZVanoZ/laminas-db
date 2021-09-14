#!/usr/bin/env bash
#------------------------------------------------------------------------------
# For use this script:
# 1. run ssh by vargrant
# $ vagrant ssh ldbt-phpunit
# 2. run script in the opened terminal
# $ bash /vagrant/phpunit-run-in-vagrant.sh
#-----
echo '-- Change curent folder to folder of .sh script'
cd $(dirname $(readlink -e $0))
echo `pwd`

echo '-- Update dependences by composer'
composer update

echo '-- Run phpunit'
php -f ./vendor/phpunit/phpunit/phpunit -v
php -f ./vendor/phpunit/phpunit/phpunit

#------------------------------------------------------------------------------