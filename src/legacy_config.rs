// path: crates/mk/src/legacy_config.rs
use std::{fs, path::PathBuf};

#[derive(Debug, Clone, Default)]
pub struct Legacy {
    pub auto_update_check: bool,
    pub extension_check: bool,
}

pub fn mk_home() -> PathBuf {
    std::env::var_os("HOME").map(PathBuf::from).unwrap_or_else(|| PathBuf::from("."))
    .join(".mk")
}

pub fn load() -> Legacy {
    let mut leg = Legacy { auto_update_check: false, extension_check: true };
    let conf = mk_home().join("mk.conf");
    if let Ok(s) = fs::read_to_string(conf) {
        for line in s.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') { continue; }
            if let Some((k,v)) = line.split_once('=') {
                let key = k.trim(); let val = v.trim().trim_matches('"');
                match key {
                    "auto_update_check" => leg.auto_update_check = val.eq_ignore_ascii_case("true"),
                    "extension_check" => leg.extension_check = val.eq_ignore_ascii_case("true"),
                    _ => {}
                }
            }
        }
    }
    leg
}
