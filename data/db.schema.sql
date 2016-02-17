CREATE TABLE `records` (
	`id`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
	`host`	TEXT NOT NULL,
	`app`	TEXT NOT NULL,
	`time`	INTEGER NOT NULL,
	`received`	INTEGER NOT NULL,
	`key`	TEXT,
	`value`	INTEGER
);
CREATE UNIQUE INDEX `nodup` ON `records` (`host` ASC,`app` ASC,`time` ASC,`key` ASC,`value` ASC);
