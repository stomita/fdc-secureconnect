DROP TABLE IF EXISTS billing;

CREATE TABLE billing (
  id int not null auto_increment,
  opp_id varchar(18) default NULL,
  name varchar(10) default NULL,
  amount decimal(12,0) default NULL,
  close_date varchar(50) default NULL,
  PRIMARY KEY (id)
);

