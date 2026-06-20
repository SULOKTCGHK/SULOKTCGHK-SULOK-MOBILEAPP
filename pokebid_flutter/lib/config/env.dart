/// 集中管理密鑰與環境設定。
///
/// 值透過 `--dart-define-from-file=env.json` 在編譯時注入，原始碼不寫死。
///
/// 執行方式：
///   flutter run -d chrome --dart-define-from-file=env.json
///   flutter build web --dart-define-from-file=env.json
///
/// env.json 範例見 env.example.json（env.json 本身已被 .gitignore 排除）。
///
/// 注意：web/行動 app 屬於前端，任何打包進 app 的金鑰最終都可能被使用者看到。
/// 真正的機密（如 eBay Cert ID）請放在伺服器端（Supabase Edge Function secrets），
/// 不要放在這裡。此檔僅用於：避免密鑰進入 git、方便更換、區分環境。
class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String justTcgKey = String.fromEnvironment('JUSTTCG_KEY');

  /// 啟動時呼叫，缺少必要設定時提早報錯（方便除錯）。
  static void assertValid() {
    assert(supabaseUrl.isNotEmpty,
        '缺少 SUPABASE_URL，請用 --dart-define-from-file=env.json 執行');
    assert(supabaseAnonKey.isNotEmpty,
        '缺少 SUPABASE_ANON_KEY，請用 --dart-define-from-file=env.json 執行');
  }
}
