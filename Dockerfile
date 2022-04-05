FROM tomcat:8.0.20-jre8
EXPOSE 8080
WORKDIR /app
RUN mkdir -p /app
COPY app/multi3/target/multi3*.war /usr/local/tomcat/webapps/maven-web-application.war