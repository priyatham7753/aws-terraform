output "frontend_launch_template_id" { value = aws_launch_template.frontend.id }
output "frontend_launch_template_version" { value = aws_launch_template.frontend.latest_version }
output "backend_launch_template_id" { value = aws_launch_template.backend.id }
output "backend_launch_template_version" { value = aws_launch_template.backend.latest_version }
