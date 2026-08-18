FROM python:3.12-slim

# PYTHONDONTWRITEBYTECODE : .pyc 캐시파일 생성 방지
# PYTHONUNBUFFERED : 파이썬에서 로그 출력 시 버퍼링하지 않고 즉시 출력 (버퍼링 시 로그가 발생되어 기록될 때 왜곡이 일어날 수 있음)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
  
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 소스 카피
COPY app ./app

# 컨테이너 실행되면 구동할 명령어
ENTRYPOINT [ "python", "-m", "app.main" ]
