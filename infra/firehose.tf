# @bronze : firehose 생성
# kinesis -> firehose -> s3
resource "aws_kinesis_firehose_delivery_stream" "logs" {
  # 이름
  name        = local.firehose_name
  destination = "extended_S3"

  # 입력소스 (키네시스 지정, 역할 설정)
  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.logs.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  # 출력대상 (버킷 지정, 역할 설정)
  extended_s3_configuration {
    bucket_arn = aws_s3_bucket.data.arn
    role_arn   = aws_iam_role.firehose.arn

    # 버퍼 관련 용량/시간 설정
    buffering_size     = var.firehose_buffer_size
    buffering_interval = var.firehose_buffer_interval

    # 데이터 레코드 압축
    # 데이터를 모아둔 상태(버퍼)에서 기록할 때의 포맷 지정
    compression_format = "UNCOMPRESSED"   # 1차는 원본으로 지정
    #compression_format = "GZIP"   # gzip 형태로 압축

    # S3 버킷 및 오류 출력 접두사 시간대
    custom_time_zone = "Asia/Seoul"

    # S3 버킷 Prefix (최대 1024자)
    # Partition Pruning -> Athena/Opensearch/Glue/Spark 등 열 기반으로 데이터 추출 시 유용 -> 검색속도 향상
    # 예시) bronze/year=2026/month=08/day=20/hour=11/...
    prefix = "bronze/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}"

    # S3 버킷 오류 출력 Prefix
    # 메달리온 계층별 하위에 error를 구성해도 되고 아래처럼 error를 따로 모아 구성가능
    # 경로상에 에러에 대한 타입 지정 -> 유형별로 에러가 모이게 작성
    error_output_prefix = "error/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}"
  }

  # 의존성
  depends_on = [
    # 입/출력 액세스 권한 생성 후 진행
    aws_iam_role_policy.firehose
  ]

}