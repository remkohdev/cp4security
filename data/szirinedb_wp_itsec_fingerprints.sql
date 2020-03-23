
-- --------------------------------------------------------

--
-- Table structure for table `wp_itsec_fingerprints`
--

DROP TABLE IF EXISTS `wp_itsec_fingerprints`;
CREATE TABLE IF NOT EXISTS `wp_itsec_fingerprints` (
  `fingerprint_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `fingerprint_user` bigint(20) UNSIGNED NOT NULL,
  `fingerprint_hash` char(32) COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `fingerprint_created_at` datetime NOT NULL,
  `fingerprint_approved_at` datetime NOT NULL,
  `fingerprint_data` longtext COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `fingerprint_snapshot` longtext COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `fingerprint_last_seen` datetime NOT NULL,
  `fingerprint_uses` int(11) NOT NULL DEFAULT '0',
  `fingerprint_status` varchar(20) COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `fingerprint_uuid` char(36) COLLATE utf8mb4_unicode_520_ci NOT NULL,
  PRIMARY KEY (`fingerprint_id`),
  UNIQUE KEY `fingerprint_user__hash` (`fingerprint_user`,`fingerprint_hash`),
  UNIQUE KEY `fingerprint_uuid` (`fingerprint_uuid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

--
-- Truncate table before insert `wp_itsec_fingerprints`
--

TRUNCATE TABLE `wp_itsec_fingerprints`;