import logging
import firebase_admin
from firebase_admin import credentials, messaging
import os
from django.conf import settings

logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK
firebase_initialized = False
try:
    # Check if service account key exists (should be provided by user or in env)
    cred_path = os.environ.get('FIREBASE_SERVICE_ACCOUNT_PATH', 'serviceAccountKey.json')
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        firebase_initialized = True
        logger.info("Firebase Admin SDK initialized successfully.")
    else:
        logger.warning(f"Firebase service account key not found at {cred_path}. Push notifications will be mocked.")
except Exception as e:
    logger.error(f"Failed to initialize Firebase Admin SDK: {e}")

def send_push_notification(user, title, body, data=None):
    """
    Sends a push notification to a specific user via FCM.
    """
    if not user.fcm_token:
        logger.info(f"No FCM token found for user {user.username}. Skipping push.")
        return False

    if not firebase_initialized:
        logger.info(f"[MOCK PUSH] To: {user.username} | Title: {title} | Body: {body}")
        # In mock mode, we just log it. In production, this would send a real FCM message.
        return True

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=user.fcm_token,
        )
        response = messaging.send(message)
        logger.info(f"Successfully sent message to {user.username}: {response}")
        return True
    except Exception as e:
        logger.error(f"Error sending FCM message to {user.username}: {e}")
        return False
