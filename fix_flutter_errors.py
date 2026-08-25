import os
file_path = 'lib/core/network/api_client.dart'
with open(file_path, 'r', encoding='utf-8') as f: content = f.read()
content = content.replace("Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async => await _dio.get(path, queryParameters: queryParameters);", "Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async => await _dio.get(path, queryParameters: queryParameters, options: options);")
with open(file_path, 'w', encoding='utf-8') as f: f.write(content)

file_path = 'lib/core/blocs/security/security_cubit.dart'
with open(file_path, 'r', encoding='utf-8') as f: content = f.read()
content = content.replace("import '../../services/secure_storage_service.dart';", "import '../../utils/secure_storage.dart';")
content = content.replace("final SecureStorageService _storage;", "")
content = content.replace("SecurityCubit(this._repository, this._storage) : super(SecurityState());", "SecurityCubit(this._repository) : super(SecurityState());")
content = content.replace("await _storage.getRefreshToken();", "await SecureStorage.getRefreshToken();")
with open(file_path, 'w', encoding='utf-8') as f: f.write(content)

file_path = 'lib/config/routes.dart'
with open(file_path, 'r', encoding='utf-8') as f: content = f.read()
content = content.replace("import '../core/services/secure_storage_service.dart';", "")
content = content.replace("SecurityCubit(SecurityRepository(ctx.read<ApiClient>()), ctx.read<SecureStorageService>())", "SecurityCubit(SecurityRepository(ctx.read<ApiClient>()))")
with open(file_path, 'w', encoding='utf-8') as f: f.write(content)

print("Fixed Flutter errors")
