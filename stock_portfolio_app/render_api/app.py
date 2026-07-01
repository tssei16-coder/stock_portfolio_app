from flask import Flask, request, jsonify
from flask_cors import CORS
import yfinance as yf
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone, timedelta
import os
import json
import time

app = Flask(__name__)
# すべてのオリジンからのアクセスを許可
CORS(app)

# Firebase 初期化
# Render環境変数 'FIREBASE_SERVICE_ACCOUNT_JSON' にJSON文字列を設定する想定
firebase_initialized = False
try:
    service_account_str = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON")
    if service_account_str:
        cred_dict = json.loads(service_account_str)
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred)
        firebase_initialized = True
        print("Firebase Admin SDK initialized via environment variable.")
    else:
        # ローカルテスト用
        local_key_path = "../python/serviceAccountKey.json"
        if os.path.exists(local_key_path):
            cred = credentials.Certificate(local_key_path)
            firebase_admin.initialize_app(cred)
            firebase_initialized = True
            print("Firebase Admin SDK initialized via local JSON file.")
        else:
            print("Warning: Firebase Service Account not found. /api/update_all will fail.")
except Exception as e:
    print(f"Error initializing Firebase: {e}")

@app.route('/')
def index():
    return "Stock API is running!"

@app.route('/api/stock', methods=['GET'])
def get_stock_info():
    code = request.args.get('code')
    if not code:
        return jsonify({'error': '証券コードが必要です', 'price': None, 'dividend': None}), 400

    ticker_symbol = f"{code}.T"
    
    try:
        ticker = yf.Ticker(ticker_symbol)
        info = ticker.info
        
        # --- 1. 株価の取得 ---
        price = (
            info.get("currentPrice")
            or info.get("regularMarketPrice")
            or info.get("previousClose")
        )
        
        if price is None or price == 0:
            hist = ticker.history(period="2d")
            if not hist.empty:
                price = float(hist["Close"].iloc[-1])
        
        if not price or price <= 0:
            price = None
        else:
            price = float(price)

        # --- 2. 年間配当金の取得 ---
        dividend_amount = None
        try:
            dividends = ticker.dividends
            if dividends is not None and not dividends.empty:
                one_year_ago = datetime.now(timezone.utc) - timedelta(days=365)
                
                try:
                    # tz-aware の場合
                    div_1y = dividends[dividends.index.tz_convert('UTC') >= one_year_ago]
                except Exception:
                    # tz-naive の場合
                    div_1y = dividends[dividends.index >= one_year_ago.replace(tzinfo=None)]

                if not div_1y.empty:
                    dividend_amount = float(div_1y.sum())
        except Exception as e:
            print(f"[{code}] 配当実績取得エラー: {e}")

        # yfinanceのinfoからフォールバック
        if dividend_amount is None or dividend_amount <= 0:
            dividend_amount = info.get("trailingAnnualDividendRate") or info.get("dividendRate")
            if dividend_amount and dividend_amount > 0:
                dividend_amount = float(dividend_amount)
            else:
                dividend_amount = None

        return jsonify({
            'code': code,
            'price': price,
            'dividend': dividend_amount
        }), 200

    except Exception as e:
        print(f"Exception: {e}")
        return jsonify({
            'error': str(e),
            'price': None,
            'dividend': None
        }), 500


@app.route('/api/update_all', methods=['GET', 'POST'])
def update_all_stocks():
    """
    Firestoreに登録されている全ユーザーの銘柄を一括更新するエンドポイント
    """
    if not firebase_initialized:
        return jsonify({"error": "Firebase Admin SDK is not initialized."}), 500

    db = firestore.client()
    user_stocks_map = {}
    
    # 全ユーザーと登録銘柄を取得
    try:
        users_ref = db.collection("users")
        users = users_ref.stream()
        for user in users:
            uid = user.id
            stocks_ref = users_ref.document(uid).collection("stocks")
            stocks = stocks_ref.stream()
            codes = [stock.id for stock in stocks]
            if codes:
                user_stocks_map[uid] = codes
    except Exception as e:
        return jsonify({"error": f"Firestoreからのデータ取得失敗: {e}"}), 500

    if not user_stocks_map:
        return jsonify({"message": "更新対象の銘柄がありません"}), 200

    # ユニークな銘柄を抽出
    all_codes = set()
    for codes in user_stocks_map.values():
        all_codes.update(codes)

    # 各銘柄の最新データを取得
    data_map = {}
    for i, code in enumerate(all_codes, 1):
        ticker_symbol = f"{code}.T"
        try:
            ticker = yf.Ticker(ticker_symbol)
            info = ticker.info
            
            # 株価
            price = (info.get("currentPrice") or info.get("regularMarketPrice") or info.get("previousClose"))
            if price is None or price == 0:
                hist = ticker.history(period="2d")
                if not hist.empty:
                    price = float(hist["Close"].iloc[-1])
            if not price or price <= 0:
                price = None
                
            # 配当
            dividend_amount = None
            try:
                dividends = ticker.dividends
                if dividends is not None and not dividends.empty:
                    one_year_ago = datetime.now(timezone.utc) - timedelta(days=365)
                    try:
                        div_1y = dividends[dividends.index.tz_convert('UTC') >= one_year_ago]
                    except Exception:
                        div_1y = dividends[dividends.index >= one_year_ago.replace(tzinfo=None)]
                    if not div_1y.empty:
                        dividend_amount = float(div_1y.sum())
            except Exception:
                pass
            
            if dividend_amount is None or dividend_amount <= 0:
                dividend_amount = info.get("trailingAnnualDividendRate") or info.get("dividendRate")
                
            if price is not None:
                data_map[code] = {
                    "price": float(price),
                    "dividend": float(dividend_amount) if dividend_amount else None
                }
        except Exception as e:
            print(f"[{code}] Fetch error: {e}")
            
        time.sleep(1) # APIレートリミット対策

    # 各ユーザーのFirestoreを一斉更新
    success_count = 0
    fail_count = 0
    updated_records = []

    for uid, codes in user_stocks_map.items():
        user_ref = db.collection("users").document(uid).collection("stocks")
        for code in codes:
            if code in data_map:
                data = data_map[code]
                try:
                    update_payload = {
                        "price": data["price"],
                        "priceUpdatedAt": datetime.now(timezone.utc),
                    }
                    if data.get("dividend") is not None and data["dividend"] > 0:
                        update_payload["dividend"] = data["dividend"]
                    
                    user_ref.document(code).update(update_payload)
                    success_count += 1
                    updated_records.append(code)
                except Exception as e:
                    fail_count += 1

    return jsonify({
        "message": "Update complete",
        "unique_stocks_fetched": len(all_codes),
        "success_count": success_count,
        "fail_count": fail_count,
    }), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
