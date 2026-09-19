with open('server/index.js', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('const app = express();', "const app = express();\n\n// Trust the reverse proxy (Render) so rate limiting works correctly\napp.set('trust proxy', 1);\n")

with open('server/index.js', 'w', encoding='utf-8') as f:
    f.write(content)
