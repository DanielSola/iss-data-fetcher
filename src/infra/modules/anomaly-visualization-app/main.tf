resource "aws_amplify_app" "vite_app" {
  name       = "vite-app"
  repository = "https://github.com/DanielSola/iss-telemetry-anomaly-visualization" # Replace with your repo URL
  access_token = var.github_token # GitHub token for connecting repo

  build_spec = <<EOT
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm install
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: dist
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
EOT

  environment_variables = {
    NODE_ENV = "production"
    VITE_WEBSOCKET_URL = var.websocket_url
  }
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.vite_app.id
  branch_name = "main"
  framework   = "Web"
  stage       = "PRODUCTION"
  enable_auto_build = true
}