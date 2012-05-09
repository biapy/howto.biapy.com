Handle PHP sessions with Memcached and MySQL
============================================

Files used by the guide  [Gérer les sessions PHP avec Memcached et MySQL (fr)](https://howto.biapy.com/fr/debian-gnu-linux/serveurs/php/gerer-les-sessions-php-avec-memcached-et-mysql).

* __memcached_mysql_sessionhandler.class.php__ : The PHP custom session handler class (to place in _/etc/php5/session-management/_).
* __memcached_mysql_sessionhandler_config.class.php__ : The PHP custom session handler configuration class (to place in _/etc/php5/session-management/_).
* __sessions-store-memcached-mysql.ini__ : The PHP custom session handler configuration (to place in _/etc/php5/conf.d/_).
* __memcached_mysql_sessionhandler.sql__ : The PHP custom session handler SQL database initialisation script.

