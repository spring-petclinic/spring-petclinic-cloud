CREATE DATABASE IF NOT EXISTS service_instance_db;

USE service_instance_db;

CREATE TABLE IF NOT EXISTS visits (
  id INT(4) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  pet_id INT(4) UNSIGNED NOT NULL,
  visit_date DATE,
  description VARCHAR(8192)
  -- FOREIGN KEY (pet_id) REFERENCES pets(id)
) engine=InnoDB;
