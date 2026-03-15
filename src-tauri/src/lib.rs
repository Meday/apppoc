// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
use std::sync::Mutex;

use tauri::{Manager, RunEvent};
use tauri_plugin_shell::process::CommandChild;
use tauri_plugin_shell::ShellExt;

#[derive(Default)]
struct SidecarState(Mutex<Option<CommandChild>>);

#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_shell::init())
        .manage(SidecarState::default())
        .setup(|app| {
            let sidecar_command = app.shell().sidecar("frankenphp")?;
            let sidecar = sidecar_command
                .args([
                    "php-server",
                    "--listen",
                    "127.0.0.1:8080",
                    "--root",
                    "backend/public",
                ])
                .spawn()?;

            let state = app.state::<SidecarState>();
            *state.0.lock().unwrap() = Some(sidecar.1);

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![greet])
        .build(tauri::generate_context!())
        .expect("error while building tauri application")
        .run(|app_handle, event| {
            if let RunEvent::Exit = event {
                let child = {
                    let state = app_handle.state::<SidecarState>();
                    let mut guard = state.0.lock().unwrap();
                    guard.take()
                };

                if let Some(child) = child {
                    let _ = child.kill();
                }
            }
        });
}
