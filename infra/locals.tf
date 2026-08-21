locals {
  # subnet의 갯수만큼 AZ 영역 자동 선택
  availability_zones = slice(
    data.aws_availability_zones.available.names, # AZ list
    0,                                           # start index
    length(var.public_subnet_cidrs)              # end index
  )

  # 기타 이름 설정
  cluster_name    = "${var.project_name}-cluster"
  task_family     = "${var.project_name}-task"
  repository_name = "${var.project_name}-repo"
  log_group_name  = "/ecs/${var.project_name}"

  # @bronze : 데이터 스트림, 파이어호스 이름 정의 추가
  kinesis_stream_name = "${var.project_name}-kinesis"
  firehose_name       = "${var.project_name}-firehose"
}

# @silver : 추가된 리소스명 정의를 위한 local 변수 추가
locals {
  silver_kinesis_stream_name = "${var.project_name}-silver-kinesis"
  silver_firehose_name       = "${var.project_name}-silver-firehose"
  flink_application_name     = "${var.project_name}-silver-flink"
  flink_log_group_name       = "/aws/kinesis-analysis/${var.project_name}-silver-flink"
  flink_log_stream_name      = "${var.project_name}-kinesis-analysis-log-stream"
}