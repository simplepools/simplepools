#!/bin/sh
pkill java
rm /home/webapp-0.0.1-SNAPSHOT.jar
cp /home/tmp/simplepools-webapp/target/webapp-0.0.1-SNAPSHOT.jar /home/webapp-0.0.1-SNAPSHOT.jar
java -jar /home/webapp-0.0.1-SNAPSHOT.jar org.simplepools.webapp.WebappApplication > /home/logs.txt 2> /home/error.txt &
echo "Server successfully restarted."
