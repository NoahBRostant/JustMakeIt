// path: crates/mk/src/cli.rs
use std::{fs, io::{self, Read}, path::PathBuf};

use anyhow::{bail, Context, Result};
use clap::{Args, Parser, Subcommand};

use crate::{config::Config, legacy_config, ops, template::ContextVars, templater};

#[derive(Debug, Parser)]
#[command(name = "mk", about = "Just Make It — fast file/dir creation from templates", version)]
pub struct Cli {
    /// Path(s) to create (files and/or directories)
    #[arg(value_name = "PATH", num_args = 0.., global = true)]
    targets: Vec<PathBuf>,

    /// Verbose output
    #[arg(short, long)]
    verbose: bool,

    /// Force create even if file exists (overwrites) [alias: -y/--yes]
    #[arg(short, long, visible_short_alias = 'y', visible_alias = "yes")]
    force: bool,

        /// Do not overwrite existing files [alias: -n/--no]
        #[arg(short = 'n', long, visible_alias = "no")]
        no_clobber: bool,

        /// Create parent directories as needed
        #[arg(short = 'p', long)]
        parents: bool,

        /// Treat target(s) as directories
        #[arg(short = 'd', long)]
        dir: bool,

        /// Explicitly treat target(s) as files
        #[arg(short = 'f', long)]
        file: bool,

        /// Template name (file in ~/.mk/.templates) or extension (e.g. rs, py, md)
        #[arg(short = 't', long, value_name = "NAME|EXT")]
        template: Option<String>,

        /// Do not apply any external template files/placeholders
        #[arg(long = "no-template")]
        no_template: bool,

        /// File mode in octal (Unix only), e.g. 644, 755  [aliases: -c/--chmod]
        #[arg(short = 'm', long = "mode", visible_short_alias = 'c', visible_alias = "chmod", value_name = "OCTAL")]
        mode: Option<String>,

        /// Open created file(s) in $VISUAL/$EDITOR (or provided editor with --editor)
        #[arg(short='o', long)]
        open: bool,

        /// Editor command to use when --open is set
        #[arg(long, value_name = "EDITOR")]
        editor: Option<String>,

        /// Read content from STDIN and write to file(s)
        #[arg(long)]
        stdin: bool,

        /// Create from a list file (one target per line; supports per-line flags)
        #[arg(short = 'l', long = "list", value_name = "FILE")]
        list_file: Option<PathBuf>,

        /// List templates available in ~/.mk/.templates
        #[arg(long = "list-templates")]
        list_templates: bool,

        /// Dry run (print what would happen)
        #[arg(long)]
        dry_run: bool,

        /// Subcommands
        #[command(subcommand)]
        cmd: Option<Cmd>,
}

#[derive(Debug, Subcommand)]
pub enum Cmd {
    /// List built-in config templates
    Templates,
    /// Initialize a default config to $XDG_CONFIG_HOME/mk/config.toml
    Init(InitArgs),
}

#[derive(Debug, Args)]
pub struct InitArgs {
    /// Overwrite existing config
    #[arg(short, long)]
    force: bool,
}

impl Cli {
    pub fn parse() -> Self { <Self as Parser>::parse() }

