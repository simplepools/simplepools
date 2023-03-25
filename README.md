DeFi made simple.

- 🔭 I’m currently working on the Simple Pools website.
- 🤔 I’m looking for help with everything related to Simple Pools.
- 💬 Ask me about DeFi.
- 📫 Reach me at contact@simplepools.org

How to start developing:
Clone the repository. Build the front-end with `npm install` and then `ng build` from `simplepools-website-frontend` folder.
For frontend development use `./start-with-proxy.bat` (on windows) to start watching for changes and proxy server requests to the spring-boot app.
In another terminal run the server with: `mvnw spring-boot:run` from `simplepools-webapp` folder.
If you want to debug the Java server you can start with debug `org.simplepools.webapp.WebappApplication`.

On the server where the app is ran, we must have folders: `/home/webapp` and `/home/webapp/logs` with
write permissions for the USER (in security actions variables) in order for the autodeploy to work properly.
Also you have to allow the USER to start server on ports < 1024:
`sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/lib/jvm/java-17-openjdk-arm64/bin/java`

- https://simplepools.org