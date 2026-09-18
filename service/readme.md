$env:APP_NAME="enterprisebot"
$env:VERSION="1.2.3"
set env

# build command
docker build -t demo-service:local .

# run command
docker run --rm `
  --name demo-service `
  -p 8080:8080 `
  -e APP_NAME=enterprisebot `
  -e VERSION=1.0.0 `
  demo-service:local


  # non  root verify : ecpected 10001
  docker run --rm demo-service:local id