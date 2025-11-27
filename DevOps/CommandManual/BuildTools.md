# Build Tools

## maven
```bash
# determine file location
mvn -X clean | grep "settings"

# determini effective settings
mvn help:effective-settings

# override the default location
mvn clean --settings /tmp/my-settings.xml --global-settings /tmp/global-settings.xml

# package
mvn clean package -U -DskipTests

# deploy
mvn clean package deploy -U -DskipTests
```
