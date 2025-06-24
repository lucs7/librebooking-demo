LOCK TABLES `announcements` WRITE;
/*!40000 ALTER TABLE `announcements` DISABLE KEYS */;
INSERT INTO `announcements` VALUES
(1,'&lt;div class=&quot;alert alert-primary&quot;&gt;&lt;p&gt;&lt;strong&gt;This is a public demo of LibreBooking.&lt;/strong&gt;&lt;br&gt;Please do not enter personal or sensitive data.&lt;br&gt;The instance resets automatically every 20 minutes, including all bookings and settings.&lt;/p&gt;&lt;ul style=&quot;font-size: large; margin-top: 1em;&quot;&gt;&lt;li&gt;&lt;strong&gt;Admin Login:&lt;/strong&gt; &lt;code&gt;admin&lt;/code&gt; / &lt;code&gt;demoadmin&lt;/code&gt;&lt;/li&gt;&lt;li&gt;&lt;strong&gt;User Login:&lt;/strong&gt; &lt;code&gt;user&lt;/code&gt; / &lt;code&gt;demouser&lt;/code&gt;&lt;/li&gt;&lt;/ul&gt;&lt;/div&gt;',NULL,NULL,NULL,5);
/*!40000 ALTER TABLE `announcements` ENABLE KEYS */;
UNLOCK TABLES;