-- MySQL Script generated by MySQL Workbench
-- Sun Apr 11 01:42:22 2021
-- Model: New Model    Version: 1.0
-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `mydb` DEFAULT CHARACTER SET utf8 ;
USE `mydb` ;

-- -----------------------------------------------------
-- Table `mydb`.`lenses`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`lenses` (
  `id_lenses` INT NOT NULL COMMENT 'This is the main database with objects on the sky (can be included to have mocks with exactly the same associations). This should have only observational data (e.g. image separation instead of Einstein radius since that would require an instance in the model table).	\n',
  `ra` FLOAT NOT NULL,
  `dec` FLOAT NOT NULL,
  `name` VARCHAR(45) NOT NULL,
  `image_sep` FLOAT NULL,
  `z_source` FLOAT NULL,
  `z_lens` FLOAT NULL,
  `lens_type` SET('GAL', 'GROUP', 'CLUSTER', 'AGN') NULL,
  `source_type` SET('GAL', 'QSO', 'GW', 'FRB', 'GRB', 'SN') NOT NULL,
  `flag_confirmed` TINYINT NOT NULL DEFAULT 0,
  `flag_contaminant` TINYINT NOT NULL DEFAULT 0,
  `alt_name` VARCHAR(150) NULL,
  `owner` INT NULL COMMENT 'Same as idusers',
  `access_level` TINYINT NULL,
  `submitted_at` DATETIME NULL,
  `last_modified` DATETIME NULL,
  `info` TEXT NULL,
  `image_config` ENUM("CUSP", "FOLD", "CROSS", "DOUBLE", "RING", "ARCS") NULL,
  PRIMARY KEY (`id_lenses`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`papers`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`papers` (
  `id_papers` INT NOT NULL COMMENT 'Papers table with associations to lenses and methods',
  `bibcode` VARCHAR(19) NULL,
  `authors` VARCHAR(200) NULL,
  `title` VARCHAR(200) NULL,
  `discovery_paper` TINYINT NULL,
  `pubdate_year` INT NULL,
  PRIMARY KEY (`id_papers`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`sdss_phot`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`sdss_phot` (
  `id_lenses` INT NOT NULL COMMENT 'Example catalogue, generally will be an external catalogue cross-matched to the lens. Is separate from the imaging data since that is linked with models. 	',
  `u` FLOAT NULL,
  `u_err` FLOAT NULL,
  `g` FLOAT NULL,
  `g_err` FLOAT NULL,
  `r` FLOAT NULL,
  `r_err` FLOAT NULL,
  `i` FLOAT NULL,
  `i_err` FLOAT NULL,
  `z` FLOAT NULL,
  `z_err` FLOAT NULL)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`finders`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`finders` (
  `id_finders` INT NOT NULL COMMENT 'Lens finding methods to be associated possibly with papers and lenses via many-to-many.',
  `name` VARCHAR(100) NOT NULL COMMENT 'This table describes the lens finding methods that can have many-to-many associations with papers and/or lenses.	',
  `description` TEXT NOT NULL,
  `owner` INT NULL,
  `submitted_at` DATETIME NULL,
  `findmethodtypes` ENUM('Visual Inspection', 'NN', 'SVM', 'Serendipity', 'Multiband', 'Single band', 'Emission lines', 'Citizen Science', 'Gaia') NULL,
  PRIMARY KEY (`id_finders`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`users`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`users` (
  `id_users` INT NOT NULL COMMENT 'Users table, perhaps need more metadata?',
  `username` VARCHAR(45) NULL,
  `firstname` VARCHAR(45) NULL,
  `lastname` VARCHAR(45) NULL,
  `email` VARCHAR(45) NULL,
  `password` VARCHAR(45) NULL,
  `group_ids` TEXT NULL,
  PRIMARY KEY (`id_users`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`panstarrs_phot`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`panstarrs_phot` (
  `id_lenses` INT NOT NULL COMMENT 'Example catalogue, generally will be an external catalogue cross-matched to the lens. Is separate from the imaging data since that is linked with models. 		',
  `g` FLOAT NULL,
  `g_err` FLOAT NULL,
  `r` FLOAT NULL,
  `r_err` FLOAT NULL,
  `i` FLOAT NULL,
  `i_err` FLOAT NULL,
  `z` FLOAT NULL,
  `z_err` FLOAT NULL,
  `y` FLOAT NULL,
  `y_err` FLOAT NULL)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`scores`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`scores` (
  `id_scores` INT NOT NULL,
  `id_finders` INT NOT NULL COMMENT 'This is where the methods are given a score for a lens (method can be extended to visual inspection and be given a score).',
  `id_lenses` INT NOT NULL,
  `score` FLOAT NULL,
  `owner` INT NULL,
  `submitted_at` DATETIME NULL,
  INDEX `fk_methods_has_lenses_lenses1_idx` (`id_lenses` ASC) VISIBLE,
  INDEX `fk_methods_has_lenses_methods1_idx` (`id_finders` ASC) VISIBLE,
  PRIMARY KEY (`id_scores`),
  CONSTRAINT `fk_methods_has_lenses_methods1`
    FOREIGN KEY (`id_finders`)
    REFERENCES `mydb`.`finders` (`id_finders`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_methods_has_lenses_lenses1`
    FOREIGN KEY (`id_lenses`)
    REFERENCES `mydb`.`lenses` (`id_lenses`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`papers_lenses`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`papers_lenses` (
  `id_lenses` INT NOT NULL,
  `id_papers` INT NOT NULL,
  PRIMARY KEY (`id_lenses`, `id_papers`),
  INDEX `fk_lenses_has_papers_papers1_idx` (`id_papers` ASC) VISIBLE,
  INDEX `fk_lenses_has_papers_lenses1_idx` (`id_lenses` ASC) VISIBLE,
  CONSTRAINT `fk_lenses_has_papers_lenses1`
    FOREIGN KEY (`id_lenses`)
    REFERENCES `mydb`.`lenses` (`id_lenses`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_lenses_has_papers_papers1`
    FOREIGN KEY (`id_papers`)
    REFERENCES `mydb`.`papers` (`id_papers`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`papers_finders`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`papers_finders` (
  `id_papers` INT NOT NULL,
  `id_finders` INT NOT NULL,
  PRIMARY KEY (`id_papers`, `id_finders`),
  INDEX `fk_papers_has_methods_methods1_idx` (`id_finders` ASC) VISIBLE,
  INDEX `fk_papers_has_methods_papers1_idx` (`id_papers` ASC) VISIBLE,
  CONSTRAINT `fk_papers_has_methods_papers1`
    FOREIGN KEY (`id_papers`)
    REFERENCES `mydb`.`papers` (`id_papers`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_papers_has_methods_methods1`
    FOREIGN KEY (`id_finders`)
    REFERENCES `mydb`.`finders` (`id_finders`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`collections`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`collections` (
  `id_collections` INT NOT NULL,
  `object_type` VARCHAR(45) NOT NULL,
  `object_ids` TEXT NULL COMMENT 'csv of id_lenses 	',
  `owner` INT NULL COMMENT 'User id 	',
  `name` VARCHAR(45) NULL,
  `access_level` TINYINT NULL,
  PRIMARY KEY (`id_collections`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`groups`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`groups` (
  `id_groups` INT NOT NULL,
  `user_ids` TEXT NULL,
  `groupname` VARCHAR(45) NULL,
  `owner` INT NULL,
  PRIMARY KEY (`id_groups`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`model_methods`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`model_methods` (
  `id_model_methods` INT NOT NULL,
  `name` VARCHAR(100) NULL,
  `description` TEXT NULL,
  `owner` INT NULL,
  `submitted_at` DATETIME NULL,
  PRIMARY KEY (`id_model_methods`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`models`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`models` (
  `id_models` INT NOT NULL,
  `id_lenses` INT NOT NULL,
  `id_model_methods` INT NOT NULL,
  `owner` INT NULL,
  `submitted_at` DATETIME NULL,
  `einstein_radius` FLOAT NULL,
  `mass_model` SET('SIE', 'SPEMD', 'external_shear', 'NFW', 'free_form') NULL,
  `mass_sheet` TINYINT NULL,
  `multiplane` TINYINT NULL,
  `source_reconstruction` SET('analytic', 'pixellated', 'wavelets', 'shapelets') NULL,
  PRIMARY KEY (`id_models`),
  INDEX `fk_model_methods_has_lenses_lenses1_idx` (`id_lenses` ASC) VISIBLE,
  CONSTRAINT `fk_model_methods_has_lenses_model_methods1`
    FOREIGN KEY (`id_models`)
    REFERENCES `mydb`.`model_methods` (`id_model_methods`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_model_methods_has_lenses_lenses1`
    FOREIGN KEY (`id_lenses`)
    REFERENCES `mydb`.`lenses` (`id_lenses`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`futuredata`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`futuredata` (
  `id_futuredata` INT NOT NULL,
  `owner` INT NULL,
  `description` TEXT NULL,
  `completion_date` DATETIME NULL,
  `status` VARCHAR(45) NULL,
  PRIMARY KEY (`id_futuredata`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`lenses_futuredata`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`lenses_futuredata` (
  `id_lenses` INT NOT NULL,
  `id_future_data` INT NOT NULL,
  PRIMARY KEY (`id_lenses`, `id_future_data`),
  INDEX `fk_future_data_has_lenses_lenses1_idx` (`id_future_data` ASC) VISIBLE,
  INDEX `fk_future_data_has_lenses_future_data1_idx` (`id_lenses` ASC) VISIBLE,
  CONSTRAINT `fk_future_data_has_lenses_future_data1`
    FOREIGN KEY (`id_lenses`)
    REFERENCES `mydb`.`futuredata` (`id_futuredata`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_future_data_has_lenses_lenses1`
    FOREIGN KEY (`id_future_data`)
    REFERENCES `mydb`.`lenses` (`id_lenses`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`data_summary`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`data_summary` (
  `id_lenses` INT NOT NULL,
  `sdss_phot` TINYINT NULL,
  `panstarrs_phot` TINYINT NULL,
  `des_pixels` TINYINT NULL,
  `panstarrs_pixels` TINYINT NULL,
  `sdss_spectrum` TINYINT NULL,
  `HST` TINYINT NULL,
  PRIMARY KEY (`id_lenses`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`access`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`access` (
  `object_type` VARCHAR(45) NOT NULL,
  `object_id` INT NOT NULL,
  `user_or_group` TINYINT NOT NULL,
  `user_id` INT NOT NULL,
  PRIMARY KEY (`object_type`, `object_id`, `user_or_group`, `user_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`papers_models`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`papers_models` (
  `id_papers` INT NOT NULL,
  `id_models` INT NOT NULL,
  PRIMARY KEY (`id_papers`, `id_models`),
  INDEX `fk_papers_has_models_models1_idx` (`id_models` ASC) VISIBLE,
  INDEX `fk_papers_has_models_papers1_idx` (`id_papers` ASC) VISIBLE,
  CONSTRAINT `fk_papers_has_models_papers1`
    FOREIGN KEY (`id_papers`)
    REFERENCES `mydb`.`papers` (`id_papers`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_papers_has_models_models1`
    FOREIGN KEY (`id_models`)
    REFERENCES `mydb`.`models` (`id_models`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;