"""
Email service for sending transactional emails.

Handles sending emails using fastapi-mail.
Includes fallback to console logging if email credentials are not configured (for development).
"""

from typing import List
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from pydantic import EmailStr
from src.core.config import settings
import logging

logger = logging.getLogger(__name__)


class EmailService:
    """
    Service for sending emails.
    """

    def __init__(self):
        self.enabled = bool(settings.MAIL_USERNAME and settings.MAIL_PASSWORD)

        if self.enabled:
            self.conf = ConnectionConfig(
                MAIL_USERNAME=settings.MAIL_USERNAME,
                MAIL_PASSWORD=settings.MAIL_PASSWORD,
                MAIL_FROM=settings.MAIL_FROM or settings.MAIL_USERNAME,
                MAIL_PORT=settings.MAIL_PORT,
                MAIL_SERVER=settings.MAIL_SERVER,
                MAIL_STARTTLS=settings.MAIL_STARTTLS,
                MAIL_SSL_TLS=settings.MAIL_SSL_TLS,
                USE_CREDENTIALS=settings.USE_CREDENTIALS,
                VALIDATE_CERTS=settings.VALIDATE_CERTS,
            )
            self.fastmail = FastMail(self.conf)
            logger.info("📧 Email service initialized with SMTP credentials")
        else:
            logger.warning(
                "⚠️ Email credentials not found. Emails will be logged to console only."
            )

    async def send_email(
        self,
        subject: str,
        recipients: List[EmailStr],
        body: str,
        subtype: MessageType = MessageType.html,
    ):
        """
        Send an email to a list of recipients.

        Args:
            subject: Email subject
            recipients: List of email addresses
            body: Email body (HTML or text)
            subtype: Message type (html or plain)
        """
        if self.enabled:
            try:
                message = MessageSchema(
                    subject=subject, recipients=recipients, body=body, subtype=subtype
                )
                await self.fastmail.send_message(message)
                logger.info(f"✅ Email sent to {recipients}: {subject}")
            except Exception as e:
                logger.error(f"❌ Failed to send email: {str(e)}")
                # Don't raise exception to avoid breaking the user flow
                # Just log the error
        else:
            # Fallback for development
            self._log_email_to_console(subject, recipients, body)

    def _log_email_to_console(self, subject: str, recipients: List[str], body: str):
        """Log email content to console for debugging."""
        print("\n" + "=" * 60)
        print(f"📧 [MOCK EMAIL] To: {', '.join(recipients)}")
        print(f"📝 Subject: {subject}")
        print("-" * 60)
        print(body)
        print("=" * 60 + "\n")

    async def send_password_reset_email(self, email: EmailStr, code: str):
        """
        Send password reset email with OTP code.
        """
        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; color: #333;">
                <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                    <h2 style="color: #4DA6FF;">Reset Your Password 🔐</h2>
                    <p>Hi there!</p>
                    <p>We received a request to reset the password for your Nova Draw AI account.</p>
                    <p>Use the code below to reset your password:</p>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <span style="background-color: #f0f0f0; color: #333; padding: 15px 30px; font-size: 24px; letter-spacing: 5px; font-weight: bold; border-radius: 10px; border: 2px dashed #FF7EB9;">{code}</span>
                    </div>
                    
                    <p style="font-size: 14px;">This code will expire in 15 minutes.</p>
                    
                    <p style="font-size: 12px; color: #888; margin-top: 30px;">If you didn't ask for this, you can safely ignore this email.</p>
                </div>
            </body>
        </html>
        """

        await self.send_email(
            subject="Your Nova Draw Reset Code", recipients=[email], body=html_body
        )
