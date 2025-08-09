// path: crates/mk/src/templater.rs
use std::{fs, path::{Path, PathBuf}};
use anyhow::{Context, Result};
use crate::placeholder;
use crate::legacy_config::mk_home;

pub fn templates_dir() -> PathBuf { mk_home().join(".templates") }

pub fn list_templates() -> Result<Vec<PathBuf>> {
    let dir = templates_dir();
    let mut out = vec![];
    if let Ok(rd) = fs::read_dir(&dir) {
        for e in rd.flatten() { let p = e.path(); if p.is_file() { out.push(p); } }
    }
    Ok(out)
}

pub fn resolve_template_for_input(path: &Path, explicit: Option<&str>, extension_check: bool) -> Result<Option<PathBuf>> {
    let dir = templates_dir();
    if !dir.is_dir() { return Ok(None); }

    if let Some(name) = explicit {
        // match exact or name.*
        let exact = dir.join(name);
        if exact.is_file() { return Ok(Some(exact)); }
        if let Ok(rd) = fs::read_dir(&dir) {
            for e in rd.flatten() {
                let p = e.path();
                if p.is_file() {
                    if let Some(stem) = p.file_stem().and_then(|s| s.to_str()) {
                        if stem == name { return Ok(Some(p)); }
                    }
                }
            }
        }
    } else if extension_check {
        if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
            if let Ok(rd) = fs::read_dir(&dir) {
                for e in rd.flatten() {
                    let p = e.path();
                    if p.is_file() && p.extension().and_then(|s| s.to_str()) == Some(ext) { return Ok(Some(p)); }
                }
            }
        }
    }

    Ok(None)
}

pub fn apply_template_and_placeholders(path: &Path, template_file: Option<&PathBuf>, apply_placeholders: bool, verbose: bool) -> Result<()> {
    if let Some(tpl) = template_file {
        let data = fs::read_to_string(tpl).with_context(|| format!("reading template {}", tpl.display()))?;
        if verbose { eprintln!("Template applied: {}", tpl.display()); }
        fs::write(path, data).with_context(|| format!("writing {}", path.display()))?;
    }
    // placeholders
    if !apply_placeholders { if verbose { eprintln!("Skipped placeholders for {}", path.display()); } return Ok(()); }
    // proceed if enabled
    let mut map = placeholder::builtins_for(path);
    let lua = placeholder::lua_placeholders();
    map.extend(lua);
    let content = fs::read_to_string(path).with_context(|| format!("reading {}", path.display()))?;
    let updated = placeholder::apply_placeholders(content, &map);
    fs::write(path, updated).with_context(|| format!("writing {}", path.display()))?;
    if verbose { eprintln!("Processed placeholders for {}", path.display()); }
    Ok(())
}
