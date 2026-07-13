#!/bin/sh
set -eu

TEMPLATE_FILE="email/mail-template.html"
BODY_FILE="/tmp/mail-body.html"
MAIL_FILE="/tmp/mail.txt"

echo "Preparing deployment approval email..."

if [ -z "${BAR_URL:-}" ]; then
  echo "ERROR: BAR_URL is empty"
  exit 1
fi

if [ -z "${DEPLOY_BASE_URL:-}" ]; then
  echo "ERROR: DEPLOY_BASE_URL is empty"
  exit 1
fi

BAR_NAME="$(basename "${BAR_URL}")"

urlencode() {
  value="$1"
  encoded=""

  while [ -n "${value}" ]; do
    character="${value%"${value#?}"}"
    value="${value#?}"

    case "${character}" in
      [a-zA-Z0-9.~_-])
        encoded="${encoded}${character}"
        ;;
      *)
        hex="$(printf '%s' "${character}" | od -An -tx1 | tr -d ' \n')"
        encoded="${encoded}%${hex}"
        ;;
    esac
  done

  printf '%s' "${encoded}"
}

ENCODED_BAR_URL="$(urlencode "${BAR_URL}")"

DEPLOY_URL="${DEPLOY_BASE_URL}/deploy?bar_url=${ENCODED_BAR_URL}"

echo "BAR name: ${BAR_NAME}"
echo "BAR URL: ${BAR_URL}"
echo "Deployment approval URL: ${DEPLOY_URL}"

sed \
  -e "s|{{BAR_NAME}}|${BAR_NAME}|g" \
  -e "s|{{BAR_URL}}|${BAR_URL}|g" \
  -e "s|{{DEPLOY_URL}}|${DEPLOY_URL}|g" \
  "${TEMPLATE_FILE}" > "${BODY_FILE}"

cat > "${MAIL_FILE}" <<EOF
From: ACE CI Pipeline <${SMTP_FROM}>
To: ${SMTP_TO}
Subject: BAR Build Completed - Deploy Approval Required
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8

$(cat "${BODY_FILE}")
EOF

echo "Sending email..."

curl \
  --fail \
  --show-error \
  --url "${SMTP_URL}" \
  --ssl-reqd \
  --mail-from "${SMTP_FROM}" \
  --mail-rcpt "${SMTP_TO}" \
  --user "${SMTP_USER}:${SMTP_PASS}" \
  --upload-file "${MAIL_FILE}"

echo "Email sent successfully"
