<?php
/**
 * Memcached + MySQL session storage for php5.landure.ovh1.
 *
 * MySQL connection configuration file
 *
 * @author Pierre-Yves Landuré <pierre-yves.landure@biapy.fr>
 * @see https://howto.biapy.com/fr/debian-gnu-linux/serveurs/php/gerer-les-sessions-php-avec-memcached-et-mysql/
 */
abstract class Memcached_MySQL_SessionHandler_Config
{
  // Edit the following values to your needs.
  const MYSQL_HOST = 'localhost';
  const MYSQL_DB = 'session_db';
  const MYSQL_USER = 'user';
  const MYSQL_PASSWORD = 'password';

  const TABLE_PREFIX = '';
  const FIELD_PREFIX = '';

  const MEMCACHED_ID = 'Ismeijyan5';
  // Memcached servers list.
  // To add multiple Memcached servers use:
  // const MEMCACHED_SERVERS='xx.xx.xx.ip:port:weight,xx.xx.xx.ip:port:weight,...'
  const MEMCACHED_SERVERS = '127.0.0.1:11211';
}
