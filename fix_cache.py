with open('server/middleware/cache.js', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("const cacheKey = _;", "const cacheKey = ${keyPrefix}_;")

content = content.replace("given_loans_;", "given_loans_")
content = content.replace("taken_loans_;", "taken_loans_")
content = content.replace("Invalidated cache for user", "Invalidated cache for user ")

with open('server/middleware/cache.js', 'w', encoding='utf-8') as f:
    f.write(content)
