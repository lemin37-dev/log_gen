# @silver : Managed Service for Apache Flink 리소스의 IAM
data "aws_iam_policy_document" "flink_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["kinesisanalytics.amazonaws.com"]
    }
  }
}
# Flink의 기본적인 정책 반영
resource "aws_iam_role" "flink" {
  name               = "${var.project_name}-flink-role"
  assume_role_policy = data.aws_iam_policy_document.flink_assume.json
}
# Flink에 추가 정책 반영
# 브론즈 kinesis 읽기 권한
# 실버 kinesis 쓰기 권한
# s3에 저장된 flink의 애플리케이션 zip파일 읽기 권한
# Cloud Watch 로그 기록 권한
data "aws_iam_policy_document" "flink" {
  statement {
    sid    = "ReadBronzeKinesis" # statement 구분용
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamSummary",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    resources = [
      aws_kinesis_stream.logs.arn
    ]
  }

  # silver layer에 존재하는 kinesis로 데이터를 전송하는 권한
  statement {
    sid    = "WriteSilverKinesis"
    effect = "Allow"
    actions = [
      "kinesis:PutRecord",
      "kinesis:PutRecords"
    ]
    resources = [
      aws_kinesis_stream.silver.arn
    ]
  }

  # s3에 저장된 flink 어플리케이션 코드(zip 형태) 읽기 권한
  statement {
    sid    = "ReadFlinkCode"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = [
      "${aws_s3_bucket.data.arn}/flink/*"
    ]
  }

  # 로그 읽기
  statement {
    sid    = "DescribeFlinkLog"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "*"
    ]
  }

  # 로그 쓰기
  statement {
    sid    = "WriteFlinkLog"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.flink.arn}:*"
    ]
  }
}
# 기본 구성한 role에 조회한 정책 부여
resource "aws_iam_role_policy" "flink" {
  name   = "${var.project_name}-flink-policy"
  role   = aws_iam_role.flink.id
  policy = data.aws_iam_policy_document.flink.json
}

# silver layer에서 사용하는 firehose IAM
data "aws_iam_policy_document" "firehose_silver_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "firehose_silver" {
  name               = "${var.project_name}-firehose-silver-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_silver_assume.json
}
# Firehose가 입력으로 kinesis에서 읽어오고 출력으로 s3에 저장에 관한 구성
data "aws_iam_policy_document" "firehose_silver" {
  # Silver lyaer kinesis 읽기 권한
  statement {
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamSummary",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    resources = [
      aws_kinesis_stream.silver.arn
    ]
  }

  # s3 저장 권한
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.data.arn,
      "${aws_s3_bucket.data.arn}/*"
    ]
  }
}
# firehose_s3를 통해 조회한 권한을 aws_iam_role.firehose에 부여
resource "aws_iam_role_policy" "firehose_silver" {
  name   = "${var.project_name}-firehose-silver-s3-policy"
  role   = aws_iam_role.firehose_silver.id
  policy = data.aws_iam_policy_document.firehose_silver.json
}
