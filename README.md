# Deployment-Repository

This repository contains the deployment scripts and configuration to deploy the following services:
- sita-backend
- sita-frontend

If you want to deploy the services, you have to adjust the `docker-compose.yaml` file to your needs.
The file contains the configuration for the services and their dependencies like environment 
variables or secrets. 
Each stage has its own configuration which resides in the stage folder (currently: prod and dev).
- For dev deployment, use the [`docker-compose.yml`](dev/docker-compose.yaml) in the [`dev`](dev) directory.
- (Coming soon) For production, use the `docker-compose.yaml` in the `prod` directory.

In most cases you only have to change the image tag to your needs.

### Workflow
1. Create a new branch for your changes.
2. Make your changes and commit them with a descriptive message.
3. Push your changes to the remote repository.
4. Create a pull request to merge your changes into the main branch.
5. Merge the pull request after review and approval (**approval is only necessary for prod changes**).
6. Changes on the main branch will be automatically deployed to meet the given configuration.
