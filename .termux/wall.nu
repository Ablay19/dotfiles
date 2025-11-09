#!/data/data/com.termux/files/usr/bin/nu
job spawn { termux-notification --title "Termux Boot" --content "Welcome!"}
job spawn {termux-wallpaper -u https://minimalistic-wallpaper.demolab.com/?random=1 }
job spawn { termux-wallpaper -l -u https://minimalistic-wallpaper.demolab.com/?random=2 }
job list | get pids | $in.0
