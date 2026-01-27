# Deployment-Repository

This repository contains the deployment scripts and configuration to deploy the following services:
- sita-backend
- sita-frontend

If you want to deploy the services, you have to adjust the `docker-compose.yaml` file to your needs.
The file contains the configuration for the services and their dependencies like environment 
variables or secrets. 
Each stage has its own configuration which resides in the stage folder (currently: prod and dev).
Deployment uses a single script that deploys every directory that contains a `docker-compose.yaml`.
Each stack name matches the directory name.

In most cases you only have to change the image tag to your needs.

### Deploy
- Deploy all stacks (one per directory): `go run deploy.go`
- Deploy specific stacks by directory name: `go run deploy.go dev prod`

### Workflow
1. Create a new branch for your changes.
2. Make your changes and commit them with a descriptive message.
3. Push your changes to the remote repository.
4. Create a pull request to merge your changes into the main branch.
5. Merge the pull request after review and approval (**approval is only necessary for prod changes**).
6. Changes on the main branch will be automatically deployed to meet the given configuration.
