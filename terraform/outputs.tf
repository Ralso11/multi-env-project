output "api_url" {
  description = "Base URL of the hello API for this environment"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}hello"
}

output "environment" {
  description = "Which environment this deployment represents"
  value       = var.environment
}
