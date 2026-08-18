# 목표
- AWS Fargate를 이용한 로그 생성기
  - AWS Fargate
    - EC2를 사용/관리 X
    - ECR에 등록된 이미지를 이용하여 ECS에서 직접 컨테이너 실행 -> `서버리스`로 실행환경을 제공받고 수행
    - 비용이 가장 저렴
  - 발생된 데이터
    - 데이터 형태 : 요청 -> 서비스 대응 -> 응답 => 모두 합쳐진 최종 로그 (서비스 구성 X)
    - 데이터 저장
      - S3
      - CloudWatch (AWS 로그 저장)
      - File
      - Console

# 인프라 구성
- variables.tf  : region, project name, cpu/memory 등 정보/기술/구성 조정
- version.tf
- provider.tf
- locals.tf     : 공통값 가공, 태그, 전체 프로젝트 prefix 등 구성
- vpc.tf        : 전용 네트워크(VPC, Subnet, IGW, Route Table, SG, AZ, ...) 구성
- iam.tf        : Fargage가 ECR 이미지 획득, CloudWatch에 로그 기록 등의 권한 구성
- logs.tf       : ECS 컨테이너 내 로그생성기가 발생시키는 로그의 로그 그룹을 지정
- ecr.tf        : 파이썬으로 작성한 로그생성기를 docker 이미지로 만들어 저장하는 저장소
- ecs.tf        : ECS 클러스터와 Fargate Task Definition등이 궁되는 실행환경을 구성 -> 1회성 (상시 운영 X)
- output.tf     : 생성 후 각종 정보 출력
