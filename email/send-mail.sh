#!/bin/sh
set -e

TEMPLATE_FILE="email/mail-template.html"
BODY_FILE="/tmp/mail-body.html"
MAIL_FILE="/tmp/mail.txt"
echo "Preparing email body..."

sed \
  -e "s|{{BAR_URL}}|${BAR_URL}|g" \
  -e "s|{{DEPLOY_URL}}|${DEPLOY_URL}|g" \
  "${TEMPLATE_FILE}" > "${BODY_FILE}"

cat > "${MAIL_FILE}" <<EOF
From: ${SMTP_FROM}
To: ${SMTP_TO}
Subject: BAR Build Completed - Deploy Approval Required
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8

$(cat "${BODY_FILE}")
EOF

echo "Sending email..."

curl --url "${SMTP_URL}" \
  --ssl-reqd \
  --mail-from "${SMTP_FROM}" \
  --mail-rcpt "${SMTP_TO}" \
  --user "${SMTP_USER}:${SMTP_PASS}" \
  --upload-file "${MAIL_FILE}"

echo "Email sent successfully"
