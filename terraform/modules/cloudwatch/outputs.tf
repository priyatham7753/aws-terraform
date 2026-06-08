output "dashboard_name" { value = aws_cloudwatch_dashboard.main.dashboard_name }
output "frontend_cpu_alarm_arn" { value = aws_cloudwatch_metric_alarm.frontend_cpu_high.arn }
output "backend_cpu_alarm_arn" { value = aws_cloudwatch_metric_alarm.backend_cpu_high.arn }
output "alb_5xx_alarm_arn" { value = aws_cloudwatch_metric_alarm.alb_5xx.arn }
