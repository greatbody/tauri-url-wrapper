#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::thread;
use std::time::Duration;
use sysinfo::{Pid, System};
use tauri::Manager;

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            let window = app.get_webview_window("main").unwrap();
            let base_title = window.title().unwrap_or_default();
            let pid = Pid::from_u32(std::process::id());

            thread::spawn(move || {
                let mut sys = System::new();
                loop {
                    sys.refresh_processes(sysinfo::ProcessesToUpdate::Some(&[pid]), true);
                    if let Some(proc) = sys.process(pid) {
                        let mem_bytes = proc.memory();
                        let mem_mb = mem_bytes as f64 / 1_048_576.0;
                        let cpu = proc.cpu_usage();
                        let title = format!("{} — {:.1} MB | CPU {:.1}%", base_title, mem_mb, cpu);
                        let _ = window.set_title(&title);
                    }
                    thread::sleep(Duration::from_secs(2));
                }
            });

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
