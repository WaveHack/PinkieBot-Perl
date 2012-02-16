CREATE TABLE `auth` (
  `username` varchar(255) NOT NULL,
  `password` char(40) DEFAULT NULL,
  `level` int(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`username`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;