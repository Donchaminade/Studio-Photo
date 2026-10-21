-- À exécuter SUR le serveur Windows (MySQL local), UNIQUEMENT en secours
-- si vous ne pouvez pas redéployer le JAR (AdminUserInitializer crée admin@photopicon.com au boot).
--
-- Mot de passe en clair : AdminTest2026!
--
-- Usage (sur le serveur, dans un shell MySQL local) :
--   mysql -u piconroot -p photo_db < 4_creer_admin_sql.sql

USE photo_db;

SET @pwd := '$2a$10$oeSuaa.2ZDd64Md738fQDO8LYT/JhrYF5Gom0Ca5runxvuXRQbU3q';

INSERT INTO _user (firstname, lastname, email, password, role, status, phone, pin, created_at)
VALUES ('Admin', 'Picon', 'admin@photopicon.com', @pwd, 'ADMIN', 'ACTIVE', '0600000001', '0000', NOW())
ON DUPLICATE KEY UPDATE
  password = VALUES(password),
  role = 'ADMIN',
  status = 'ACTIVE';
