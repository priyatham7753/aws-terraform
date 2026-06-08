output "backend_ec2_instance_profile_name" { value = aws_iam_instance_profile.backend_ec2.name }
output "backend_ec2_role_arn" { value = aws_iam_role.backend_ec2.arn }
output "frontend_ec2_instance_profile_name" { value = aws_iam_instance_profile.frontend_ec2.name }
output "frontend_ec2_role_arn" { value = aws_iam_role.frontend_ec2.arn }
output "eventbridge_role_arn" { value = aws_iam_role.eventbridge.arn }
