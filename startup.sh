#!/bin/sh
pkill java
rm /home/webapp-0.0.1-SNAPSHOT.jar
java -jar /home/webapp/simplepools-webapp/target/webapp-0.0.1-SNAPSHOT.jar org.simplepools.webapp.WebappApplication > /home/webapp/logs/logs.txt 2> /home/webapp/logs/error.txt &
echo "Server successfully restarted. Version 2."
