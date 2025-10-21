-- Dolibarr Database Fixes and Initialization
-- This script ensures all required tables exist

-- Create user_extrafields table if missing
CREATE TABLE IF NOT EXISTS llx_user_extrafields (
  rowid int(11) NOT NULL AUTO_INCREMENT,
  tms timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  fk_object int(11) NOT NULL,
  PRIMARY KEY (rowid),
  KEY idx_user_extrafields (fk_object)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create user_rights table if missing
CREATE TABLE IF NOT EXISTS llx_user_rights (
  rowid int(11) NOT NULL AUTO_INCREMENT,
  entity int(11) NOT NULL DEFAULT 1,
  fk_user int(11) NOT NULL,
  fk_id int(11) NOT NULL,
  PRIMARY KEY (rowid),
  UNIQUE KEY uk_user_rights (entity,fk_user,fk_id),
  KEY fk_user_rights_fk_user_user (fk_user)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create webhook_target table if missing
CREATE TABLE IF NOT EXISTS llx_webhook_target (
  rowid int(11) NOT NULL AUTO_INCREMENT,
  entity int(11) NOT NULL DEFAULT 1,
  ref varchar(128) NOT NULL,
  label varchar(255) DEFAULT NULL,
  type smallint(6) NOT NULL DEFAULT 0,
  trigger_codes text DEFAULT NULL,
  url varchar(255) NOT NULL,
  description text DEFAULT NULL,
  note_public text DEFAULT NULL,
  note_private text DEFAULT NULL,
  date_creation datetime NOT NULL,
  tms timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  fk_user_creat int(11) NOT NULL,
  fk_user_modif int(11) DEFAULT NULL,
  import_key varchar(14) DEFAULT NULL,
  status smallint(6) NOT NULL,
  PRIMARY KEY (rowid),
  UNIQUE KEY uk_webhook_target_ref (ref,entity),
  KEY idx_webhook_target_rowid (rowid),
  KEY idx_webhook_target_ref (ref),
  KEY idx_webhook_target_entity (entity),
  KEY idx_webhook_target_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ensure admin user exists
INSERT IGNORE INTO llx_user (rowid, entity, login, pass_crypted, lastname, firstname, email, admin, statut, datec)
VALUES (1, 1, 'admin', '0192023a7bbd73250516f069df18b500', 'Administrator', 'Admin', 'admin@example.com', 1, 1, NOW());

-- Ensure admin user has extrafields record
INSERT IGNORE INTO llx_user_extrafields (fk_object) VALUES (1);

-- Grant all rights to admin user
INSERT IGNORE INTO llx_user_rights (entity, fk_user, fk_id) 
SELECT 1, 1, id FROM llx_rights_def WHERE perms IS NOT NULL;

-- Update admin user to ensure full privileges
UPDATE llx_user SET admin=1, employee=1, statut=1 WHERE login='admin';
