// path: crates/mk/src/placeholder.rs
use std::{collections::HashMap, path::Path, rc::Rc, cell::RefCell};
use chrono::Local;
use dirs::config_dir;
use mlua::{Lua, Value, Variadic};
use once_cell::sync::OnceCell;

static LUA_PLACEHOLDERS_CACHE: OnceCell<HashMap<String, String>> = OnceCell::new();

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

/// Cached accessor (process-lifetime) for Lua placeholders
pub fn lua_placeholders_cached() -> &'static HashMap<String, String> {
    LUA_PLACEHOLDERS_CACHE.get_or_init(|| lua_placeholders())
}

/// Execute a Lua script to collect placeholders.
/// Supports two styles:
/// 1) Return a table: `return { KEY = "VALUE", ... }`
/// 2) Print lines: `KEY=VALUE` (we capture `print(...)` and parse lines)
/// Search order: ./mk_placeholders.lua, then ~/.config/mk/mk_placeholders.lua
pub fn lua_placeholders() -> HashMap<String, String> {
    use std::path::PathBuf;
    let mut m = HashMap::new();
    let local = Path::new("./mk_placeholders.lua");
    let home: PathBuf = config_dir()
    .unwrap_or_else(|| Path::new(".").to_path_buf())
    .join("mk")
    .join("mk_placeholders.lua");

    let script_path = if local.exists() { local.to_path_buf() } else if home.exists() { home } else { return m };

    // Spin up Lua VM with a custom print that captures lines
    let lua = Lua::new();

    let captured: Rc<RefCell<Vec<String>>> = Rc::new(RefCell::new(Vec::new()));
    let out = Rc::clone(&captured);
    if let Ok(print_fn) = lua.create_function(move |_, args: Variadic<Value>| {
        let mut parts = Vec::new();
        for v in args {
            match v {
                Value::String(s) => parts.push(s.to_str().unwrap_or_default().to_string()),
                                              Value::Integer(i) => parts.push(i.to_string()),
                                              Value::Number(n) => parts.push(n.to_string()),
                                              Value::Boolean(b) => parts.push(b.to_string()),
                                              _ => parts.push(String::new()),
            }
        }
        out.borrow_mut().push(parts.join("	"));
        Ok(())
    }) {
        let _ = lua.globals().set("print", print_fn);
    }

    // Load and execute the script
    match std::fs::read_to_string(&script_path) {
        Ok(src) => {
            // set_name expects Into<String>; use &str via .to_string_lossy().as_ref()
            let name = script_path.to_string_lossy();
            let chunk = lua.load(&src).set_name(name.as_ref());

            match chunk.eval::<Value>() {
                Ok(Value::Table(t)) => {
                    // Preferred: table return
                    for pair in t.pairs::<String, Value>() {
                        if let Ok((k, v)) = pair {
                            if let Some(s) = value_to_string(&v) { m.insert(k, s); }
                        }
                    }
                }
                Ok(_) | Err(_) => {
                    // Fallback: parse captured prints as KEY=VALUE lines
                    for line in captured.borrow().iter() {
                        if let Some((k, v)) = line.split_once('=') {
                            let k = k.trim(); let v = v.trim();
                            if !k.is_empty() { m.insert(k.to_string(), v.to_string()); }
                        }
                    }
                }
            }
        }
        Err(_) => { /* ignore */ }
    }

    m
}

fn value_to_string(v: &Value) -> Option<String> {
    match v {
        Value::String(s) => Some(s.to_str().ok()?.to_string()),
        Value::Integer(i) => Some(i.to_string()),
        Value::Number(n) => Some(n.to_string()),
        Value::Boolean(b) => Some(b.to_string()),
        _ => None,
    }
}

pub fn apply_placeholders(mut content: String, map: &std::collections::HashMap<String, String>) -> String {
    for (k, v) in map.iter() {
        let token = format!("<{{&{}&}}>", k);
        content = content.replace(&token, v);
    }
    content
}
