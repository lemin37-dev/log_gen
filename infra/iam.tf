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

