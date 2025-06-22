LOCK TABLES `announcements` WRITE;
/*!40000 ALTER TABLE `announcements` DISABLE KEYS */;
INSERT INTO `announcements` VALUES
(6,'&lt;p style=&quot;font-size: large;background-color: yellow;&quot;&gt;This is a public demo of LibreBooking. Please do not enter personal or sensitive data.&lt;br&gt; The instance resets automatically every 20 minutes, including all bookings and settings.&lt;/a&gt;&lt;/p&gt;',3,NULL,NULL,1);
/*!40000 ALTER TABLE `announcements` ENABLE KEYS */;
UNLOCK TABLES;