# @bronze : kinesis 추가
resource "aws_kinesis_stream" "logs" {
  name             = local.kinesis_stream_name
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_hour

  # 구성방식
  stream_mode_details {
    # 프로비저닝 모드로 구성 (부족하면 성능저하, 과하면 비용이 커짐)
    stream_mode = "PROVISIONED"
  }
}
