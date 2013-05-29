CREATE TABLE alias (
  id INT AUTO_INCREMENT NOT NULL,
  domain_id INT DEFAULT NULL,
  aliasname VARCHAR(255) NOT NULL,
  enabled TINYINT(1) NOT NULL,
  INDEX IDX_E16C6B94115F0EE5 (domain_id),
  INDEX enabled_index (enabled),
  UNIQUE INDEX aliasname_unique (domain_id, aliasname),
  PRIMARY KEY(id)
) DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ENGINE = InnoDB;

CREATE TABLE user (
  id INT AUTO_INCREMENT NOT NULL,
  domain_id INT DEFAULT NULL,
  username VARCHAR(255) NOT NULL,
  password VARCHAR(64) NOT NULL,
  enabled TINYINT(1) NOT NULL,
  has_mailbox TINYINT(1) NOT NULL,
  INDEX IDX_8D93D649115F0EE5 (domain_id),
  INDEX enabled_index (enabled),
  UNIQUE INDEX username_unique (domain_id, username),
  PRIMARY KEY(id)
) DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ENGINE = InnoDB;

CREATE TABLE alias_target (
  id INT AUTO_INCREMENT NOT NULL,
  alias_id INT DEFAULT NULL,
  target VARCHAR(255) NOT NULL,
  INDEX IDX_F4E9D9D85E564AE2 (alias_id),
  UNIQUE INDEX alias_target_unique (alias_id, target),
  PRIMARY KEY(id)
) DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ENGINE = InnoDB;

CREATE TABLE sender_watch (
  id INT AUTO_INCREMENT NOT NULL,
  sender_address VARCHAR(255) NOT NULL,
  target VARCHAR(255) NOT NULL, enabled TINYINT(1) NOT NULL,
  INDEX sender_address_index (sender_address),
  INDEX enabled_index (enabled),
  UNIQUE INDEX send_watch_unique (sender_address, target),
  PRIMARY KEY(id)
) DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ENGINE = InnoDB;

CREATE TABLE domain (
  id INT AUTO_INCREMENT NOT NULL,
  name VARCHAR(255) NOT NULL,
  UNIQUE INDEX UNIQ_A7A91E0B5E237E06 (name),
  PRIMARY KEY(id)
) DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ENGINE = InnoDB;

ALTER TABLE alias ADD CONSTRAINT FK_E16C6B94115F0EE5 FOREIGN KEY (domain_id) REFERENCES domain (id) ON DELETE CASCADE;
ALTER TABLE user ADD CONSTRAINT FK_8D93D649115F0EE5 FOREIGN KEY (domain_id) REFERENCES domain (id) ON DELETE CASCADE;
ALTER TABLE alias_target ADD CONSTRAINT FK_F4E9D9D85E564AE2 FOREIGN KEY (alias_id) REFERENCES alias (id) ON DELETE CASCADE;


