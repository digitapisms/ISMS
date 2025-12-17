# Google Meet JWT Signing Fix

## ✅ Bug Fixed

**Issue:** The `createJWT` function was returning a hardcoded placeholder signature (`"signature"`) instead of properly signing the JWT with RSA using the private key. This would cause Google's OAuth endpoint to reject the invalid JWT, preventing Google Meet meeting creation.

## Changes Made

### 1. Implemented Proper RS256 JWT Signing

The `createJWT` function now:
- ✅ Properly signs JWTs using RS256 algorithm with the private key
- ✅ Uses Deno's Web Crypto API for cryptographic operations
- ✅ Correctly encodes the signature in base64url format
- ✅ Handles multiple private key formats (PEM string, JSON object, JSON string)

### 2. Added Helper Functions

**`base64UrlEncode(data: string): string`**
- Converts data to base64url encoding (JWT standard)
- Replaces `+` with `-`, `/` with `_`, and removes padding `=`

**`pemToArrayBuffer(pem: string): ArrayBuffer`**
- Converts PEM-formatted private key to ArrayBuffer
- Removes PEM headers and whitespace
- Decodes base64 to binary format

**`extractPrivateKeyPem(privateKey: any): string`**
- Handles multiple private key storage formats:
  - Direct PEM string
  - JSON object with `private_key` or `privateKey` field
  - JSON string that needs parsing
- Provides clear error messages for invalid formats

### 3. Updated Private Key Parsing

The main function now:
- Attempts to parse private key as JSON (Google Service Account format)
- Falls back to treating it as a PEM string if JSON parsing fails
- Passes the key in its original format to `createJWT`, which handles both cases

## Technical Details

### JWT Signing Process

1. **Create JWT Header and Claims**
   - Header: `{ alg: 'RS256', typ: 'JWT' }`
   - Claims: `{ iss, scope, aud, exp, iat }`

2. **Encode Header and Claims**
   - Base64url encode both header and claims
   - Combine: `encodedHeader.encodedClaim`

3. **Sign with Private Key**
   - Extract PEM from various formats
   - Import key using Web Crypto API (`crypto.subtle.importKey`)
   - Sign using RSASSA-PKCS1-v1_5 with SHA-256
   - Encode signature in base64url

4. **Return Complete JWT**
   - Format: `header.claim.signature`

### Supported Private Key Formats

The implementation supports:

1. **PEM String (Direct)**
   ```
   -----BEGIN PRIVATE KEY-----
   MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
   -----END PRIVATE KEY-----
   ```

2. **Google Service Account JSON Object**
   ```json
   {
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
     "client_email": "...",
     "project_id": "..."
   }
   ```

3. **JSON String**
   - String containing JSON that will be parsed

## Error Handling

The implementation includes comprehensive error handling:
- Invalid private key format detection
- Clear error messages for troubleshooting
- Proper exception propagation with context

## Testing

To verify the fix works:

1. **Ensure credentials are configured:**
   - `GOOGLE_MEET_CLIENT_EMAIL`
   - `GOOGLE_MEET_PRIVATE_KEY` (PEM format or JSON with `private_key`)
   - `GOOGLE_MEET_PROJECT_ID`

2. **Test the Edge Function:**
   ```bash
   curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/create-google-meet \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_ANON_KEY" \
     -d '{
       "title": "Test Meeting",
       "startTime": "2024-01-01T10:00:00Z",
       "duration": 60
     }'
   ```

3. **Expected Result:**
   - JWT is properly signed and accepted by Google OAuth
   - Access token is obtained successfully
   - Google Meet meeting is created

## Security Notes

- ✅ Private keys are never logged or exposed in error messages
- ✅ Uses industry-standard RS256 algorithm
- ✅ Proper key format validation
- ✅ Secure key import using Web Crypto API

## Files Modified

- `isms_app/supabase/functions/create-google-meet/index.ts`
  - Replaced placeholder JWT signing with proper RS256 implementation
  - Added helper functions for key extraction and encoding
  - Improved error handling and format support

---

**Fixed:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Status:** ✅ Ready for production use
