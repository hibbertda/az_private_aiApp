variable "tags" {
  description = "Default tags to be applied to all resources"
  type        = map(string)
  default     = {
    owner = "Daniel Hibbert"
    projectName = "privateAIApp1"
  }
}

variable "environment" {
  description = "Variables specific to the project"
  type        = map(string)
  default     = {
    project_name = "privateAIApp"
    location     = "eastus"
  }
  
}