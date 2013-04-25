
# This is a fix for InnoDB in MySQL >= 4.1.x
# It "suspends judgement" for fkey relationships until are tables are set.
SET FOREIGN_KEY_CHECKS = 0;

#-----------------------------------------------------------------------------
#-- domain
#-----------------------------------------------------------------------------

DROP TABLE IF EXISTS `domain`;


CREATE TABLE `domain`
(
	`id` INTEGER  NOT NULL AUTO_INCREMENT,
	`name` VARCHAR(255)  NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `unique_domain` (`name`)
)Engine=InnoDB DEFAULT CHARSET=utf8;

#-----------------------------------------------------------------------------
#-- user
#-----------------------------------------------------------------------------

DROP TABLE IF EXISTS `user`;


CREATE TABLE `user`
(
	`id` INTEGER  NOT NULL AUTO_INCREMENT,
	`domain_id` INTEGER  NOT NULL,
	`username` VARCHAR(255)  NOT NULL,
	`password` VARCHAR(64)  NOT NULL,
	`enabled` INTEGER default 1 NOT NULL,
	`has_mailbox` INTEGER default 1 NOT NULL,
	PRIMARY KEY (`id`),
	INDEX `user_FI_1` (`domain_id`),
	CONSTRAINT `user_FK_1`
		FOREIGN KEY (`domain_id`)
		REFERENCES `domain` (`id`)
		ON DELETE CASCADE,
	UNIQUE KEY `unique_user` (`domain_id`, `username`)
)Engine=InnoDB DEFAULT CHARSET=utf8;

#-----------------------------------------------------------------------------
#-- alias
#-----------------------------------------------------------------------------

DROP TABLE IF EXISTS `alias`;


CREATE TABLE `alias`
(
	`id` INTEGER  NOT NULL AUTO_INCREMENT,
	`domain_id` INTEGER,
	`aliasname` VARCHAR(255)  NOT NULL,
	`enabled` INTEGER default 1 NOT NULL,
	PRIMARY KEY (`id`),
	INDEX `alias_FI_1` (`domain_id`),
	CONSTRAINT `alias_FK_1`
		FOREIGN KEY (`domain_id`)
		REFERENCES `domain` (`id`)
		ON DELETE CASCADE,
	UNIQUE KEY `unique_alias` (`domain_id`, `aliasname`)
)Engine=InnoDB DEFAULT CHARSET=utf8;

#-----------------------------------------------------------------------------
#-- alias_additional_target
#-----------------------------------------------------------------------------

DROP TABLE IF EXISTS `alias_target`;


CREATE TABLE `alias_target`
(
	`id` INTEGER  NOT NULL AUTO_INCREMENT,
	`alias_id` INTEGER  NOT NULL,
	`target` VARCHAR(512)  NOT NULL,
	PRIMARY KEY (`id`),
	INDEX `alias_target_FI_1` (`alias_id`),
	CONSTRAINT `alias_target_FK_1`
		FOREIGN KEY (`alias_id`)
		REFERENCES `alias` (`id`)
		ON DELETE CASCADE
)Engine=InnoDB DEFAULT CHARSET=utf8;

#-----------------------------------------------------------------------------
#-- sender_watch
#-----------------------------------------------------------------------------

DROP TABLE IF EXISTS `sender_watch`;


CREATE TABLE `sender_watch`
(
	`id` INTEGER  NOT NULL AUTO_INCREMENT,
	`sender_address` VARCHAR(512) NOT NULL,
	`target` VARCHAR(512) NOT NULL,
	`enabled` INTEGER default 1 NOT NULL,
	PRIMARY KEY (`id`),
	INDEX `sender_watch_sender_address` (`sender_address`)
)Engine=InnoDB DEFAULT CHARSET=utf8;


# This restores the fkey checks, after having unset them earlier
SET FOREIGN_KEY_CHECKS = 1;
