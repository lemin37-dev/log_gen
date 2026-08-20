# Fargate는 ECR Task를 생성하여 CloudWatch에 저장
# ECR에 이미지 push, CloudWatch에 로그 저장 -> 2개의 권한 필요
# 1. ECS Task policy 조회
data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# 2. 해당 Role 정의(생성)
resource "aws_iam_role" "ecs_execution" {
  name               = "${var.project_name}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

# 3. Role과 정책 연결 (ECS Task 실행 시 필요한 권한 부여)
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# @bronze : Firehose IAM Role/Policy 추가
# aws_iam_policy_document -> aws_iam_role -> aws_iam_role_policy_attachment
data "aws_iam_policy_document" "firehose_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "firehose" {
  name               = "${var.project_name}-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume.json
}

# Firehose가 입력으로 kinesis에서 읽어오고 출력으로 s3에 저장에 관한 구성
data "aws_iam_policy_document" "firehose_s3" {
  # kinesis 읽기 권한
  statement {
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    resources = [
      aws_kinesis_stream.logs.arn
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
      aws_s3_bucket.data.arn,       # 대상 버킷
      "${aws_s3_bucket.data.arn}/*" # 대상 버킷 하위 모든 경로
    ]
  }
}
# firehose_s3를 통해 조회한 권한을 aws_iam_role.firehose에 부여
resource "aws_iam_role_policy" "firehose" {
  name   = "${var.project_name}-firehose-s3-policy"
  role   = aws_iam_role.firehose.id
  policy = data.aws_iam_policy_document.firehose_s3.json
}

# @bronze : ECS -> task에서 kinesis 전송 시 활용할 role을 별도 추가
# ECS Task Role
# - Execute Role (기존, Task 실행 권한)
# - Kinesis Role (신규 추가, kinesis로 데이터 putRecord 권한)

# ECS task -> data -> kinesis 권한 부여를 위한 Role 구성
## 기본적인 ECS task 정책 부여
resource "aws_iam_role" "ecs_task_kinesis" {
  name = "${var.project_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

## ECS task -> data -> kinesis 권한 조회
data "aws_iam_policy_document" "ecs_task_kinesis" {
  statement {
    effect = "Allow"

    actions = [
      "kinesis:PutRecords",
      "kinesis:PutRecord"
    ]

    resources = [
      aws_kinesis_stream.logs.arn
    ]
  }
}

## 조회한 role 연결
resource "aws_iam_role_policy" "ecs_task_kinesis" {
  name = "${var.project_name}-kinesis-write"
  role = aws_iam_role.ecs_task_kinesis.id
  policy = data.aws_iam_policy_document.ecs_task_kinesis.json
}
