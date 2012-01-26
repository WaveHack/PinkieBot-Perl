CREATE TABLE `activity` (
  `id` int(1) NOT NULL AUTO_INCREMENT,
  `type` varchar(255) DEFAULT NULL,
  `timestamp` int(1) NOT NULL,
  `who` varchar(255) DEFAULT NULL,
  `raw_nick` varchar(255) DEFAULT NULL,
  `channel` varchar(255) DEFAULT NULL,
  `body` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

CREATE TABLE `karma` (
  `name` varchar(255) NOT NULL,
  `karma` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
