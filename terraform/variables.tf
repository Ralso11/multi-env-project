variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name used to prefix and tag all resources in this project"
  type        = string
  default     = "multi-env-project"
}

variable "environment" {
  description = "Deployment environment - dev or prod"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either \"dev\" or \"prod\"."
  }
}

variable "lambda_memory_size" {
  description = "Memory allocated to the Lambda function (MB) - can differ per environment"
  type        = number
  default     = 128
}
