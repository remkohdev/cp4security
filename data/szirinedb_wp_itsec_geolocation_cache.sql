
-- --------------------------------------------------------

--
-- Table structure for table `wp_itsec_geolocation_cache`
--

DROP TABLE IF EXISTS `wp_itsec_geolocation_cache`;
CREATE TABLE IF NOT EXISTS `wp_itsec_geolocation_cache` (
  `location_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `location_host` varchar(40) COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `location_lat` decimal(10,8) NOT NULL,
  `location_long` decimal(11,8) NOT NULL,
  `location_label` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `location_credit` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `location_time` datetime NOT NULL,
  PRIMARY KEY (`location_id`),
  UNIQUE KEY `location_host` (`location_host`),
  KEY `location_time` (`location_time`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

--
-- Truncate table before insert `wp_itsec_geolocation_cache`
--

TRUNCATE TABLE `wp_itsec_geolocation_cache`;