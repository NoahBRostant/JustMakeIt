// path: crates/mk/src/template.rs
use std::path::Path;

use chrono::Local;

#[derive(Debug, Clone)]
pub struct ContextVars {
    pub date: String,
    pub year: String,
    pub author: String,
    pub file_name: String,
    pub file_stem: String,
}

impl ContextVars {
    pub fn from_path<P: AsRef<Path>>(p: P, author: Option<&str>) -> Self {
        let p = p.as_ref();
        let name = p.file_name().and_then(|s| s.to_str()).unwrap_or("").to_string();
        let stem = p.file_stem().and_then(|s| s.to_str()).unwrap_or("").to_string();
        let now = Local::now();
        Self {
            date: now.format("%Y-%m-%d").to_string(),
            year: now.format("%Y").to_string(),
            author: author.unwrap_or("").to_string(),
            file_name: name,
            file_stem: stem,
        }
    }
}

pub fn render(body: &str, ctx: &ContextVars) -> String {
    // Tiny, fast placeholder replacement. Supports {date},{year},{author},{file_name},{file_stem}
    let mut out = body.to_string();
    for (k, v) in [
        ("{date}", &ctx.date),
        ("{year}", &ctx.year),
        ("{author}", &ctx.author),
        ("{file_name}", &ctx.file_name),
        ("{file_stem}", &ctx.file_stem),
    ] {
        out = out.replace(k, v);
    }
    out
}
