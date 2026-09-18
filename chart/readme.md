# test command 
helm template demo .\chart `
  --set replicaCount=3 `
  --set config.appName=test-app `
  --set config.version=9.9.9

  helm template demo .\chart `
  --set image.repository=my-image `
  --set image.tag=v2.0.0
  

  helm template demo .\chart `
  --set resources.requests.cpu=200m `
  --set resources.requests.memory=256Mi


  tree chart /F