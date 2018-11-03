# Store
  
|Build Status|Download|
|---|---
|[![Build Status](https://img.shields.io/travis/Kxnrl/MiniGames/master.svg?style=flat-square)](https://travis-ci.org/Kxnrl/MiniGames?branch=master) |[![Download](https://static.kxnrl.com/images/web/buttons/download.png)](https://build.kxnrl.com/MiniGames/)  
  
  
CSGO game mode -> MiniGames for mg_ map.
  
  
### Features:
* Player stats/analytics.
* Ranking system.
* Scramble/Random team.
* VAC wallhack.
* AutoBhop.
* BHop speed limiter.
* Settings enforce.
* Weapon restrict.
* Auto fill reserve clip.
* Duck spam fix.
* Hit feedback HUD.
* Team flash punisher.
  
  
### Commands:
* **sm_mg** - Open main menu. [alias: ***sm_rank***/***sm_menu***/***buyammo2***]
* **sm_top** - Show ranking list. [alias: ***sm_rank***]
* **sm_stats** - Show player stats panel. 
* **sm_options** - Open options menu.

### How to install
* [Download](https://build.kxnrl.com/MiniGames/) latest build.
* Extract all files on disk.
* Upload to server following folders: 
  * plugins 
  * translations
* make sure your database.cfg **MySQL/MariaDB only** ( path: addons/sourcemod/configs/database.cfg )
``` keyvalues
"default"
{
    "driver"    "mysql" 
    "host"      "<HOSTNAME>"
    "database"  "<DATABASE>"
    "user"      "<USERNAME>"
    "pass"      "<PASSWORD>"
    "port"      "<PORT>"
}
```
* Start your server and check error logs.

#### Any other questions
* [Steam](https://steamcommunity.com/profiles/76561198048432253/)
* [Telegram](https://t.me/Kxnrl)
  
  
#### Donate
* [Steam Trade Offer](https://steamcommunity.com/tradeoffer/new/?partner=88166525&token=lszXBJeY)
* **AliPay**: h673321480[AT]163.com
* **Paypal**: 673321480[AT]qq.com
