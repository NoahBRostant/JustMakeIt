// path: crates/mk/src/main.rs
mod cli;
mod config;
mod template;
mod ops;
mod error;
mod templater;
mod placeholder;

use anyhow::Result;

fn main() -> Result<()> {
    let cli = cli::Cli::parse();
    cli.run()
}
