local base32 = {}

base32.alphabet = string.split("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567", "")
base32.alphabet_rev = {}
for i, v in pairs(base32.alphabet) do
	base32.alphabet_rev[v] = i - 1
end

base32.decimalToBinary = function(decimal)
	local binary = ""
	while decimal > 0 do
		binary = tostring(decimal % 2) .. binary
		decimal = math.floor(decimal / 2)
	end
	return binary ~= "" and binary or "0"
end

base32.decode = function(str)
	local splitbits = str:gsub(".", function(c)
		return c ~= "=" and string.format("%05u", base32.decimalToBinary(base32.alphabet_rev[c])) or ""
	end)
	return ((splitbits:len() % 8) == 0 and splitbits or splitbits .. string.rep("0", (8 - (splitbits:len() % 8)))):gsub("%d%d%d%d%d%d%d%d", function(c)
		return tonumber(c,2) ~= 0 and string.char(tonumber(c, 2)) or ""
	end)
end

return base32
