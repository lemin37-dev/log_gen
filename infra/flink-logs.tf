# @silver : flink log group 생성
resource "aws_cloudwatch_log_group" "flink" {
  name              = local.flink_log_group_name
  retention_in_days = var.log_retention_days
}

# 실시간 처리 -> log stream 생성
resource "aws_cloudwatch_log_stream" "flink" {
  name           = local.flink_log_stream_name
  log_group_name = aws_cloudwatch_log_group.flink.name # 해당 스트림에 속할 그룹 지정
}
