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
- sg.tf         : 보안그룹(외부 연결 X) -> ingress 미지정
- logs.tf       : ECS 컨테이너 내 로그생성기가 발생시키는 로그의 로그 그룹을 지정
- ecr.tf        : 파이썬으로 작성한 로그생성기를 docker 이미지로 만들어 저장하는 저장소
- ecs.tf        : ECS 클러스터와 Fargate Task Definition등이 궁되는 실행환경을 구성 -> 1회성 (상시 운영 X)
- output.tf     : 생성 후 각종 정보 출력

## 적용
```
cd infra
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

# 로그 생성기
## 로그 포맷
- 서비스 요청에 따른 처리가 완료된 후 로그로 기록하는 최종 필드를 포함한 데이터 샘플 (faker로 생성)
```json
{
  "schema_version": "1.0",
  "record_type": "application_log",
  "event_id": "...",
  "trace_id": "...",
  "run_id": "...",
  "occurred_at": "2026-08-12T16:30:11.123+09:00",
  "generated_at_utc": "2026-08-12T07:30:11.123+00:00",
  "domain": "ecommerce",
  "event_type": "order_created",
  "service": {...},
  "client": {...},
  "request": {
    "method": "POST",
    "path": "/api/orders",
    "request_bytes": 1234
  },
  "response": {
    "status_code": 201,
    "latency_ms": 287,
    "response_bytes": 3590
  },
  "data": {... domain specific ...}
}
```

## 지원 도메인 및 이벤트 정의
- domain으로 카테고리 설정
- 각 도메인에 맞춰 이벤트 비율, 시간대별 발생량, 주요 필드, 지연시간 등을 설정
  - 실제 도메인의 인사이트를 반영하여 설계

| DOMAIN | 주요 이벤트 예시 |
|---|---|
| `ecommerce` | product_view, search, add_to_cart, checkout, order_created, payment_completed |
| `finance` | account_login, balance_inquiry, card_payment, transfer, deposit, withdrawal |
| `smartfactory` | sensor_reading, equipment_state, quality_inspection, alarm, maintenance_event |
| `game` | login, session_heartbeat, match_started, match_finished, item_purchase, quest_completed |

## 실제와 유사한 발생간격
- 고려사항
  - 시간대 별 가중치
  - 평일/주말 가중치
  - 간헐적 발생하는 부스터(트래픽 상승)
  - ...

- 예시
  - 이커머스 : 점심/저녁 시간대 증가, 주말 감소
  - 금융 : 주간 시간 증가, 주말 감소
  - 스마트팩토리 : 24시간 비교적 일정, 교대/주말 변화
  - 게임 : 저녁/야간/주말 증가세
  - 증가세를 적용하여 피크 시 트래픽을 평소대비 5~10배 가중할 수 있음

## 오염 데이터
- 비율 지정 (각 이벤트에서 비율을 정해 오염 데이터 생산) -> ETL에서 clean작업으로 처리
- 오염 유형
```
missing_field
null_required
wrong_type
invalid_timestamp
numeric_outlier
invalid_enum
negative_latency
duplicate
malformed_json
...
```

# 로그 발생기의 데이터 파이프라인 상 포지션
```
              Data Source Simulator
              Fargate + Python/Faker
                      │ <- (다양한 출력 방향으로 전개)
    ┌─────────────────┼─────────────────┐
    │                 │                 │
    ▼                 ▼                 ▼
    S3              Kinesis            Kafka
File/Batch         AWS Stream       Event Stream
    │                 │                 │
    └─────────────────┼─────────────────┘
                      ▼
                Bronze Layer
                      │
              ETL / ELT Processing
          Pandas / Polars / Spark
                      │
                    Silver
                      │
                    Gold
                      │
        Athena / OpenSearch / BI
```

# 로그 발생기 구조 및 설치
- 구조
```
~/generator
L app/
  L domains/
    L *.py          # 4개 도메인에 대한 로그 생성 제너레이터 함수
  L *.py            # 로그 생성기 메인코드, 각종 기능 처리
L Dockerfile        # 컨테이너 기반이 되는 이미지 생성용, ECR push
L requirements.txt  # 필요 패키지
```

- 설치
```
pip install -r requirements.txt
```

# Scripts
- run-local.bat|sh
  - 로컬 PC에서 로그 생성(로컬 테스트)
  ```
  # 흐름
  도메인 로그 생성
  ↓
  60초 동안 실행
  ↓
  평균 5 RPS 속도로 생성
  ↓
  5% 오염 데이터 구성
  ↓
  출력은 stdout, file 모두 구성(both)
  ↓
  시간 배율 조절은 1

  # 실행 옵션
  scripts\run-local.bat [DOMAIN] [DURATION] [RPS] [CORRUPTION] [OUTPUT] [TIME_SCALE]

  # 샘플 
  scripts\run-local.bat finance 5 5 0.05 both 1  
  ```

- setup.bat|sh
```
  # 흐름
  Terraform init
      ↓
  Terraform apply
      ↓
  ECR Repository 생성
  ECS/Fargate 관련 인프라 생성
      ↓
  AWS ECR 로그인
      ↓
  Docker 이미지 Build
      ↓
  ECR에 latest 이미지 Push

  # 실행
  .\scripts\setup.bat
```

- run-generator.bat|sh
  - AWS fargate에서 진행
```
  # 흐름
  로컬 PC 명령 수행
  ↓
  AWS ECS run-task 가동
  ↓
  ECS Cluster
  ↓
  Fargate task 작동
  ↓
  Dcoker Container
  ↓
  Python 로그 생성기 작동
  ↓
  CloudWatch에 로그 저장

  # 실행 옵션
  scripts\run-generator.bat [DOMAIN] [DURATION] [BASE_RPS] [CORRUPTION_RATE] [TASK_COUNT] [REGION] [TIME_SCALE]

  # 샘플
  scripts\run-generator.bat ecommerce 2 5 0.05 1 ap-northeast-2 1
```