# Terraform Azure Private AI App Deployment Example

Deploy an Azure Function App with private connectivity to Azure OpenAI.

![Logical Architecture](/static/AzPrivateAIApp_example.drawio.png)

## Description

This project provides a Terraform template to deploy Azure resources that enable the use of Azure AI and compute services in a private, isolated environment with public access disabled.

## Requirements

This template serves as a starting point and may require additional steps to fully function in your environment.

- All public access to the deployed managed services is blocked. This includes the ability to deploy code to the Function App. The deployment endpoints for the Function are only accessible on the Private Endpoint.

    - To deploy code the network restrictions will need to be eased or the machining pushing needs a network path to the Private Endpoint.

- The [Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service) AI service must be deployed and configured for private networking. Note that model deployments are not included and are necessary for full functionality. Ensure that your Azure subscription has the required quota to deploy the desired model.

- [Something Else I'm sure]

### Variables

|variable|type|description|
|---|---|---|
|tags| map(string)|key value pairs for any required tags in your Azure environment |
|environment| map(string)| various environment specific variables used during the deployment. |

|Environment Required ||
|---|---|
|project_name| unique project name identification. Used for resource name generation. |
|location| Azure region for deployment|


#### Example terraform variables - *example.tfvars*

**Tags:**

*These are required tags in my environment, change as needed*

```hcl
tags = {
    owner = ""
    projectName ""
}
```

**environment:**

```hcl
environment = {
    project_name = ""
    location = ""
}
```

