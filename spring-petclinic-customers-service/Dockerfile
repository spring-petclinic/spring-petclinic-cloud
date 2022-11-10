FROM openjdk:11.0.11-jdk-slim                           

COPY ./target/*.jar /app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
