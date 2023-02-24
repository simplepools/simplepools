#!/bin/sh
pkill java
java -jar /home/webapp/simplepools-webapp/target/webapp-0.0.1-SNAPSHOT.jar org.simplepools.webapp.WebappApplication > /home/webapp/logs/logs.txt 2> /home/webapp/logs/error.txt &
echo "Server successfully restarted. Version 3."
