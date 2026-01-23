/**
 * UTF-8 safe Base64 encoding/decoding helpers
 *
 * Standard JavaScript atob/btoa functions don't handle UTF-8 multi-byte
 * characters correctly. They treat each byte as a single Latin-1 character,
 * which causes "mojibake" corruption for characters like em-dash (—),
 * curly quotes, and non-ASCII text.
 *
 * These helpers properly encode strings to UTF-8 bytes before Base64 encoding,
 * and properly decode UTF-8 bytes after Base64 decoding.
 */

/**
 * Encode a string to Base64, properly handling UTF-8 multi-byte characters
 * @param {string} str - The string to encode
 * @returns {string} Base64 encoded string
 */
export function base64EncodeUTF8(str) {
  // First encode to UTF-8 using encodeURIComponent (which produces %XX sequences)
  // Then convert those sequences back to bytes for btoa
  return btoa(
    encodeURIComponent(str).replace(/%([0-9A-F]{2})/g, (_, p1) =>
      String.fromCharCode(parseInt(p1, 16))
    )
  )
}

/**
 * Decode a Base64 string, properly handling UTF-8 multi-byte characters
 * @param {string} str - The Base64 string to decode
 * @returns {string} Decoded UTF-8 string
 */
export function base64DecodeUTF8(str) {
  // First decode Base64 to bytes, then convert each byte to a %XX sequence
  // and use decodeURIComponent to properly decode UTF-8
  return decodeURIComponent(
    atob(str)
      .split('')
      .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
      .join('')
  )
}
