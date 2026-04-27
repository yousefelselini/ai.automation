export function isMetaConfigured() {
  return Boolean(process.env.META_APP_ID && process.env.META_APP_SECRET && process.env.META_VERIFY_TOKEN && process.env.META_REDIRECT_URI);
}
