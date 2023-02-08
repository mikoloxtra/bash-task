#!/bin/bash

# Set the website name from the command line argument
website_name=$1

# Create the Dockerfile, docker-compose.yml and Nginx virtual host folder
# ... (Same as the previous script)

# Add all files to the Git repository
git init
git add .
git commit -m "Initial commit"

# Push the repository to Github
git remote add origin https://github.com/${GITHUB_USERNAME}/$website.git
git push -u origin master

# Login to Heroku CLI
heroku container:login

# Deploy the Docker image to Heroku
heroku container:push web --app $website

# Release the image on Heroku
heroku container:release web --app $website
