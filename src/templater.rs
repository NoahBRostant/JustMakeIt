// path: crates/mk/src/templater.rs
use std::{fs, path::{Path, PathBuf}};
use anyhow::{Context, Result};
use once_cell::sync::OnceCell;
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

static TEMPLATES_CACHE: OnceCell<Vec<PathBuf>> = OnceCell::new();
fn cached_templates() -> Vec<PathBuf> {
    TEMPLATES_CACHE.get_or_init(|| {
        let dir = templates_dir();
        let mut out = vec![];
        if let Ok(rd) = fs::read_dir(&dir) {
            for e in rd.flatten() {
                let p = e.path();
                if p.is_file() { out.push(p); }
            }
        }
        out
    }).clone()
}

pub fn resolve_template_for_input(path: &Path, explicit: Option<&str>, extension_check: bool) -> Result<Option<PathBuf>> {
    let dir = templates_dir();
    if !dir.is_dir() { return Ok(None); }

    let list = cached_templates();

    if let Some(name) = explicit {
        // exact filename match first
        let exact = dir.join(name);
        if exact.is_file() { return Ok(Some(exact)); }
        // otherwise match by file_stem
        for p in &list {
            if let Some(stem) = p.file_stem().and_then(|s| s.to_str()) {
                if stem == name { return Ok(Some(p.clone())); }
            }
            if let Some(fname) = p.file_name().and_then(|s| s.to_str()) {
                if fname == name { return Ok(Some(p.clone())); }
            }
        }
    } else if extension_check {
        if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
            for p in &list {
                if p.extension().and_then(|s| s.to_str()) == Some(ext) {
                    return Ok(Some(p.clone()));
                }
            }
        }
    }

    Ok(None)
}

pub fn apply_template_and_placeholders(path: &Path, template_file: Option<&PathBuf>, apply_placeholders: bool, verbose: bool) -> Result<()> {
    // Fast path: if we have a template file, load it and (optionally) apply placeholders in-memory, then write once.
    if let Some(tpl) = template_file {
        let mut data = fs::read_to_string(tpl).with_context(|| format!("reading template {}", tpl.display()))?;
        if verbose { eprintln!("Template applied: {}", tpl.display()); }
        if apply_placeholders {
            let mut map = placeholder::builtins_for(path);
            for (k, v) in placeholder::lua_placeholders_cached().iter() { map.insert(k.clone(), v.clone()); }
            data = placeholder::apply_placeholders(data, &map);
        } else if verbose {
            eprintln!("Skipped placeholders for {}", path.display());
        }
        fs::write(path, data).with_context(|| format!("writing {}", path.display()))?;
        if apply_placeholders && verbose { eprintln!("Processed placeholders for {}", path.display()); }
        return Ok(());
    }

    // Otherwise, only placeholders (if enabled) against whatever content is already on disk
    if apply_placeholders {
        let mut map = placeholder::builtins_for(path);
        for (k, v) in placeholder::lua_placeholders_cached().iter() { map.insert(k.clone(), v.clone()); }
        let content = fs::read_to_string(path).with_context(|| format!("reading {}", path.display()))?;
        let updated = placeholder::apply_placeholders(content, &map);
        fs::write(path, updated).with_context(|| format!("writing {}", path.display()))?;
        if verbose { eprintln!("Processed placeholders for {}", path.display()); }
    } else if verbose {
        eprintln!("Skipped placeholders for {}", path.display());
    }
    Ok(())
}
