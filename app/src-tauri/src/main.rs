// В готовой сборке для Windows не открывать окно консоли рядом с приложением.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    axo_team_desktop_lib::run()
}
