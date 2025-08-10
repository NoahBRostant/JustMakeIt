// path: crates/mk/src/ops.rs
use std::{
    fs::{self, OpenOptions},
    io::Write,
    path::Path,
    process::Command,
};

use anyhow::{bail, Context, Result};

use crate::{config::Template, template};

pub fn create_dir<P: AsRef<Path>>(path: P, parents: bool, mode: Option<&str>, dry_run: bool) -> Result<()> {
    let p = path.as_ref();
    if dry_run {
        println!("mk: create dir {}{}", p.display(), if parents {" (parents)"} else {""});
        return Ok(());
    }
    if p.exists() {
        if p.is_dir() {
            #[cfg(unix)]
            if let Some(m) = mode { apply_mode_unix(p, m)?; }
            println!("mk: exists {}", p.display());
            return Ok(());
        } else {
            bail!("path exists and is not a directory: {}", p.display());
        }
    }
    if parents {
        fs::create_dir_all(p).with_context(|| format!("creating {}", p.display()))?;
    } else {
        fs::create_dir(p).with_context(|| format!("creating {}", p.display()))?;
    }
    #[cfg(unix)]
    if let Some(m) = mode { apply_mode_unix(p, m)?; }
    println!("mk: created dir {}", p.display());
    Ok(())
}

pub fn create_file(
    path: &Path,
    tmpl: Option<&Template>,
    ctx: &template::ContextVars,
    parents: bool,
    force: bool,
        no_clobber: bool,
        mode: Option<&str>,
        stdin_content: Option<&str>,
        dry_run: bool,
) -> Result<()> {
    if dry_run {
        println!("mk: create file {}", path.display());
        return Ok(());
    }

    if let Some(parent) = path.parent() {
        if parents {
            fs::create_dir_all(parent)
            .with_context(|| format!("creating parents for {}", path.display()))?;
        }
    }

    let exists = path.exists();
    if exists && no_clobber {
        println!("mk: exists, skipping {}", path.display());
        return Ok(());
    }

    // Decide content
    let mut content = String::new();
    if let Some(s) = stdin_content {
        content.push_str(s);
    } else if let Some(t) = tmpl {
        content = crate::template::render(&t.body, ctx);
    }

    // Open with overwrite or create_new semantics
    let f = if force {
        OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(true)
        .open(path)
    } else {
        OpenOptions::new()
        .create_new(!exists)
        .create(true)
        .write(true)
        .open(path)
    };
    let mut f = f.with_context(|| format!("opening {}", path.display()))?;

    if !content.is_empty() {
        f.write_all(content.as_bytes())
        .with_context(|| format!("writing {}", path.display()))?;
    }

    // Apply mode: CLI flag takes precedence over template mode
    #[cfg(unix)]
    {
        let mode_final = mode.or_else(|| tmpl.and_then(|t| t.mode.as_deref()));
        if let Some(m) = mode_final { apply_mode_unix(path, m)?; }
    }

    println!("mk: created {}", path.display());
    Ok(())
}

#[cfg(unix)]
fn apply_mode_unix(path: &Path, octal: &str) -> Result<()> {
    use std::os::unix::fs::PermissionsExt;
    let m = u32::from_str_radix(octal, 8).context("parsing mode octal (e.g. 644)")?;
    let perm = fs::Permissions::from_mode(m);
    fs::set_permissions(path, perm).with_context(|| format!("chmod {octal} {}", path.display()))?;
    Ok(())
}

#[cfg(not(unix))]
fn apply_mode_unix(_path: &Path, _octal: &str) -> Result<()> { Ok(()) }

pub fn open_in_editor(path: &Path, editor: Option<&str>) -> Result<()> {
    let ed = editor
    .map(|s| s.to_string())
    .or_else(|| std::env::var("VISUAL").ok())
    .or_else(|| std::env::var("EDITOR").ok())
    .unwrap_or_else(|| {
        #[cfg(target_os="windows")]
        { "notepad".to_string() }
        #[cfg(not(target_os="windows"))]
        { "nano".to_string() }
    });

    let status = Command::new(ed)
    .arg(path)
    .status()
    .context("spawning editor")?;

    if !status.success() { bail!("editor exited with non-zero status"); }
    Ok(())
}
