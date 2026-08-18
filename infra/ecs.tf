# 컨테이너의 실행환경 제공
# 1. 클러스터 생성
resource "aws_ecs_cluster" "this" {
  name = local.cluster_name
}

# 2. Fargate에서 실행할 로그 생성기 컨테이너에 대한 실행 시 명세(rule, setting)
resource "aws_ecs_task_definition" "generator" {
  # 관리 그룹 (family)
  # family:1 -> family:2 (수정 작업이 일어나면 number를 부여하여 새로 생성)
  family = local.task_family
  # Fargate 사용 : task가 어떤 실행환경에서 작동할 것인지 지정(faragte 전용, fargate + 관리형인스턴스, ...)
  requires_compatibilities = ["FARGATE"]
  # 네트워크 구성, task가 작동할 때마다 a or b 존에 매번 상이하게 할당
  network_mode = "awsvpc"
  # CPU 사양
  cpu = tostring(var.task_cpu)
  # 메모리 사양
  memory = tostring(var.task_memory)
  # 권한 (ECS Task 기본, push, 로그 저장 권한)
  execution_role_arn = aws_iam_role.ecs_execution.arn
  # 서버리스 (컴퓨팅 자원의 운영체계)
  runtime_platform {
    operating_system_family = "LINUX"  # 컨테이너 실행환경
    cpu_architecture        = "X86_64" # 아키텍쳐
  }
  # 컨테이너 상세 정의서
  container_definitions = jsonencode([
    {
      # 컨테이너명
      name = "log-generator"
      # 이미지명
      image = "${aws_ecr_repository.generator.repository_url}:${var.image_tag}"
      # 해당 컨테이너가 Task의 필수 컨테이너임을 지정
      essential = true

      # 환경변수 -> 로그 생성기의 구동 설정값
      environment = [
        { name = "DOMAIN", value = "ecommerce" },
        { name = "DURATION_SECONDS", value = "300" },
        { name = "MAX_EVENTS", value = "0" },
        { name = "BASE_RPS", value = "2.0" },
        { name = "TIME_SCALE", value = "1.0" },
        { name = "CORRUPTION_RATE", value = "0.03" },
        { name = "INCLUDE_CORRUPTION_LABEL", value = "false" },
        { name = "OUTPUT_MODE", value = "stdout" },
        { name = "LOG_FILE", value = "/tmp/generated-logs.jsonl" },
        { name = "TIMEZONE", value = "Asia/Seoul" },
        { name = "FAKER_LOCALE", value = "ko_KR" },
        { name = "ENVIRONMENT", value = "simulation" },
        { name = "RUN_ID", value = "manual" }
      ]

      # CloudWatch 로그 전송 설정
      logConfiguration = {
        # CloudWatch logs용으로 로그 드라이버 지정
        logDriver = "awslogs"

        # 옵션
        options = {
          "awslogs-group"  = aws_cloudwatch_log_group.generator.name
          "awslogs-region" = var.aws_region
          # 문자열 prefix('generator') 세팅
          "awslogs-stream-prefix" = "generator"
        }
      }
    }
  ])
}
