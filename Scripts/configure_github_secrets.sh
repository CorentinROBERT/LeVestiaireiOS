#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/Scripts/ci-secrets.local.env"
EXAMPLE_FILE="${ROOT_DIR}/Scripts/ci-secrets.env.example"

cd "$ROOT_DIR"

if [ ! -f "$ENV_FILE" ]; then
  cp "$EXAMPLE_FILE" "$ENV_FILE"
  echo "✅ Fichier créé : Scripts/ci-secrets.local.env"
  echo "   Remplis les chemins et identifiants, puis relance ce script."
  exit 0
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

require_var() {
  local name="$1"
  local value="${!name:-}"
  if [ -z "$value" ]; then
    echo "❌ Variable manquante dans ci-secrets.local.env : $name"
    exit 1
  fi
}

require_file() {
  local path="$1"
  local label="$2"
  if [ ! -f "$path" ]; then
    echo "❌ Fichier introuvable ($label) : $path"
    exit 1
  fi
}

require_var APP_STORE_CONNECT_KEY_ID
require_var APP_STORE_CONNECT_ISSUER_ID
require_var APP_STORE_CONNECT_KEY_PATH
require_var IOS_DISTRIBUTION_CERTIFICATE_PATH
require_var IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
require_var IOS_PROVISIONING_PROFILE_PATH
require_var KEYCHAIN_PASSWORD

require_file "$APP_STORE_CONNECT_KEY_PATH" "clé API App Store Connect"
require_file "$IOS_DISTRIBUTION_CERTIFICATE_PATH" "certificat .p12"
require_file "$IOS_PROVISIONING_PROFILE_PATH" "profil de provisioning"

if [ -z "${IOS_PROVISIONING_PROFILE_NAME:-}" ]; then
  IOS_PROVISIONING_PROFILE_NAME="$(
    security cms -D -i "$IOS_PROVISIONING_PROFILE_PATH" 2>/dev/null \
      | plutil -extract Name raw - 2>/dev/null || true
  )"
fi

if [ -z "${IOS_PROVISIONING_PROFILE_NAME:-}" ]; then
  echo "❌ Impossible de détecter IOS_PROVISIONING_PROFILE_NAME. Renseigne-le manuellement."
  exit 1
fi

GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-CorentinROBERT/LeVestiaireiOS}"

encode_file() {
  openssl base64 -A -in "$1"
}

APP_STORE_CONNECT_KEY_CONTENT="$(encode_file "$APP_STORE_CONNECT_KEY_PATH")"
IOS_DISTRIBUTION_CERTIFICATE_BASE64="$(encode_file "$IOS_DISTRIBUTION_CERTIFICATE_PATH")"
IOS_PROVISIONING_PROFILE_BASE64="$(encode_file "$IOS_PROVISIONING_PROFILE_PATH")"

echo ""
echo "==> Secrets prêts pour ${GITHUB_REPOSITORY}"
echo "    Profil détecté : ${IOS_PROVISIONING_PROFILE_NAME}"
echo ""

set_secret() {
  local name="$1"
  local value="$2"

  if command -v gh >/dev/null 2>&1; then
    printf '%s' "$value" | gh secret set "$name" --repo "$GITHUB_REPOSITORY" --env production
    echo "✅ Secret GitHub défini (production) : $name"
  else
    echo "⚠️  gh CLI absent — ajoute ce secret manuellement dans GitHub :"
    echo "    Nom  : $name"
    if [ "${#value}" -gt 120 ]; then
      echo "    Valeur : <contenu base64 de ${#value} caractères — utilise gh ou l'UI GitHub>"
    else
      echo "    Valeur : $value"
    fi
    echo ""
  fi
}

if command -v gh >/dev/null 2>&1; then
  if ! gh auth status >/dev/null 2>&1; then
    echo "Connexion GitHub requise : gh auth login"
    exit 1
  fi

  echo "==> Configuration de l'environnement GitHub « production » (si absent)"
  if gh api "repos/${GITHUB_REPOSITORY}/environments/production" >/dev/null 2>&1; then
    echo "✅ Environnement production déjà présent"
  else
    gh api \
      --method PUT \
      "repos/${GITHUB_REPOSITORY}/environments/production" \
      --input - <<< '{}' >/dev/null
    echo "✅ Environnement production créé"
  fi
  echo ""
fi

set_secret "APP_STORE_CONNECT_KEY_ID" "$APP_STORE_CONNECT_KEY_ID"
set_secret "APP_STORE_CONNECT_ISSUER_ID" "$APP_STORE_CONNECT_ISSUER_ID"
set_secret "APP_STORE_CONNECT_KEY_CONTENT" "$APP_STORE_CONNECT_KEY_CONTENT"
set_secret "IOS_DISTRIBUTION_CERTIFICATE_BASE64" "$IOS_DISTRIBUTION_CERTIFICATE_BASE64"
set_secret "IOS_DISTRIBUTION_CERTIFICATE_PASSWORD" "$IOS_DISTRIBUTION_CERTIFICATE_PASSWORD"
set_secret "IOS_PROVISIONING_PROFILE_BASE64" "$IOS_PROVISIONING_PROFILE_BASE64"
set_secret "IOS_PROVISIONING_PROFILE_NAME" "$IOS_PROVISIONING_PROFILE_NAME"
set_secret "KEYCHAIN_PASSWORD" "$KEYCHAIN_PASSWORD"

echo ""
echo "==> Terminé"
echo "    Lance un déploiement : GitHub → Actions → iOS Release → Run workflow"
echo "    Test local (optionnel) : bundle install && bundle exec fastlane beta"
