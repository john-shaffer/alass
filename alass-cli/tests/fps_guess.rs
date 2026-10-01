//! Framerate guessing against real timings: voice activity spans extracted from an episode with
//! music under most of the dialog, and its English subtitles, which were timed for 25 FPS while
//! the video runs at 23.976 FPS.

use alass_cli::{guess_fps_ratio, NoProgressInfo, FPS_RATIOS, FPS_RATIO_DESCRIPTIONS};
use alass_core::{TimePoint, TimeSpan};

fn load(name: &str) -> Vec<TimeSpan> {
    let path = format!("{}/tests/fixtures/{}", env!("CARGO_MANIFEST_DIR"), name);
    std::fs::read_to_string(&path)
        .unwrap()
        .lines()
        .map(|line| {
            let mut ms = line.split(' ').map(|x| x.parse::<i64>().unwrap());
            TimeSpan::new(TimePoint::from(ms.next().unwrap()), TimePoint::from(ms.next().unwrap()))
        })
        .collect()
}

fn guess(vad: &[TimeSpan], subs: &[TimeSpan]) -> &'static str {
    let (idx, _) = guess_fps_ratio(vad, subs, &FPS_RATIOS, NoProgressInfo {});
    idx.map_or("1", |idx| FPS_RATIO_DESCRIPTIONS[idx])
}

#[test]
fn guesses_ratio_for_drifting_subtitles() {
    let vad = load("bluey-s01e05-vad.txt");
    let subs = load("bluey-s01e05-subs.txt");
    assert_eq!(guess(&vad, &subs), "23.976/25");
}

#[test]
fn guesses_no_ratio_after_correction() {
    let vad = load("bluey-s01e05-vad.txt");
    let subs: Vec<TimeSpan> = load("bluey-s01e05-subs.txt")
        .into_iter()
        .map(|ts| ts.scaled(23.976 / 25.))
        .collect();
    assert_eq!(guess(&vad, &subs), "1");
}
