-- ============================================================================
-- RSG SALOON PREMIUM - DATABASE SCHEMA
-- Run this SQL before starting the resource
-- ============================================================================

-- Saloon shop stock (public inventory for customers)
CREATE TABLE IF NOT EXISTS `saloon_premium_stock` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `saloon` VARCHAR(50) NOT NULL,
    `item` VARCHAR(50) NOT NULL,
    `quantity` INT DEFAULT 0,
    `price` DECIMAL(10,2) DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_stock` (`saloon`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Saloon private storage (crafted items before adding to shop)
CREATE TABLE IF NOT EXISTS `saloon_premium_storage` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `saloon` VARCHAR(50) NOT NULL,
    `item` VARCHAR(50) NOT NULL,
    `quantity` INT DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_storage` (`saloon`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Saloon cashbox (earnings from sales)
CREATE TABLE IF NOT EXISTS `saloon_premium_cashbox` (
    `saloon` VARCHAR(50) PRIMARY KEY,
    `balance` DECIMAL(15,2) DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Transaction history (detailed logs)
CREATE TABLE IF NOT EXISTS `saloon_premium_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `saloon` VARCHAR(50) NOT NULL,
    `type` ENUM('sale', 'withdraw', 'deposit', 'tip', 'refill', 'craft', 'storage_withdraw') NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `item` VARCHAR(50),
    `quantity` INT,
    `citizenid` VARCHAR(50),
    `player_name` VARCHAR(100),
    `timestamp` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_saloon` (`saloon`),
    INDEX `idx_type` (`type`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Employee statistics (optional performance tracking)
CREATE TABLE IF NOT EXISTS `saloon_premium_employees` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `saloon` VARCHAR(50) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `player_name` VARCHAR(100),
    `items_crafted` INT DEFAULT 0,
    `items_sold` INT DEFAULT 0,
    `sales_total` DECIMAL(15,2) DEFAULT 0,
    `tips_earned` DECIMAL(10,2) DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_employee` (`saloon`, `citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default cashbox entries for all saloons
INSERT IGNORE INTO `saloon_premium_cashbox` (`saloon`, `balance`) VALUES
('valsaloontender', 0),
('blasaloontender', 0),
('rhosaloontender', 0),
('stdenissaloontender1', 0),
('stdenissaloontender2', 0),
('vansaloontender', 0),
('armsaloontender', 0),
('tumsaloontender', 0);

-- ============================================================================
-- V2.0 ADDITIONS
-- ============================================================================

-- Customer bills / invoices
CREATE TABLE IF NOT EXISTS `saloon_premium_bills` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `saloon` VARCHAR(50) NOT NULL,
    `target_citizenid` VARCHAR(50) NOT NULL,
    `sender_citizenid` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `paid` BOOLEAN DEFAULT FALSE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_target` (`target_citizenid`),
    INDEX `idx_paid` (`paid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

