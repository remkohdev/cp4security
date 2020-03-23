
-- --------------------------------------------------------

--
-- Table structure for table `wp_itsec_opaque_tokens`
--

DROP TABLE IF EXISTS `wp_itsec_opaque_tokens`;
CREATE TABLE IF NOT EXISTS `wp_itsec_opaque_tokens` (
  `token_id` char(64) COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `token_hashed` char(64) COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `token_type` varchar(32) COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `token_data` text COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `token_created_at` datetime NOT NULL,
  PRIMARY KEY (`token_id`),
  UNIQUE KEY `token_hashed` (`token_hashed`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

--
-- Truncate table before insert `wp_itsec_opaque_tokens`
--

TRUNCATE TABLE `wp_itsec_opaque_tokens`;