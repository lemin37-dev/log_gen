# 로그 생성기가 구동되는 컨테이너의 이미지 저장소
# 1. 저장소 생성
resource "aws_ecr_repository" "generator" {
  name = local.repository_name
  # 저장소 삭제 시 남아있는 이미지가 있을 경우 삭제 옵션 정의
  force_delete = true
  # 같은 태그로 이미지 갱신 허용
  image_tag_mutability = "MUTABLE"
  # 이미지 push 시 자동 검사
  image_scanning_configuration {
    scan_on_push = true
  }
}

# 2. 저장소 저장 정책 정의 (비용관리)
resource "aws_ecr_lifecycle_policy" "generator" {
  repository = aws_ecr_repository.generator.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "keep 20 images"
        selection = {
          tagStatus   = "any"                # 태그 무관
          countType   = "imageCountMoreThan" # 20개 초과 시 action
          countNumber = 20                   # 임계값
        }
        # 삭제 action
        action = {
          type = "expire"
        }
      }
    ]
  })
}