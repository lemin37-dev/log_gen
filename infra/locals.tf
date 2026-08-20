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