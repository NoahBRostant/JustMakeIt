// path: crates/mk/src/config.rs
use std::{collections::BTreeMap, fs, path::PathBuf};

use anyhow::{Context, Result};
use dirs::config_dir;
use serde::{Deserialize, Serialize};

fn default_true() -> bool { true }
fn default_false() -> bool { false }

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Config {
    #[serde(default)]
    pub author: Option<String>,
    /// If true, mk will create missing parent directories automatically (like `mkdir -p`).
    /// Can still be overridden per-invocation via `-p/--parents` (which always enables it).
    #[serde(default = "default_true")]
    pub auto_create_parents: bool,
    #[serde(default = "default_false")]
    pub extension_check: bool,
    /// If true, mk will run the external placeholder stage (builtins + Lua) after writing files.
    /// Set to false to skip `<{&KEY&}>` replacement without disabling external file templates.
    #[serde(default = "default_true")]
    pub apply_external_placeholders: bool,
    #[serde(default)]
    pub templates: BTreeMap<String, Template>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Template {
    /// Optional file extension associated with this template (e.g. "rs")
    pub ext: Option<String>,
    /// Optional file mode (octal string, Unix only)
    pub mode: Option<String>,
    /// Body content (supports {vars})
    pub body: String,
}

impl Config {
    pub fn default_path() -> Result<PathBuf> {
        let base = config_dir().context("cannot resolve config dir ($XDG_CONFIG_HOME)")?;
        Ok(base.join("mk").join("config.toml"))
    }

    pub fn load_default() -> Result<Self> {
        let path = Self::default_path()?;
        if !path.exists() {
            return Ok(Self::default_with_builtin());
        }
        let s = fs::read_to_string(&path)
        .with_context(|| format!("reading config: {}", path.display()))?;
        let mut cfg: Self = toml::from_str(&s).context("parsing config.toml")?;
        // ensure builtins exist but do not override user entries
        for (k, v) in Self::builtin_templates() {
            cfg.templates.entry(k).or_insert(v);
        }
        Ok(cfg)
    }

    pub fn write_default(force: bool) -> Result<()> {
        let path = Self::default_path()?;
        if let Some(parent) = path.parent() {
            // Always create missing parent directories (quality-of-life default).
            // This mirrors common shell usage expectations like `mkdir -p $(dirname file)`.
            if !parent.exists() {
                fs::create_dir_all(parent)
                .with_context(|| format!("creating parents for {}", path.display()))?;
            }
        }
        if path.exists() && !force {
            anyhow::bail!("config exists: {} (use --force to overwrite)", path.display());
        }
        let cfg = Self::default_with_builtin();
        fs::write(&path, toml::to_string_pretty(&cfg)?)
        .with_context(|| format!("writing {}", path.display()))?;
        Ok(())
    }

    pub fn get_template(&self, key: &str) -> Option<&Template> {
        // prefer explicit name match, then any template whose ext matches key
        self.templates.get(key).or_else(|| {
            self.templates.values().find(|t| t.ext.as_deref() == Some(key))
        })
    }

    fn default_with_builtin() -> Self {
        let mut cfg = Self { author: None, auto_create_parents: default_true(), extension_check: default_false(), apply_external_placeholders: default_true(), templates: Default::default() };
        for (k, v) in Self::builtin_templates() {
            cfg.templates.insert(k, v);
        }
        cfg
    }

    fn builtin_templates() -> Vec<(String, Template)> {
        vec![
            ("default".into(), Template { ext: None, mode: None, body: "".into() }),
            ("rs".into(), Template {
                ext: Some("rs".into()), mode: None,
             body: r#"// {file_name} — created {date}
             // Author: {author}

             fn main() {
             println!("Hello, {file_stem}!");
            }
            "#.into()
            }),
            ("sh".into(), Template {
                ext: Some("sh".into()), mode: Some("755".into()),
             body: "#!/usr/bin/env bash
             set -euo pipefail

             ".into(),
            }),
            ("gd".into(), Template { ext: Some("gd".into()), mode: None, body: "extends Node
                ".into() }),
                ("md".into(), Template { ext: Some("md".into()), mode: None, body: "# {file_stem}

                ".into() }),
        ]
    }
}
