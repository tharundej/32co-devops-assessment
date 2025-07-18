I set up a GitHub Actions pipeline to automate building, testing, and deploying the Flask application.

Build: Creates a Docker image of the app.
Test: Runs unit tests using pytest.
Deploy: Pushes the image to ECR, updates the Terraform launch template with the new image tag, and refreshes the ASG.