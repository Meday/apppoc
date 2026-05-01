use std::sync::Mutex;

use tauri::{Manager, RunEvent};
use tauri_plugin_shell::process::CommandChild;
use tauri_plugin_shell::ShellExt;

#[derive(Default)]
struct SidecarState(Mutex<Option<CommandChild>>);

fn resolve_backend_root(app: &tauri::App) -> String {
    // In production, the backend is bundled in the resource directory
    if let Ok(resource_dir) = app.path().resource_dir() {
        let backend_public = resource_dir.join("backend").join("public");
        if backend_public.exists() {
            return backend_public.to_string_lossy().to_string();
        }
    }
    // Fallback for dev mode: relative path from the project root
    "backend/public".to_string()
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_shell::init())
        .manage(SidecarState::default())
        .setup(|app| {
            let backend_root = resolve_backend_root(app);
            let sidecar_command = app.shell().sidecar("frankenphp");
            match sidecar_command {
                Ok(cmd) => {
                    match cmd
                        .args([
                            "php-server",
                            "--listen",
                            "127.0.0.1:8080",
                            "--root",
                            &backend_root,
                        ])
                        .spawn()
                    {
                        Ok(sidecar) => {
                            let state = app.state::<SidecarState>();
                            *state.0.lock().unwrap() = Some(sidecar.1);
                        }
                        Err(e) => {
                            eprintln!("Sidecar spawn failed (dev mode?): {e}");
                        }
                    }
                }
                Err(e) => {
                    eprintln!("Sidecar not found (dev mode?): {e}");
                }
            }

            Ok(())
        })
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
