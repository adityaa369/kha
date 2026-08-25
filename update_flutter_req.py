import os

file_path = 'lib/data/repositories/security_repository.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "Future<List<SessionModel>> getSessions() async {",
    "Future<List<SessionModel>> getSessions(String? currentRefreshToken) async {"
)

content = content.replace(
    "final response = await _apiClient.get('/auth/sessions');",
    "final response = await _apiClient.get('/auth/sessions', options: Options(headers: currentRefreshToken != null ? {'x-refresh-token': currentRefreshToken} : {}));"
)

# add import for Options
content = "import 'package:dio/dio.dart';\n" + content

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

# Update Cubit
cubit_path = 'lib/core/blocs/security/security_cubit.dart'
with open(cubit_path, 'r', encoding='utf-8') as f:
    c_content = f.read()

c_content = c_content.replace(
    "final sessions = await _repository.getSessions();",
    "final rt = await _storage.getRefreshToken();\n      final sessions = await _repository.getSessions(rt);"
)

with open(cubit_path, 'w', encoding='utf-8') as f:
    f.write(c_content)

# Update SessionModel
model_path = 'lib/data/models/session_model.dart'
with open(model_path, 'r', encoding='utf-8') as f:
    m_content = f.read()

m_content = m_content.replace("final DateTime expiresAt;", "final DateTime expiresAt;\n  final bool isCurrent;")
m_content = m_content.replace("required this.expiresAt,", "required this.expiresAt,\n    this.isCurrent = false,")
m_content = m_content.replace("expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : DateTime.now(),", "expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : DateTime.now(),\n      isCurrent: json['isCurrent'] == true,")

with open(model_path, 'w', encoding='utf-8') as f:
    f.write(m_content)

print("Updated flutter repository and cubit to pass refresh token")
