with open('server/controllers/loans.js', 'r', encoding='utf-8') as f:
    content = f.read()
    
content = content.replace("try {\n                const lenderUser", "try {\n            if (req.user.email) {\n                const lenderUser")
content = content.replace("});\n        } catch (emailErr)", "});\n            }\n        } catch (emailErr)")

with open('server/controllers/loans.js', 'w', encoding='utf-8') as f:
    f.write(content)
