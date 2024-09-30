# Data API Builder Azure Deployment

This repository contains scripts and configuration files for deploying a Data API Builder instance on Azure App Service with SQL Server and Azure Storage integration.

# Why App service for Containers?

As of September 2024, the database connection for Azure Static Web Apps is still in [preview](https://learn.microsoft.com/en-us/azure/static-web-apps/database-overview), which made it unfit for my use case. So I developed this script.

However, I also recommend considering [Azure Container Apps](https://learn.microsoft.com/en-us/azure/data-api-builder/tutorial-deploy-container-app-cli), which I prefer as a more scalable and robust solution.

## What is Data API Builder?

Data API Builder (DAB) is a powerful, cross-platform tool that simplifies the creation of APIs for database operations. It replaces custom CRUD APIs with a zero-code, configuration-based approach. Key features include:

- Support for multiple backend data sources (SQL Server, Azure SQL, Cosmos DB, PostgreSQL, MySQL)
- Automatic generation of REST and GraphQL endpoints
- Native OpenAPI and Swagger support
- Flexible security with EasyAuth, Microsoft Entra Identity, or custom JWT servers
- Seamless integration with Azure services (Static Web Apps, Container Apps, etc.)
- Granular security controls and policy engine
- In-memory caching and OData-like query support for REST endpoints
- Nested Create statements within single transactions for GraphQL

DAB significantly reduces codebase size, eliminates many unit tests, shortens CI/CD pipelines, and introduces advanced capabilities typically reserved for large development teams. It's designed to be simple, scalable, and observable, making it an excellent choice for developers looking to streamline their API development process.

## Files in this Repository

- `dab-config.json`: Configuration file for Data API Builder
- `runScript.ps1`: Main PowerShell script for deploying resources
- `upload-config.ps1`: Script for uploading the config file to Azure Blob Storage
- `createTable.ps1`: Script for creating tables in the SQL database
- `AppServiceDataApiBuilder.bicep`: Bicep template for Azure resource deployment

## Prerequisites

- Azure CLI
- PowerShell (version 5.1 or later)
- An active Azure subscription

## Usage

1. Ensure you have Azure CLI and PowerShell installed on your system.

2. Clone this repository and navigate to the directory:
   ```
   git clone https://github.com/JuanMeeske/AppServiceForContainers-DAB.git
   cd AppServiceForContainers-DAB
   ```

3. Log in to your Azure account:
   ```
   az login
   ```

4. Set the context to the subscription you want to use:
   ```
   az account set --subscription "Your-Subscription-Name-or-ID"
   ```

5. Run the deployment script:
   ```
   ./runScript.ps1
   ```

This script will create the necessary Azure resources and deploy the Data API Builder.

Post deployment the script wil try to reach the deployed API. This takes a while because the App Service for Containers needs to start, and this takes some time.
You will see something that looks like:

```
Attempting to reach the API at http://mydabapi-uksouth-wjbf123.azurewebsites.net/swagger for 5 minutes...
Failed to reach the API at 09:20:11. Retrying...
Failed to reach the API at 09:20:41. Retrying...
Failed to reach the API at 09:21:11. Retrying...
Successfully reached the API at 09:21:39      
```

## Deployment Process

The `runScript.ps1` script performs the following actions:
1. Creates a resource group
2. Deploys Azure resources using the Bicep template
3. Creates database tables
4. Uploads the Data API Builder configuration to Azure Blob Storage

## What This Deployment Creates

- Azure App Service with Data API Builder container
- Azure SQL Server and Database
- Azure Storage Account
- Virtual Network with proper configurations

## Configuration

The `dab-config.json` file defines the Data API Builder configuration, including database connection, REST and GraphQL endpoints, and entity definitions.

## Documentation and Resources

For comprehensive information on Data API Builder, refer to the official Microsoft documentation:

- [Data API Builder Overview](https://learn.microsoft.com/en-us/azure/data-api-builder/overview)
- [Quickstart: Create and query a REST API](https://learn.microsoft.com/en-us/azure/data-api-builder/quickstart-rest-api)
- [Quickstart: Create and query a GraphQL API](https://learn.microsoft.com/en-us/azure/data-api-builder/quickstart-graphql-api)
- [Data API Builder CLI reference](https://learn.microsoft.com/en-us/azure/data-api-builder/cli-reference)
- [Configuration file reference](https://learn.microsoft.com/en-us/azure/data-api-builder/configuration-file)
- [REST API reference](https://learn.microsoft.com/en-us/azure/data-api-builder/rest-api-reference)
- [GraphQL API reference](https://learn.microsoft.com/en-us/azure/data-api-builder/graphql-api-reference)
- [Security and authentication](https://learn.microsoft.com/en-us/azure/data-api-builder/authentication-authorization)



## Contributing

Feel free to submit issues or pull requests if you have suggestions for improvements or encounter any problems.
For additional resources, tutorials, and best practices, my website [jmsk.io](https://jmsk.io).

## License

MIT License
