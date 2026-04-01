output "main_budget_name" {
  description = "Name of the main monthly budget"
  value       = aws_budgets_budget.monthly_total.name
}

output "safety_net_budget_name" {
  description = "Name of the safety net budget (if enabled)"
  value       = try(aws_budgets_budget.safety_net[0].name, null)
}
