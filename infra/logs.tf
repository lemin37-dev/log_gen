# fargate를 통해서 task가 작동되면 stdout/stderr 등 발생 -> CloudWatch에 저장
resource "aws_cloudwatch_log_group" "generator" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days # log 보관기간
}