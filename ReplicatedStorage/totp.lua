local totp = {}

totp.base32 = require(script.base32decode)
totp.sha1 = require(script.sha1)

totp.generate = function(secret, offset)
	local hmac = totp.sha1.hmac_sha1_binary(totp.base32.decode(secret), string.pack(">I8", (os.time() // 30) + offset))

	local start = bit32.band(string.byte(hmac, #hmac), 0x0F)
	local passwordBin = string.sub(hmac, start + 1, start + 4)
	local firstByte = string.byte(passwordBin)
	passwordBin = string.char(bit32.band(firstByte, 0x7F), string.byte(passwordBin, 2, 4))

	local password = string.unpack(">I4", passwordBin) % 1_000_000

	return password
end

return totp
