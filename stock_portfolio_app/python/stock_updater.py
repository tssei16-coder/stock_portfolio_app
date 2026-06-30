"""
stock_updater.py
================
yfinanceを使って日本株の株価を取得し、Firestoreを更新するスクリプト。

使い方:
  python stock_updater.py

定期実行 (Windowsタスクスケジューラ):
  毎平日 15:35 に実行することを推奨（大引け: 15:30）

必要な準備:
  1. pip install -r requirements.txt
  2. serviceAccountKey.json をこのディレクトリに配置
  3. FIREBASE_USER_UID を以下の設定セクションに入力
"""

import yfinance as yf
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone
import time
import logging
import sys
import os

# ========== 設定セクション ==========
# Firebase Admin SDK の認証情報ファイル（.gitignoreに追加してください）
SERVICE_ACCOUNT_KEY = "serviceAccountKey.json"

# FirebaseのユーザーUID（Firebase Console > Authentication で確認できます）
# 例: "AbCdEf1234567890xyz"
FIREBASE_USER_UID = "YOUR_USER_UID_HERE"

# 取得する銘柄リスト（証券コード + .T の形式）
# ※ Firestoreに登録されている銘柄コードから自動取得するため、通常は変更不要
# 手動で絞り込みたい場合のみ設定してください
MANUAL_TICKER_LIST = []  # 空の場合はFirestoreから自動取得

# 株価取得間隔（秒）: レートリミット対策
REQUEST_INTERVAL_SECONDS = 2

# ====================================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler("stock_updater.log", encoding="utf-8"),
    ],
)
logger = logging.getLogger(__name__)


def initialize_firebase():
    """Firebase Admin SDK を初期化"""
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        logger.error(f"認証ファイルが見つかりません: {SERVICE_ACCOUNT_KEY}")
        logger.error("Firebase Console からサービスアカウントキーをダウンロードしてください")
        sys.exit(1)

    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    logger.info("Firebase接続 ✓")
    return db


def get_stock_codes_from_firestore(db: firestore.Client) -> list[str]:
    """Firestoreから登録済みの銘柄コードを取得"""
    stocks_ref = db.collection("users").document(FIREBASE_USER_UID).collection("stocks")
    docs = stocks_ref.stream()
    codes = [doc.id for doc in docs]
    logger.info(f"Firestoreから {len(codes)} 銘柄を取得: {codes}")
    return codes


def fetch_stock_price(code: str) -> float | None:
    """
    yfinance で現在の株価を取得する。
    日本株は証券コード + '.T' の形式。
    
    Args:
        code: 証券コード（例: "7203"）
    Returns:
        現在株価（円）, 取得失敗時は None
    """
    ticker_symbol = f"{code}.T"
    try:
        ticker = yf.Ticker(ticker_symbol)
        
        # まず info から currentPrice を試みる（最速）
        info = ticker.info
        
        # いくつかのフィールドを試みる（yfinanceのフィールド名が変わることがあるため）
        price = (
            info.get("currentPrice")
            or info.get("regularMarketPrice")
            or info.get("previousClose")
        )
        
        # info から取得できない場合、直近の履歴データから取得
        if price is None or price == 0:
            hist = ticker.history(period="2d")
            if not hist.empty:
                price = float(hist["Close"].iloc[-1])
        
        if price and price > 0:
            logger.info(f"  {code} ({ticker_symbol}): ¥{price:,.0f}")
            return float(price)
        else:
            logger.warning(f"  {code}: 株価を取得できませんでした（データなし）")
            return None
            
    except Exception as e:
        logger.error(f"  {code}: 取得エラー - {e}")
        return None


def update_price_in_firestore(db: firestore.Client, code: str, price: float):
    """Firestoreの株価フィールドを更新"""
    stock_ref = (
        db.collection("users")
        .document(FIREBASE_USER_UID)
        .collection("stocks")
        .document(code)
    )
    stock_ref.update({
        "price": price,
        "priceUpdatedAt": datetime.now(timezone.utc),
    })
    logger.info(f"  → Firestore更新完了: {code} = ¥{price:,.0f}")


def is_weekday_and_market_hours() -> bool:
    """
    平日かつ市場時間内（15:30以降）かチェック
    タスクスケジューラで15:35に実行する場合は不要だが、
    念のためのガード処理
    """
    now_jst = datetime.now()  # ローカル時刻（日本時間を想定）
    if now_jst.weekday() >= 5:  # 土(5)・日(6)
        logger.info("本日は休日のためスキップします")
        return False
    return True


def main():
    logger.info("=" * 50)
    logger.info("株価自動更新スクリプト 開始")
    logger.info(f"実行日時: {datetime.now().strftime('%Y/%m/%d %H:%M:%S')}")
    logger.info("=" * 50)

    # 平日チェック（--force オプションで強制実行）
    force = "--force" in sys.argv
    if not force and not is_weekday_and_market_hours():
        logger.info("--force オプションで強制実行できます")
        return

    # Firebase初期化
    db = initialize_firebase()

    # 銘柄リスト取得
    if FIREBASE_USER_UID == "YOUR_USER_UID_HERE":
        logger.error("FIREBASE_USER_UID が設定されていません！")
        logger.error("stock_updater.py の設定セクションに UID を入力してください")
        sys.exit(1)

    codes = MANUAL_TICKER_LIST if MANUAL_TICKER_LIST else get_stock_codes_from_firestore(db)

    if not codes:
        logger.warning("更新対象の銘柄がありません")
        return

    # 株価取得 & 更新
    success_count = 0
    fail_count = 0

    for i, code in enumerate(codes, 1):
        logger.info(f"\n[{i}/{len(codes)}] {code} の株価を取得中...")
        price = fetch_stock_price(code)

        if price is not None:
            update_price_in_firestore(db, code, price)
            success_count += 1
        else:
            fail_count += 1

        # レートリミット対策
        if i < len(codes):
            time.sleep(REQUEST_INTERVAL_SECONDS)

    # 結果サマリー
    logger.info("\n" + "=" * 50)
    logger.info(f"完了: 成功 {success_count} 銘柄 / 失敗 {fail_count} 銘柄")
    logger.info("=" * 50)


if __name__ == "__main__":
    main()
