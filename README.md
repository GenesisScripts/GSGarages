GS Garages offer a better way to RP with more risk of owning vehicles such as cop raids and just a clean and unique overhall of ESX Garages a V2 May be released but not in the near feature. 

Preview : https://streamable.com/s6dp7h

Features
- Cop Raids
- Vehicle Insurenace 
- Clean garage menu that shows you stats about your cars 

Dependancys 
- OX Lib 
- ESX 

My Discord : https://discord.gg/UQYvu52By9

----------------SQL ----------------------
CREATE TABLE IF NOT EXISTS `owned_vehicles` (
  `owner` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `plate` varchar(12) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vehicle` longtext COLLATE utf8mb4_unicode_ci,
  `type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'car',
  `stored` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;