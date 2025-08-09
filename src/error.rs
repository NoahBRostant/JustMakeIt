// path: crates/mk/src/error.rs
use thiserror::Error;

#[derive(Debug, Error)]
pub enum MkError {
    #[error("template not found: {0}")]
    TemplateNotFound(String),
}
