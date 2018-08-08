#!/bin/bash

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
FILE=MiniGames-git$COUNT-$2.7z

echo " "
echo "*** Trigger build ***"
echo " "
wget "https://github.com/Kxnrl/Store/raw/master/include/store.inc" -q -O include/store.inc
wget "https://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

chmod +x addons/sourcemod/scripting/spcomp

for file in include/minigames.inc
do
  sed -i "s%<commit_counts>%$COUNT%g" $file > output.txt
  rm output.txt
done

mkdir build
mkdir build/plugins
mkdir build/scripting

cp -rf include/*            addons/sourcemod/scripting/include
cp -rf minigames            addons/sourcemod/scripting
cp -rf MiniGames.sp         addons/sourcemod/scripting
cp -rf inputkill_hotfix     addons/sourcemod/scripting

addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/MiniGames.sp -o"build/plugins/MiniGames.smx"
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/inputkill_hotfix.sp -o"build/plugins/inputkill_hotfix.smx"

if [ ! -f "build/plugins/MiniGames.smx" ]; then
    echo "Compile failed!"
    exit 1;
fi

if [ ! -f "build/plugins/inputkill_hotfix.smx" ]; then
    echo "Compile failed!"
    exit 1;
fi


mv LICENSE build
mv include              build/scripting
mv minigames            build/scripting
mv MiniGames.sp         build/scripting
mv inputkill_hotfix.sp  build/scripting
mv translations         build

cd build
7z a $FILE -t7z -mx9 LICENSE plugins scripting translations >nul

echo -e "Upload file RSYNC ..."
RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./$FILE $RSYNC_USER@$RSYNC_HOST::TravisCI/MiniGames/$1/

if [ "$1" = "1.9" ]; then
echo "Upload RAW RSYNC ..."
RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./plugins/MiniGames.smx $RSYNC_USER@$RSYNC_HOST::TravisCI/_Raw/
RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./translations/com.kxnrl.minigames.translations.txt $RSYNC_USER@$RSYNC_HOST::TravisCI/_Raw/translations/
fi
