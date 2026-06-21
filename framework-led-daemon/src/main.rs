mod app;
mod audio;
mod config;
mod device;
mod doctor;
mod font;
mod frame;
mod notify;
mod render;
mod sys;
mod tmux;

use anyhow::Result;
use clap::{Parser, Subcommand};
use tracing_subscriber::EnvFilter;

#[derive(Debug, Parser)]
#[command(version, about = "Framework Laptop LED Matrix status daemon")]
struct Cli {
    #[command(subcommand)]
    command: Option<Command>,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// Run the daemon. This is also the default when no command is given.
    Run(app::RunArgs),
    /// Check config, hardware, permissions, and service installation.
    Doctor(doctor::DoctorArgs),
    /// Print detected LED matrix serial devices.
    Devices,
    /// Trigger a transient event. Useful from tmux hooks or scripts.
    Notify {
        #[arg(value_enum)]
        event: notify::ManualEvent,
    },
}

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    let cli = Cli::parse();
    match cli.command.unwrap_or(Command::Run(app::RunArgs::default())) {
        Command::Run(args) => app::run(args),
        Command::Doctor(args) => doctor::run(args),
        Command::Devices => {
            for device in device::discover_devices()? {
                println!("{}", device.describe());
            }
            Ok(())
        }
        Command::Notify { event } => notify::send_manual_event(event),
    }
}
