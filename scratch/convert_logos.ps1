Add-Type -AssemblyName System.Drawing
$imgCust = [System.Drawing.Image]::FromFile("d:\trimly_final\trimly_customer_app_logo.jpeg")
$imgCust.Save("d:\trimly_final\apps\customer-app\assets\icon\icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$imgCust.Save("d:\trimly_final\apps\customer-app\assets\icon\icon_foreground.png", [System.Drawing.Imaging.ImageFormat]::Png)
$imgCust.Dispose()

$imgSalon = [System.Drawing.Image]::FromFile("d:\trimly_final\trimly_salon_app_logo.jpeg")
$imgSalon.Save("d:\trimly_final\apps\salon-app\assets\icon\icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$imgSalon.Save("d:\trimly_final\apps\salon-app\assets\icon\icon_foreground.png", [System.Drawing.Imaging.ImageFormat]::Png)
$imgSalon.Dispose()
write-host "Logos converted successfully!"
