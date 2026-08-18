'''
- 도메인 : 이커머스
- 이커머스 로그 : 상품 조회, 검색, 장바구니, 주문, 결제, ... 관련 로그
'''
from faker import Faker
from common import http_status
import random
import uuid

# 해당 도메인에서 발생가능한 이벤트 종류 정의
EVENTS = ["product_view", "search", "add_to_cart", "checkout", "order_created", "payment_completed"]
# 가중치 부여하여 이벤트의 발생빈도 조절 (도메인 인사이트를 활용하여 분석 설계)
WEIGHTS = [34, 20, 17, 9, 11, 9]
# 제품 카테고리 정의
CATEGORIES = ["food", "fashion", "beauty", "electronics", "home", "sports"]
# 결제 방식 정의
PAYMENTS = ["card", "bank_transfer", "easy_pay", "points"]

def generate(fake:Faker, *, timezone_name:str, environment:str, run_id:str) -> dict:
  # 이벤트 타입 선택
  event_type = random.choices(EVENTS, weights=WEIGHTS, k=1)[0]

  # 사용자 ID (임의 구성)
  # 중복성을 고려하여 랜덤 활용 (고유성을 가진 uuid 활용 X)
  user_id = f'usr_{random.randint(100000, 999999)}'

  # 요청 흐름을 구분하는 Session ID (고유함)
  session_id = uuid.uuid4().hex[:20]

  # 제품 ID (중복가능성 있음)
  product_id = f'prd_{random.randint(100000, 999999)}'

  # 제품 카테고리
  category = random.choices(CATEGORIES)[0]

  # 제품의 주문 수량
  quantity = random.choices([1,2,3,4], weights=[70,20,7,3], k=1)[0]

  # 제품 단가
  unit_price = random.randrange(5000, 300000, 100)

  # 캠페인(이벤트)
  campaign = random.choices([None, None, None, "summer_sale", "coupon", "winter_sale"])[0]

  # 이벤트별 요청에 대한 method, URL(API 경로), 지연(ms)
  routes = {
    "product_view"      : {"GET", f"/api/products/{product_id}", 70},
    "search"            : {"GET", f"/api/search", 95},
    "add_to_cart"       : {"POST", f"/api/cart/items", 100},
    "checkout"          : {"POST", f"/api/checkout", 240},
    "order_created"     : {"POST", f"/api/ordrs", 310},
    "payment_completed" : {"POST", f"/api/payments", 420}
  }
  method, path, median_latency = routes[event_type]

  # 응답코드 (400 미만이면 모두 성공, 이상일 경우 오류)
  print(routes[event_type])
  print(method)
  status = http_status(method=method)

  data = {
    "user_id" : user_id,
    "session_id" : session_id,
    "product_id" : product_id,
    "category" : category,
    "quantity" : quantity,
    "unit_price" : unit_price,
    "currency" : "KRW",
    "campaign" : campaign,
  }

  # 이벤트 타입별 추가 데이터 구성
  ## 검색 이벤트 - 검색 키워드, 검색결과
  if event_type == "search":
    data.update({
      "keyword" : fake.word(),
      "result_count" : random.randint(0, 240)
    })

  ## 주문 이벤트 - 주문 id, 금액, 결제
  if event_type in {"checkout", "order_created", "payment_completed"}:
    data.update({
      "order_id" : f'ord_{uuid.uuid4().hex[:16]}',
      "total_amount" : unit_price * quantity,
      "payment_method" : random.choices(PAYMENTS)[0],
    })

  ## 결제 완료 이벤트 - 성공/실패
  if event_type == "payment_completed":
    # 응답코드 기준으로 판정
    data["payments_result"] = "approve" if status < 400 else random.choices(["timeout", "cancelled"])[0]


  return {
    # 공용 데이터
    "event_type" : event_type,
    "request" : {
      "method" : method,
      "path" : path,
      #"request_bytes" : ,
    },
    "response" : {
      "status_code" : status,
      "latency_ms" : median_latency,
      #"response_bytes" : ,
    },

    # 도메인별 커스텀 데이터
    "data" : data
  }