// path: crates/mk/src/placeholder.rs
use std::{collections::HashMap, path::Path, process::Command};
use chrono::Local;
use dirs::config_dir;
use once_cell::sync::OnceCell;

pub fn builtins_for(path: &Path) -> HashMap<String, String> {
    let mut m = HashMap::new();
    let file_name = path.file_name().and_then(|s| s.to_str()).unwrap_or("").to_string();
    let now = Local::now();
    m.insert("FILENAME".into(), file_name);
    m.insert("DATE".into(), now.format("%Y-%m-%d").to_string());
    m.insert("TIME".into(), now.format("%H:%M:%S").to_string());
    m.insert("DATETIME".into(), now.format("%Y-%m-%d %H:%M:%S").to_string());
    m
}

/// Execute an optional Lua script that prints lines like `KEY=VALUE`.
/// Search order: ./mk_placeholders.lua, then ~/.config/mk/mk_placeholders.lua
pub fn lua_placeholders() -> HashMap<String, String> {
    let mut m = HashMap::new();
    let local = std::path::Path::new("./mk_placeholders.lua");
    let home = config_dir().unwrap_or_else(|| std::path::Path::new(".").to_path_buf()).join("mk").join("mk_placeholders.lua");
    let script = if local.exists() { local.to_path_buf() } else if home.exists() { home } else { return m };

    let out = Command::new("lua").arg(script).output();
    if let Ok(o) = out {
        if o.status.success() {
            if let Ok(s) = String::from_utf8(o.stdout) {
                for line in s.lines() {
                    if let Some((k,v)) = line.split_once('=') {
                        let k = k.trim(); let v = v.trim();
                        if !k.is_empty() { m.insert(k.to_string(), v.to_string()); }
                    }
                }
            }
        }
    }
    m
}

static LUA_CACHE: OnceCell<HashMap<String, String>> = OnceCell::new();
/// Cached variant: runs Lua at most once per process and reuses the map.
pub fn lua_placeholders_cached() -> &'static HashMap<String, String> {
    LUA_CACHE.get_or_init(|| lua_placeholders())
}

pub fn apply_placeholders(mut content: String, map: &HashMap<String, String>) -> String {
    for (k, v) in map.iter() {
        let token = format!("<{{&{}&}}>", k);
        content = content.replace(&token, v);
    }
    content
}
