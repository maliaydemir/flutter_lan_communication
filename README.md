
# Flutter LAN Communication

LAN üzerinden UDP Broadcast ve basit birer HTTP server ile mesajlaşma uygulaması.

### UDP Broadcast
Mesajların x.x.x.255 üzerinden yerel ağa bağlı tüm cihazlara gönderilmesini sağlamak için kullanıldı.

### HTTP server
Sesli mesaj gönderiminde UDP protokolünün maksimum gönderim sınırı aşıldığından dolayı cihazlar UDP üzerinden sesli mesaj olduğuna dair haberdar edilir. Her cihaz sesli mesaj gönderen cihaza ait IP adresi sayesinde mevcut ses dosyasına erişir. Diğer cihazların gönderilen ses dosyasına erişmesi için gönderici tarafında bir HTTP Server çalışır durumda bulunmaktadır.
