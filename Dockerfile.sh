################################
#
# PowerDNS V3.4
# MySQL
# PowerAdmin 2.17
#
# VERSION V1.0.0
#
#################################

FROM centos:centos6

## Install repo
RUN rpm -ihv https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm


## Install MySQL and PHP
RUN yum -y install php php-mcrypt php-pdo php-mysql mysql-server httpd

RUN service mysqld start
RUN service httpd start
RUN chkconfig mysqld on
RUN chkconfig httpd on

RUN mysqladmin create powerdns
RUN mysql -Bse "create user 'powerdns'@'localhost' identified by 'pass1234'"
RUN mysql -Bse "grant all privileges on powerdns.* to 'powerdns'@'localhost'"

RUN mysql -uroot -ppass1234 << EOF
use powerdns
CREATE TABLE domains (
  id                    INT AUTO_INCREMENT,
  name                  VARCHAR(255) NOT NULL,
  master                VARCHAR(128) DEFAULT NULL,
  last_check            INT DEFAULT NULL,
  type                  VARCHAR(6) NOT NULL,
  notified_serial       INT DEFAULT NULL,
  account               VARCHAR(40) DEFAULT NULL,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE UNIQUE INDEX name_index ON domains(name);


CREATE TABLE records (
  id                    INT AUTO_INCREMENT,
  domain_id             INT DEFAULT NULL,
  name                  VARCHAR(255) DEFAULT NULL,
  type                  VARCHAR(10) DEFAULT NULL,
  content               VARCHAR(64000) DEFAULT NULL,
  ttl                   INT DEFAULT NULL,
  prio                  INT DEFAULT NULL,
  change_date           INT DEFAULT NULL,
  disabled              TINYINT(1) DEFAULT 0,
  ordername             VARCHAR(255) BINARY DEFAULT NULL,
  auth                  TINYINT(1) DEFAULT 1,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE INDEX nametype_index ON records(name,type);
CREATE INDEX domain_id ON records(domain_id);
CREATE INDEX recordorder ON records (domain_id, ordername);


CREATE TABLE supermasters (
  ip                    VARCHAR(64) NOT NULL,
  nameserver            VARCHAR(255) NOT NULL,
  account               VARCHAR(40) DEFAULT NULL,
  PRIMARY KEY (ip, nameserver)
) Engine=InnoDB;


CREATE TABLE comments (
  id                    INT AUTO_INCREMENT,
  domain_id             INT NOT NULL,
  name                  VARCHAR(255) NOT NULL,
  type                  VARCHAR(10) NOT NULL,
  modified_at           INT NOT NULL,
  account               VARCHAR(40) NOT NULL,
  comment               VARCHAR(64000) NOT NULL,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE INDEX comments_domain_id_idx ON comments (domain_id);
CREATE INDEX comments_name_type_idx ON comments (name, type);
CREATE INDEX comments_order_idx ON comments (domain_id, modified_at);


CREATE TABLE domainmetadata (
  id                    INT AUTO_INCREMENT,
  domain_id             INT NOT NULL,
  kind                  VARCHAR(16),
  content               TEXT,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE INDEX domainmetaidindex ON domainmetadata(domain_id);


CREATE TABLE cryptokeys (
  id                    INT AUTO_INCREMENT,
  domain_id             INT NOT NULL,
  flags                 INT NOT NULL,
  active                BOOL,
  content               TEXT,
  PRIMARY KEY(id)
) Engine=InnoDB;

CREATE INDEX domainidindex ON cryptokeys(domain_id);


CREATE TABLE tsigkeys (
  id                    INT AUTO_INCREMENT,
  name                  VARCHAR(255),
  algorithm             VARCHAR(50),
  secret                VARCHAR(255),
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE UNIQUE INDEX namealgoindex ON tsigkeys(name, algorithm);

exit

EOF


RUN yum install -y wget unzip

RUN mkdir /root/pkgs
RUN cd /root/pkgs
RUN wget https://autotest.powerdns.com/job/auth-git-semistatic-rpm-amd64/lastSuccessfulBuild/artifact/pdns-static-0.0.20140713_4945_b02dfdb-1.x86_64.rpm
RUN wget https://autotest.powerdns.com/job/auth-git-semistatic-rpm-amd64/lastSuccessfulBuild/artifact/pdns-tools-0.0.20140713_4945_b02dfdb-1.x86_64.rpm
RUN rpm -ihv *.rpm

RUN groupadd pdns
RUN useradd -g pdns pdns -m

## Change pdns configuration /etc/powerdns/pdns.conf

#RUN service pdns start
#RUN chkconfig pdns on

## Install poweradmin
cd /var/www/html/
wget https://github.com/poweradmin/poweradmin/archive/v2.1.7.zip
unzip v2.1.7.zip
mv poweradmin-2.1.7 poweradmin

EXPOSE 53/udp 53/tcp 80 8081
ENTRYPOINT service pdns start