    pub fn run(self) -> Result<()> {
        // Flags that don't require targets
        if self.list_templates {
            let list = templater::list_templates()?;
            if list.is_empty() { println!("No templates in ~/.mk/.templates"); }
            else {
                println!("Available templates:");
                for p in list { println!("  - {}", p.file_name().unwrap().to_string_lossy()); }
            }
            return Ok(());
        }

        // Subcommands that do not require targets
        if let Some(cmd) = &self.cmd {
            match cmd {
                Cmd::Templates => {
                    let cfg = Config::load_default()?;
                    for (name, t) in cfg.templates.iter() {
                        println!("{name}{}", t.ext.as_deref().map(|e| format!(" (.{e})")).unwrap_or_default());
                    }
                    return Ok(());
                }
                Cmd::Init(args) => {
                    Config::write_default(args.force)?;
                    println!("mk: wrote default config to {}", Config::default_path()?.display());
                    return Ok(());
                }
            }
        }

        let cfg = Config::load_default()?;
        let legacy = legacy_config::load();

        if self.no_clobber && self.force {
            bail!("--no-clobber and --force are mutually exclusive");
        }

        if self.targets.is_empty() && self.list_file.is_none() {
            bail!("No targets provided. Try: mk README.md src/main.rs -p -t rs");
        }

        // Expand from list file if provided
        if let Some(list_path) = &self.list_file {
            let content = fs::read_to_string(list_path).with_context(|| format!("reading list {}", list_path.display()))?;
            for line in content.lines() {
                let line = line.trim();
                if line.is_empty() || line.starts_with('#') { continue; }
                let mut parts = line.split_whitespace();
                let Some(path_str) = parts.next() else { continue };
                let mut t_override = self.template.clone();
                let mut mode_override = self.mode.clone();
                let mut open_override = self.open;
                let mut no_tmpl_override = self.no_template;
                let mut force_override = self.force;
                let mut no_clobber_override = self.no_clobber;
                for arg in parts {
                    if let Some(rest) = arg.strip_prefix("-t=").or(arg.strip_prefix("--template=")) { t_override = Some(rest.to_string()); }
                    else if let Some(rest) = arg.strip_prefix("-c=").or(arg.strip_prefix("--chmod=")) { mode_override = Some(rest.to_string()); }
                    else if arg == "-o" || arg == "--open" { open_override = true; }
                    else if arg == "--no-template" { no_tmpl_override = true; }
                    else if arg == "-y" || arg == "--yes" { force_override = true; no_clobber_override = false; }
                    else if arg == "-n" || arg == "--no" { no_clobber_override = true; force_override = false; }
                }
                self.process_single(PathBuf::from(path_str), &cfg, &legacy, t_override, mode_override.as_deref(), open_override, no_tmpl_override, force_override, no_clobber_override)?;
            }
            return Ok(());
        }

        for target in &self.targets {
            // Decide if this should be a directory or a file
            let target_exists = target.exists();
            let treat_as_dir = if self.dir { true }
            else if self.file { false }
            else if target_exists && target.is_dir() { true }
            else if self.template.is_none() && !self.stdin && target.extension().is_none() { true }
            else { false };

            if treat_as_dir {
                ops::create_dir(target, self.parents, self.mode.as_deref(), self.dry_run)?;
                if self.open { println!("mk: directory created: {}", target.display()); }
                continue;
            }

            // Prompt if exists
            if target.exists() && target.is_file() && !self.dry_run {
                if self.force { /* proceed */ }
                else if self.no_clobber { println!("mk: exists, skipping {}", target.display()); continue; }
                else {
                    eprint!("The file '{}' exists. Overwrite? (y/n) ", target.display());
                    use std::io::Write as _; io::stderr().flush().ok();
                    let mut answer = String::new(); io::stdin().read_line(&mut answer)?;
                    if !matches!(answer.trim(), "y"|"Y") { println!("mk: skipped {}", target.display()); continue; }
                }
            }

            // Build template context
            let mut stdin_buf = String::new();
            if self.stdin { io::stdin().read_to_string(&mut stdin_buf).context("reading from stdin")?; }
            let tmpl_name_or_ext = self.template.clone().or_else(|| target.extension().map(|e| e.to_string_lossy().to_string()));
            let tmpl = tmpl_name_or_ext.as_ref().and_then(|key| cfg.get_template(key)).or_else(|| cfg.get_template("default"));
            let ctx = ContextVars::from_path(target, cfg.author.as_deref());
            let content = if self.stdin { Some(stdin_buf.as_str()) } else { None };

            ops::create_file(target, tmpl, &ctx, self.parents, true, false, self.mode.as_deref(), content, self.dry_run)?;

            // External template + placeholders
            if !self.no_template {
                let t_file = templater::resolve_template_for_input(target, self.template.as_deref(), legacy.extension_check)?;
                templater::apply_template_and_placeholders(target, t_file.as_ref(), self.verbose)?;
            }

            if self.open { ops::open_in_editor(target, self.editor.as_deref())?; }
        }

        Ok(())
    }

    fn process_single(
        &self,
        target: PathBuf,
        cfg: &Config,
        legacy: &legacy_config::Legacy,
        template_override: Option<String>,
        mode_override: Option<&str>,
        open_override: bool,
        no_template_override: bool,
        force_override: bool,
            no_clobber_override: bool,
    ) -> Result<()> {
        // Decide if directory
        let target_exists = target.exists();
        let treat_as_dir = if self.dir { true } else if self.file { false } else if target_exists && target.is_dir() { true } else if template_override.is_none() && target.extension().is_none() { true } else { false };
        if treat_as_dir { ops::create_dir(&target, self.parents, mode_override, self.dry_run)?; return Ok(()); }

        // Prompt if exists
        if target.exists() && target.is_file() && !self.dry_run {
            if force_override { /* proceed */ }
            else if no_clobber_override { println!("mk: exists, skipping {}", target.display()); return Ok(()); }
            else {
                eprint!("The file '{}' exists. Overwrite? (y/n) ", target.display());
                use std::io::Write as _; io::stderr().flush().ok();
                let mut answer = String::new(); io::stdin().read_line(&mut answer)?;
                if !matches!(answer.trim(), "y"|"Y") { println!("mk: skipped {}", target.display()); return Ok(()); }
            }
        }

        // Build template context
        let mut stdin_buf = String::new();
        if self.stdin { io::stdin().read_to_string(&mut stdin_buf).context("reading from stdin")?; }
        let tmpl_name_or_ext = template_override.clone().or_else(|| target.extension().map(|e| e.to_string_lossy().to_string()));
        let tmpl = tmpl_name_or_ext.as_ref().and_then(|key| cfg.get_template(key)).or_else(|| cfg.get_template("default"));
        let ctx = ContextVars::from_path(&target, cfg.author.as_deref());
        let content = if self.stdin { Some(stdin_buf.as_str()) } else { None };

        ops::create_file(&target, tmpl, &ctx, self.parents, true, false, mode_override, content, self.dry_run)?;

        if !no_template_override {
            let t_file = templater::resolve_template_for_input(&target, template_override.as_deref(), legacy.extension_check)?;
            templater::apply_template_and_placeholders(&target, t_file.as_ref(), self.verbose)?;
        }

        if open_override { ops::open_in_editor(&target, self.editor.as_deref())?; }
        Ok(())
    }
}
