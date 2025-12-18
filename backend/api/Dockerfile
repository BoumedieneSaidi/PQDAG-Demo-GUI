FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Install Docker CLI, Python3, OpenSSH client, and bash
RUN apk add --no-cache docker-cli python3 openssh-client bash

# Create SSH directory
RUN mkdir -p /root/.ssh

COPY --from=build /app/target/*.jar app.jar
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port
EXPOSE 8080

# Run the application
ENTRYPOINT ["/entrypoint.sh"]
