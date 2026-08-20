# 개요
- main branch는 로그를 CloudWatch에 저장하고 있음
  - application 상태/오류/디버깅 용도 (개발, 유지보수 관련) -> 웹/앱 개발자 활용
- 데이터 엔지니어 관점에서는 새로운 파이프라인 구성이 필요 
  - S3에 바로 적재
    - 불필요한 I/O가 많이 발생하게 됨 (빈번한 putObject 행위 발생)
    - 작은 파일이 많이 발생함
  - 방식
    - 데이터 실시간 스트리밍 수집 -> Kinesis 활용
    - 데이터를 모아서(시간/용량 단위) 한번에 S3에 저장 -> firehose 활용
    - Streaming Ingestion
  - 향후 
    - Kinesis -> flink(대용량, 실시간 전처리)/lambda -> Kinesis -> firehose로 구성하여 silver 단계 구성가능

# 구성도
- 기본적인 스트리밍 수집
```
                      ┌→ CloudWatch Logs
                      │   운영/디버깅
Fargate Generator ────┤
                      │
                      └→ Kinesis
                           │
                           │
                           ↓
                        Firehose
                           ↓
                           S3 : bronze layer (메달리온 아키텍처 기반)
                      데이터 파이프라인
```

# 메달리온 아키텍쳐
- 데이터레이크(하우스)의 표준 데이터 품질 관리 패턴
- 구성

|단계|의미|뉘앙스|저장형태|
|--|--|--|--|
|Bronze|가공되지 않은 기록|무슨 일이 일어났는가?<br/>Raw 데이터|gzip|
|Silver|전처리, 클리닝 등 데이터 정제과정<br/>분석 가능한 깔끔한 테이블|누가, 언제, 무엇을 구매했는가?|parquet|
|Gold|보고서에 바로 들어갈 숫자<br/>숫자, 분석, 대시보드 등 즉시 사용(비즈니스)할 수준의 데이터|이번 시간 매출은 얼마인가?|parquet|

# 수정 및 추가 workflow
```
[1] Terraform 인프라 생성
       │
       ├─ Kinesis Data Stream
       ├─ S3 Bucket
       ├─ Firehose IAM Role
       └─ Firehose
       │
       ▼
[2] 기존 Fargate IAM 수정
       │
       └─ Task Role + kinesis:PutRecord(s)
       │
       ▼
[3] Python 로그 생성기 수정
       │
       ├─ config.py
       ├─ output.py
       └─ main.py
       │
       ▼
[4] Docker 이미지 재빌드
       │
       ▼
[5] run-generator.bat|sh 수정
       │
       ▼
[6] 실행
       │
       ▼
Fargate → Kinesis → Firehose → S3 확인 (jsonl, gzip)
```

# 인프라 수정 및 추가
```
├─infra
│  │  ecr.tf              # 유지
│  │  ecs.tf              
│  │  iam.tf              # firehose, ecs-task ~ kinesis 관련 내용 추가
│  │  locals.tf
│  │  logs.tf             # 유지
│  │  output.tf
│  │  provider.tf
│  │  sg.tf               # 유지
│  │  variables.tf
│  │  version.tf          # 유지
│  │  vpc.tf              # 유지
│  │  
│  │  kinesis.tf          # 신규
│  │  firehose.tf         # 신규
│  │  s3.tf               # 신규
```

# 프로그램(파이썬) 수정
- 로그를 kinesis로 전송하도록 조정
- 패키지 추가 (requirements.txt)
  ```
  Faker
  boto3   # AWS SDK 패키지
  ```
- config.py : ECS에서 추가한 환경변수 전달
- output.py : 출력방향에 kinesis 추가
- main.py : 생성 매개변수 조정

# bat|sh 수정
- 코드 수정 -> 이미지 수정 필요 -> ECR 업데이트 (setup.bat|sh)
```
scripts\setup.bat
```

# 브론즈 데이터 생성
- 실행 옵션
```
ecommerce       도메인
5               5초 실행
5               기본 5 RPS
0.05            오염 데이터 5%
1               Fargate Task 1개
ap-northeast-2  서울 리전
1               Time Scale 1배
```

- 명령
- 25건 생성
- CloudWatch 로그 기록(default : stdout)
- kinesis -> firehose -> s3 기록
- 로그 발생 후 S3에서 언제 확인가능한지? -> 설정상 약간의 텀이 존재함(firehose의 buffer 설정 확인)
- 실행
```
scripts\run-generator.bat ecommerce 5 5 0.05 1 ap-northeast-2 1
```
- 로그 확인
```
aws logs tail "/ecs/de-ai-19-loggen" --follow --region "ap-northeast-2"
```
