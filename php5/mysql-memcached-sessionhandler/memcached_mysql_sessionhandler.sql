CREATE TABLE `php_session` (
  `session_id` varchar(32) NOT NULL,
  `session_expiration` int(10) UNSIGNED NOT NULL,
  `session_data` text NOT NULL,
  PRIMARY KEY (`session_id`),
  KEY `expiration` (`session_expiration`)
) ENGINE=MyISAM;
