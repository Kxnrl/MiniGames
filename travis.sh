#!/bin/bash

FTP_HOST=$2
FTP_USER=$3
FTP_PSWD=$4

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
FILE=MiniGames-git$COUNT-$5.7z

echo " "
echo "*** Trigger build ***"
echo " "
wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

chmod +x addons/sourcemod/scripting/spcomp

for file in SourcePawn/include/shop.inc
do
  sed -i "s%<commit_counts>%$COUNT%g" $file > output.txt
  rm output.txt
done

mkdir build
mkdir build/plugins
mkdir build/scripts

cp -rf MiniGames     addons/sourcemod/scripting
cp -rf MiniGames.sp  addons/sourcemod/scripting

addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/MiniGames.sp -o"build/plugins/MiniGames.smx"

mv LICENSE build
mv MiniGames     build/scripts
mv MiniGames.sp  build/scripts

cd build
7z a $FILE -t7z -mx9 LICENSE plugins scripts >nul

echo -e "Upload file ..."
lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /MiniGames/$1/ $FILE"

echo "Upload RAW..."
cd plugins
lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /MiniGames/Raw/ MiniGames.smx"